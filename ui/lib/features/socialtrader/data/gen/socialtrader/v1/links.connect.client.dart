//
//  Generated code. Do not modify.
//  source: socialtrader/v1/links.proto
//

import "package:connectrpc/connect.dart" as connect;
import "links.pb.dart" as socialtraderv1links;
import "links.connect.spec.dart" as specs;

/// LinkService binds a wallet to the caller's profile with a Sign-In with
/// Ethereum (EIP-4361) signature over a server nonce. Authenticated only: the
/// profile comes from the caller's claims.
extension type LinkServiceClient (connect.Transport _transport) {
  Future<socialtraderv1links.IssueNonceResponse> issueNonce(
    socialtraderv1links.IssueNonceRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LinkService.issueNonce,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1links.LinkWalletResponse> linkWallet(
    socialtraderv1links.LinkWalletRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LinkService.linkWallet,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1links.GetLinkedWalletResponse> getLinkedWallet(
    socialtraderv1links.GetLinkedWalletRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LinkService.getLinkedWallet,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
