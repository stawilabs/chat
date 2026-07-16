// Copyright 2023-2026 Ant Investor Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package models

import (
	"time"

	"github.com/antinvestor/common/v2/timescale"
)

const (
	roomEventsChunkInterval = 24 * time.Hour
)

// Hypertables returns the TimescaleDB configuration for this app's
// append-only tables. Applied idempotently by timescale.Ensure after
// SQL migrations in the migrate job.
//
// CompressAfter is deliberately zero: TimescaleDB columnstore/compression
// rejects ENABLE ROW LEVEL SECURITY (SQLSTATE 0A000). Frame tenancy
// installs RLS on every Tenanted model (including RoomEvent) during
// Migrate, so enabling compression would make every subsequent migrate
// job fail fatally and block Helm upgrades.
func Hypertables() []timescale.Hypertable {
	return []timescale.Hypertable{
		{
			Table:         "room_events",
			TimeColumn:    "created_at",
			ChunkInterval: roomEventsChunkInterval,
			SegmentBy:     []string{"partition_id", "room_id"},
			CompressAfter: 0, // incompatible with frame RLS on hypertables
			RetainFor:     0, // chat history is durable forever
		},
	}
}
