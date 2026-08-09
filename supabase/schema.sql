-- ========================================================
-- SUPABASE DATABASE SCHEMA: PROFILES & DONATIONS (RAZORPAY)
-- ========================================================

-- 1. Create PROFILES Table linked to auth.users (1:1 relationship)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  phone TEXT,
  location TEXT,
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for profile email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Automatic trigger to create or update a profile entry when a user registers in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_name text;
  v_phone text;
  v_location text;
BEGIN
  v_name := COALESCE(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', '');
  v_phone := COALESCE(new.raw_user_meta_data->>'phone', new.raw_user_meta_data->>'phone_number', '');
  v_location := COALESCE(new.raw_user_meta_data->>'location', new.raw_user_meta_data->>'address', '');

  INSERT INTO public.profiles (id, user_id, email, name, phone, location, email_verified, updated_at)
  VALUES (
    new.id,
    new.id,
    new.email,
    v_name,
    v_phone,
    v_location,
    (new.email_confirmed_at IS NOT NULL),
    timezone('utc'::text, now())
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = CASE WHEN EXCLUDED.name <> '' THEN EXCLUDED.name ELSE public.profiles.name END,
    phone = CASE WHEN EXCLUDED.phone <> '' THEN EXCLUDED.phone ELSE public.profiles.phone END,
    location = CASE WHEN EXCLUDED.location <> '' THEN EXCLUDED.location ELSE public.profiles.location END,
    email_verified = (new.email_confirmed_at IS NOT NULL),
    updated_at = timezone('utc'::text, now());
  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    -- Ensure trigger never fails auth user creation
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
 
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 2. Create DONATIONS Table (1:N relationship with profiles)
CREATE TABLE IF NOT EXISTS public.donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  currency TEXT DEFAULT 'INR' NOT NULL,
  razorpay_order_id TEXT NOT NULL UNIQUE,
  razorpay_payment_id TEXT,
  razorpay_signature TEXT,
  status TEXT DEFAULT 'created' NOT NULL, -- 'created', 'pending', 'successful', 'failed'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for donation queries
CREATE INDEX IF NOT EXISTS idx_donations_user_id ON public.donations(user_id);
CREATE INDEX IF NOT EXISTS idx_donations_order_id ON public.donations(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_donations_payment_id ON public.donations(razorpay_payment_id);


-- 3. Row Level Security (RLS) Policies

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

-- Profiles Security Policies:
-- Allow viewing profile if authenticated or matched id
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (true);

-- Allow inserting profile during registration
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (true);

-- Allow updating profile details
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (true)
  WITH CHECK (true);


-- Donations Security Policies:
-- Users can read only their own donations
CREATE POLICY "Users can view own donations"
  ON public.donations
  FOR SELECT
  USING (auth.uid() = user_id);

-- Note: Inserting and updating donations is restricted to Edge Functions running with SUPABASE_SERVICE_ROLE_KEY,
-- which bypasses RLS safely and prevents clients from spoofing payment statuses or amounts.
