-- ====================================================================
-- HISAB AUTHENTICATION AUTOMATION MIGRATION
-- --------------------------------------------------------------------
-- Creates a profile row for every new auth user, keeps the profile in
-- sync with the identity provider used at sign-up, and backfills the
-- rows for users that already existed before this migration.
-- ====================================================================

-- 1. Extra profile columns for authentication metadata
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS email TEXT,
    ADD COLUMN IF NOT EXISTS auth_provider TEXT NOT NULL DEFAULT 'email',
    ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;

-- 2. Helper: create or refresh the profile of an auth user.
--    SECURITY DEFINER lets the trigger write to public.profiles while
--    RLS is enabled. The search_path is pinned to avoid search_path attacks.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        display_name,
        avatar_url,
        email,
        auth_provider,
        email_verified
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.raw_user_meta_data ->> 'name',
            split_part(COALESCE(NEW.email, ''), '@', 1)
        ),
        NEW.raw_user_meta_data ->> 'avatar_url',
        NEW.email,
        COALESCE(
            NULLIF(NEW.raw_app_meta_data ->> 'provider', ''),
            'email'
        ),
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false)
    )
    ON CONFLICT (id) DO UPDATE
    SET display_name = EXCLUDED.display_name,
        avatar_url = EXCLUDED.avatar_url,
        email = EXCLUDED.email,
        auth_provider = EXCLUDED.auth_provider,
        email_verified = EXCLUDED.email_verified,
        updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 3. Trigger: run the helper whenever a user is created.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Trigger: keep the profile in sync when the email is confirmed or the
--    user metadata changes (for example a Google avatar refresh).
CREATE OR REPLACE FUNCTION public.handle_user_updated()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET email_verified = COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        email = COALESCE(NEW.email, email),
        avatar_url = COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', avatar_url),
        display_name = COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.raw_user_meta_data ->> 'name',
            display_name
        ),
        updated_at = now()
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
AFTER UPDATE ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_user_updated();

-- 5. Backfill: every existing auth user gets a profile row.
INSERT INTO public.profiles (
    id,
    display_name,
    avatar_url,
    email,
    auth_provider,
    email_verified
)
SELECT
    u.id,
    COALESCE(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        split_part(COALESCE(u.email, ''), '@', 1)
    ),
    u.raw_user_meta_data ->> 'avatar_url',
    u.email,
    COALESCE(NULLIF(u.raw_app_meta_data ->> 'provider', ''), 'email'),
    COALESCE(u.email_confirmed_at IS NOT NULL, false)
FROM auth.users u
ON CONFLICT (id) DO UPDATE
SET display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url,
    email = EXCLUDED.email,
    auth_provider = EXCLUDED.auth_provider,
    email_verified = EXCLUDED.email_verified,
    updated_at = now();

-- 6. Index for lookups by sign-in provider.
CREATE INDEX IF NOT EXISTS idx_profiles_auth_provider ON public.profiles(auth_provider);

-- 7. Grant the authenticated role the permissions it needs on the new columns.
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_user_updated() TO authenticated;
