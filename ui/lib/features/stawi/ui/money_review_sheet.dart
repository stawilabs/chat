import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_account_service.dart';
import '../domain/money_review.dart';
import 'stawi_feedback.dart';

/// Shows [review]; true when the person confirmed. Dismissing it, or
/// cancelling, is false.
Future<bool> showMoneyReview(BuildContext context, MoneyReview review) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            key: const Key('money-review'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                review.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final (label, value) in review.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(label)),
                      const SizedBox(width: 12),
                      Flexible(child: Text(value, textAlign: TextAlign.end)),
                    ],
                  ),
                ),
              for (final note in review.notes)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    note,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Checked on this device: this is what you asked for, from '
                'your account.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('money-review-sign'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(review.signLabel),
              ),
              TextButton(
                key: const Key('money-review-cancel'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;

/// Shows [prepared]'s review and, once confirmed, signs and submits it.
/// Null when the person cancelled or the submit failed (a snack bar says why).
Future<settlement.AccountCall?> reviewAndSubmit(
  BuildContext context,
  WidgetRef ref,
  PreparedMoneyCall prepared,
) async {
  if (!await showMoneyReview(context, prepared.review) || !context.mounted) {
    return null;
  }
  return runStawiAction(
    context,
    () => ref.read(stawiAccountServiceProvider).submit(prepared),
    success: prepared.review.done,
  );
}

/// prepare → review → device lock → submit, with errors in a snack bar; null
/// when nothing was signed.
Future<settlement.AccountCall?> runMoneyAction(
  BuildContext context,
  WidgetRef ref,
  Future<PreparedMoneyCall> Function() prepare,
) async {
  final prepared = await runStawiAction(context, prepare);
  if (prepared == null || !context.mounted) return null;
  return reviewAndSubmit(context, ref, prepared);
}
