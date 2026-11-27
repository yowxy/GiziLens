-- Single active Premium subscription plan for GiziLens SPPG.
-- Harga resmi: Rp299.000/bulan (belum termasuk PPN 11%) dengan kuota 500 scan.
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
 '500 scan ompreng AI per bulan, ekspor laporan PDF resmi, dan sinkronisasi SPPG Cloud',
 299000,
 'MONTHLY',
 'MONTHLY',
 500,
 NULL,
 365,
 '["Kuota 500 scan ompreng AI per bulan", "Ekspor PDF resmi (Watermark + SHA-256) & XLSX", "Multi-demografis AKG (SD, SMP, SMA)", "Notifikasi defisit porsi >15%", "Riwayat audit 12 bulan", "Prioritas dukungan teknis BGN"]'::jsonb,
 true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  billing_cycle = EXCLUDED.billing_cycle,
  quota_cycle = EXCLUDED.quota_cycle,
  scan_quota = EXCLUDED.scan_quota,
  max_members = EXCLUDED.max_members,
  history_retention_days = EXCLUDED.history_retention_days,
  features = EXCLUDED.features,
  is_active = true,
  updated_at = NOW();
COMMIT;
