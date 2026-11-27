-- GiziLens PostgreSQL 14+ | generated from the Alembic SQL revisions
-- Run only if NOT using Alembic for the same schema.
-- WARNING: destroys all data in the 14 tables. Back up before executing.
BEGIN;

-- Revision 0004 (down)
DROP TABLE ai_usage_logs;

-- Revision 0003 (down)
DROP TABLE inspection_items;
DROP TABLE inspections;
DROP TABLE scan_images;
DROP TABLE scans;

-- Revision 0002 (down)
DROP TABLE payments;
DROP TABLE quota_buckets;
DROP TABLE subscriptions;
DROP TABLE plans;

-- Revision 0001 (down)
DROP TABLE akg_targets;
DROP TABLE batches;
DROP TABLE sppg_school_links;
DROP TABLE organization_members;
DROP TABLE organizations;

COMMIT;
