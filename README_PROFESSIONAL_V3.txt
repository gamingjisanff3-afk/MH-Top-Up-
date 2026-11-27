NOVA TOPUP — Professional V3

Includes:
- Dynamic website branding in customer login/auth UI
- Google OAuth + email/password customer login
- Persistent customer_profiles table sync (Supabase)
- Professional customer account/profile with Google avatar/name
- Full My Orders page with summary and empty state
- Live order status display and pending cancellation
- Professional bKash/Nagad provider selection styling
- Slower, clearer notice ticker
- Existing storefront/banner/category/payment asset paths preserved

Deployment:
1. Keep index.html, sw.js, manifest.webmanifest and the existing assets/ folder together.
2. Run supabase_professional_update.sql once in Supabase SQL Editor.
3. Enable Google provider in Supabase Auth and configure the production Site URL + Redirect URL.
4. Never put a Google client secret in frontend code/GitHub.
