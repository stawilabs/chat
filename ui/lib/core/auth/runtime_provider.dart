import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';

import '../networking/api_config.dart';

/// Auth runtime configuration for the chat client.
///
/// Values mirror the [ApiConfig] OAuth2 settings and the existing
/// `org.stawi.chat://sso/redirect` deep-link used by Hydra client
/// registration and the platform URL-scheme manifests (see below).
///
/// `apiBaseUrl` is the unified API origin for the new auth runtime.
/// Legacy per-service base URLs (chat / gateway / files / profile / devices)
/// remain in place for now and are routed through `runtime.fetch` by the
/// Connect transport in `RuntimeTransport`; later dispatches collapse them
/// onto a single gateway origin.
///
/// Platform manifest state (verified by CHAT-9):
///   * Android — `ui/android/app/src/main/AndroidManifest.xml` declares an
///     `android:scheme="org.stawi.chat"` intent-filter with host
///     `sso` and path-prefix `/redirect` on flutter_web_auth_2's
///     `CallbackActivity`, which matches [kChatRedirectUri] end-to-end.
///   * iOS — `ui/ios/Runner/Info.plist` registers `org.stawi.chat`
///     under `CFBundleURLTypes`. (iOS Runner assets are provisioned at
///     build time; see `ios_oauth_setup.md` for the reference payload.)
///   * macOS — `ui/macos/Runner/Info.plist` registers
///     `org.stawi.chat` under `CFBundleURLTypes`.
///
/// Keep this comment in sync with the manifest files if the redirect URI
/// ever changes.
const String kChatRedirectUri = 'org.stawi.chat://sso/redirect';

const AuthConfig kChatAuthConfig = AuthConfig(
  clientId: ApiConfig.oauth2ClientId,
  idpBaseUrl: ApiConfig.oauth2IssuerUrl,
  apiBaseUrl: 'https://api.stawi.org',
  redirectScheme: 'org.stawi.chat',
  redirectUri: kChatRedirectUri,
  scopes: ['openid', 'profile', 'contact', 'offline_access'],
);

/// Constructs a fresh [AuthRuntime] for the chat app.
///
/// Call once at app start and override `authRuntimeProvider` with the
/// resulting instance so widget tree consumers share the same runtime.
AuthRuntime buildChatRuntime() => createAuthRuntime(
  kChatAuthConfig,
  nativeCredentialConfig: const NativeCredentialConfig(
    googleServerClientId: ApiConfig.googleServerClientId,
    enableApple: true,
  ),
);
