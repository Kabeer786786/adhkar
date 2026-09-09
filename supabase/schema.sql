-- ========================================================
-- SUPABASE DATABASE SCHEMA: PROFILES & DONATIONS (RAZORPAY)
-- ========================================================
-- This schema supports friction-free, passwordless user profile
-- registration via Supabase Edge Function without requiring auth.users or email OTP.
-- The Razorpay donations workflow remains fully intact.

-- 1. Create PROFILES Table (Independent of auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for profile email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);


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
-- Allow public select for profiles
CREATE POLICY "Allow public read access to profiles"
  ON public.profiles
  FOR SELECT
  USING (true);

-- Allow public insert to profiles (used by Edge Functions and client fallback)
CREATE POLICY "Allow public insert to profiles"
  ON public.profiles
  FOR INSERT
  WITH CHECK (true);

-- Allow updating profile details
CREATE POLICY "Allow public update to profiles"
  ON public.profiles
  FOR UPDATE
  USING (true)
  WITH CHECK (true);


-- Donations Security Policies:
-- Allow viewing donations
CREATE POLICY "Allow public read access to donations"
  ON public.donations
  FOR SELECT
  USING (true);

-- Note: Inserting and updating donations is executed by Razorpay Edge Functions
-- (create-order, verify-payment, razorpay-webhook) running with SUPABASE_SERVICE_ROLE_KEY,
-- which bypasses RLS safely and guarantees payment integrity.

CREATE TABLE IF NOT EXISTS public.keep_alive (
    id INTEGER PRIMARY KEY,
    last_ping TIMESTAMP WITH TIME ZONE
        DEFAULT timezone('utc'::text, now())
);

INSERT INTO public.keep_alive (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.keep_alive ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow keep alive read"
ON public.keep_alive
FOR SELECT
TO anon
USING (true);