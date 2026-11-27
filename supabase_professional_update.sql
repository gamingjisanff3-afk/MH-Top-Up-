-- NOVA TOPUP production database setup
-- Run the whole file in Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin')),
  created_at timestamptz not null default now()
);

-- Bootstrap the first administrator. The account must already exist in
-- Supabase Authentication > Users. Change the email if your admin uses another one.
insert into public.user_roles (user_id, role)
select id, 'admin'
from auth.users
where lower(email) = lower('mhmiraz443@gmail.com')
on conflict (user_id) do update set role = excluded.role;

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$ select exists (select 1 from public.user_roles r where r.user_id = auth.uid() and r.role = 'admin'); $$;

create table if not exists public.categories (
  id text primary key,
  name text not null,
  image_url text not null default '',
  description text not null default '',
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  category_id text not null references public.categories(id) on update cascade on delete cascade,
  name text not null,
  price_bdt numeric(12,2) not null check (price_bdt >= 0),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.banners (
  id text primary key,
  image_url text not null default '',
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_code text not null unique,
  user_id uuid not null references auth.users(id) on delete restrict,
  product_id text not null references public.products(id) on delete restrict,
  category_name text not null default '',
  package_name text not null,
  player_uid text not null check (player_uid ~ '^[0-9]{6,15}$'),
  payment_method text not null check (payment_method in ('bKash','Nagad')),
  payer_number text,
  transaction_id text not null,
  amount_bdt numeric(12,2) not null default 0,
  status text not null default 'Pending' check (status in ('Pending','Processing','Confirmed','Completed','Cancelled','Rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Never trust a price sent by the browser. Resolve current price/name from DB.
create or replace function public.set_order_from_catalog()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare p public.products%rowtype;
begin
  select * into p from public.products where id = new.product_id and active = true;
  if not found then raise exception 'Selected package is unavailable'; end if;
  new.package_name := p.name;
  new.amount_bdt := p.price_bdt;
  select c.name into new.category_name from public.categories c where c.id = p.category_id;
  new.status := 'Pending';
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists trg_set_order_from_catalog on public.orders;
create trigger trg_set_order_from_catalog before insert on public.orders
for each row execute function public.set_order_from_catalog();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at before update on public.orders
for each row execute function public.touch_updated_at();

-- Migration-safe status expansion for an existing production table.
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check check (status in ('Pending','Processing','Confirmed','Completed','Cancelled','Rejected'));


-- Customer profile: one persistent profile row per authenticated customer.
create table if not exists public.customer_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  avatar_url text not null default '',
  provider text not null default 'email',
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.customer_profiles enable row level security;
drop policy if exists "customer read own profile" on public.customer_profiles;
create policy "customer read own profile" on public.customer_profiles for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "customer insert own profile" on public.customer_profiles;
create policy "customer insert own profile" on public.customer_profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "customer update own profile" on public.customer_profiles;
create policy "customer update own profile" on public.customer_profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.user_roles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.banners enable row level security;
alter table public.site_settings enable row level security;
alter table public.orders enable row level security;

-- Public storefront reads only active catalogue/banner records.
drop policy if exists "public read active categories" on public.categories;
create policy "public read active categories" on public.categories for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admin manage categories" on public.categories;
create policy "admin manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admin manage products" on public.products;
create policy "admin manage products" on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public read active banners" on public.banners;
create policy "public read active banners" on public.banners for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admin manage banners" on public.banners;
create policy "admin manage banners" on public.banners for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public read site settings" on public.site_settings;
create policy "public read site settings" on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "admin manage site settings" on public.site_settings;
create policy "admin manage site settings" on public.site_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "user read own role" on public.user_roles;
create policy "user read own role" on public.user_roles for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "admin manage roles" on public.user_roles;
create policy "admin manage roles" on public.user_roles for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "customer create own orders" on public.orders;
create policy "customer create own orders" on public.orders for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "customer read own orders" on public.orders;
create policy "customer read own orders" on public.orders for select to authenticated using (user_id = auth.uid() or public.is_admin());
-- Customers may cancel only their own Pending orders. They cannot change any other status.
drop policy if exists "customer cancel own pending orders" on public.orders;
create policy "customer cancel own pending orders" on public.orders for update to authenticated
using (user_id = auth.uid() and status = 'Pending')
with check (user_id = auth.uid() and status = 'Cancelled');
drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Starter categories. Admin dashboard can subsequently add/edit/remove these.
insert into public.categories(id,name,image_url,description,active,sort_order) values
('uid','UID TOPUP (BD)','assets/category-2.webp','Bangladesh server direct top-up',true,1),
('weekly','WEEKLY / MONTHLY','assets/category-3.webp','Weekly and monthly membership',true,2),
('lite','WEEKLY LITE','assets/category-4.webp','Weekly Lite membership',true,3),
('level','LEVEL UP PASS','assets/category-5.webp','Level Up Pass',true,4),
('likes','FF LIKES','assets/category-1.webp','Daily likes package',true,5),
('indo','INDONESIA SERVER','assets/category-6.webp','Indonesia server packages',true,6)
on conflict (id) do nothing;

insert into public.products(id,category_id,name,price_bdt,active,sort_order) values
('1','uid','25 Diamonds',22,true,1),('2','uid','50 Diamonds',38,true,2),('3','uid','100 Diamonds',75,true,3),('4','uid','115 Diamonds',79,true,4),('5','uid','240 Diamonds',158,true,5),('6','uid','355 Diamonds',237,true,6),('7','uid','480 Diamonds',316,true,7),('8','uid','505 Diamonds',336,true,8),('9','uid','610 Diamonds',400,true,9),('10','uid','725 Diamonds',479,true,10),('11','uid','850 Diamonds',558,true,11),('12','uid','1090 Diamonds',716,true,12),('13','uid','1240 Diamonds',800,true,13),('14','uid','1480 Diamonds',958,true,14),('15','uid','1720 Diamonds',1116,true,15),('16','uid','1850 Diamonds',1200,true,16),('17','uid','2090 Diamonds',1358,true,17),('18','uid','2530 Diamonds',1610,true,18),
('19','weekly','Weekly Membership',158,true,1),('20','weekly','Monthly Membership',499,true,2),('21','lite','Weekly Lite',79,true,1),('22','level','Level Up Pass',237,true,1),('23','likes','200 Likes',20,true,1),('24','indo','Indonesia Diamond Pack',0,true,1)
on conflict (id) do nothing;

insert into public.site_settings(key,value) values
('brand','"NOVA TOPUP"'::jsonb),('logo_text','"NT"'::jsonb),('logo_data','""'::jsonb),('support','""'::jsonb),
('payments','{"bKash":"","Nagad":""}'::jsonb),('socials','{"Facebook":"","WhatsApp":"","Telegram":""}'::jsonb)
on conflict (key) do nothing;

-- IMPORTANT: create your admin account in Authentication > Users first.
-- Then replace YOUR_AUTH_USER_UUID and run this one statement in SQL Editor:
-- insert into public.user_roles(user_id, role) values ('YOUR_AUTH_USER_UUID', 'admin') on conflict (user_id) do update set role='admin';

-- Public image storage for category images, site logo and banners.
-- Run this section once in Supabase SQL Editor after the main setup.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('topup-assets', 'topup-assets', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "Public can view topup images" on storage.objects;
create policy "Public can view topup images" on storage.objects
for select using (bucket_id = 'topup-assets');

drop policy if exists "Admins can upload topup images" on storage.objects;
create policy "Admins can upload topup images" on storage.objects
for insert to authenticated with check (bucket_id = 'topup-assets' and public.is_admin());

drop policy if exists "Admins can update topup images" on storage.objects;
create policy "Admins can update topup images" on storage.objects
for update to authenticated using (bucket_id = 'topup-assets' and public.is_admin())
with check (bucket_id = 'topup-assets' and public.is_admin());

drop policy if exists "Admins can delete topup images" on storage.objects;
create policy "Admins can delete topup images" on storage.objects
for delete to authenticated using (bucket_id = 'topup-assets' and public.is_admin());
