# GiziLens — PostgreSQL migrations v1

Schema for the FastAPI backend, Flutter history and React admin dashboard. Firebase Auth and Firestore `users/{uid}` remain the identity/profile source. PostgreSQL stores operational data only. Minimum PostgreSQL 14 (uses built-in `gen_random_uuid()`). Run with a migration role in an empty GiziLens database or staging first. No existing application files, database or Firebase data have been modified by this package.

## Contents

| Revision | Tables |
| --- | --- |
| 0001 | organizations, organization_members, sppg_school_links, batches, akg_targets |
| 0002 | plans, subscriptions, quota_buckets, payments |
| 0003 | scans, scan_images, inspections, inspection_items |
| 0004 | ai_usage_logs |

`alembic/versions/sql/` holds the canonical SQL for each revision (up/down). `sql/001_initial_schema.sql` and `sql/001_rollback_schema.sql` are combined versions for direct SQL execution. `sql/002_smoke_test.sql` is a rollback-only test of selected constraints. `seeds/` contains optional inactive drafts.

## A. Recommended: Alembic (FastAPI)

1. Copy `alembic/`, `alembic.ini`, and `requirements-migrations.txt` into `GiziLens/backend/`. If the backend already has Alembic, merge the revision chain instead of overwriting its existing configuration. Keep the `versions/sql/` folder with the revisions.
2. Install `pip install -r requirements-migrations.txt` in your Python environment. Add these dependencies to the backend Docker build when implementing the integration. Make sure the Dockerfile copies `alembic/` and `alembic.ini` if running migrations in a container.
3. Add `DATABASE_URL` to the existing backend `.env` (see `.env.migrations.example`). **Do not replace your `.env` or commit secrets.** Example for a database on the same private Docker network:
   ```env
   DATABASE_URL=postgresql+asyncpg://gizilens:YOUR_PASSWORD@postgres:5432/gizilens
   ```
   Replace the hostname with the actual database host; configure TLS as required by a remote database. URL-encode reserved characters in credentials. This package does not install PostgreSQL or provision a database.
4. From the backend directory:
   ```bash
   alembic upgrade head --sql > migration_preview.sql
   alembic upgrade head
   alembic current
   ```
   Expected current revision: `0004 (head)`. Offline generation can run without a live database. `alembic downgrade -1` removes only the latest revision; `alembic downgrade base` destroys all 14 tables and their contents. Back up and review before any downgrade.

`env.py` intentionally uses `target_metadata=None`: this is a hand-written initial schema, not an ORM model package. Wire SQLAlchemy model metadata later for autogeneration.

## B. Alternative: SQL directly (psql / pgAdmin / database SQL editor)

Choose A **or** B, not both. Direct SQL execution does not create the Alembic revision ledger. If switching to Alembic later, compare the schema first and only then stamp the correct revision.

```bash
# psql needs a normal postgresql:// URL, not postgresql+asyncpg://.
psql "$PG_DSN" -v ON_ERROR_STOP=1 -f sql/001_initial_schema.sql
psql "$PG_DSN" -v ON_ERROR_STOP=1 -f sql/002_smoke_test.sql
```

Alternatively paste the initial schema into a SQL editor connected to the target database. It is transactional but intentionally not rerunnable; duplicate tables should fail rather than mask schema drift. Rollback is destructive:

```bash
psql "$PG_DSN" -v ON_ERROR_STOP=1 -f sql/001_rollback_schema.sql
```

For a DB on the existing 2 GB VPS, avoid exposing TCP 5432 to the internet; use a private Docker network and monitor memory. Managed PostgreSQL is also compatible.

## Optional seeds

```bash
psql "$PG_DSN" -v ON_ERROR_STOP=1 -f seeds/001_draft_plans.sql
psql "$PG_DSN" -v ON_ERROR_STOP=1 -f seeds/002_draft_akg_targets.sql
```

- Pricing draft is taken from Flutter: Rp99,000 monthly, Rp249,000 quarterly, Rp699,000 annually. Quotas and unconfirmed member caps are NULL; **NULL is not unlimited**. All plans remain inactive until terms are approved. Monthly quota reset is the proposed default independent of billing interval. The ten-scan trial is modeled as a separate lifetime bucket, not a paid plan.
- Four lunch AKG presets are taken from `target_akg_model.dart`. They are inactive and labeled unverified; obtain nutrition-policy approval before activation. Do not derive compliance rules from the inconsistent 85% vs 90–110% thresholds in the current client.
- Seeds are rerunnable and never overwrite existing entries. No test users, payments, fake scan history or live subscriptions are seeded.

