# Example Usage

This directory contains examples demonstrating how to use the chat application components and features.

## Basic Usage

```dart
import 'package:chat/chat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: ChatApp(),
    ),
  );
}
```

## Authentication Example

```dart
import 'package:chat/features/auth/data/auth_repository.dart';

class MyAuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return ElevatedButton(
      onPressed: () async {
        try {
          await ref.read(authRepositoryProvider).login();
        } catch (e) {
          // Handle authentication error
        }
      },
      child: Text('Login'),
    );
  }
}
```

## Chat Integration Example

```dart
import 'package:chat/features/chat/data/chat_repository.dart';

class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageProvider('room-id'));
    
    return messages.when(
      data: (messageList) => ListView.builder(
        itemCount: messageList.length,
        itemBuilder: (context, index) {
          return MessageBubble(message: messageList[index]);
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Security Best Practices

- Always use the provided authentication system
- Store sensitive data using the secure storage utilities
- Implement proper error handling for network operations
- Use the mock authentication system for testing

For more detailed examples, see the test files in the `test/` directory.
