import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../../core/navigation/navigation_helper.dart';
import '../../rooms/data/room_providers.dart';
import '../data/stawi_account_service.dart';
import '../data/stawi_counterparty.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_vault_service.dart';
import '../domain/loan_terms.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import '../domain/stawi_money.dart';
import 'loan_detail_screen.dart';
import 'loan_widgets.dart';
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';
import 'terms_entry.dart';

/// The money button of a chat's app bar: in a DM it opens the money sheet
/// with the other person; in a group, the room's Stawi screen (where a room
/// not converted yet shows how to convert it). Other rooms (bots, channels)
/// have none.
class ChatMoneyButton extends ConsumerWidget {
  const ChatMoneyButton({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;

  /// How the chat is shown: in a DM, the other person's name.
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(roomByIdProvider(roomId)).asData?.value?.type;
    if (type != 'direct' && type != 'group') return const SizedBox.shrink();
    return IconButton(
      key: const Key('chat-money'),
      icon: const Icon(Icons.payments_outlined),
      tooltip: 'Money',
      onPressed: () => type == 'direct'
          ? showDmMoneySheet(context, roomId: roomId, partnerName: roomName)
          : NavigationHelper.navigateToStawiRoom(
              context,
              roomId: roomId,
              roomName: roomName,
            ),
    );
  }
}

/// The money sheet of the DM [roomId] with [partnerName]: the loans between
/// the two of them, then Lend and Ask to borrow. The partner's account is
/// chat's answer for this DM, never a typed address.
Future<void> showDmMoneySheet(
  BuildContext context, {
  required String roomId,
  required String partnerName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: DmMoneySheet(roomId: roomId, partnerName: partnerName),
  ),
);

class DmMoneySheet extends ConsumerWidget {
  const DmMoneySheet({
    required this.roomId,
    required this.partnerName,
    super.key,
  });

  final String roomId;
  final String partnerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(counterpartyAccountProvider(roomId));
    final name = partnerName;
    Widget line(String text, {Key? key}) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, key: key),
    );
    return SingleChildScrollView(
      child: Column(
        key: const Key('dm-money-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Money with $name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...partner.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              if (error is DirectPartnerRefused)
                line(
                  DirectPartnerRefused.messageFor(name),
                  key: const Key('dm-money-refused'),
                )
              else ...[
                line(stawiErrorMessage(error)),
                TextButton(
                  key: const Key('dm-money-retry'),
                  onPressed: () =>
                      ref.invalidate(counterpartyAccountProvider(roomId)),
                  child: const Text('Try again'),
                ),
              ],
            ],
            data: (contact) => contact == null
                ? [
                    line(
                      '$name has no Stawi account yet',
                      key: const Key('dm-money-no-account'),
                    ),
                  ]
                : [
                    _PairLoans(roomId: roomId, name: name),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: const Key('dm-lend'),
                              onPressed: () => _open(context, DmLoanMode.lend),
                              child: const Text('Lend'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('dm-ask'),
                              onPressed: () => _open(context, DmLoanMode.ask),
                              child: const Text('Ask to borrow'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, DmLoanMode mode) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DmLoanScreen(roomId: roomId, partnerName: partnerName, mode: mode),
      ),
    );
  }
}

/// The loans between the person and the DM partner, each opening its page.
class _PairLoans extends ConsumerWidget {
  const _PairLoans({required this.roomId, required this.name});

