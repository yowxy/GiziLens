-- Run after schema creation in a test database. All fixture rows are rolled back.
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/002_smoke_test.sql
BEGIN;
DO $$
DECLARE
    org uuid;
    other_org uuid;
    batch uuid;
    target uuid;
    bucket uuid;
    scan uuid;
    audit uuid;
    suffix text := gen_random_uuid()::text;
    uid text := 'fixture-' || suffix;
BEGIN
    INSERT INTO organizations (name,type,registration_code,status)
        VALUES ('Fixture SPPG','SPPG','fixture-' || suffix,'VERIFIED') RETURNING id INTO org;
    INSERT INTO organizations (name,type,registration_code,status)
        VALUES ('Fixture School','SCHOOL','fixture-' || suffix,'VERIFIED') RETURNING id INTO other_org;
    INSERT INTO organization_members (organization_id,firebase_uid,membership_role,status)
        VALUES (org,uid,'OFFICER','ACTIVE'), (other_org,uid,'SCHOOL_PIC','ACTIVE');
    INSERT INTO sppg_school_links (sppg_id,school_id,status,started_at)
        VALUES (org,other_org,'ACTIVE',now());
    INSERT INTO batches (sppg_id,school_id,batch_code,production_date,created_by_uid)
        VALUES (org,other_org,'FIXTURE',current_date,uid) RETURNING id INTO batch;
    INSERT INTO akg_targets (group_code,group_name,standard_version,calories,protein,fat,carbohydrate,fiber)
        VALUES ('fixture-' || suffix,'Fixture target','TEST',600,20,20,80,8) RETURNING id INTO target;
    INSERT INTO quota_buckets (organization_id,quota_type,scan_limit)
        VALUES (org,'TRIAL',10) RETURNING id INTO bucket;

    BEGIN
        INSERT INTO quota_buckets (organization_id,quota_type,scan_limit) VALUES (org,'TRIAL',10);
        RAISE EXCEPTION 'Expected duplicate trial to be rejected';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    BEGIN
        UPDATE quota_buckets SET used_scans=11 WHERE id=bucket;
        RAISE EXCEPTION 'Expected quota overflow to be rejected';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO scans (organization_id,firebase_uid,batch_id,akg_target_id,quota_bucket_id,
                          idempotency_key,target_snapshot,reservation_expires_at)
        VALUES (other_org,uid,batch,target,bucket,'cross-tenant','{}'::jsonb,now()+interval '5 minutes');
        RAISE EXCEPTION 'Expected cross-tenant quota reference to be rejected';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;

    -- Same transaction: reserve quota and create scan.
    UPDATE quota_buckets SET reserved_scans=reserved_scans+1 WHERE id=bucket;
    INSERT INTO scans (organization_id,firebase_uid,batch_id,akg_target_id,quota_bucket_id,
                       idempotency_key,target_snapshot,reservation_expires_at)
    VALUES (org,uid,batch,target,bucket,'scan-1','{"calories":600}'::jsonb,now()+interval '5 minutes')
    RETURNING id INTO scan;
    BEGIN
        INSERT INTO scans (organization_id,firebase_uid,batch_id,akg_target_id,quota_bucket_id,
                          idempotency_key,target_snapshot,reservation_expires_at)
        VALUES (org,uid,batch,target,bucket,'scan-1','{}'::jsonb,now()+interval '5 minutes');
        RAISE EXCEPTION 'Expected duplicate scan to be rejected';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    -- Same transaction: consume reservation and persist response.
    UPDATE quota_buckets SET reserved_scans=reserved_scans-1,used_scans=used_scans+1 WHERE id=bucket;
    UPDATE scans SET status='SUCCESS',quota_status='CONSUMED',raw_result='{"items":[]}'::jsonb,
        completed_at=now(),processing_ms=100 WHERE id=scan;
    INSERT INTO scan_images (scan_id,storage_backend,bucket,object_key,image_type,mime_type,size_bytes,width,height)
    VALUES (scan,'R2','fixture',suffix || '/original.jpg','ORIGINAL','image/jpeg',1000,100,100);
    INSERT INTO inspections (scan_id,verified_by_uid,total_weight,total_calories,total_protein,total_fat,
        total_carbohydrate,total_fiber,compliance_status,policy_version)
    VALUES (scan,uid,100,130,3,1,28,1,'NOT_ASSESSED','TEST') RETURNING id INTO audit;
    INSERT INTO inspection_items (inspection_id,name,category,estimated_gram,confidence,calories,protein,fat,
        carbohydrate,fiber,is_verified)
    VALUES (audit,'Fixture item','Pokok',100,0.9,130,3,1,28,1,true);
    BEGIN
        INSERT INTO inspections (scan_id,verified_by_uid,total_weight,total_calories,total_protein,total_fat,
            total_carbohydrate,total_fiber,compliance_status,policy_version)
        VALUES (scan,uid,100,130,3,1,28,1,'NOT_ASSESSED','TEST');
        RAISE EXCEPTION 'Expected duplicate final inspection to be rejected';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    INSERT INTO ai_usage_logs (scan_id,attempt_number,model,status) VALUES (scan,1,'fixture','SUCCESS');
    RAISE NOTICE 'GiziLens smoke test passed; fixtures will be rolled back.';
END $$;
ROLLBACK;
