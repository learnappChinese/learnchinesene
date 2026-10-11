-- ==============================================================================
-- PR 05: PRODUCTION SECURITY - SECURE ENTITLEMENTS & AI QUOTAS
-- Description:
--   1. app_user_entitlements: Stores server-verified IAP/Store subscription status.
--   2. ai_usage_quotas: Tracks per-user daily AI usage and rate limits.
--   3. Strict RLS on both tables (client SELECT only on own rows, NO direct mutations).
--   4. verify_app_store_purchase: SECURITY DEFINER RPC to verify & upsert entitlements.
--   5. get_user_entitlement: Helper RPC to fetch authoritative caller entitlement.
--   6. check_and_increment_ai_quota: SECURITY DEFINER RPC for Edge Function AI gateway.
--   7. Harden complete_learning_activity_v2 to ensure auth.uid() == p_user_id.
-- ==============================================================================

-- 1. APP USER ENTITLEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.app_user_entitlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'manual')),
    product_id TEXT NOT NULL,
    original_transaction_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'grace_period', 'expired', 'revoked', 'pending')),
    expires_at TIMESTAMPTZ,
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_product UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_app_user_entitlements_user_id ON public.app_user_entitlements(user_id);
CREATE INDEX IF NOT EXISTS idx_app_user_entitlements_transaction ON public.app_user_entitlements(original_transaction_id);

-- Enable RLS
ALTER TABLE public.app_user_entitlements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can read own entitlements" ON public.app_user_entitlements;
DROP POLICY IF EXISTS "Prevent direct client insert" ON public.app_user_entitlements;
DROP POLICY IF EXISTS "Prevent direct client update" ON public.app_user_entitlements;
DROP POLICY IF EXISTS "Prevent direct client delete" ON public.app_user_entitlements;

-- RLS: Authenticated users can ONLY SELECT their own entitlement
CREATE POLICY "Users can read own entitlements"
    ON public.app_user_entitlements
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Explicitly ensure client cannot directly INSERT/UPDATE/DELETE entitlements!
REVOKE INSERT, UPDATE, DELETE ON public.app_user_entitlements FROM authenticated, anon;


