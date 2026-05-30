-- =============================================================================
-- EUBC Transport App — Supabase database setup
-- =============================================================================
-- This script creates all tables, policies, helper functions, a trigger, and
-- seed data required to run the Edinburgh University Boat Club transport app.
-- It is fully idempotent: safe to run more than once without duplicating data
-- or raising errors. Re-running will not overwrite existing rows.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
    id   uuid primary key references auth.users (id) on delete cascade,
    role text not null check (role in ('member', 'admin'))
);

create table if not exists public.members (
    id               bigint generated always as identity primary key,
    full_name        text    not null,
    short_name       text    not null,
    squad            text    check (squad in ('SW', 'SM', 'Cox')),
    student_number   text,
    pickup_location  text,
    can_drive        boolean not null default false,
    active           boolean not null default true,
    created_at       timestamptz not null default now()
);

create table if not exists public.pickup_locations (
    id         bigint generated always as identity primary key,
    name       text not null,
    sort_order int  not null default 0,
    colour     text
);

create table if not exists public.club_vehicles (
    id   bigint generated always as identity primary key,
    code text not null,
    name text
);

create table if not exists public.transport_plans (
    id             bigint generated always as identity primary key,
    session_date   date    not null unique,
    departure_time text,
    data           jsonb   not null default '{}'::jsonb,
    published      boolean not null default false,
    updated_at     timestamptz not null default now()
);

create table if not exists public.settings (
    id                   int     primary key default 1 check (id = 1),
    passenger_charge     numeric not null default 2.50,
    personal_drive_credit numeric not null default 5.00,
    club_drive_value     numeric not null default 0,
    data                 jsonb   not null default '{}'::jsonb
);


-- ---------------------------------------------------------------------------
-- 2. AUTO-PROFILE TRIGGER
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, role)
    values (
        new.id,
        case when new.email = 'admin@eubc.local' then 'admin' else 'member' end
    );
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();


-- ---------------------------------------------------------------------------
-- 3. HELPER FUNCTION
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.profiles
        where id = auth.uid() and role = 'admin'
    );
$$;


-- ---------------------------------------------------------------------------
-- 4. ROW-LEVEL SECURITY
-- ---------------------------------------------------------------------------

alter table public.profiles          enable row level security;
alter table public.members           enable row level security;
alter table public.pickup_locations  enable row level security;
alter table public.club_vehicles     enable row level security;
alter table public.transport_plans   enable row level security;
alter table public.settings          enable row level security;

-- ── pickup_locations ────────────────────────────────────────────────────────

drop policy if exists "pickup_locations: authenticated select" on public.pickup_locations;
create policy "pickup_locations: authenticated select"
    on public.pickup_locations
    for select
    to authenticated
    using (auth.role() = 'authenticated');

drop policy if exists "pickup_locations: admin insert" on public.pickup_locations;
create policy "pickup_locations: admin insert"
    on public.pickup_locations
    for insert
    to authenticated
    with check (public.is_admin());

drop policy if exists "pickup_locations: admin update" on public.pickup_locations;
create policy "pickup_locations: admin update"
    on public.pickup_locations
    for update
    to authenticated
    using (public.is_admin())
    with check (public.is_admin());

drop policy if exists "pickup_locations: admin delete" on public.pickup_locations;
create policy "pickup_locations: admin delete"
    on public.pickup_locations
    for delete
    to authenticated
    using (public.is_admin());

-- ── club_vehicles ────────────────────────────────────────────────────────────

drop policy if exists "club_vehicles: authenticated select" on public.club_vehicles;
create policy "club_vehicles: authenticated select"
    on public.club_vehicles
    for select
    to authenticated
    using (auth.role() = 'authenticated');

drop policy if exists "club_vehicles: admin insert" on public.club_vehicles;
create policy "club_vehicles: admin insert"
    on public.club_vehicles
    for insert
    to authenticated
    with check (public.is_admin());

drop policy if exists "club_vehicles: admin update" on public.club_vehicles;
create policy "club_vehicles: admin update"
    on public.club_vehicles
    for update
    to authenticated
    using (public.is_admin())
    with check (public.is_admin());

drop policy if exists "club_vehicles: admin delete" on public.club_vehicles;
create policy "club_vehicles: admin delete"
    on public.club_vehicles
    for delete
    to authenticated
    using (public.is_admin());

-- ── settings ────────────────────────────────────────────────────────────────

drop policy if exists "settings: authenticated select" on public.settings;
create policy "settings: authenticated select"
    on public.settings
    for select
    to authenticated
    using (auth.role() = 'authenticated');

drop policy if exists "settings: admin insert" on public.settings;
create policy "settings: admin insert"
    on public.settings
    for insert
    to authenticated
    with check (public.is_admin());

drop policy if exists "settings: admin update" on public.settings;
create policy "settings: admin update"
    on public.settings
    for update
    to authenticated
    using (public.is_admin())
    with check (public.is_admin());

drop policy if exists "settings: admin delete" on public.settings;
create policy "settings: admin delete"
    on public.settings
    for delete
    to authenticated
    using (public.is_admin());

-- ── transport_plans ──────────────────────────────────────────────────────────

drop policy if exists "transport_plans: authenticated select published or admin" on public.transport_plans;
create policy "transport_plans: authenticated select published or admin"
    on public.transport_plans
    for select
    to authenticated
    using (published = true or public.is_admin());

drop policy if exists "transport_plans: admin insert" on public.transport_plans;
create policy "transport_plans: admin insert"
    on public.transport_plans
    for insert
    to authenticated
    with check (public.is_admin());

