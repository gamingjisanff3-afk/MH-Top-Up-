# NOVA TOPUP — Google Login Setup

The website already contains the real Supabase Google OAuth client flow. You only need to enable Google in Supabase and register your production URL in Google Cloud.

## 1. Supabase

Open your Supabase project:

https://supabase.com/dashboard/project/nndrzwfidsoaqnjbstji

Go to **Authentication → Sign In / Providers → Google** and enable Google.

Create a Google OAuth **Web application** client in Google Cloud and paste the Client ID and Client Secret into the Supabase Google provider settings.

## 2. Google Cloud

Open:

https://console.cloud.google.com/

Create/select a project → **Google Auth Platform** → **Clients** → create an **OAuth client ID** → Application type: **Web application**.

### Authorized JavaScript origins

Add your actual deployed website origin, for example:

`https://YOUR-SITE.netlify.app`

Use your real custom domain instead if you have one.

### Authorized redirect URI

Use exactly this Supabase callback URL:

`https://nndrzwfidsoaqnjbstji.supabase.co/auth/v1/callback`

Do not add a trailing slash unless Google/Supabase shows one.

## 3. Supabase URL Configuration

In Supabase go to **Authentication → URL Configuration**.

Set **Site URL** to your real deployed website URL, for example:

`https://YOUR-SITE.netlify.app`

Under **Redirect URLs**, add the same production URL. If you test locally, add your local URL too, but remove development URLs when you no longer need them.

The application sends the current site URL as `redirectTo`, so it must be present in Supabase's allowed Redirect URLs.

## 4. Test

1. Open the live NOVA TOPUP website.
2. Click **Login**.
3. Click **Continue with Google**.
4. Select a Google account.
5. Google returns to NOVA TOPUP.
6. The session is stored by Supabase Auth.
7. Refreshing the page should keep the user logged in.

## Important

The Google Client Secret belongs only in Supabase's provider settings. Never put the Google Client Secret inside `index.html`, GitHub, or a public frontend file.

The website's admin permission is separate from Google login. A normal Google user must not automatically become an admin; the existing `user_roles`/RLS security model remains responsible for admin access.
