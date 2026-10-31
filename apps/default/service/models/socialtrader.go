package models

import (
	"time"

	"github.com/pitabwire/frame/v3/data"
)

// SocialTraderRoomBinding binds a chat room to a strategy pool: the server's
// record that the pool's leader bound the room, written only after the
// socialtrader service confirmed the pool and the leader's linked wallet.
// It, not the room's metadata (which any room owner can write), is what the
// fact publisher and the card path trust.
type SocialTraderRoomBinding struct {
	data.BaseModel
	RoomID string `gorm:"type:varchar(50);uniqueIndex"`
	// PoolID is the pool address, lowercase hex.
	PoolID string `gorm:"type:varchar(42);index"`
	// LeaderProfileID is the profile that bound the room: the pool leader's.
	LeaderProfileID string `gorm:"type:varchar(50)"`
	BoundAt         time.Time
}

// TableName returns the database table name for SocialTraderRoomBinding.
func (*SocialTraderRoomBinding) TableName() string { return "socialtrader_room_bindings" }