drop policy if exists "transport_plans: admin update" on public.transport_plans;
create policy "transport_plans: admin update"
    on public.transport_plans
    for update
    to authenticated
    using (public.is_admin())
    with check (public.is_admin());

drop policy if exists "transport_plans: admin delete" on public.transport_plans;
create policy "transport_plans: admin delete"
    on public.transport_plans
    for delete
    to authenticated
    using (public.is_admin());

-- ── members ──────────────────────────────────────────────────────────────────
-- Members contain student numbers (PII) — only admins may read or write.

drop policy if exists "members: admin all" on public.members;
create policy "members: admin all"
    on public.members
    for all
    to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- ── profiles ─────────────────────────────────────────────────────────────────

drop policy if exists "profiles: own row or admin select" on public.profiles;
create policy "profiles: own row or admin select"
    on public.profiles
    for select
    to authenticated
    using (id = auth.uid() or public.is_admin());

-- No insert/update/delete policies for profiles: the trigger handles inserts
-- and there is intentionally no client-side write access.


-- ---------------------------------------------------------------------------
-- 5. SEED DATA
-- ---------------------------------------------------------------------------

-- settings (single row; on conflict is harmless)
insert into public.settings (id, passenger_charge, personal_drive_credit, club_drive_value, data)
values (1, 2.50, 5.00, 0, '{}'::jsonb)
on conflict (id) do nothing;

-- pickup_locations (guard with not exists so re-runs don't append duplicates)
do $$ begin
    if not exists (select 1 from public.pickup_locations) then
        insert into public.pickup_locations (name, sort_order, colour) values
            ('Pleasance',              1, '#cfe9cf'),
            ('29 Lauriston Gardens',   2, '#fdf3c4'),
            ('20 Upper Gray St',       3, '#cfe7f3'),
            ('35 Spottiswoode St',     4, '#cdd9f0'),
            ('59 Spottiswoode St',     5, '#cdd9f0'),
            ('19 Argyle Pl',           6, '#cdd9f0');
    end if;
end $$;

-- club_vehicles
do $$ begin
    if not exists (select 1 from public.club_vehicles) then
        insert into public.club_vehicles (code, name) values
            ('CVF', 'Club minibus CVF'),
            ('CWY', 'Club minibus CWY');
    end if;
end $$;

-- members — drivers first, then passengers.
-- full_name is set to short_name as a placeholder; update via the admin Roster tab.
do $$ begin
    if not exists (select 1 from public.members) then
        insert into public.members (full_name, short_name, can_drive, active) values
            -- Drivers
            ('Grace D',      'Grace D',      true,  true),
            ('Murray B',     'Murray B',     true,  true),
            ('Lucy L',       'Lucy L',       true,  true),
            ('Drew M',       'Drew M',       true,  true),
            ('Ben N',        'Ben N',        true,  true),
            ('Josh M',       'Josh M',       true,  true),
            ('Onur H',       'Onur H',       true,  true),
            ('Alex L',       'Alex L',       true,  true),
            ('James D',      'James D',      true,  true),
            ('Molly W',      'Molly W',      true,  true),
            ('Charlotte G',  'Charlotte G',  true,  true),
            -- Passengers
            ('Maddie M',     'Maddie M',     false, true),
            ('Charlotte A',  'Charlotte A',  false, true),
            ('Megan B',      'Megan B',      false, true),
            ('Isabel S',     'Isabel S',     false, true),
            ('Ellie P',      'Ellie P',      false, true),
            ('Jess M',       'Jess M',       false, true),
            ('Amy F',        'Amy F',        false, true),
            ('Lauren B',     'Lauren B',     false, true),
            ('Freddie B',    'Freddie B',    false, true),
            ('Alex R',       'Alex R',       false, true),
            ('Oskar U',      'Oskar U',      false, true),
            ('Tim T',        'Tim T',        false, true),
            ('Sam R',        'Sam R',        false, true),
            ('Anna W',       'Anna W',       false, true),
            ('Sophia W',     'Sophia W',     false, true),
            ('Kate Mc',      'Kate Mc',      false, true),
            ('Lara T',       'Lara T',       false, true),
            ('Esther N',     'Esther N',     false, true),
            ('Nienke N',     'Nienke N',     false, true),
            ('Lucy E',       'Lucy E',       false, true),
            ('Nick B',       'Nick B',       false, true),
            ('Alex D',       'Alex D',       false, true),
            ('Henrik G',     'Henrik G',     false, true),
            ('Leo O',        'Leo O',        false, true),
            ('Laith I',      'Laith I',      false, true),
            ('Freddy F',     'Freddy F',     false, true),
            ('Arabella C',   'Arabella C',   false, true),
            ('Anna H',       'Anna H',       false, true),
            ('Will M',       'Will M',       false, true),
            ('James L',      'James L',      false, true),
            ('Hector P',     'Hector P',     false, true),
            ('Gabe M',       'Gabe M',       false, true),
            ('Isla B',       'Isla B',       false, true),
            ('Maddie F',     'Maddie F',     false, true),
            ('Penny I',      'Penny I',      false, true),
            ('Beatrix F',    'Beatrix F',    false, true),
            ('Amber S',      'Amber S',      false, true),
            ('Imogen S',     'Imogen S',     false, true),
            ('Chloe H',      'Chloe H',      false, true),
            ('Isla M',       'Isla M',       false, true),
            ('Lucy M',       'Lucy M',       false, true),
            ('Tamina B',     'Tamina B',     false, true),
            ('Rebecca S',    'Rebecca S',    false, true);
    end if;
end $$;
