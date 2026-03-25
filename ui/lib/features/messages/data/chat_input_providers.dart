import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_input_providers.g.dart';

// Riverpod providers for WhatsApp-style chat input architecture

@riverpod
class EmojiPanelVisibility extends _$EmojiPanelVisibility {
  @override
  bool build() => false;

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }

  void toggle() {
    state = !state;
  }
}

@riverpod
bool typingState(Ref ref) => false;

@riverpod
class TypingNotifier extends _$TypingNotifier {
  Timer? _timer;

  @override
  bool build() => false;

  void onTyping() {
    if (!state) {
      state = true;
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      // Use ref.mounted to check if provider is still alive
      if (ref.mounted) {
        state = false;
      }
    });
  }
}
