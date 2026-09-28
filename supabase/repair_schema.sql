-- Run this ONCE if you already had `services`/`locations`/`bookings` tables
-- from before schema.sql existed. `create table if not exists` does nothing
-- to a table that already exists, so an older table can be missing columns
-- the app now needs (this is exactly what caused the
-- "column services.enabled does not exist" error).
-- Safe to run anytime — every statement is a no-op if the column is already there.

alter table public.services add column if not exists enabled boolean not null default true;
alter table public.services add column if not exists description text not null default '';
alter table public.services add column if not exists image_url text not null default '';
alter table public.services add column if not exists created_at timestamptz not null default now();

alter table public.locations add column if not exists enabled boolean not null default true;
alter table public.locations add column if not exists city text not null default '';
alter table public.locations add column if not exists governorate text not null default '';
alter table public.locations add column if not exists created_at timestamptz not null default now();

alter table public.slots add column if not exists capacity int not null default 1;
alter table public.slots add column if not exists enabled boolean not null default true;

alter table public.bookings add column if not exists booking_mode text not null default 'pending';
alter table public.bookings add column if not exists confirmed_at timestamptz;
alter table public.bookings add column if not exists expires_at timestamptz;
alter table public.bookings add column if not exists cancelled_at timestamptz;
alter table public.bookings add column if not exists cancelled_by uuid references public.users(id);
alter table public.bookings add column if not exists cancellation_reason text;
alter table public.bookings add column if not exists updated_at timestamptz not null default now();

alter table public.users add column if not exists role text not null default 'customer';
alter table public.users add column if not exists full_name text;
alter table public.users add column if not exists created_at timestamptz not null default now();
