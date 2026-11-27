-- Optional: existing Flutter prices, not approved for production.
-- Quotas are intentionally NULL (unset, NOT unlimited).
-- All rows stay inactive until quota, member limit and retention are approved.
BEGIN;
INSERT INTO plans (code, name, description, price, billing_cycle, quota_cycle,
                   scan_quota, max_members, history_retention_days, features, is_active)
VALUES
('plan_starter','Paket Mandiri','Draft dari pricing Flutter',99000,'MONTHLY','MONTHLY',
 NULL,1,30,'["Ekspor PDF"]'::jsonb,false),
('plan_pro','Paket SPPG Pro','Draft dari pricing Flutter',249000,'QUARTERLY','MONTHLY',
 NULL,NULL,365,'["Ekspor PDF dan XLSX","Notifikasi"]'::jsonb,false),
('plan_enterprise','Paket Sentral MBG','Draft dari pricing Flutter',699000,'ANNUAL','MONTHLY',
 NULL,5,365,'["Multi akun","Ekspor PDF dan XLSX"]'::jsonb,false)
ON CONFLICT (code) DO NOTHING;
COMMIT;
