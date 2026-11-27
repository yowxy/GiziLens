-- ============================================================================
-- GiziLens — one-time database bootstrap (run as a PostgreSQL superuser)
-- ============================================================================
-- Usage (PowerShell / bash):
--   psql -U postgres -h localhost -v gizilens_password="ganti-password-ini" \
--        -f scripts/setup_database.sql
--
-- Creates:
--   role     : gizilens
--   database : gizilens (owner gizilens)
-- Safe to re-run.
-- ============================================================================

\set ON_ERROR_STOP on

-- 1. Role
SELECT format('CREATE ROLE gizilens LOGIN PASSWORD %L', :'gizilens_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gizilens')
\gexec

-- 2. Database
SELECT 'CREATE DATABASE gizilens OWNER gizilens'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'gizilens')
\gexec

-- 3. Privileges on the public schema (PostgreSQL 15+)
\connect gizilens
GRANT ALL ON SCHEMA public TO gizilens;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO gizilens;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO gizilens;

\echo 'Database gizilens siap. Lanjutkan dengan: python scripts/init_db.py'
