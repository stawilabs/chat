import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_room_service.dart';
import '../domain/decision_progress.dart' show finishesItselfNote;
import '../domain/governance_requests.dart' show shortAccount;
import '../domain/room_setup.dart' show setupRunsRotation;
import '../domain/rotation.dart';
import '../domain/stawi_money.dart';
import 'contribute_screen.dart';
import 'decision_progress_screen.dart' show followDecision;
import 'governance_sheet.dart';
import 'stawi_feedback.dart';

/// Who a rotation's accounts are: each member's chat name, and which
/// accounts are the signed-in person's.
final class RotationNames {
  const RotationNames(this._byAccount, this._mine);

  static const RotationNames none = RotationNames({}, {});

  final Map<String, String> _byAccount;
  final Set<String> _mine;

  static String _key(List<int> account) => bytesToHex0x(account).toLowerCase();

  bool isMe(List<int> account) => _mine.contains(_key(account));

  /// "You", the member's name, or a short account.
  String of(List<int> account) => isMe(account)
      ? 'You'
      : _byAccount[_key(account)] ?? shortAccount(account);
}

/// A room's rotation names: finance's members by account, named from the
/// chat's members by profile, and the person's own accounts.
final rotationNamesProvider = FutureProvider.autoDispose
    .family<RotationNames, String>((ref, roomId) async {
      final chat = await ref.watch(roomMembersProvider(roomId).future);
      final onChain = await ref.watch(stawiMembersProvider(roomId).future);
      final picks = rotationCandidates([
        for (final m in chat) (profileId: m.profileId, name: m.name),
      ], onChain);
      final names = {
        for (final m in onChain)
          if (m.accountAddress.length == 20)
            RotationNames._key(
              m.accountAddress,
            ): picks.where((p) => p.memberId == m.memberId).firstOrNull?.name ??
                chat
                    .where((c) => c.profileId == m.profileId)
                    .firstOrNull
                    ?.name ??
                shortAccount(m.accountAddress),
      };
      Set<String> mine;
      try {
        final me = await ref.watch(stawiIdentityProvider.future);
        mine = {for (final a in me.addresses) RotationNames._key(a)};
      } on Object {
        mine = {};
      }
      return RotationNames(names, mine);
    });

/// Whether a room can start a rotation: a merry-go-round room once its
/// setup votes have passed.
enum RotationEligibility { notRotationRoom, settingUp, ready }

final rotationEligibilityProvider = FutureProvider.autoDispose
    .family<RotationEligibility, String>((ref, roomId) async {
      final setup = await ref.watch(stawiRoomSetupProvider(roomId).future);
      if (!setupRunsRotation(setup)) return RotationEligibility.notRotationRoom;
      return setup.state == settlement.RoomSetupState.ROOM_SETUP_STATE_READY
          ? RotationEligibility.ready
          : RotationEligibility.settingUp;
    });

/// The room's rotation at a glance on its Stawi page: hidden when it has
/// none (and cannot start one).
class RotationCard extends ConsumerWidget {
  const RotationCard({required this.roomId, required this.roomName, super.key});

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(stawiRotationsProvider(roomId)).asData?.value;
    final eligible = ref
        .watch(rotationEligibilityProvider(roomId))
        .asData
        ?.value;
    final names =
        ref.watch(rotationNamesProvider(roomId)).asData?.value ??
        RotationNames.none;
    final cycle = cycles?.firstOrNull;
    if (cycle == null &&
        (eligible == null || eligible == RotationEligibility.notRotationRoom)) {
      return const SizedBox.shrink();
    }
    final String title;
    final String subtitle;
    if (cycle == null) {
      title = 'Rotation';
      subtitle = eligible == RotationEligibility.ready
          ? 'No rotation yet: start one and the group votes on it'
          : 'You can start a rotation once the setup votes have passed';
    } else {
      final s = RotationStatus(cycle);
      title = s.completed
          ? 'Rotation complete: ${cycle.turns.length} turns'
          : 'Rotation: turn ${cycle.currentTurn + 1} of ${cycle.turns.length}';
      final now = s.current;
      final next = s.next;
      subtitle = s.completed
          ? 'Every turn is paid or passed over'
          : [
              if (now != null) 'Now: ${names.of(now.account)}',
              if (next != null) 'Next: ${names.of(next.account)}',
            ].join(' · ');
    }
    return Card(
      key: const Key('rotation-card'),
      child: ListTile(
        leading: const Icon(Icons.autorenew),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openRotation(context, roomId: roomId, roomName: roomName),
      ),
    );
  }
}

