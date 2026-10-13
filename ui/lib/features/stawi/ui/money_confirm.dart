import 'package:flutter/material.dart';

import '../domain/money_review.dart';

/// A plain confirmation of what is about to be signed: the review's title and
/// lines. True when the person confirmed. Task 11's review sheet replaces it.
Future<bool> confirmMoney(BuildContext context, MoneyReview review) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('money-confirm'),
        title: Text(review.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in review.lines) Text('$label: $value'),
            for (final note in review.notes) Text(note),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('money-confirm-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('money-confirm-sign'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(review.signLabel),
          ),
        ],
      ),
    ) ??
    false;
