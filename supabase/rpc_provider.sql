-- Provider-only RPCs. Run after schema.sql and rpc.sql.
-- Every function starts by checking public.current_role() = 'provider',
-- and every booking is scoped to bookings.provider_id = auth.uid()
-- so a provider can only ever see or touch their own assigned bookings.

create or replace function public.provider_bookings(p_status text)
returns table (
  id uuid,
  customer_name text,
  service_name text,
  location_name text,
  starts_at timestamptz,
  ends_at timestamptz,
  status text,
  booking_mode text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'provider' then
    raise exception 'unauthorized';
  end if;

  return query
    select b.id, u.full_name, s.name, l.name, sl.starts_at, sl.ends_at, b.status, b.booking_mode
    from public.bookings b
    join public.users u on u.id = b.customer_id
    join public.services s on s.id = b.service_id
    join public.locations l on l.id = b.location_id
    join public.slots sl on sl.id = b.slot_id
    where b.provider_id = auth.uid()
      and (p_status is null or b.status = p_status)
    order by sl.starts_at;
end;
$$;

revoke all on function public.provider_bookings(text) from public;
grant execute on function public.provider_bookings(text) to authenticated;

create or replace function public.provider_confirm_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.bookings;
begin
  if public.current_role() is distinct from 'provider' then
    raise exception 'unauthorized';
  end if;

  update public.bookings
  set status = 'confirmed', confirmed_at = now(), updated_at = now()
  where id = p_booking_id
    and provider_id = auth.uid()
    and status = 'pending'
  returning * into v_row;

  if not found then
    raise exception 'booking_not_confirmable';
  end if;

  return v_row;
end;
$$;

revoke all on function public.provider_confirm_booking(uuid) from public;
grant execute on function public.provider_confirm_booking(uuid) to authenticated;

create or replace function public.provider_cancel_booking(p_booking_id uuid, p_reason text)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.bookings;
begin
  if public.current_role() is distinct from 'provider' then
    raise exception 'unauthorized';
  end if;

  if p_reason is null or length(trim(p_reason)) = 0 then
    raise exception 'reason_required';
  end if;

  update public.bookings
  set status = 'cancelled',
      cancelled_at = now(),
      cancelled_by = auth.uid(),
      cancellation_reason = p_reason,
      updated_at = now()
  where id = p_booking_id
    and provider_id = auth.uid()
    and status in ('pending','confirmed')
  returning * into v_row;

  if not found then
    raise exception 'booking_not_cancellable';
  end if;

  return v_row;
end;
$$;

revoke all on function public.provider_cancel_booking(uuid,text) from public;
grant execute on function public.provider_cancel_booking(uuid,text) to authenticated;

create or replace function public.provider_assigned_locations()
returns table (
  service_id uuid,
  service_name text,
  location_id uuid,
  location_name text,
  booking_mode text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'provider' then
    raise exception 'unauthorized';
  end if;

  return query
    select pa.service_id, s.name, pa.location_id, l.name, pa.booking_mode
    from public.provider_assignments pa
    join public.services s on s.id = pa.service_id
    join public.locations l on l.id = pa.location_id
    where pa.provider_id = auth.uid();
end;
$$;

revoke all on function public.provider_assigned_locations() from public;
grant execute on function public.provider_assigned_locations() to authenticated;
