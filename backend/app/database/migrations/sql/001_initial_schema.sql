-- GiziLens PostgreSQL 14+ | generated from the Alembic SQL revisions
-- Run only if NOT using Alembic for the same schema.
BEGIN;

-- Revision 0001 (up)
-- Organizations and operational master data. Firebase owns user identity.
CREATE TABLE organizations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(255) NOT NULL CHECK (btrim(name) <> ''),
    type varchar(20) NOT NULL CHECK (type IN ('SPPG','SCHOOL','INDIVIDUAL')),
    registration_code varchar(100),
    province varchar(100),
    city varchar(100),
    district varchar(100),
    address text,
    status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','VERIFIED','SUSPENDED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (registration_code IS NULL OR btrim(registration_code) <> ''),
    CHECK (status <> 'VERIFIED' OR type = 'INDIVIDUAL' OR registration_code IS NOT NULL)
);
CREATE UNIQUE INDEX uq_organizations_registration ON organizations (type, lower(btrim(registration_code))) WHERE registration_code IS NOT NULL;
CREATE INDEX ix_organizations_region ON organizations (type, province, city);
CREATE INDEX ix_organizations_status ON organizations (status, type);

CREATE TABLE organization_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES organizations(id),
    firebase_uid varchar(128) NOT NULL CHECK (btrim(firebase_uid) <> ''),
    membership_role varchar(30) NOT NULL CHECK (membership_role IN ('OWNER','MANAGER','NUTRITIONIST','OFFICER','SCHOOL_PIC','VIEWER')),
    status varchar(20) NOT NULL DEFAULT 'INVITED' CHECK (status IN ('INVITED','ACTIVE','SUSPENDED')),
    joined_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (organization_id, firebase_uid)
);
CREATE INDEX ix_members_uid_status ON organization_members (firebase_uid, status);

CREATE TABLE sppg_school_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sppg_id uuid NOT NULL REFERENCES organizations(id),
    school_id uuid NOT NULL REFERENCES organizations(id),
    status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACTIVE','INACTIVE')),
    started_at timestamptz,
    ended_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (sppg_id <> school_id),
    CHECK (ended_at IS NULL OR (started_at IS NOT NULL AND ended_at >= started_at)),
    CHECK (status <> 'ACTIVE' OR (started_at IS NOT NULL AND ended_at IS NULL))
);
CREATE UNIQUE INDEX uq_active_sppg_school_link ON sppg_school_links (sppg_id, school_id) WHERE status = 'ACTIVE';
CREATE INDEX ix_sppg_school_school ON sppg_school_links (school_id, status);
CREATE INDEX ix_sppg_school_sppg ON sppg_school_links (sppg_id, status);

CREATE TABLE batches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sppg_id uuid NOT NULL REFERENCES organizations(id),
    school_id uuid REFERENCES organizations(id),
    batch_code varchar(100) NOT NULL CHECK (btrim(batch_code) <> ''),
    production_date date NOT NULL,
    created_by_uid varchar(128) NOT NULL CHECK (btrim(created_by_uid) <> ''),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (sppg_id, batch_code),
    CHECK (school_id IS NULL OR school_id <> sppg_id)
);
CREATE INDEX ix_batches_sppg_date ON batches (sppg_id, production_date DESC);
CREATE INDEX ix_batches_school_date ON batches (school_id, production_date DESC);

CREATE TABLE akg_targets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_code varchar(50) NOT NULL,
    group_name varchar(150) NOT NULL,
    standard_version varchar(100) NOT NULL,
    calories numeric(12,4) NOT NULL CHECK (calories > 0),
    protein numeric(12,4) NOT NULL CHECK (protein > 0),
    fat numeric(12,4) NOT NULL CHECK (fat > 0),
    carbohydrate numeric(12,4) NOT NULL CHECK (carbohydrate > 0),
    fiber numeric(12,4) NOT NULL CHECK (fiber > 0),
    is_active boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (group_code, standard_version)
);
CREATE UNIQUE INDEX uq_active_akg_group ON akg_targets (group_code) WHERE is_active;

