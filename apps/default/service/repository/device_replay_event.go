package repository

import (
	"context"
	"errors"
	"time"

	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/workerpool"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

const replayCreateBatchSize = 100

type deviceReplayRepository struct {
	datastore.BaseRepository[*models.DeviceReplayEvent]
}

func NewDeviceReplayRepository(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
) DeviceReplayRepository {
	return &deviceReplayRepository{
		BaseRepository: datastore.NewBaseRepository[*models.DeviceReplayEvent](
			ctx,
			dbPool,
			workMan,
			func() *models.DeviceReplayEvent { return &models.DeviceReplayEvent{} },
		),
	}
}

func (drr *deviceReplayRepository) ListAfterCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	afterCursor string,
	upperBoundCursor string,
	limit int,
) ([]*models.DeviceReplayEvent, error) {
	var events []*models.DeviceReplayEvent

	query := drr.Pool().DB(ctx, true).
		Where("profile_id = ? AND device_id = ? AND deleted_at IS NULL", profileID, deviceID).
		Order("id ASC")

	if afterCursor != "" {
		query = query.Where("id > ?", afterCursor)
	}
	if upperBoundCursor != "" {
		query = query.Where("id <= ?", upperBoundCursor)
	}
	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&events).Error; err != nil {
		return nil, err
	}

	return events, nil
}

func (drr *deviceReplayRepository) GetByCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	cursor string,
) (*models.DeviceReplayEvent, error) {
	event := &models.DeviceReplayEvent{}
	err := drr.Pool().DB(ctx, true).
		Where("profile_id = ? AND device_id = ? AND id = ? AND deleted_at IS NULL", profileID, deviceID, cursor).
		First(event).Error
	if err != nil {
		return nil, err
	}

	return event, nil
}

func (drr *deviceReplayRepository) GetByEventID(
	ctx context.Context,
	profileID string,
	deviceID string,
	eventID string,
) (*models.DeviceReplayEvent, error) {
	event := &models.DeviceReplayEvent{}
	err := drr.Pool().DB(ctx, true).
		Where("profile_id = ? AND device_id = ? AND event_id = ? AND deleted_at IS NULL",
			profileID, deviceID, eventID).
		First(event).Error
	if err != nil {
		return nil, err
	}

	return event, nil
}

func (drr *deviceReplayRepository) GetLatestCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
) (string, error) {
	event := &models.DeviceReplayEvent{}
	err := drr.Pool().DB(ctx, true).
		Select("id").
		Where("profile_id = ? AND device_id = ? AND deleted_at IS NULL", profileID, deviceID).
		Order("id DESC").
		Limit(1).
		First(event).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", nil
		}
		return "", err
	}

	return event.GetID(), nil
}

func (drr *deviceReplayRepository) CreateIgnoringDuplicates(
	ctx context.Context,
	entries []*models.DeviceReplayEvent,
) error {
	if len(entries) == 0 {
		return nil
	}

	return drr.Pool().DB(ctx, false).
		Clauses(clause.OnConflict{DoNothing: true}).
		CreateInBatches(entries, replayCreateBatchSize).Error
}

func (drr *deviceReplayRepository) ListByEventAndDevices(
	ctx context.Context,
	profileID string,
	eventID string,
	deviceIDs []string,
) ([]*models.DeviceReplayEvent, error) {
	if len(deviceIDs) == 0 {
		return nil, nil
	}

	var events []*models.DeviceReplayEvent
	err := drr.Pool().DB(ctx, true).
		Where("profile_id = ? AND event_id = ? AND device_id IN ? AND deleted_at IS NULL", profileID, eventID, deviceIDs).
		Order("id ASC").
		Find(&events).Error
	if err != nil {
		return nil, err
	}

	return events, nil
}

func (drr *deviceReplayRepository) TrimDevice(
	ctx context.Context,
	profileID string,
	deviceID string,
	keep int,
	maxAge time.Duration,
) error {
	db := drr.Pool().DB(ctx, false)

	return db.Transaction(func(tx *gorm.DB) error {
		// Use Unscoped for hard-delete — replay entries should be physically
		// removed so autovacuum can reclaim space and the table stays lean.
		if maxAge > 0 {
			cutoff := time.Now().Add(-maxAge)
			if err := tx.Unscoped().
				Where("profile_id = ? AND device_id = ? AND created_at < ?", profileID, deviceID, cutoff).
				Delete(&models.DeviceReplayEvent{}).Error; err != nil {
				return err
			}
		}

		if keep <= 0 {
			return tx.Unscoped().Where("profile_id = ? AND device_id = ?", profileID, deviceID).
				Delete(&models.DeviceReplayEvent{}).Error
		}

		anchor := struct {
			ID string
		}{}
		err := tx.Model(&models.DeviceReplayEvent{}).
			Select("id").
			Where("profile_id = ? AND device_id = ? AND deleted_at IS NULL", profileID, deviceID).
			Order("id DESC").
			Offset(keep - 1).
			Limit(1).
			Scan(&anchor).Error
		if err != nil {
			return err
		}
		if anchor.ID == "" {
			return nil
		}

		return tx.Unscoped().Where(
			"profile_id = ? AND device_id = ? AND id < ?",
			profileID,
			deviceID,
			anchor.ID,
		).Delete(&models.DeviceReplayEvent{}).Error
	})
}
