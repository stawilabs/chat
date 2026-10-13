import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_counterparty.dart';
import 'stawi_feedback.dart';

/// Lets the person choose where money goes: one of their DM partners. Null
/// when they dismiss it. There is no typed address.
Future<StawiContactAccount?> showDmPartnerPicker(BuildContext context) =>
    showModalBottomSheet<StawiContactAccount>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SafeArea(child: DmPartnerPicker()),
    );

/// The person's DMs, each partner's Stawi account looked up only when its
/// row is built. A partner with an account can be chosen; one without, or
/// one who has not written in the DM yet (chat refuses the lookup), is shown
/// and cannot.
class DmPartnerPicker extends ConsumerWidget {
  const DmPartnerPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(directRoomsProvider);
    return Column(
      key: const Key('dm-partner-picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Send to',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Flexible(
          child: rooms.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(stawiErrorMessage(error)),
            ),
            data: (rooms) => rooms.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Start a direct message with someone to send them money',
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, i) => _PartnerTile(room: rooms[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PartnerTile extends ConsumerWidget {
  const _PartnerTile({required this.room});

  final DirectRoomRef room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = Key('dm-partner-${room.roomId}');
    final title = Text(room.name);
    return ref
        .watch(counterpartyAccountProvider(room.roomId))
        .when(
          loading: () => ListTile(
            key: key,
            enabled: false,
            title: title,
            subtitle: const Text('Finding their Stawi account…'),
          ),
          error: (error, _) => ListTile(
            key: key,
            enabled: false,
            title: title,
            subtitle: Text(
              error is DirectPartnerRefused
                  ? DirectPartnerRefused.messageFor(room.name)
                  : stawiErrorMessage(error),
            ),
          ),
          data: (contact) => contact == null
              ? ListTile(
                  key: key,
                  enabled: false,
                  title: title,
                  subtitle: Text('${room.name} has no Stawi account yet'),
                )
              : ListTile(
                  key: key,
                  title: title,
                  subtitle: Text(
                    shortHex(bytesToHex0x(contact.address).toLowerCase()),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(contact.named(room.name)),
                ),
        );
  }
}
