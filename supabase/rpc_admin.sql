-- Admin-only RPCs. Run after schema.sql and rpc.sql.
-- Every function starts by checking public.current_role() = 'admin'.

-- ---------- Services ----------

create or replace function public.admin_upsert_service(
  p_id uuid,
  p_name text,
  p_description text,
  p_image_url text,
  p_enabled boolean
)
returns public.services
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.services;
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  if p_id is null then
    insert into public.services (name, description, image_url, enabled)
    values (p_name, coalesce(p_description, ''), coalesce(p_image_url, ''), coalesce(p_enabled, true))
    returning * into v_row;
  else
    update public.services
    set name = p_name,
        description = coalesce(p_description, ''),
        image_url = coalesce(p_image_url, ''),
        enabled = coalesce(p_enabled, true)
    where id = p_id
    returning * into v_row;

    if not found then
      raise exception 'service_not_found';
    end if;
  end if;

  return v_row;
end;
$$;

revoke all on function public.admin_upsert_service(uuid,text,text,text,boolean) from public;
grant execute on function public.admin_upsert_service(uuid,text,text,text,boolean) to authenticated;

create or replace function public.admin_list_services()
returns setof public.services
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  return query select * from public.services order by name;
end;
$$;

revoke all on function public.admin_list_services() from public;
grant execute on function public.admin_list_services() to authenticated;

-- ---------- Locations ----------

create or replace function public.admin_upsert_location(
  p_id uuid,
  p_name text,
  p_city text,
  p_governorate text,
  p_enabled boolean
)
returns public.locations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.locations;
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  if p_id is null then
    insert into public.locations (name, city, governorate, enabled)
    values (p_name, coalesce(p_city, ''), coalesce(p_governorate, ''), coalesce(p_enabled, true))
    returning * into v_row;
  else
    update public.locations
    set name = p_name,
        city = coalesce(p_city, ''),
        governorate = coalesce(p_governorate, ''),
        enabled = coalesce(p_enabled, true)
    where id = p_id
    returning * into v_row;

    if not found then
      raise exception 'location_not_found';
    end if;
  end if;

  return v_row;
end;
$$;

revoke all on function public.admin_upsert_location(uuid,text,text,text,boolean) from public;
grant execute on function public.admin_upsert_location(uuid,text,text,text,boolean) to authenticated;

create or replace function public.admin_list_locations()
returns setof public.locations
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  return query select * from public.locations order by name;
end;
$$;

revoke all on function public.admin_list_locations() from public;
grant execute on function public.admin_list_locations() to authenticated;

-- ---------- Service <-> location links ----------

