NOVA TOPUP — VISUAL & GOOGLE LOGIN UPDATE

WHAT CHANGED
- Banner corner radius reduced to a clean, professional 8px treatment.
- “Regular Game Topup” heading is now styled as a stronger, premium storefront section heading.
- Floating Install App button has been restyled to match the dark navy/blue/purple diamond theme. It remains compact at the lower-right corner; its URL is controlled from Admin > Branding.
- When a customer opens a category, the banner and slider dots are hidden, leaving the site header/logo and the selected top-up flow. Footer and header Login action are hidden in this focused category/order view. Back to Categories restores the home view.
- Horizontal logo sizing and image display are refined for desktop and mobile.
- Customer Login now includes a real Supabase Google OAuth button, with Email/Password kept as fallback.
- Service worker cache version bumped so browsers can receive the new files.

GOOGLE SIGN-IN SETUP (REQUIRED BEFORE IT CAN WORK)
1. Open Supabase Dashboard > Authentication > Sign In / Providers > Google and enable Google.
2. Open Google Cloud Console: https://console.cloud.google.com/ and select/create a project.
3. Configure OAuth consent screen / Google Auth Platform branding and audience as required by Google.
4. Create an OAuth Client ID of type Web application.
5. Add your deployed Netlify site origin (for example https://YOUR-SITE.netlify.app) under Authorized JavaScript origins.
6. In Authorized redirect URIs, add this exact Supabase callback:
   https://nndrzwfidsoaqnjbstji.supabase.co/auth/v1/callback
7. Copy the Google Client ID and Client Secret into Supabase > Authentication > Sign In / Providers > Google, then Save.
8. In Supabase > Authentication > URL Configuration, set Site URL to your deployed Netlify URL and add that same URL to Redirect URLs. If you use a custom domain, add it too.
9. Deploy the updated site and test Login > Continue with Google.

Google OAuth is not ready until the Client ID/Secret and Supabase redirect settings are configured. Google OAuth is for customer login; it does not automatically grant Admin privileges. Admin access must continue to be granted only through the existing user_roles admin permission.

DEPLOY TO NETLIFY
- Upload index.html, sw.js, manifest.webmanifest and the complete assets folder together.
- Preserve existing assets such as category images, bKash/Nagad logos and other site images. This package may not contain all your original images.
- Keep the Supabase Storage bucket topup-assets and its existing public-read/upload policies.
- After deploy, hard refresh once (Ctrl+Shift+R). The Service Worker cache was versioned to v3.

NOTES
- Category view intentionally hides the banner, slider dots, footer and Login action until Back to Categories is selected.
- Existing product cards, payment form, package ordering and database tables were not intentionally redesigned.
- The browser must be online for first-time OAuth and fresh Supabase data. Actual Google login must be tested after provider setup.

PAYMENT LOGOS RESTORED
- Added local assets/bkash-logo.svg and assets/nagad-logo.svg.
- Updated the payment method image references to these local files so the bKash/Nagad marks do not depend on missing JPG files or an external image host.
- Keep the complete assets/ folder when deploying to Netlify.
- These are clean text/vector-style payment identifiers for UI display; use provider-approved official brand artwork if your merchant agreement requires exact official logo files.
