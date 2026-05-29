-- Copyright 2023-2026 Ant Investor Ltd
--
-- Licensed under the Apache License, Version 2.0 (the "License").

-- room_events is promoted to a TimescaleDB hypertable. TimescaleDB requires
-- the time-partition column to participate in every UNIQUE/PRIMARY
-- constraint, so replace the BaseModel-default PK (id) with a composite
-- (id, created_at). GORM queries continue to work because BeforeCreate
-- sets both columns and xid-generated ids remain globally unique.
--
-- ZERO-DOWNTIME CAVEAT: ADD PRIMARY KEY takes an ACCESS EXCLUSIVE lock and
-- builds its backing unique index synchronously by scanning the whole table.
-- This is safe on the initial (empty/small) deployment. If this ever needs to
-- run against a large, live room_events table, switch to the concurrent
-- pattern: CREATE UNIQUE INDEX CONCURRENTLY room_events_pk_idx ON
-- room_events (id, created_at) outside a transaction, then ALTER TABLE ...
-- ADD PRIMARY KEY USING INDEX room_events_pk_idx. The current migrator wraps
-- each patch in a transaction, so CONCURRENTLY would require migrator support.

ALTER TABLE room_events DROP CONSTRAINT IF EXISTS room_events_pkey;
ALTER TABLE room_events ADD PRIMARY KEY (id, created_at);
