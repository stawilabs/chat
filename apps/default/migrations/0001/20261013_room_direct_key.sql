-- Copyright 2023-2026 Ant Investor Ltd
--
-- Licensed under the Apache License, Version 2.0 (the "License").
--
-- Personal rooms (DIRECT, BOT) are found by their people's key, oldest first,
-- within a tenancy.
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS direct_key varchar(100) NOT NULL DEFAULT '';
CREATE INDEX IF NOT EXISTS idx_rooms_direct_key_lookup
    ON rooms (direct_key, tenant_id, partition_id, created_at)
    WHERE direct_key <> '' AND deleted_at IS NULL;
