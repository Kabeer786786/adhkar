# Supabase Edge Functions Deployment & Configuration

## 1. Set Razorpay & Supabase Secrets

The error `BAD_REQUEST_ERROR: Authentication failed` occurs when `RAZORPAY_KEY_ID` or `RAZORPAY_KEY_SECRET` is missing, mismatched, expired, or has whitespace in Supabase Secrets.

Run this command to update your secrets:

```bash
npx supabase secrets set RAZORPAY_KEY_ID=your_key_id RAZORPAY_KEY_SECRET=your_key_secret RAZORPAY_WEBHOOK_SECRET=your_webhook_secret SERVICE_ROLE_KEY_SUPABASE=your_supabase_service_role_key
```

> **Note:**
> - If testing in Test Mode, make sure `RAZORPAY_KEY_ID` starts with `rzp_test_...` and is paired with your **Test Secret**.
> - If in Live Mode, make sure `RAZORPAY_KEY_ID` starts with `rzp_live_...` and is paired with your **Live Secret**.
> - Do not include surrounding quotes or spaces when setting secrets.

---

## 2. Deploy Edge Functions

Deploy the updated functions:

```bash
npx supabase functions deploy create-order
npx supabase functions deploy verify-payment
npx supabase functions deploy razorpay-webhook
npx supabase functions deploy register-user
```