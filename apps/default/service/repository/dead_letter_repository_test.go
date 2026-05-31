package repository_test

import (
	"testing"

	"github.com/pitabwire/frame/frametests"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type DeadLetterRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestDeadLetterRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(DeadLetterRepositoryTestSuite))
}

func (s *DeadLetterRepositoryTestSuite) TestRecordPersistsDeadLetter() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewDeadLetterRepository(ctx, dbPool, workMan)

		payload := []byte("the-original-message-bytes")
		headers := map[string]string{"dlq_original_queue": "device.event.delivery", "x": "y"}

		require.NoError(t, repo.Record(ctx, "device.event.delivery", "max retries exceeded", payload, headers))

		var rows []*models.DeadLetterEvent
		require.NoError(t, dbPool.DB(ctx, true).
			Table("dead_letter_events").
			Where("original_queue = ?", "device.event.delivery").
			Find(&rows).Error)

		require.Len(t, rows, 1)
		s.Equal("max retries exceeded", rows[0].ErrorMessage)
		s.Equal(payload, rows[0].Payload)
		s.Equal("y", rows[0].Headers["x"])
	})
}
