package health_test

import (
	"testing"

	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/health"
	"github.com/stawilabs/chat/apps/default/tests"
)

type HealthCheckerTestSuite struct {
	tests.BaseTestSuite
}

func TestHealthCheckerTestSuite(t *testing.T) {
	suite.Run(t, new(HealthCheckerTestSuite))
}

func (s *HealthCheckerTestSuite) TestDBCheckerReportsHealthy() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

		checker := health.DBChecker{Pool: dbPool}
		require.Equal(t, "database", checker.Name())
		require.NoError(t, checker.CheckHealth(), "a live database must report healthy")
	})
}
