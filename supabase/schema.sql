-- Run this once in the Supabase SQL editor, BEFORE rpc.sql / rpc_admin.sql / rpc_provider.sql.
-- Nothing in this project will work without these tables.

create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  phone text,
  full_name text,
  role text not null default 'customer' check (role in ('customer','provider','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  image_url text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null default '',
  governorate text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.service_locations (
  service_id uuid not null references public.services(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  primary key (service_id, location_id)
);

create table if not exists public.provider_assignments (
  id bigint generated always as identity primary key,
  service_id uuid not null references public.services(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  provider_id uuid not null references public.users(id) on delete cascade,
  booking_mode text not null default 'pending' check (booking_mode in ('instant','pending'))
);

create table if not exists public.slots (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity int not null default 1,
  enabled boolean not null default true
);
create index if not exists idx_slots_lookup on public.slots (service_id, location_id, starts_at);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id) on delete cascade,
  service_id uuid not null references public.services(id),
  location_id uuid not null references public.locations(id),
  slot_id uuid not null references public.slots(id),
  provider_id uuid references public.users(id),
  status text not null default 'pending' check (status in ('pending','confirmed','cancelled')),
  booking_mode text not null default 'pending',
  confirmed_at timestamptz,
  expires_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by uuid references public.users(id),
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_bookings_customer on public.bookings (customer_id);
create index if not exists idx_bookings_provider on public.bookings (provider_id);
create index if not exists idx_bookings_slot on public.bookings (slot_id);

-- Used by every admin_*/provider_* RPC to check the caller's role.
-- security definer + owned by the table owner, so it can read public.users
-- even though users can normally only read their own row.
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.users where id = auth.uid();
$$;

revoke all on function public.current_role() from public;
grant execute on function public.current_role() to authenticated;

alter table public.users enable row level security;
alter table public.services enable row level security;
alter table public.locations enable row level security;
alter table public.service_locations enable row level security;
alter table public.slots enable row level security;
alter table public.bookings enable row level security;
alter table public.provider_assignments enable row level security;

create policy "users read own row" on public.users for select using (auth.uid() = id);
create policy "users update own row" on public.users for update using (auth.uid() = id);
create policy "users insert own row" on public.users for insert with check (auth.uid() = id);

create policy "services public read" on public.services for select using (true);
create policy "locations public read" on public.locations for select using (true);
create policy "service_locations public read" on public.service_locations for select using (true);
create policy "slots public read" on public.slots for select using (true);

create policy "bookings read own" on public.bookings for select using (auth.uid() = customer_id);
-- All inserts/updates to services, locations, slots, provider_assignments and
-- bookings go only through the security-definer RPCs in rpc.sql,
-- rpc_admin.sql and rpc_provider.sql, so no write policies are needed here.

-- IMPORTANT — bootstrapping the first admin:
-- There is no admin yet to promote your first admin from inside the app.
-- After that person signs in once (so their row exists in public.users),
-- run supabase/seed_admin.sql once by hand in the Supabase SQL editor.
