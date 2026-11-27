-- Single active Premium subscription plan for GiziLens SPPG.
BEGIN;
UPDATE plans
SET is_active = false,
    updated_at = NOW()
WHERE code <> 'plan_premium';

INSERT INTO plans (code, name, description, price, billing_cycle, quota_cycle,
                   scan_quota, max_members, history_retention_days, features, is_active)
VALUES
('plan_premium',
 'GiziLens Premium',
 'Akses penuh audit gizi AI, ekspor laporan PDF resmi, dan sinkronisasi SPPG Cloud',
 99000,
 'MONTHLY',
 'MONTHLY',
 NULL,
 NULL,
 365,
 '["Scan Ompreng AI tanpa batas kuota", "Ekspor PDF resmi (Watermark + SHA-256) & XLSX", "Multi-demografis AKG (SD, SMP, SMA)", "Notifikasi defisit porsi >15%", "Prioritas dukungan teknis BGN"]'::jsonb,
 true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  billing_cycle = EXCLUDED.billing_cycle,
  features = EXCLUDED.features,
  is_active = true,
  updated_at = NOW();
COMMIT;