## Integration contract (important)

1. **Identity**: verify Firebase ID token with Firebase Admin SDK in FastAPI; derive `uid` from the token. Never accept client UID as ownership. The `scans` composite FK ensures a historical organization membership exists; check that membership and organization are currently active/verified on each request. Firebase Admin SDK should read trusted global role/verification; protect these fields from client writes in Firestore rules. Do not store passwords, ID tokens or profile copies in PostgreSQL. An optional limited `verifier_snapshot` preserves audit display context, not authentication.
2. **Organizations**: SPPG and school official codes are unique per type (case-insensitive); verified institutions require a code. The service must verify the institution and prevent duplicate individual organizations/abuse. It must enforce SPPG/SCHOOL types and valid links, restrict batch access to the assigned SPPG or recipient school, and authorize independent auditors explicitly. MVP: one destination per batch, optionally none for internal checks; if many schools per batch are required, introduce a batch-destinations table. Membership records must be retained/suspended rather than deleted while referenced by historical scans.
3. **Quota**: in one short transaction, lock the organization/bucket, ensure plan/period/permissions are valid, reserve with a conditional update and insert `scans` with a unique client idempotency key. Commit before calling AI. On successful validated inference, atomically consume the reservation and persist the response; on failure, release it. Guard transitions by `quota_status='RESERVED'` so retries cannot double-charge; use row locks and reconcile expired reservations (`reservation_expires_at`). Do not hold SQL transactions during AI calls or storage upload. Trial is one bucket per organization, limit 10, no reset. Decide whether valid no-food detections consume quota; default proposal: valid analysis consumes, transport/provider failures release. Bucket period overlap and counter-to-scan consistency require transactional service logic.
4. **Audit**: save raw inference and normalized target snapshot; do not overwrite raw AI output when the operator corrects items. Finalize one successful scan per inspection, validate items, recompute totals and policy on the server, and persist inspection + items in one transaction. Backend must forbid modifications/deletions of locked audits via normal endpoints; this schema does not include a DB immutability trigger or audit-revision workflow. Confidence stored as 0–1, convert Flutter percentage accordingly. `bounding_box` uses normalized `{x,y,width,height}` object; validate coordinates in the service. Map SQL status `TIDAK_SESUAI` to the Flutter UI label `TIDAK SESUAI`. Store timestamps as `timestamptz`; convert to Asia/Jakarta on display.
5. **Photos**: private Firebase Storage/R2/S3 bucket. Store `storage_backend`, `bucket`, `object_key` and metadata only. Return short-lived signed URL after access authorization; never store the signed URL as canonical data. For correct bounding boxes, retain the exact oriented image used for inference as `ORIGINAL`. If retaining an additional unmodified camera original later, extend `image_type` and store the coordinate transform. Implement storage cleanup/reconciliation on failed scans and apply approved retention; set `deleted_at` when object removal succeeds. No storage SDK or bucket is created by the SQL.
6. **Payments**: compute price server-side, store terms at checkout (`payments.entitlement_snapshot`), verify Midtrans notification and server-side transaction status/amount, and idempotently activate one subscription per paid order. Sandbox payments must never grant real production access or count toward real revenue. Update expired subscriptions before activation; only one active term per organization. Each renewal is a new term. Server must enforce seat limits, non-overlapping periods and entitlement snapshots. Never trust a Flutter success callback. `updated_at` fields must be maintained by the application.
7. **AI costs**: capture actual provider/model/attempt IDs when exposed by 9Router. Unknown values stay NULL; `estimated_cost` is not a guarantee of billed cost. `currency` and `cost_source` are required when a cost is supplied. Do not infer actual provider from combo name. Avoid logging image Base64, prompts containing personal data, or credentials.
8. **Legacy history**: `origin='LEGACY_FIRESTORE'` + unique `legacy_firestore_id` permits idempotent migration of existing Firestore inspections without consuming trial or premium quota. Establish verified UID membership, batch and AKG target mapping first; preserve original timestamps, do not fabricate raw inference/photos/usage. No automatic Firestore import is included. After reconciliation, switch mobile history/dashboard to FastAPI and stop dual writes. Firestore users remain unchanged.

## Validation performed

Alembic revision chain and offline SQL generation for upgrade and downgrade were checked. This environment has no running PostgreSQL instance, so the schema and smoke test have **not** been executed against a real database. Execute in staging first. Backend ORM, API routes, Firebase rules, storage integration and payment verification are subsequent implementation work; creating the tables alone does not enforce all business/security policies.