/// Opens the room's rotation.
Future<void> openRotation(
  BuildContext context, {
  required String roomId,
  required String roomName,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => RotationScreen(roomId: roomId, roomName: roomName),
  ),
);

/// The room's rotation: the cycle, whose turn it is now and next, who has
/// paid this period and who is late, and the payouts made.
class RotationScreen extends ConsumerWidget {
  const RotationScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(stawiRotationsProvider(roomId));
    return Scaffold(
      appBar: AppBar(title: const Text('Rotation')),
      body: cycles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(stawiErrorMessage(e))),
        data: (list) => list.isEmpty
            ? _NoRotation(roomId: roomId)
            : _CycleView(
                roomId: roomId,
                roomName: roomName,
                listed: list.first,
              ),
      ),
    );
  }
}

class _NoRotation extends ConsumerWidget {
  const _NoRotation({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref
        .watch(rotationEligibilityProvider(roomId))
        .asData
        ?.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'No rotation is running in this group.',
          key: Key('rotation-none'),
        ),
        const SizedBox(height: 8),
        const Text(
          'In a rotation every member pays in each period, and one member '
          'at a time receives the whole pot, in the order the group agrees.',
        ),
        const SizedBox(height: 16),
        if (eligible == RotationEligibility.ready)
          FilledButton.icon(
            key: const Key('rotation-start'),
            icon: const Icon(Icons.autorenew),
            label: const Text('Start a rotation'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StartRotationScreen(roomId: roomId),
              ),
            ),
          )
        else if (eligible == RotationEligibility.settingUp)
          const Text('You can start one once the group\'s setup votes pass.')
        else
          const Text(
            'Rotations run in merry-go-round groups (the '
            'merry_go_round_weekly rules, chosen when the group is made a '
            'Stawi room).',
          ),
      ],
    );
  }
}

class _CycleView extends ConsumerWidget {
  const _CycleView({
    required this.roomId,
    required this.roomName,
    required this.listed,
  });

  final String roomId;
  final String roomName;
  final finance.RotationCycle listed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(stawiRotationProvider(roomId));
    final names =
        ref.watch(rotationNamesProvider(roomId)).asData?.value ??
        RotationNames.none;
    final asset = ref.watch(stawiRoomAssetProvider(roomId)).asData?.value;
    final cycle = live.asData?.value.rotation ?? listed;
    final assets = live.asData != null
        ? StawiAssets(live.asData!.value.assets)
        : watchRoomAssets(ref, roomId);
    final s = RotationStatus(cycle);
    final theme = Theme.of(context);
    String money(finance.Money m) => formatMoney(m, assets);
    String units(String minor) {
      final v = BigInt.tryParse(minor);
      return v == null || asset == null ? unknownAmount : formatUnits(v, asset);
    }

