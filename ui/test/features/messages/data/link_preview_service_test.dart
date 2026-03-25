import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/features/messages/data/link_preview_service.dart';

void main() {
  group('LinkPreviewService', () {
    group('extractUrls', () {
      test('extracts single HTTP URL from text', () {
        const text = 'Check out this link: http://example.com';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['http://example.com']);
      });

      test('extracts single HTTPS URL from text', () {
        const text = 'Check this: https://www.google.com/search?q=flutter';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['https://www.google.com/search?q=flutter']);
      });

      test('extracts multiple URLs from text', () {
        const text =
            'Visit https://flutter.dev and https://dart.dev for documentation';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, contains('https://flutter.dev'));
        expect(urls, contains('https://dart.dev'));
        expect(urls.length, 2);
      });

      test('returns empty list for text without URLs', () {
        const text = 'This is just regular text without any links';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, isEmpty);
      });

      test('handles URLs at the beginning of text', () {
        const text = 'https://example.com is a great website';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['https://example.com']);
      });

      test('handles URLs at the end of text', () {
        const text = 'Great article at https://medium.com/article';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['https://medium.com/article']);
      });

      test('handles URLs with path and query params', () {
        const text = 'See https://example.com/path/to/page?id=123&ref=abc';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['https://example.com/path/to/page?id=123&ref=abc']);
      });

      test('excludes PDF file URLs', () {
        const text = 'Download the PDF: https://example.com/document.pdf';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, isEmpty);
      });

      test('excludes ZIP file URLs', () {
        const text = 'Download: https://example.com/archive.zip';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, isEmpty);
      });

      test('excludes executable URLs', () {
        const text = 'Don\'t download: https://example.com/app.exe';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, isEmpty);
      });

      test('handles multiline text', () {
        const text = '''
First line
Check https://example1.com
Second line with https://example2.com
Last line
''';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls.length, 2);
        expect(urls, contains('https://example1.com'));
        expect(urls, contains('https://example2.com'));
      });

      test('handles URLs with fragments', () {
        const text = 'Go to https://example.com/page#section';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['https://example.com/page#section']);
      });

      test('handles URLs with port numbers', () {
        const text = 'Dev server at http://localhost:8080/app';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, ['http://localhost:8080/app']);
      });

      test('ignores partial URLs without scheme', () {
        const text = 'Visit example.com or www.google.com';
        final urls = LinkPreviewService.extractUrls(text);
        expect(urls, isEmpty);
      });
    });

    group('cache behavior', () {
      late LinkPreviewService service;

      setUp(() {
        service = LinkPreviewService(
          () async => 'test-token',
          () => throw UnimplementedError('No files client in test'),
        );
      });

      test('clearCache removes all cached entries', () {
        // This is a basic test - the cache is internal
        // but clearCache should not throw
        expect(() => service.clearCache(), returnsNormally);
      });
    });
  });
}
