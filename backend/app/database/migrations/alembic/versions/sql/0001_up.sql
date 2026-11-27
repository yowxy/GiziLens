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
