import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_finance_service.dart';
import '../domain/stawi_money.dart';
import 'stawi_feedback.dart';

/// The member's statement in a Stawi room, from finance's read model.
/// Amounts are integer minor units of the asset, shown as finance gives them.
class StatementScreen extends ConsumerWidget {
  const StatementScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statement = ref.watch(stawiStatementProvider(roomId));
    return Scaffold(
      appBar: AppBar(title: Text('Statement · $roomName')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(stawiStatementProvider(roomId).future),
        child: statement.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  stawiErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          data: (s) => _StatementView(statement: s),
        ),
      ),
    );
  }
}

class _StatementView extends StatelessWidget {
  const _StatementView({required this.statement});

  final finance.Statement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMd();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance', style: theme.textTheme.labelLarge),
                Text(
                  formatMoney(statement.closingBalance),
                  key: const Key('statement-closing'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Opening ${formatMoney(statement.openingBalance)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (statement.hasFrom() || statement.hasTo())
                  Text(
                    '${statement.hasFrom() ? dates.format(statement.from.toDateTime()) : ''}'
                    ' – '
                    '${statement.hasTo() ? dates.format(statement.to.toDateTime()) : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (statement.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No entries yet', textAlign: TextAlign.center),
          ),
        for (final line in statement.lines)
          ListTile(
            title: Text(
              line.description.isNotEmpty ? line.description : line.bucket,
            ),
            subtitle: Text(
              line.hasAt() ? dates.add_jm().format(line.at.toDateTime()) : '',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _isZero(line.credit)
                      ? '−${formatMoney(line.debit)}'
                      : '+${formatMoney(line.credit)}',
                ),
                Text(
                  formatMoney(line.runningBalance),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  static bool _isZero(finance.Money money) =>
      money.amount.isEmpty || money.amount == '0';
}
