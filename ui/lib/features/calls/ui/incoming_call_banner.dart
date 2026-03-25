import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/call_manager.dart';
import 'call_screen.dart';

class IncomingCallBanner extends ConsumerWidget {
  const IncomingCallBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callManagerAsync = ref.watch(callManagerProvider);

    return callManagerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (callManager) => StreamBuilder<CallState>(
        stream: callManager.callStateStream,
        builder: (context, snapshot) {
          if (snapshot.data == CallState.incoming) {
            return Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Incoming Call',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              callManager.callerSenderId ?? 'Unknown Caller',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () {
                          callManager.endCall();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.call_end),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          callManager.answerCall();
                          final roomId = callManager.currentRoomId;
                          if (roomId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CallScreen(
                                  roomId: roomId,
                                  roomName:
                                      callManager.callerSenderId ?? 'Call',
                                ),
                              ),
                            );
                          }
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.call),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