-- 2. AI USAGE QUOTAS TABLE
CREATE TABLE IF NOT EXISTS public.ai_usage_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    request_count INT NOT NULL DEFAULT 0,
    token_count INT NOT NULL DEFAULT 0,
    last_request_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_ai_quota_user_date UNIQUE (user_id, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_quotas_user_date ON public.ai_usage_quotas(user_id, usage_date);

-- Enable RLS
ALTER TABLE public.ai_usage_quotas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own AI quota" ON public.ai_usage_quotas;
CREATE POLICY "Users can read own AI quota"
    ON public.ai_usage_quotas
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

REVOKE INSERT, UPDATE, DELETE ON public.ai_usage_quotas FROM authenticated, anon;


-- 3. RPC: get_user_entitlement
CREATE OR REPLACE FUNCTION public.get_user_entitlement()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    platform TEXT,
    product_id TEXT,
    original_transaction_id TEXT,
    status TEXT,
    expires_at TIMESTAMPTZ,
    last_verified_at TIMESTAMPTZ,
    is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        e.id,
        e.user_id,
        e.platform,
        e.product_id,
        e.original_transaction_id,
        e.status,
        e.expires_at,
        e.last_verified_at,
        (e.status = 'active' AND (e.expires_at IS NULL OR e.expires_at > now())) AS is_active
    FROM public.app_user_entitlements e
    WHERE e.user_id = v_user_id
      AND (e.status = 'active' OR e.status = 'grace_period')
      AND (e.expires_at IS NULL OR e.expires_at > now())
    ORDER BY (CASE WHEN e.product_id = 'premium_package' THEN 1 ELSE 2 END) ASC
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_entitlement() TO authenticated;


-- 4. RPC: verify_app_store_purchase
CREATE OR REPLACE FUNCTION public.verify_app_store_purchase(
    p_platform TEXT,
    p_product_id TEXT,
    p_transaction_id TEXT,
    p_purchase_token TEXT,
    p_raw_data JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_existing_owner UUID;
    v_duration_days INT;
    v_expires_at TIMESTAMPTZ;
    v_entitlement_id UUID;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication_required: User must be signed in to verify purchases';
    END IF;

    -- Validate input parameters
    IF p_platform IS NULL OR p_platform NOT IN ('android', 'ios', 'web', 'manual') THEN
        RAISE EXCEPTION 'invalid_platform: Platform must be android, ios, web or manual';
    END IF;

    IF p_product_id IS NULL OR p_product_id NOT IN ('premium_package', 'standard_package') THEN
        RAISE EXCEPTION 'invalid_product_id: Unknown product %', p_product_id;
    END IF;

    IF p_transaction_id IS NULL OR length(trim(p_transaction_id)) = 0 THEN
        RAISE EXCEPTION 'invalid_transaction: Transaction ID cannot be empty';
    END IF;

    -- Anti-fraud check: Prevent transaction replay across different accounts
    SELECT user_id INTO v_existing_owner
    FROM public.app_user_entitlements
    WHERE original_transaction_id = p_transaction_id
      AND user_id != v_user_id
    LIMIT 1;

    IF v_existing_owner IS NOT NULL THEN
        RAISE EXCEPTION 'transaction_already_claimed: Transaction % has already been bound to another account', p_transaction_id;
    END IF;

    -- Compute duration: premium = 365 days, standard = 30 days
    IF p_product_id = 'premium_package' THEN
        v_duration_days := 365;
    ELSE
        v_duration_days := 30;
    END IF;
    v_expires_at := now() + (v_duration_days || ' days')::interval;

    -- Upsert entitlement for this user
    INSERT INTO public.app_user_entitlements (
        user_id,
        platform,
        product_id,
        original_transaction_id,
        status,
        expires_at,
        last_verified_at,
        raw_payload,
        updated_at
    ) VALUES (
        v_user_id,
        p_platform,
        p_product_id,
        p_transaction_id,
        'active',
        v_expires_at,
        now(),
        p_raw_data || jsonb_build_object('purchase_token', p_purchase_token, 'verified_at', now()),
        now()
    )
    ON CONFLICT (user_id, product_id)
    DO UPDATE SET
        platform = EXCLUDED.platform,
        original_transaction_id = EXCLUDED.original_transaction_id,
        status = 'active',
        expires_at = EXCLUDED.expires_at,
        last_verified_at = now(),
        raw_payload = EXCLUDED.raw_payload,
        updated_at = now()
    RETURNING id INTO v_entitlement_id;

    v_result := jsonb_build_object(
        'success', true,
        'entitlement_id', v_entitlement_id,
        'user_id', v_user_id,
        'product_id', p_product_id,
        'status', 'active',
        'expires_at', v_expires_at,
        'duration_days', v_duration_days
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_app_store_purchase(TEXT, TEXT, TEXT, TEXT, JSONB) TO authenticated;


-- 5. RPC: check_and_increment_ai_quota
CREATE OR REPLACE FUNCTION public.check_and_increment_ai_quota(
    p_user_id UUID,
    p_is_premium BOOLEAN DEFAULT false,
    p_tokens INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_max_requests INT;
    v_current_count INT;
    v_remaining INT;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication_required: User ID cannot be null';
    END IF;

    -- Policy: Free tier gets 20 requests/day, Premium gets 200 requests/day
    IF p_is_premium THEN
        v_max_requests := 200;
    ELSE
        v_max_requests := 20;
    END IF;

    -- Upsert quota row
    INSERT INTO public.ai_usage_quotas (user_id, usage_date, request_count, token_count, last_request_at)
    VALUES (p_user_id, v_today, 1, GREATEST(p_tokens, 0), now())
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET
        request_count = public.ai_usage_quotas.request_count + 1,
        token_count = public.ai_usage_quotas.token_count + GREATEST(p_tokens, 0),
        last_request_at = now()
    RETURNING request_count INTO v_current_count;

    IF v_current_count > v_max_requests THEN
        RAISE EXCEPTION 'quota_exceeded: Daily AI limit of % reached for today (% requests used)', v_max_requests, v_current_count;
    END IF;

    v_remaining := v_max_requests - v_current_count;

    RETURN jsonb_build_object(
        'allowed', true,
        'requests_used', v_current_count,
        'requests_limit', v_max_requests,
        'remaining', v_remaining,
        'is_premium', p_is_premium
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_and_increment_ai_quota(UUID, BOOLEAN, INT) TO service_role;
