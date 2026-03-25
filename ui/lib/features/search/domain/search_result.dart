import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

/// Message search result with context
@freezed
abstract class MessageSearchResult with _$MessageSearchResult {
  const factory MessageSearchResult({
    required String messageId,
    required String roomId,
    required String roomName,
    required String text,
    required String senderId,
    required DateTime timestamp,

    /// The query that matched this result (for highlighting)
    required String query,
  }) = _MessageSearchResult;

  factory MessageSearchResult.fromJson(Map<String, dynamic> json) =>
      _$MessageSearchResultFromJson(json);
}

/// Extension for highlighting matched text
extension MessageSearchResultExtension on MessageSearchResult {
  /// Get the text with match indices for highlighting
  List<TextMatch> getHighlightMatches() {
    final matches = <TextMatch>[];
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    var startIndex = 0;
    while (true) {
      final index = textLower.indexOf(queryLower, startIndex);
      if (index == -1) break;

      matches.add(TextMatch(start: index, end: index + query.length));
      startIndex = index + query.length;
    }

    return matches;
  }

  /// Format timestamp for display
  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get excerpt with context around the match
  String getExcerpt({int contextLength = 50}) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final index = textLower.indexOf(queryLower);

    if (index == -1) return text;

    final start = (index - contextLength).clamp(0, text.length);
    final end = (index + query.length + contextLength).clamp(0, text.length);

    var excerpt = text.substring(start, end);

    if (start > 0) excerpt = '...$excerpt';
    if (end < text.length) excerpt = '$excerpt...';

    return excerpt;
  }
}

/// Represents a match position in text
class TextMatch {
  const TextMatch({required this.start, required this.end});

  final int start;
  final int end;
}
