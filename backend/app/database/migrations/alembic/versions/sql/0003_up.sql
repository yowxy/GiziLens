-- Immutable inference snapshot and final inspection are distinct records.
CREATE TABLE scans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES organizations(id),
    firebase_uid varchar(128) NOT NULL CHECK (btrim(firebase_uid) <> ''),
    batch_id uuid NOT NULL REFERENCES batches(id),
    akg_target_id uuid NOT NULL REFERENCES akg_targets(id),
    quota_bucket_id uuid,
    idempotency_key varchar(100) NOT NULL CHECK (btrim(idempotency_key) <> ''),
    origin varchar(20) NOT NULL DEFAULT 'LIVE' CHECK (origin IN ('LIVE','LEGACY_FIRESTORE')),
    legacy_firestore_id text UNIQUE,
    status varchar(20) NOT NULL DEFAULT 'PROCESSING' CHECK (status IN ('PROCESSING','SUCCESS','FAILED')),
    quota_status varchar(20) NOT NULL DEFAULT 'RESERVED' CHECK (quota_status IN ('RESERVED','CONSUMED','RELEASED','NOT_APPLICABLE')),
    ai_model varchar(150),
    raw_result jsonb CHECK (raw_result IS NULL OR jsonb_typeof(raw_result) = 'object'),
    target_snapshot jsonb NOT NULL CHECK (jsonb_typeof(target_snapshot) = 'object'),
    processing_ms integer CHECK (processing_ms >= 0),
    error_code varchar(50),
    created_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    reservation_expires_at timestamptz,
    UNIQUE (organization_id, firebase_uid, idempotency_key),
    FOREIGN KEY (organization_id, firebase_uid) REFERENCES organization_members(organization_id, firebase_uid),
    FOREIGN KEY (quota_bucket_id, organization_id) REFERENCES quota_buckets(id, organization_id),
    CHECK ((origin = 'LIVE' AND legacy_firestore_id IS NULL AND quota_bucket_id IS NOT NULL
        AND ((status = 'PROCESSING' AND quota_status = 'RESERVED' AND reservation_expires_at IS NOT NULL)
          OR (status = 'SUCCESS' AND quota_status = 'CONSUMED' AND raw_result IS NOT NULL)
          OR (status = 'FAILED' AND quota_status = 'RELEASED')))
        OR (origin = 'LEGACY_FIRESTORE' AND legacy_firestore_id IS NOT NULL
          AND quota_bucket_id IS NULL AND quota_status = 'NOT_APPLICABLE' AND status = 'SUCCESS')),
    CHECK ((status = 'PROCESSING' AND completed_at IS NULL)
        OR (status IN ('SUCCESS','FAILED') AND completed_at IS NOT NULL AND completed_at >= created_at))
);
CREATE INDEX ix_scans_uid_created ON scans (firebase_uid, created_at DESC, id DESC);
CREATE INDEX ix_scans_org_created ON scans (organization_id, created_at DESC, id DESC);
CREATE INDEX ix_scans_batch ON scans (batch_id, created_at DESC);
CREATE INDEX ix_scans_quota ON scans (quota_bucket_id);
CREATE INDEX ix_scans_status_created ON scans (status, created_at DESC);
CREATE INDEX ix_scans_stale_reservation ON scans (reservation_expires_at) WHERE quota_status = 'RESERVED';

CREATE TABLE scan_images (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id uuid NOT NULL REFERENCES scans(id),
    storage_backend varchar(30) NOT NULL CHECK (storage_backend IN ('FIREBASE','S3','R2','SUPABASE','LOCAL')),
    bucket varchar(255) NOT NULL,
    object_key text NOT NULL CHECK (btrim(object_key) <> ''),
    image_type varchar(20) NOT NULL CHECK (image_type IN ('ORIGINAL','THUMBNAIL')),
    mime_type varchar(50) NOT NULL CHECK (mime_type LIKE 'image/%'),
    size_bytes bigint NOT NULL CHECK (size_bytes > 0),
    width integer NOT NULL CHECK (width > 0),
    height integer NOT NULL CHECK (height > 0),
    sha256 char(64) CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
    created_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    UNIQUE (scan_id, image_type),
    UNIQUE (storage_backend, bucket, object_key),
    CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE inspections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id uuid NOT NULL UNIQUE REFERENCES scans(id),
    verified_by_uid varchar(128) NOT NULL CHECK (btrim(verified_by_uid) <> ''),
    verifier_snapshot jsonb CHECK (verifier_snapshot IS NULL OR jsonb_typeof(verifier_snapshot) = 'object'),
    total_weight numeric(10,2) NOT NULL CHECK (total_weight >= 0),
    total_calories numeric(12,4) NOT NULL CHECK (total_calories >= 0),
    total_protein numeric(12,4) NOT NULL CHECK (total_protein >= 0),
    total_fat numeric(12,4) NOT NULL CHECK (total_fat >= 0),
    total_carbohydrate numeric(12,4) NOT NULL CHECK (total_carbohydrate >= 0),
    total_fiber numeric(12,4) NOT NULL CHECK (total_fiber >= 0),
    compliance_status varchar(20) NOT NULL CHECK (compliance_status IN ('SESUAI','TIDAK_SESUAI','NOT_ASSESSED')),
    policy_version varchar(50) NOT NULL,
    notes text,
    locked_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (locked_at >= created_at)
);
CREATE INDEX ix_inspections_locked_at ON inspections (locked_at DESC, id DESC);
CREATE INDEX ix_inspections_status_locked ON inspections (compliance_status, locked_at DESC);
CREATE INDEX ix_inspections_verifier ON inspections (verified_by_uid, locked_at DESC);

CREATE TABLE inspection_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id uuid NOT NULL REFERENCES inspections(id),
    name varchar(150) NOT NULL CHECK (btrim(name) <> ''),
    category varchar(50) NOT NULL,
    compartment_number integer CHECK (compartment_number > 0),
    estimated_gram numeric(10,2) NOT NULL CHECK (estimated_gram > 0),
    confidence numeric(5,4) CHECK (confidence BETWEEN 0 AND 1),
    calories numeric(12,4) NOT NULL CHECK (calories >= 0),
    protein numeric(12,4) NOT NULL CHECK (protein >= 0),
    fat numeric(12,4) NOT NULL CHECK (fat >= 0),
    carbohydrate numeric(12,4) NOT NULL CHECK (carbohydrate >= 0),
    fiber numeric(12,4) NOT NULL CHECK (fiber >= 0),
    bounding_box jsonb CHECK (bounding_box IS NULL OR jsonb_typeof(bounding_box) = 'object'),
    is_verified boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_inspection_items_inspection ON inspection_items (inspection_id);