    final current = s.current;
    final next = s.next;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(stawiRotationsProvider(roomId))
          ..invalidate(stawiRotationProvider(roomId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            key: const Key('rotation-summary'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.completed
                        ? 'Rotation complete'
                        : 'Turn ${cycle.currentTurn + 1} of '
                              '${cycle.turns.length}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Each turn receives ${money(cycle.pot)}'),
                  if (current != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      names.isMe(current.account)
                          ? 'Now: your turn'
                          : 'Now: ${names.of(current.account)}',
                      key: const Key('rotation-now'),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      [
                        turnStateWords(current),
                        if (current.hasPayableFrom())
                          'from ${dayWords(current.payableFrom.toDateTime())}',
                      ].join(', '),
                    ),
                    if (cycle.shortfall.isNotEmpty &&
                        current.state ==
                            finance
                                .RotationTurnState
                                .ROTATION_TURN_STATE_WAITING)
                      Text(
                        'The pot is short by ${units(cycle.shortfall)}',
                        key: const Key('rotation-shortfall'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                  if (next != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Next: ${names.of(next.account)}',
                      key: const Key('rotation-next-turn'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!s.completed) ...[
            const SizedBox(height: 16),
            Text('This period', style: theme.textTheme.titleMedium),
            if (live.hasError)
              Text(
                'Who has paid could not be read just now. '
                '${stawiErrorMessage(live.error!)}',
                key: const Key('rotation-dues-unavailable'),
              ),
            for (final m in cycle.members)
              ListTile(
                key: Key('rotation-member-${m.turn}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  m.late
                      ? Icons.warning_amber
                      : s.paidUp(m)
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: m.late
                      ? theme.colorScheme.error
                      : s.paidUp(m)
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text(names.of(m.account)),
                subtitle: Text(
                  m.late
                      ? 'Late${m.hasLateBy() ? ' by ${money(m.lateBy)}' : ''}'
                      : s.paidUp(m)
                      ? 'Paid for this period'
                      : s.duesRead
                      ? 'Not paid yet'
                      : '',
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('rotation-pay'),
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Pay my contribution'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ContributeScreen(roomId: roomId, roomName: roomName),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your contribution is the group\'s dues: pay it here or turn on '
              'automatic dues on the room\'s Savings tab.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text('Turns', style: theme.textTheme.titleMedium),
          for (final t in cycle.turns)
            ListTile(
              key: Key('rotation-turn-${t.turn}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(radius: 14, child: Text('${t.turn + 1}')),
              title: Text(names.of(t.account)),
              subtitle: Text(
                [
                  turnStateWords(t),
                  if (t.state ==
                          finance.RotationTurnState.ROTATION_TURN_STATE_PAID &&
                      t.hasPaid())
                    money(t.paid),
                  if (t.hasPaidAt())
                    dayWords(t.paidAt.toDateTime())
                  else if (t.hasPayableFrom())
                    'from ${dayWords(t.payableFrom.toDateTime())}',
                ].join(' · '),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${s.payouts.length} of ${cycle.turns.length} payouts made. Stawi '
            'pays each turn by itself once its period has begun and the pot '
            'is whole.',
            key: const Key('rotation-payouts'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// "Start a rotation": the members in turn order (drag to reorder, or
/// shuffle), what each pays per period and when it starts; then what will
/// change and Review and sign, behind the device lock. Settlement prepares
/// the cycle, and the device checks it before signing ([checkedRotation]).
class StartRotationScreen extends ConsumerStatefulWidget {
  const StartRotationScreen({required this.roomId, this.random, super.key});

  final String roomId;

  /// The shuffle's randomness (a secure one unless a test gives its own).
  final Random? random;

  @override
  ConsumerState<StartRotationScreen> createState() =>
      _StartRotationScreenState();
}

class _StartRotationScreenState extends ConsumerState<StartRotationScreen> {
  List<RotationPick>? _order;
  final Set<String> _left = {};
  final _amount = TextEditingController();
  bool _amountFilled = false;
  bool _shuffled = false;
  DateTime? _startsAt;
  ({List<RotationPick> order, BigInt contribution})? _chosen;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  List<RotationPick> get _included => [
    for (final p in _order ?? const <RotationPick>[])
      if (!_left.contains(p.memberId)) p,
  ];

  void _shuffle() {
    final order = _order;
    if (order == null) return;
    final shuffled = shuffledOrder(_included, widget.random);
    var i = 0;
    setState(() {
      _order = [
        for (final p in order)
          if (_left.contains(p.memberId)) p else shuffled[i++],
      ];
      _shuffled = true;
    });
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 366)),
    );
    if (day != null && mounted) setState(() => _startsAt = day);
  }

  void _next(StawiAsset? asset) {
    final included = _included;
    if (included.length < minRotationMembers) {
      setState(() => _error = 'Choose at least two members');
      return;
    }
    if (asset == null) {
      setState(() => _error = 'The room\'s asset could not be read');
      return;
    }
    try {
      final c = BigInt.parse(parseAmountInput(_amount.text, asset));
      setState(() {
        _chosen = (order: included, contribution: c);
        _error = null;
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _sign(
    finance.PolicyVersion inForce,
    StawiAsset asset,
    ({List<RotationPick> order, BigInt contribution}) chosen,
  ) async {
    setState(() => _sending = true);
    final service = ref.read(stawiRoomServiceProvider);
    final sent = await signRoomActSent(
      context,
      ref,
      () => service.prepareAct(
        roomId: widget.roomId,
        request: proposeRotationRequest(
          order: chosen.order,
          contribution: chosen.contribution,
          inForce: inForce,
          asset: asset,
          startsAt: _startsAt,
        ),
      ),
    );
    if (!mounted) return;
    if (sent == null) {
      setState(() => _sending = false);
      return;
    }
    ref.invalidate(stawiRotationsProvider(widget.roomId));
    await followDecision(context, widget.roomId, sent, 'Start a rotation');
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(roomMembersProvider(widget.roomId));
    final onChain = ref.watch(stawiMembersProvider(widget.roomId));
    final policy = ref.watch(stawiPolicyProvider(widget.roomId));
    final asset = ref.watch(stawiRoomAssetProvider(widget.roomId));
    final problem = chat.error ?? onChain.error ?? policy.error;
    Widget body;
    if (problem != null) {
      body = Center(child: Text(stawiErrorMessage(problem)));
    } else if (chat.asData == null ||
        onChain.asData == null ||
        policy.asData == null ||
        asset.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final inForce = policy.asData!.value;
      final a = asset.asData?.value;
      _order ??= rotationCandidates([
        for (final m in chat.asData!.value)
          (profileId: m.profileId, name: m.name),
      ], onChain.asData!.value);
      if (!_amountFilled && a != null) {
        _amountFilled = true;
        final min = BigInt.tryParse(
          inForce.constitution.savings.minimum.amount,
        );
        if (min != null && min > BigInt.zero) {
          _amount.text = _plain(min, a);
        }
      }
      final chosen = _chosen;
      body = chosen == null || a == null
          ? _choose(context, inForce, a)
          : _confirm(context, inForce, a, chosen);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Start a rotation')),
      body: body,
    );
  }

  /// [units] as a person types it: "10", "12.5".
  static String _plain(BigInt units, StawiAsset asset) {
    if (asset.decimals == 0) return units.toString();
    final scale = BigInt.from(10).pow(asset.decimals);
    final frac = (units % scale)
        .toString()
        .padLeft(asset.decimals, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? '${units ~/ scale}' : '${units ~/ scale}.$frac';
  }

  Widget _choose(
    BuildContext context,
    finance.PolicyVersion inForce,
    StawiAsset? asset,
  ) {
    final theme = Theme.of(context);
    final order = _order!;
    final period = periodWords(inForce.constitution.periodModel);
    var turn = 0;
    final turns = {
      for (final p in order)
        if (!_left.contains(p.memberId)) p.memberId: ++turn,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Who receives the pot, and in which order? Drag to reorder.',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (order.length < minRotationMembers)
          const Text(
            'A rotation needs at least two active members.',
            key: Key('rotation-too-few'),
          ),
        ReorderableListView(
          key: const Key('rotation-order'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => setState(() {
            final list = List<RotationPick>.of(order);
            list.insert(to, list.removeAt(from));
            _order = list;
          }),
          children: [
            for (final (i, p) in order.indexed)
              ListTile(
                key: Key('rotation-pick-${p.memberId}'),
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  key: Key('rotation-include-${p.memberId}'),
                  value: !_left.contains(p.memberId),
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _left.remove(p.memberId);
                    } else {
                      _left.add(p.memberId);
                    }
                  }),
                ),
                title: Text(p.name),
                subtitle: Text(
                  turns[p.memberId] == null
                      ? 'Not in the rotation'
                      : 'Turn ${turns[p.memberId]}',
                  key: Key('rotation-turn-of-${p.memberId}'),
                ),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Icon(
                    Icons.drag_handle,
                    key: Key('rotation-drag-${p.memberId}'),
                  ),
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('rotation-shuffle'),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle the order'),
            onPressed: _included.length < 2 ? null : _shuffle,
          ),
        ),
        if (_shuffled)
          Text(
            'Shuffled on this phone. The order above is the one the group '
            'votes on: ${_included.map((p) => p.name).join(', ')}.',
            key: const Key('rotation-shuffled'),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('rotation-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Each member pays per $period',
            suffixText: asset?.symbol,
            helperText:
                'The pot each turn receives is this times the members. The '
                'room\'s period is one $period; a rotation keeps it.',
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text('Starts', style: theme.textTheme.titleSmall),
        RadioGroup<bool>(
          groupValue: _startsAt != null,
          onChanged: (dated) {
            if (dated ?? false) {
              _pickStart();
            } else {
              setState(() => _startsAt = null);
            }
          },
          child: Column(
            children: [
              const RadioListTile<bool>(
                key: Key('rotation-start-soonest'),
                value: false,
                title: Text('As soon as the vote allows'),
              ),
              RadioListTile<bool>(
                key: const Key('rotation-start-dated'),
                value: true,
                title: Text(
                  _startsAt == null
                      ? 'From a date…'
                      : 'From the first $period on or after '
                            '${dayWords(_startsAt!)}',
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('rotation-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('rotation-next'),
          onPressed: () => _next(asset),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _confirm(
    BuildContext context,
    finance.PolicyVersion inForce,
    StawiAsset asset,
    ({List<RotationPick> order, BigInt contribution}) chosen,
  ) {
    final theme = Theme.of(context);
    final period = periodWords(inForce.constitution.periodModel);
    final pot = chosen.contribution * BigInt.from(chosen.order.length);
    final dues = BigInt.tryParse(inForce.constitution.savings.minimum.amount);
    final differs =
        dues != null && dues > BigInt.zero && dues != chosen.contribution;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Start a rotation', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('What will change', style: theme.textTheme.titleSmall),
        Text(
          'Every $period each of the ${chosen.order.length} members pays '
          '${formatUnits(chosen.contribution, asset)}, and one member at a '
          'time receives ${formatUnits(pot, asset)}:',
          key: const Key('rotation-confirm-terms'),
        ),
        for (final (i, p) in chosen.order.indexed)
          ListTile(
            key: Key('rotation-confirm-turn-$i'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
            title: Text(p.name),
          ),
        Text(
          _startsAt == null
              ? 'The first turn is the first $period that begins once the '
                    'vote can take effect.'
              : 'The first turn is the first $period that begins on or '
                    'after ${dayWords(_startsAt!)}.',
        ),
        if (differs) ...[
          const SizedBox(height: 8),
          Text(
            'The group\'s dues are ${formatUnits(dues, asset)} a $period, '
            'not ${formatUnits(chosen.contribution, asset)}: each turn is '
            'paid only once the room\'s savings hold its whole pot.',
            key: const Key('rotation-dues-differ'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Text('What happens next', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text(
          'The group votes on the rotation. $finishesItselfNote Then Stawi '
          'pays each turn\'s pot by itself as soon as its period has begun '
          'and everyone\'s contribution is in.',
        ),
        const SizedBox(height: 12),
        Text(
          'Your phone checks the rotation settlement prepares (the order, '
          'the pot and the first turn) against what you chose before you '
          'sign, and asks for your screen lock to sign.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('rotation-sign'),
          onPressed: _sending ? null : () => _sign(inForce, asset, chosen),
          child: Text(_sending ? 'Signing…' : 'Review and sign'),
        ),
        TextButton(
          onPressed: _sending ? null : () => setState(() => _chosen = null),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

/// What a rotation card in the chat adds to finance's words: whose turn it
/// is by name (or that it is yours), who is late, and the way to the
/// rotation (and, when you are late, to pay).
class RotationCardDetails extends ConsumerWidget {
  const RotationCardDetails({
    required this.roomId,
    required this.roomName,
    required this.kind,
    required this.data,
    super.key,
  });

  final String roomId;
  final String roomName;
  final String kind;
  final Map<String, String> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names =
        ref.watch(rotationNamesProvider(roomId)).asData?.value ??
        RotationNames.none;
    final theme = Theme.of(context);
    final recipient = accountOf(data['recipient']);
    final late = accountsOfList(data['late']);
    final order = accountsOfList(data['order']);
    final mine = recipient != null && names.isMe(recipient);
    final meLate = late.any(names.isMe);
    final lines = <(String, String)>[
      if (recipient != null)
        (
          kind == RotationCards.payout ? 'Paid to' : 'Whose turn',
          names.of(recipient),
        ),
      if (late.isNotEmpty) ('Late', late.map(names.of).join(', ')),
      if (order.isNotEmpty)
        ('Order', [for (final a in order) names.of(a)].join(', ')),
    ];
    return Column(
      key: const Key('rotation-card-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine && kind == RotationCards.turn)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'It is your turn: this pot comes to you.',
              key: const Key('rotation-card-yours'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (mine && kind == RotationCards.payout)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'The pot was paid to your Stawi account.',
              key: const Key('rotation-card-yours'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (meLate)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'You are late with your contribution: the pot waits for it.',
              key: const Key('rotation-card-me-late'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 6),
        for (final (label, value) in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('rotation-card-open'),
              icon: const Icon(Icons.autorenew),
              label: const Text('See the rotation'),
              onPressed: () =>
                  openRotation(context, roomId: roomId, roomName: roomName),
            ),
            if (meLate)
              FilledButton.tonalIcon(
                key: const Key('rotation-card-pay'),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Pay now'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContributeScreen(roomId: roomId, roomName: roomName),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
