module buf.build/gen/go/stawi/socialtrader/connectrpc/go/v2

go 1.26

// The protos are vendored, not published to the BSR, so the message module
// is the sibling directory rather than a buf.build/gen release.
replace buf.build/gen/go/stawi/socialtrader/protocolbuffers/go => ../protocolbuffers

require (
	buf.build/gen/go/stawi/socialtrader/protocolbuffers/go v0.0.0-00010101000000-000000000000
	connectrpc.com/connect/v2 v2.0.1
)
