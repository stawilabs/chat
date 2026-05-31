package org.stawi.chat

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the screenshot-prevention MethodChannel. Without this handler the Dart
 * ScreenshotPreventionService.enableScreenshotPrevention() threw
 * MissingPluginException (swallowed) yet still reported "enabled", so sensitive
 * financial chats were screenshot-able and appeared in the app-switcher despite
 * the protection being "on". FLAG_SECURE blocks screenshots, screen recording,
 * and the recents thumbnail.
 */
class MainActivity : FlutterActivity() {
    private val screenshotChannel = "chat.app/screenshot_prevention"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenshotChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureFlag" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                        result.success(true)
                    }
                    "disableSecureFlag" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    }
                    // enableSecureField/disableSecureField are iOS-only; ignore here.
                    else -> result.notImplemented()
                }
            }
    }
}
