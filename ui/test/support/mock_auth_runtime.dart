import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';

/// Lightweight [AuthRuntime] stand-in for widget and unit tests.
///
/// Implements the full `AuthRuntime` contract with in-memory state,
/// streams owned and closed by the mock, and a pluggable [fetchHandler]
/// for tests that care about the HTTP surface of the runtime.
///
/// Typical usage:
///
/// ```dart
/// final mock = MockAuthRuntime.authenticated(
///   claimsMap: const {'sub': 'user-1', 'contact_id': 'contact-42'},
///   roles: const ['user'],
/// );
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [authRuntimeProvider.overrideWithValue(mock)],
///     child: const MyApp(),
///   ),
/// );
/// ```
///
/// Tests that need to simulate auth transitions (e.g. login/logout flows)
/// drive them via [setAuthState]. The mock does not call into
/// `flutter_appauth`, secure storage, or the isolate worker — making it
/// safe in widget-test environments where those plugins are unavailable.
class MockAuthRuntime implements AuthRuntime {
  MockAuthRuntime({
    AuthState initialState = AuthState.unauthenticated,
    this.claimsMap = const <String, dynamic>{},
    this.roles = const <String>[],
    this.nativeProviders = const <NativeCredentialProviderKind>{},
    this.fetchHandler,
    this.uploadHandler,
  }) : _state = initialState {
    // Seed the stream with the initial value so `StreamProvider` listeners
    // don't sit in a `loading` state in synchronous widget tests.
    scheduleMicrotask(() {
      if (!_stateController.isClosed) _stateController.add(_state);
    });
  }

  /// Convenience constructor for tests that want an immediately-
  /// authenticated runtime.
  factory MockAuthRuntime.authenticated({
    Map<String, dynamic> claimsMap = const <String, dynamic>{},
    List<String> roles = const <String>[],
    Set<NativeCredentialProviderKind> nativeProviders =
        const <NativeCredentialProviderKind>{},
    Future<ApiResponse> Function(
      String path, {
      String method,
      Map<String, String>? headers,
      Object? body,
      Duration? timeout,
    })?
    fetchHandler,
  }) {
    return MockAuthRuntime(
      initialState: AuthState.authenticated,
      claimsMap: claimsMap,
      roles: roles,
      nativeProviders: nativeProviders,
      fetchHandler: fetchHandler,
    );
  }

  AuthState _state;
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();
  final StreamController<SecurityEvent> _securityController =
      StreamController<SecurityEvent>.broadcast();
  final StreamController<CredentialEvent> _credentialController =
      StreamController<CredentialEvent>.broadcast();

  /// Claims returned by [getClaims] / [getUserClaims]. Mutable so tests
  /// can tweak the value across a single `MockAuthRuntime` instance.
  Map<String, dynamic> claimsMap;

  /// Roles returned by [getRoles].
  List<String> roles;

  /// Native credential providers advertised via
  /// [availableNativeProviders]. Empty by default.
  Set<NativeCredentialProviderKind> nativeProviders;

  /// Optional hook invoked by [fetch]. When null, [fetch] returns an
  /// empty `200 OK` JSON response.
  Future<ApiResponse> Function(
    String path, {
    String method,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  })?
  fetchHandler;

  /// Optional hook invoked by [upload].
  Future<ApiResponse> Function(
    String path, {
    required String fieldName,
    required String filename,
    required String contentType,
    required Stream<List<int>> bytes,
    required int length,
    Map<String, String>? headers,
    Duration? timeout,
  })?
  uploadHandler;

  /// List of paths passed to [fetch]. Useful for `expect` assertions.
  final List<String> fetchCalls = <String>[];

  /// List of paths passed to [upload].
  final List<String> uploadCalls = <String>[];

  int _ensureAuthenticatedCalls = 0;
  int get ensureAuthenticatedCalls => _ensureAuthenticatedCalls;

  int _logoutCalls = 0;
  int get logoutCalls => _logoutCalls;

  bool _disposed = false;
  bool get disposed => _disposed;

  /// Drive an explicit state transition. Emits on [authStateStream].
  void setAuthState(AuthState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  /// Push a [SecurityEvent] through [securityEventStream].
  void emitSecurityEvent(SecurityEvent event) {
    if (!_securityController.isClosed) _securityController.add(event);
  }

  /// Push a [CredentialEvent] through [credentialEventStream].
  void emitCredentialEvent(CredentialEvent event) {
    if (!_credentialController.isClosed) _credentialController.add(event);
  }

  @override
  AuthState get state => _state;

  @override
  bool get isAuthenticated => _state == AuthState.authenticated;

  @override
  Stream<AuthState> get authStateStream => _stateController.stream;

  @override
  Stream<SecurityEvent> get securityEventStream => _securityController.stream;

  @override
  Stream<CredentialEvent> get credentialEventStream =>
      _credentialController.stream;

  @override
  Future<void> ensureAuthenticated() async {
    _ensureAuthenticatedCalls++;
    if (_state != AuthState.authenticated) {
      setAuthState(AuthState.authenticated);
    }
  }

  @override
  Future<ApiResponse> fetch(
    String path, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    fetchCalls.add(path);
    final handler = fetchHandler;
    if (handler != null) {
      return handler(
        path,
        method: method,
        headers: headers,
        body: body,
        timeout: timeout,
      );
    }
    return Future.value(
      ApiResponse(
        status: 200,
        headers: const <String, String>{'content-type': 'application/json'},
        body: Uint8List.fromList(utf8.encode('{}')),
      ),
    );
  }

  @override
  Future<ApiResponse> upload(
    String path, {
    required String fieldName,
    required String filename,
    required String contentType,
    required Stream<List<int>> bytes,
    required int length,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    uploadCalls.add(path);
    final handler = uploadHandler;
    if (handler != null) {
      return handler(
        path,
        fieldName: fieldName,
        filename: filename,
        contentType: contentType,
        bytes: bytes,
        length: length,
        headers: headers,
        timeout: timeout,
      );
    }
    return Future.value(
      ApiResponse(
        status: 200,
        headers: const <String, String>{'content-type': 'application/json'},
        body: Uint8List.fromList(utf8.encode('{}')),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getClaims() async {
    if (_state != AuthState.authenticated) return const <String, dynamic>{};
    return Map<String, dynamic>.from(claimsMap);
  }

  @override
  Future<UserClaims> getUserClaims() async {
    if (_state != AuthState.authenticated) {
      return const UserClaims(<String, dynamic>{});
    }
    return UserClaims(Map<String, dynamic>.from(claimsMap));
  }

  @override
  Future<List<String>> getRoles() async {
    if (_state != AuthState.authenticated) return const <String>[];
    return List<String>.unmodifiable(roles);
  }

  @override
  Future<void> logout() async {
    _logoutCalls++;
    setAuthState(AuthState.unauthenticated);
  }

  @override
  Future<Set<NativeCredentialProviderKind>> availableNativeProviders() async {
    return Set<NativeCredentialProviderKind>.unmodifiable(nativeProviders);
  }

  @override
  Future<void> prefetchDiscovery() async {
    // no-op for tests
  }

  @override
  String get version => 'mock-auth-runtime';

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stateController.close();
    await _securityController.close();
    await _credentialController.close();
  }
}
