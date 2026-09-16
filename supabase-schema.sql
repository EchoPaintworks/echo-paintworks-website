-- ============================================================
-- Echo Paintworks — Supabase schema
-- Run this once in Supabase: SQL Editor > New query > paste > Run
-- ============================================================

-- Profiles table: one row per user, created automatically on signup
create table public.profiles (
  id uuid references auth.users(id) primary key,
  full_name text,
  email text,
  phone text,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz default now()
);

-- Projects table: one row per job/project
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) not null,
  title text default 'Painting Project',
  status text not null default 'requested' check (
    status in ('requested','quoted','scheduled','in_progress','complete','paid')
  ),
  amount_cents integer,
  stripe_checkout_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Messages table: two-way conversation log per customer
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) not null,
  sender text not null check (sender in ('customer','admin')),
  body text not null,
  channel text not null default 'dashboard' check (channel in ('sms','dashboard')),
  twilio_sid text,
  created_at timestamptz default now()
);

-- ============================================================
-- Row Level Security: customers see only their own data,
-- admins (you) see everything.
-- ============================================================

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.messages enable row level security;

create or replace function public.is_admin() returns boolean as $$
  select exists(
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

-- Profiles policies
create policy "view own or admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "update own or admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin());
create policy "insert own profile" on public.profiles
  for insert with check (id = auth.uid());

-- Projects policies
create policy "customer views own projects" on public.projects
  for select using (customer_id = auth.uid() or public.is_admin());
create policy "admin manages all projects" on public.projects
  for all using (public.is_admin());

-- Messages policies
create policy "view own thread or admin" on public.messages
  for select using (customer_id = auth.uid() or public.is_admin());
create policy "send own message or admin" on public.messages
  for insert with check (customer_id = auth.uid() or public.is_admin());

-- ============================================================
-- Auto-create a profile row whenever someone signs up
-- ============================================================
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, phone, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    'customer'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- IMPORTANT — after running this once:
-- 1. Sign up on your own site as your first user (this creates your profile).
-- 2. Come back here and run this ONE line (replace with your real email):
--
--    update public.profiles set role = 'admin' where email = 'you@echopaintworks.com';
--
-- That makes YOUR account the admin account that sees everything.
-- ============================================================