  final String roomId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(dmPairLoansProvider(roomId));
    final mine = ref.watch(stawiIdentityProvider).asData?.value.addresses;
    final assets = watchLoanAssets(ref);
    return loans.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(key: Key('dm-loans-loading')),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(stawiErrorMessage(e)),
      ),
      data: (loans) => mine == null
          // Who is who is not known yet: not "no loans".
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(key: Key('dm-loans-loading')),
              ),
            )
          : loans.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No loans with $name yet',
                key: const Key('dm-loans-none'),
              ),
            )
          : Column(
              key: const Key('dm-loans'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final loan in loans)
                  LoanCard(
                    view: LoanView(loan, mine: mine),
                    assets: assets,
                    counterpartyName: name,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LoanDetailScreen(ref: LoanRef.of(loan)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Lending to the DM partner, or asking them to lend.
enum DmLoanMode { lend, ask }

/// How long an offer or an ask stays open, in days.
const List<int> dmOfferDays = [1, 3, 7, 14];

/// An offer to lend to, or an ask to borrow from, the other person of the DM
/// [roomId]: the amount and terms with a live quote, how long it stays open
/// and, to lend, the pocket the money comes from; then review and sign. The
/// card reaches the DM from finance once the chain has it; the app posts
/// nothing.
class DmLoanScreen extends ConsumerStatefulWidget {
  const DmLoanScreen({
    required this.roomId,
    required this.partnerName,
    required this.mode,
    super.key,
  });

  final String roomId;
  final String partnerName;
  final DmLoanMode mode;

  @override
  ConsumerState<DmLoanScreen> createState() => _DmLoanScreenState();
}

class _DmLoanScreenState extends ConsumerState<DmLoanScreen> {
  Uint8List? _pocket;
  BigInt? _amount;
  LoanTerms? _terms;
  int _days = 7;
  bool _busy = false;

  bool get _lend => widget.mode == DmLoanMode.lend;
  String get _name => widget.partnerName;

  /// Pockets an offer may come from: free savings and goals others may
  /// borrow from, with money in them.
  static List<finance.SavingsPocket> _sources(finance.GetVaultResponse v) => [
    for (final p in v.pockets)
      if (canLendFrom(p) && moneyUnits(p.cash) > BigInt.zero) p,
  ];

  Future<void> _submit(StawiContactAccount partner) async {
    final amount = _amount;
    final terms = _terms;
    if (amount == null || terms == null || _busy) return;
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    final expiresAt = ref.read(stawiClockProvider)().add(Duration(days: _days));
    setState(() => _busy = true);
    try {
      final PersonalRequest request;
      String? pocketLabel;
      if (_lend) {
        final chosen = _pocket;
        if (chosen == null) return;
        // The pocket is read again: what it held when the list was shown may
        // have moved since.
        final fresh = await runStawiAction(
          context,
          ref.read(stawiVaultServiceProvider).vault,
        );
        if (fresh == null || !mounted) return;
        final now = fresh.pockets
            .where((p) => bytesEqual(pocketId(p), chosen))
            .firstOrNull;
        if (now == null || !canLendFrom(now) || moneyUnits(now.cash) < amount) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                'Not enough in ${now == null ? 'that pocket' : pocketName(now)}',
              ),
            ),
          );
          return;
        }
        pocketLabel = pocketName(now);
        request = PersonalRequest.offer(
          borrower: partner.address,
          pocket: chosen,
          amount: amount,
          terms: terms,
          expiresAt: expiresAt,
        );
      } else {
        request = PersonalRequest.ask(
          lender: partner.address,
          amount: amount,
          terms: terms,
          expiresAt: expiresAt,
        );
      }
      final call = await runMoneyAction(
        context,
        ref,
        () => service.preparePersonal(
          request,
          counterpartyName: _name,
          pocketName: pocketLabel,
        ),
      );
      if (call == null) return;
      await settleThenRefresh(container, service, call, [
        ...moneyProviders(),
        dmPairLoansProvider(widget.roomId),
      ]);
      if (mounted) Navigator.of(context).pop();
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(counterpartyAccountProvider(widget.roomId));
    final asset = ref.watch(stawiTestAssetProvider).asData?.value.asset;
    final money = asset == null || asset.assetId.isEmpty
        ? null
        : StawiAsset.fromInfo(asset);
    return Scaffold(
      appBar: AppBar(title: Text(_lend ? 'Lend to $_name' : 'Ask $_name')),
      body: partner.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is DirectPartnerRefused
                  ? DirectPartnerRefused.messageFor(_name)
                  : stawiErrorMessage(e),
            ),
          ),
        ),
        data: (contact) => contact == null
            ? Center(child: Text('$_name has no Stawi account yet'))
            : money == null
            ? const Center(child: CircularProgressIndicator())
            : _form(context, contact, money),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    StawiContactAccount partner,
    StawiAsset money,
  ) {
    final heading = Theme.of(context).textTheme.titleSmall;
    final List<Widget> pockets;
    BigInt? max;
    if (_lend) {
      final vault = ref.watch(myVaultProvider);
      final assets = watchLoanAssets(ref);
      pockets = vault.when(
        loading: () => const [LinearProgressIndicator()],
        error: (e, _) => [Text(stawiErrorMessage(e))],
        data: (v) {
          final sources = _sources(v);
          if (sources.isEmpty) {
            return const [
              Text(
                'Add money to your free savings, or to a goal others can '
                'borrow from, to lend from it.',
                key: Key('dm-lend-no-pocket'),
              ),
            ];
          }
          final chosen = sources
              .where(
                (p) => _pocket != null && bytesEqual(pocketId(p), _pocket!),
              )
              .firstOrNull;
          if (chosen != null) max = moneyUnits(chosen.cash);
          return [
            Text('Lend from', style: heading),
            for (final p in sources)
              RadioListTile<String>(
                key: Key('dm-pocket-${bytesToHexKey(pocketId(p))}'),
                value: bytesToHexKey(pocketId(p)),
                // ignore: deprecated_member_use
                groupValue: chosen == null
                    ? null
                    : bytesToHexKey(pocketId(chosen)),
                // ignore: deprecated_member_use
                onChanged: (_) => setState(() => _pocket = pocketId(p)),
                title: Text(pocketName(p)),
                subtitle: Text('${formatMoney(p.cash, assets)} saved'),
              ),
          ];
        },
      );
    } else {
      pockets = const [];
    }
    final ready =
        _amount != null && _terms != null && (!_lend || _pocket != null);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AccountSetupBanner(),
        ...pockets,
        const SizedBox(height: 12),
        TermsEntry(
          kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
          asset: money,
          maxAmount: max,
          onChanged: (amount, terms, _) => setState(() {
            _amount = amount;
            _terms = terms;
          }),
        ),
        const SizedBox(height: 16),
        Text(_lend ? 'Offer open for' : 'Ask open for', style: heading),
        Wrap(
          spacing: 8,
          children: [
            for (final d in dmOfferDays)
              ChoiceChip(
                key: Key('dm-expiry-$d'),
                label: Text(d == 1 ? '1 day' : '$d days'),
                selected: _days == d,
                onSelected: (_) => setState(() => _days = d),
              ),
          ],
        ),
        if (!_lend)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Asking shares your loan record with $_name until they lend, '
              'decline, or the ask ends.',
              key: const Key('dm-ask-note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('dm-loan-submit'),
          onPressed: !ready || _busy ? null : () => _submit(partner),
          child: Text(_lend ? 'Lend' : 'Ask to borrow'),
        ),
      ],
    );
  }
}