-- Revision 0002 (up)
-- Commercial records; all prices are integer IDR, never floating point.
CREATE TABLE plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code varchar(50) NOT NULL UNIQUE,
    name varchar(100) NOT NULL,
    description text,
    price bigint NOT NULL CHECK (price >= 0),
    billing_cycle varchar(20) NOT NULL CHECK (billing_cycle IN ('MONTHLY','QUARTERLY','ANNUAL')),
    quota_cycle varchar(20) NOT NULL DEFAULT 'MONTHLY' CHECK (quota_cycle IN ('MONTHLY','BILLING_PERIOD')),
    scan_quota integer CHECK (scan_quota > 0),
    max_members integer CHECK (max_members > 0),
    history_retention_days integer CHECK (history_retention_days > 0),
    features jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(features) = 'array'),
    is_active boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (NOT is_active OR (scan_quota IS NOT NULL AND max_members IS NOT NULL AND history_retention_days IS NOT NULL))
);

CREATE TABLE subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES organizations(id),
    plan_id uuid NOT NULL REFERENCES plans(id),
    status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACTIVE','EXPIRED','CANCELLED')),
    starts_at timestamptz NOT NULL,
    expires_at timestamptz NOT NULL,
    price_snapshot bigint NOT NULL CHECK (price_snapshot >= 0),
    entitlement_snapshot jsonb NOT NULL CHECK (jsonb_typeof(entitlement_snapshot) = 'object'),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (expires_at > starts_at),
    UNIQUE (id, organization_id),
    UNIQUE (id, organization_id, plan_id)
);
CREATE UNIQUE INDEX uq_active_subscription_org ON subscriptions (organization_id) WHERE status = 'ACTIVE';
CREATE INDEX ix_subscriptions_org_created ON subscriptions (organization_id, created_at DESC);
CREATE INDEX ix_subscriptions_expiry ON subscriptions (expires_at) WHERE status = 'ACTIVE';

CREATE TABLE quota_buckets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES organizations(id),
    subscription_id uuid,
    quota_type varchar(20) NOT NULL CHECK (quota_type IN ('TRIAL','SUBSCRIPTION')),
    scan_limit integer NOT NULL CHECK (scan_limit > 0),
    used_scans integer NOT NULL DEFAULT 0 CHECK (used_scans >= 0),
    reserved_scans integer NOT NULL DEFAULT 0 CHECK (reserved_scans >= 0),
    period_start timestamptz NOT NULL DEFAULT now(),
    period_end timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id, organization_id),
    FOREIGN KEY (subscription_id, organization_id) REFERENCES subscriptions(id, organization_id),
    CHECK (used_scans::bigint + reserved_scans::bigint <= scan_limit),
    CHECK (period_end IS NULL OR period_end > period_start),
    CHECK ((quota_type = 'TRIAL' AND subscription_id IS NULL AND scan_limit = 10 AND period_end IS NULL)
        OR (quota_type = 'SUBSCRIPTION' AND subscription_id IS NOT NULL AND period_end IS NOT NULL))
);
CREATE UNIQUE INDEX uq_lifetime_trial_org ON quota_buckets (organization_id) WHERE quota_type = 'TRIAL';
CREATE UNIQUE INDEX uq_subscription_quota_period ON quota_buckets (subscription_id, period_start) WHERE subscription_id IS NOT NULL;
CREATE INDEX ix_quota_org_period ON quota_buckets (organization_id, period_start DESC, period_end);

