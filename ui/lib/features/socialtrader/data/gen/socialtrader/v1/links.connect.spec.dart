//
//  Generated code. Do not modify.
//  source: socialtrader/v1/links.proto
//

import "package:connectrpc/connect.dart" as connect;
import "links.pb.dart" as socialtraderv1links;

/// LinkService binds a wallet to the caller's profile with a Sign-In with
/// Ethereum (EIP-4361) signature over a server nonce. Authenticated only: the
/// profile comes from the caller's claims.
abstract final class LinkService {
  /// Fully-qualified name of the LinkService service.
  static const name = 'socialtrader.v1.LinkService';

  static const issueNonce = connect.Spec(
    '/$name/IssueNonce',
    connect.StreamType.unary,
    socialtraderv1links.IssueNonceRequest.new,
    socialtraderv1links.IssueNonceResponse.new,
  );

  static const linkWallet = connect.Spec(
    '/$name/LinkWallet',
    connect.StreamType.unary,
    socialtraderv1links.LinkWalletRequest.new,
    socialtraderv1links.LinkWalletResponse.new,
  );

  static const getLinkedWallet = connect.Spec(
    '/$name/GetLinkedWallet',
    connect.StreamType.unary,
    socialtraderv1links.GetLinkedWalletRequest.new,
    socialtraderv1links.GetLinkedWalletResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
