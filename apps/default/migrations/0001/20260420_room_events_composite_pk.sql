-- Copyright 2023-2026 Ant Investor Ltd
--
-- Licensed under the Apache License, Version 2.0 (the "License").

-- room_events is promoted to a TimescaleDB hypertable. TimescaleDB requires
-- the time-partition column to participate in every UNIQUE/PRIMARY
-- constraint, so replace the BaseModel-default PK (id) with a composite
-- (id, created_at). GORM queries continue to work because BeforeCreate
-- sets both columns and xid-generated ids remain globally unique.

ALTER TABLE room_events DROP CONSTRAINT IF EXISTS room_events_pkey;
ALTER TABLE room_events ADD PRIMARY KEY (id, created_at);