CREATE TABLE payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES organizations(id),
    plan_id uuid NOT NULL REFERENCES plans(id),
    subscription_id uuid,
    payer_firebase_uid varchar(128) NOT NULL CHECK (btrim(payer_firebase_uid) <> ''),
    order_id varchar(64) NOT NULL UNIQUE,
    gross_amount bigint NOT NULL CHECK (gross_amount > 0),
    currency varchar(3) NOT NULL DEFAULT 'IDR' CHECK (currency = 'IDR'),
    entitlement_snapshot jsonb NOT NULL CHECK (jsonb_typeof(entitlement_snapshot) = 'object'),
    payment_method varchar(30),
    payment_gateway varchar(30) NOT NULL DEFAULT 'MIDTRANS',
    gateway_environment varchar(20) NOT NULL DEFAULT 'SANDBOX' CHECK (gateway_environment IN ('SANDBOX','PRODUCTION')),
    gateway_transaction_id varchar(150),
    status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PAID','FAILED','EXPIRED','CANCELLED','REFUNDED','PARTIALLY_REFUNDED')),
    refunded_amount bigint NOT NULL DEFAULT 0 CHECK (refunded_amount >= 0 AND refunded_amount <= gross_amount),
    paid_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (subscription_id, organization_id, plan_id) REFERENCES subscriptions(id, organization_id, plan_id),
    CHECK (status NOT IN ('PAID','REFUNDED','PARTIALLY_REFUNDED') OR paid_at IS NOT NULL),
    CHECK (subscription_id IS NULL OR status IN ('PAID','REFUNDED','PARTIALLY_REFUNDED')),
    CHECK ((status = 'REFUNDED' AND refunded_amount = gross_amount)
        OR (status = 'PARTIALLY_REFUNDED' AND refunded_amount > 0 AND refunded_amount < gross_amount)
        OR (status NOT IN ('REFUNDED','PARTIALLY_REFUNDED') AND refunded_amount = 0))
);
CREATE UNIQUE INDEX uq_payment_gateway_transaction ON payments (payment_gateway, gateway_environment, gateway_transaction_id) WHERE gateway_transaction_id IS NOT NULL;
CREATE UNIQUE INDEX uq_payment_subscription_activation ON payments (subscription_id) WHERE subscription_id IS NOT NULL;
CREATE INDEX ix_payments_org_created ON payments (organization_id, created_at DESC);
CREATE INDEX ix_payments_paid_at ON payments (paid_at DESC) WHERE status IN ('PAID','REFUNDED','PARTIALLY_REFUNDED');

-- Revision 0003 (up)
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

-- Revision 0004 (up)
-- Provider attempt data. Unknown values remain NULL, never fabricated.
CREATE TABLE ai_usage_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id uuid NOT NULL REFERENCES scans(id),
    attempt_number integer NOT NULL CHECK (attempt_number > 0),
    gateway_request_id varchar(200),
    provider varchar(100),
    model varchar(150),
    input_tokens integer CHECK (input_tokens >= 0),
    output_tokens integer CHECK (output_tokens >= 0),
    estimated_cost numeric(18,8) CHECK (estimated_cost >= 0),
    currency varchar(3) CHECK (currency ~ '^[A-Z]{3}$'),
    cost_source varchar(30) CHECK (cost_source IN ('PROVIDER_REPORTED','ESTIMATED')),
    latency_ms integer CHECK (latency_ms >= 0),
    status varchar(20) NOT NULL CHECK (status IN ('SUCCESS','FAILED','TIMEOUT','UNKNOWN')),
    error_code varchar(50),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (scan_id, attempt_number),
    CHECK ((estimated_cost IS NULL AND currency IS NULL AND cost_source IS NULL)
        OR (estimated_cost IS NOT NULL AND currency IS NOT NULL AND cost_source IS NOT NULL))
);
CREATE INDEX ix_ai_usage_provider_date ON ai_usage_logs (provider, created_at DESC);
CREATE INDEX ix_ai_usage_date ON ai_usage_logs (created_at DESC);
CREATE INDEX ix_ai_usage_gateway_request ON ai_usage_logs (gateway_request_id) WHERE gateway_request_id IS NOT NULL;

COMMIT;
