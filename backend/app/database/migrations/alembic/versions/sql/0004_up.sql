-- Provider attempt data. Unknown values remain NULL, never fabricated.
CREATE TABLE ai_usage_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id uuid NOT NULL REFERENCES scans(id),
    attempt_number integer NOT NULL CHECK (attempt_number > 0),
    gateway_request_id varchar(200),
    provider varchar(100),
    model varchar(150),
    input_tokens integer CHECK (input_tokens >= 0),
    output_tokens integer CHECK (output_tokens >= 0),
    estimated_cost numeric(18,8) CHECK (estimated_cost >= 0),
    currency varchar(3) CHECK (currency ~ '^[A-Z]{3}$'),
    cost_source varchar(30) CHECK (cost_source IN ('PROVIDER_REPORTED','ESTIMATED')),
    latency_ms integer CHECK (latency_ms >= 0),
    status varchar(20) NOT NULL CHECK (status IN ('SUCCESS','FAILED','TIMEOUT','UNKNOWN')),
    error_code varchar(50),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (scan_id, attempt_number),
    CHECK ((estimated_cost IS NULL AND currency IS NULL AND cost_source IS NULL)
        OR (estimated_cost IS NOT NULL AND currency IS NOT NULL AND cost_source IS NOT NULL))
);
CREATE INDEX ix_ai_usage_provider_date ON ai_usage_logs (provider, created_at DESC);
CREATE INDEX ix_ai_usage_date ON ai_usage_logs (created_at DESC);
CREATE INDEX ix_ai_usage_gateway_request ON ai_usage_logs (gateway_request_id) WHERE gateway_request_id IS NOT NULL;
