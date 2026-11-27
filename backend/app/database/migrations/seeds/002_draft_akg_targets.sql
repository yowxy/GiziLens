-- Optional: exact lunch values from Flutter target_akg_model.dart.
-- Not independently validated against the applicable AKG/BGN policy.
-- Inactive until a qualified reviewer approves version and thresholds.
BEGIN;
INSERT INTO akg_targets (group_code, group_name, standard_version, calories, protein, fat, carbohydrate, fiber, is_active)
VALUES
('SD_1_3','SD Kelas 1–3 (7–9 Tahun)','APP_PRESET_UNVERIFIED_2026_11',536.25,13.0,17.875,81.25,7.475,false),
('SD_4_6','SD Kelas 4–6 (10–12 Tahun)','APP_PRESET_UNVERIFIED_2026_11',633.75,16.25,21.125,94.25,8.9375,false),
('SMP','SMP (13–15 Tahun)','APP_PRESET_UNVERIFIED_2026_11',724.375,21.9375,24.375,105.625,10.2375,false),
('SMA_SMK','SMA / SMK (16–18 Tahun)','APP_PRESET_UNVERIFIED_2026_11',845.0,24.375,27.625,126.75,11.8625,false)
ON CONFLICT (group_code, standard_version) DO NOTHING;
COMMIT;
