package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	aconfig "github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/apps/default/tests"
)

// SetupSuite drives chat's setup plan the way the cluster's setup Job runs it:
// migrations against a real Postgres, then ChatService's permission manifest
// published to a stand-in for tenancy's registration endpoint.
type SetupSuite struct {
	tests.BaseTestSuite
}

func TestSetupSuite(t *testing.T) {
	suite.Run(t, new(SetupSuite))
}

// registered records the manifests tenancy's registration endpoint receives.
type registered struct {
	mu        sync.Mutex
	manifests []map[string]any
}

func (r *registered) handler(t *testing.T) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		if req.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var manifest map[string]any
		if err := json.NewDecoder(req.Body).Decode(&manifest); err != nil {
			t.Errorf("manifest body: %v", err)
			http.Error(w, "bad body", http.StatusBadRequest)
			return
		}
		r.mu.Lock()
		r.manifests = append(r.manifests, manifest)
		r.mu.Unlock()
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"registered":true}`))
	})
}

func (r *registered) all() []map[string]any {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]map[string]any(nil), r.manifests...)
}

func (s *SetupSuite) TestSetupMigratesAndRegistersPermissionsIdempotently() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		tenancy := &registered{}
		server := httptest.NewServer(tenancy.handler(t))
		t.Cleanup(server.Close)
		t.Setenv(frame.ManifestRegistrationURLEnvVar, server.URL+frame.ManifestRegistrationPath)

		// Frame names a migration by its basename only when the basename
		// resolves from the working directory; the migrate step chdirs into
		// the migration directory for that reason. Start there too, so the
		// suite's own migration and the setup runs name migrations alike, as
		// consecutive setup Jobs do. t.Chdir restores the directory after.
		t.Chdir(tests.MigrationPath())

		ctx, svc := s.CreateService(t, dep)
		cfg, ok := svc.Config().(*aconfig.ChatConfig)
		require.True(t, ok)
		cfg.DatabaseMigrationPath = tests.MigrationPath()

		svc.Init(ctx, setupOptions(cfg)...)
		require.Equal(t, []string{frame.SetupTaskMigrate, frame.SetupTaskPermissions}, svc.SetupTaskNames())

		// First as a legacy migrate process (DO_MIGRATION, argv "migrate"),
		// then as a setup process (DO_SETUP, argv "setup"), which runs every
		// registered step. Each run after the first finds nothing to migrate.
		require.True(t, frame.ShouldRunSetup(cfg))
		require.NoError(t, svc.RunSetupForProcess(ctx, cfg), "legacy migrate run")
		cfg.DoSetup = true
		require.True(t, frame.IsSetupMode(cfg))
		require.NoError(t, svc.RunSetupForProcess(ctx, cfg), "setup run")
		require.NoError(t, svc.RunSetupForProcess(ctx, cfg), "repeated setup run")

		manifests := tenancy.all()
		require.Len(t, manifests, 3, "one ChatService manifest per setup run")
		for _, manifest := range manifests {
			require.Equal(t, "service_chat", manifest["namespace"])
			require.Contains(t, manifest["permissions"], "stawi_card_post")
			require.Contains(t, manifest["permissions"], "event_send")
			bindings, isMap := manifest["role_bindings"].(map[string]any)
			require.True(t, isMap)
			require.Contains(t, bindings["service"], "stawi_card_post")
			require.NotContains(t, bindings["owner"], "stawi_card_post")
		}
		require.Equal(t, manifests[0]["permissions"], manifests[2]["permissions"])
	})
}

func (s *SetupSuite) TestSetupWithoutRegistrationURLOnlyMigrates() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		t.Setenv(frame.ManifestRegistrationURLEnvVar, "")
		t.Chdir(tests.MigrationPath())

		ctx, svc := s.CreateService(t, dep)
		cfg, ok := svc.Config().(*aconfig.ChatConfig)
		require.True(t, ok)
		cfg.DatabaseMigrationPath = tests.MigrationPath()

		svc.Init(ctx, setupOptions(cfg)...)
		require.Equal(t, []string{frame.SetupTaskMigrate}, svc.SetupTaskNames())
		require.NoError(t, svc.RunSetupForProcess(ctx, cfg))
	})
}