create or replace function public.admin_link_service_location(p_service_id uuid, p_location_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  insert into public.service_locations (service_id, location_id)
  values (p_service_id, p_location_id)
  on conflict do nothing;
end;
$$;

revoke all on function public.admin_link_service_location(uuid,uuid) from public;
grant execute on function public.admin_link_service_location(uuid,uuid) to authenticated;

create or replace function public.admin_unlink_service_location(p_service_id uuid, p_location_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  delete from public.service_locations
  where service_id = p_service_id and location_id = p_location_id;
end;
$$;

revoke all on function public.admin_unlink_service_location(uuid,uuid) from public;
grant execute on function public.admin_unlink_service_location(uuid,uuid) to authenticated;

create or replace function public.admin_service_location_ids(p_service_id uuid)
returns setof uuid
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  return query select location_id from public.service_locations where service_id = p_service_id;
end;
$$;

revoke all on function public.admin_service_location_ids(uuid) from public;
grant execute on function public.admin_service_location_ids(uuid) to authenticated;

-- ---------- Slots (availability) ----------

create or replace function public.admin_upsert_slot(
  p_id uuid,
  p_service_id uuid,
  p_location_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_capacity int,
  p_enabled boolean
)
returns public.slots
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.slots;
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  if p_id is null then
    insert into public.slots (service_id, location_id, starts_at, ends_at, capacity, enabled)
    values (p_service_id, p_location_id, p_starts_at, p_ends_at, coalesce(p_capacity, 1), coalesce(p_enabled, true))
    returning * into v_row;
  else
    update public.slots
    set service_id = p_service_id,
        location_id = p_location_id,
        starts_at = p_starts_at,
        ends_at = p_ends_at,
        capacity = coalesce(p_capacity, 1),
        enabled = coalesce(p_enabled, true)
    where id = p_id
    returning * into v_row;

    if not found then
      raise exception 'slot_not_found';
    end if;
  end if;

  return v_row;
end;
$$;

revoke all on function public.admin_upsert_slot(uuid,uuid,uuid,timestamptz,timestamptz,int,boolean) from public;
grant execute on function public.admin_upsert_slot(uuid,uuid,uuid,timestamptz,timestamptz,int,boolean) to authenticated;

create or replace function public.admin_list_slots(p_service_id uuid, p_location_id uuid)
returns setof public.slots
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  return query
    select * from public.slots
    where (p_service_id is null or service_id = p_service_id)
      and (p_location_id is null or location_id = p_location_id)
    order by starts_at;
end;
$$;

revoke all on function public.admin_list_slots(uuid,uuid) from public;
grant execute on function public.admin_list_slots(uuid,uuid) to authenticated;

create or replace function public.admin_delete_slot(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  delete from public.slots where id = p_id;
end;
$$;

revoke all on function public.admin_delete_slot(uuid) from public;
grant execute on function public.admin_delete_slot(uuid) to authenticated;

-- ---------- Users & roles ----------

create or replace function public.admin_list_users(p_role text)
returns setof public.users
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  return query
    select * from public.users
    where p_role is null or role = p_role
    order by created_at desc;
end;
$$;

revoke all on function public.admin_list_users(text) from public;
grant execute on function public.admin_list_users(text) to authenticated;

create or replace function public.admin_set_user_role(p_user_id uuid, p_role text)
returns public.users
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.users;
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  if p_role not in ('customer','provider','admin') then
    raise exception 'invalid_role';
  end if;

  update public.users set role = p_role where id = p_user_id
  returning * into v_row;

  if not found then
    raise exception 'user_not_found';
  end if;

  return v_row;
end;
$$;

revoke all on function public.admin_set_user_role(uuid,text) from public;
grant execute on function public.admin_set_user_role(uuid,text) to authenticated;

-- ---------- Provider assignments ----------

create or replace function public.admin_upsert_provider_assignment(
  p_id bigint,
  p_service_id uuid,
  p_location_id uuid,
  p_provider_id uuid,
  p_booking_mode text
)
returns public.provider_assignments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.provider_assignments;
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  if p_booking_mode not in ('instant','pending') then
    raise exception 'invalid_booking_mode';
  end if;

  if p_id is null then
    insert into public.provider_assignments (service_id, location_id, provider_id, booking_mode)
    values (p_service_id, p_location_id, p_provider_id, p_booking_mode)
    returning * into v_row;
  else
    update public.provider_assignments
    set service_id = p_service_id,
        location_id = p_location_id,
        provider_id = p_provider_id,
        booking_mode = p_booking_mode
    where id = p_id
    returning * into v_row;

    if not found then
      raise exception 'assignment_not_found';
    end if;
  end if;

  return v_row;
end;
$$;

revoke all on function public.admin_upsert_provider_assignment(bigint,uuid,uuid,uuid,text) from public;
grant execute on function public.admin_upsert_provider_assignment(bigint,uuid,uuid,uuid,text) to authenticated;

create or replace function public.admin_list_provider_assignments()
returns table (
  id bigint,
  service_id uuid,
  service_name text,
  location_id uuid,
  location_name text,
  provider_id uuid,
  provider_name text,
  booking_mode text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  return query
    select pa.id, pa.service_id, s.name, pa.location_id, l.name, pa.provider_id, u.full_name, pa.booking_mode
    from public.provider_assignments pa
    join public.services s on s.id = pa.service_id
    join public.locations l on l.id = pa.location_id
    join public.users u on u.id = pa.provider_id
    order by pa.id desc;
end;
$$;

revoke all on function public.admin_list_provider_assignments() from public;
grant execute on function public.admin_list_provider_assignments() to authenticated;

create or replace function public.admin_delete_provider_assignment(p_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;
  delete from public.provider_assignments where id = p_id;
end;
$$;

revoke all on function public.admin_delete_provider_assignment(bigint) from public;
grant execute on function public.admin_delete_provider_assignment(bigint) to authenticated;

-- ---------- Bookings overview ----------

create or replace function public.admin_list_bookings(p_status text)
returns table (
  id uuid,
  customer_name text,
  service_name text,
  location_name text,
  starts_at timestamptz,
  status text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception 'unauthorized';
  end if;

  return query
    select b.id, u.full_name, s.name, l.name, sl.starts_at, b.status, b.created_at
    from public.bookings b
    join public.users u on u.id = b.customer_id
    join public.services s on s.id = b.service_id
    join public.locations l on l.id = b.location_id
    join public.slots sl on sl.id = b.slot_id
    where p_status is null or b.status = p_status
    order by b.created_at desc
    limit 200;
end;
$$;

revoke all on function public.admin_list_bookings(text) from public;
grant execute on function public.admin_list_bookings(text) to authenticated;
