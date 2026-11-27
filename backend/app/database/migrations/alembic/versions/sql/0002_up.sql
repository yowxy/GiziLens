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
