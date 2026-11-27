NOVA TOPUP — FINAL Google OAuth + Performance Build

This build keeps the existing Supabase project and storefront. Google OAuth is implemented with Supabase Auth using signInWithOAuth(provider:'google'), persistent sessions, URL detection, and production redirect handling.

Important: enabling Google OAuth cannot be completed from frontend code alone. Follow GOOGLE_LOGIN_SETUP.md and configure Google in Supabase + Google Cloud.

Supabase project URL:
https://nndrzwfidsoaqnjbstji.supabase.co

Files:
- index.html — storefront + real Supabase Auth Google/Email login
- sw.js — PWA cache
- manifest.webmanifest — PWA manifest
- assets/bkash-logo.webp — supplied payment logo
- assets/nagad-logo.webp — supplied payment logo
- GOOGLE_LOGIN_SETUP.md — exact Google OAuth activation steps

Do not expose a Google Client Secret in frontend code.
