import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'wallet_platform_stub.dart'
    if (dart.library.js_interop) 'wallet_platform_web.dart'
    as platform;

part 'wallet_service.g.dart';

/// A transaction the socialtrader service prepared for the wallet to sign:
/// calldata the app never builds itself. The wallet signs and sends it; the
/// app only ever holds the hash it returns.
@immutable
class PreparedTx {
  const PreparedTx({
    required this.to,
    required this.data,
    required this.value,
    required this.chainId,
    this.description = '',
  });

  /// The contract called (0x-prefixed hex).
  final String to;

  /// The calldata (0x-prefixed hex).
  final String data;

  /// The native value sent (0x-prefixed hex, "0x0" for none).
  final String value;
  final int chainId;

  /// What the call does, for the review the person sees before signing.
  final String description;

  @override
  bool operator ==(Object other) =>
      other is PreparedTx &&
      other.to == to &&
      other.data == data &&
      other.value == value &&
      other.chainId == chainId;

  @override
  int get hashCode => Object.hash(to, data, value, chainId);

  @override
  String toString() => 'PreparedTx(to: $to, chainId: $chainId)';
}

/// Thrown when a signature is asked of a wallet that only reads: a pasted
/// address, or a platform without a signer.
class WalletReadOnlyException implements Exception {
  const WalletReadOnlyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when a signature is asked before any wallet is connected.
class WalletNotConnectedException implements Exception {
  const WalletNotConnectedException([this.message = 'Connect a wallet first']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when this platform has no signer at all (no injected provider on
/// web; no WalletConnect on mobile).
class WalletUnavailableException implements Exception {
  const WalletUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The signer a platform offers. Web wraps the injected EIP-1193 provider;
/// other platforms are read-only until WalletConnect is bundled. Private keys
/// never pass through here: the platform signs, the app gets hashes.
abstract interface class WalletPlatform {
  /// Whether this platform can sign at all.
  bool get canSign;

  /// What the signer is called to the person ("MetaMask", "read-only").
  String get signerLabel;

  /// Asks the signer for an account; returns its address.
  Future<String> connect();

  /// Asks the signer to sign and send [tx] from [from]; returns the hash.
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  });

  /// Asks the signer for an EIP-191 personal_sign of [message] by [from].
  Future<String> personalSign({required String from, required String message});
}

/// The WalletConnect project id, when a build is given one. Without it the
/// non-web platforms stay read-only.
const String walletConnectProjectId = String.fromEnvironment(
  'WALLETCONNECT_PROJECT_ID',
);

/// What the wallet looks like to the UI.
@immutable
class WalletState {
  const WalletState({
    this.address,
    this.readOnly = true,
    this.connecting = false,
    this.error,
    this.signerLabel = '',
    this.signerAvailable = false,
  });

  /// The connected or pasted address, lowercase hex; null when none.
  final String? address;

  /// True when the address was pasted or the platform cannot sign.
  final bool readOnly;
  final bool connecting;

  /// The last connection failure, shown until the next attempt.
  final String? error;

  /// The signer's name, for the settings screen.
  final String signerLabel;

  /// Whether this platform has a signer at all (an injected wallet on web);
  /// false where only a pasted, read-only address is possible.
  final bool signerAvailable;

  bool get isConnected => address != null && address!.isNotEmpty;

  /// Whether a transaction can be signed right now.
  bool get canSign => isConnected && !readOnly;

  /// `0x1234…abcd`.
  String get shortAddress {
    final a = address;
    if (a == null || a.length < 10) return a ?? '';
    return '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
  }

  WalletState copyWith({
    String? address,
    bool clearAddress = false,
    bool? readOnly,
    bool? connecting,
    String? error,
    bool clearError = false,
    String? signerLabel,
  }) => WalletState(
    address: clearAddress ? null : (address ?? this.address),
    readOnly: readOnly ?? this.readOnly,
    connecting: connecting ?? this.connecting,
    error: clearError ? null : (error ?? this.error),
    signerLabel: signerLabel ?? this.signerLabel,
    signerAvailable: signerAvailable,
  );
}

/// Validates an EVM address (0x + 40 hex digits); returns it lowercased.
String normalizeAddress(String address) {
  final trimmed = address.trim();
  final ok = RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(trimmed);
  if (!ok) {
    throw ArgumentError.value(address, 'address', 'not an EVM address');
  }
  return trimmed.toLowerCase();
}

/// The platform's signer; tests override it with a fake.
@Riverpod(keepAlive: true)
WalletPlatform walletPlatform(Ref ref) => platform.createWalletPlatform();

/// The wallet the trading group module signs with. Connecting asks the
/// platform signer for an account; a pasted address reads only. Nothing is
/// ever sent without a call to [sendPrepared], which the UI makes on a tap.
@Riverpod(keepAlive: true)
class WalletController extends _$WalletController {
  @override
  WalletState build() {
    final signer = ref.watch(walletPlatformProvider);
    return WalletState(
      signerLabel: signer.signerLabel,
      signerAvailable: signer.canSign,
    );
  }

  WalletPlatform get _platform => ref.read(walletPlatformProvider);

  /// Asks the platform signer for an account. A failure is kept in
  /// [WalletState.error]; the state stays disconnected.
  Future<void> connect() async {
    state = state.copyWith(connecting: true, clearError: true);
    try {
      final address = normalizeAddress(await _platform.connect());
      if (!ref.mounted) return;
      state = state.copyWith(
        address: address,
        readOnly: !_platform.canSign,
        connecting: false,
        clearError: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        clearAddress: true,
        readOnly: true,
        connecting: false,
        error: _describe(e),
      );
    }
  }

  /// Forgets the address and any error.
  void disconnect() {
    state = WalletState(
      signerLabel: state.signerLabel,
      signerAvailable: state.signerAvailable,
    );
  }

  /// Uses a pasted address for portfolio views only: it can never sign, even
  /// on a platform that has a signer.
  void setReadOnlyAddress(String address) {
    final normalized = normalizeAddress(address);
    state = state.copyWith(
      address: normalized,
      readOnly: true,
      connecting: false,
      clearError: true,
    );
  }

  /// Asks the wallet to sign and send [tx]; returns the transaction hash.
  Future<String> sendPrepared(PreparedTx tx) async {
    final from = _signingAddress();
    return _platform.sendTransaction(from: from, tx: tx);
  }

  /// Asks the wallet for a personal_sign of [message] (wallet linking).
  Future<String> personalSign(String message) async {
    final from = _signingAddress();
    return _platform.personalSign(from: from, message: message);
  }

  String _signingAddress() {
    final current = state;
    final address = current.address;
    if (address == null || address.isEmpty) {
      throw const WalletNotConnectedException();
    }
    if (current.readOnly) {
      throw WalletReadOnlyException(
        _platform.canSign
            ? 'This address was pasted and can only read. Connect the '
                  'wallet to sign.'
            : 'This device cannot sign: open the app on the web with a '
                  'browser wallet to sign.',
      );
    }
    return address;
  }

  static String _describe(Object error) => switch (error) {
    WalletUnavailableException(:final message) => message,
    StateError(:final message) => message,
    ArgumentError(:final message) => '$message',
    _ => error.toString(),
  };
}
