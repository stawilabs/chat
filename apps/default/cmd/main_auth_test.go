package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/handlers"
	"github.com/stawilabs/chat/apps/default/service/stawi/stawitest"
	"github.com/stawilabs/chat/apps/default/tests"
)

// unauthenticatedRequestsAreRefused drives the HTTP handler main serves —
// the same interceptor chain the chat RPCs run behind — with no credentials.
// The Stawi paths (Stawi acts and service cards both arrive on SendEvent)
// add no route of their own; every RPC refuses an unauthenticated caller, and
// there is no endpoint that accepts settlement facts over HTTP.
type AuthSuite struct {
	tests.BaseTestSuite
}

func TestAuthSuite(t *testing.T) {
	suite.Run(t, new(AuthSuite))
}

func (s *AuthSuite) TestUnauthenticatedRequestsAreRefused() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		s.unauthenticatedRequestsAreRefused(t, dep)
	})
}

func (s *AuthSuite) unauthenticatedRequestsAreRefused(t *testing.T, dep *definition.DependencyOption) {
	ctx, svc := s.CreateService(t, dep)

	mux := setupConnectServer(ctx, svc, nil, nil, authz.NewMiddleware(svc.SecurityManager().GetAuthorizer(ctx)),
		handlers.WithStawi(stawitest.NewRooms(), stawitest.NewAccounts()))
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)

	const room = `"roomId":"d3l2p7rh1v8s73a0room"`
	for procedure, body := range map[string]string{
		"/chat.v1.ChatService/SendEvent": `{"event":[{"id":"d3l2p7rh1v8s73a0evt0",` + room + `,"type":"ROOM_EVENT_TYPE_EVENT",` +
			`"payload":{"type":"PAYLOAD_TYPE_FINANCE_CARD","financeCard":{"cardId":"c","groupId":"g",` +
			`"kind":"k","title":"t"}}}]}`,
		"/chat.v1.ChatService/AddRoomSubscriptions": `{` + room + `}`,
		"/chat.v1.ChatService/DeleteRoom":           `{` + room + `}`,
		"/chat.v1.ChatService/SubmitProposal": `{` + room +
			`,"proposalId":"d3l2p7rh1v8s73a0prop","action":"PROPOSAL_ACTION_APPROVE"}`,
	} {
		t.Run(procedure, func(t *testing.T) {
			resp, postErr := http.Post(server.URL+procedure, "application/json", strings.NewReader(body))
			require.NoError(t, postErr)
			t.Cleanup(func() { _ = resp.Body.Close() })
			raw, _ := io.ReadAll(resp.Body)
			require.Equal(t, http.StatusUnauthorized, resp.StatusCode, string(raw))
		})
	}

	for _, path := range []string{"/stawi/facts", "/chat.v1.ChatService/StawiFacts", "/reconcile"} {
		t.Run("no route "+path, func(t *testing.T) {
			resp, postErr := http.Post(server.URL+path, "application/octet-stream", strings.NewReader("x"))
			require.NoError(t, postErr)
			t.Cleanup(func() { _ = resp.Body.Close() })
			require.NotEqual(t, http.StatusOK, resp.StatusCode)
		})
	}
}
