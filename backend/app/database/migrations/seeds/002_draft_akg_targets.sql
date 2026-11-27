-- Optional: exact lunch values from Flutter target_akg_model.dart
-- (30% of daily AKG 2019; fiber at 14 g per 1000 kkal).
-- Not independently validated against the applicable AKG/BGN policy.
-- Inactive until a qualified reviewer approves version and thresholds.
BEGIN;
INSERT INTO akg_targets (group_code, group_name, standard_version, calories, protein, fat, carbohydrate, fiber, is_active)
VALUES
('SD_1_3','SD Kelas 1–3 (7–9 Tahun)','APP_PRESET_UNVERIFIED_2026_11',495.0,12.0,16.5,75.0,7.0,false),
('SD_4_6','SD Kelas 4–6 (10–12 Tahun)','APP_PRESET_UNVERIFIED_2026_11',585.0,15.0,19.5,87.0,8.0,false),
('SMP','SMP (13–15 Tahun)','APP_PRESET_UNVERIFIED_2026_11',669.0,20.25,22.5,97.5,9.0,false),
('SMA_SMK','SMA / SMK (16–18 Tahun)','APP_PRESET_UNVERIFIED_2026_11',780.0,22.5,25.5,117.0,11.0,false)
ON CONFLICT (group_code, standard_version) DO NOTHING;
COMMIT;
