-- Factory Workforce Management System
-- Run this whole file in the Supabase SQL editor. It is safe to run more than once
-- (it also upgrades an older copy of this schema).

create table if not exists contractors(id uuid primary key references auth.users on delete cascade, name text, factory text);
alter table contractors add column if not exists mobile text;
alter table contractors add column if not exists address text;
alter table contractors add column if not exists settings jsonb default '{}'::jsonb;

create table if not exists workers(id uuid primary key default gen_random_uuid(), contractor_id uuid references contractors(id) on delete cascade, auth_id uuid references auth.users on delete set null, worker_code text, name text, pf_no text, esi_no text, bank_account text, mobile text, address text, joined_on date, daily_wage numeric not null, active boolean default true);
alter table workers add column if not exists user_id text;
create unique index if not exists workers_user_id_key on workers(lower(user_id));
create unique index if not exists workers_code_key on workers(contractor_id, worker_code);

create table if not exists attendance(id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id) on delete cascade, day date, status text, check_in timestamptz, check_out timestamptz, unique(worker_id,day));

create table if not exists advances(id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id) on delete cascade, day date, amount numeric);

create table if not exists payslips(id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id) on delete cascade, month date, gross numeric, deductions numeric, net numeric, status text default 'Pending', published boolean default false);
alter table payslips add column if not exists wage numeric, add column if not exists pres numeric, add column if not exists half numeric, add column if not exists leave numeric, add column if not exists pf numeric, add column if not exists esi numeric, add column if not exists adv numeric;
create unique index if not exists payslips_worker_month on payslips(worker_id, month);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on contractors, workers, attendance, advances, payslips to authenticated;

alter table contractors enable row level security;
alter table workers enable row level security;
alter table attendance enable row level security;
alter table advances enable row level security;
alter table payslips enable row level security;

-- contractors
drop policy if exists own_contractor on contractors;
create policy own_contractor on contractors for all using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists worker_sees_contractor on contractors;
create policy worker_sees_contractor on contractors for select using (id in (select contractor_id from workers where auth_id = auth.uid()));

-- workers
drop policy if exists contractor_workers on workers;
create policy contractor_workers on workers for all using (contractor_id = auth.uid()) with check (contractor_id = auth.uid());
drop policy if exists worker_self on workers;
create policy worker_self on workers for select using (auth_id = auth.uid());

-- attendance
drop policy if exists contractor_att on attendance;
create policy contractor_att on attendance for all
  using (worker_id in (select id from workers where contractor_id = auth.uid()))
  with check (worker_id in (select id from workers where contractor_id = auth.uid()));
drop policy if exists worker_att_read on attendance;
create policy worker_att_read on attendance for select using (worker_id in (select id from workers where auth_id = auth.uid()));
-- a worker may only check in for today (or yesterday/tomorrow to allow for time-zone differences)
drop policy if exists worker_checkin on attendance;
create policy worker_checkin on attendance for insert with check (
  status = 'Present' and day between current_date - 1 and current_date + 1
  and worker_id in (select id from workers where auth_id = auth.uid() and active));
drop policy if exists worker_checkout on attendance;
create policy worker_checkout on attendance for update
  using (day between current_date - 1 and current_date + 1 and worker_id in (select id from workers where auth_id = auth.uid() and active))
  with check (status = 'Present' and worker_id in (select id from workers where auth_id = auth.uid()));

-- advances
drop policy if exists contractor_adv on advances;
create policy contractor_adv on advances for all
  using (worker_id in (select id from workers where contractor_id = auth.uid()))
  with check (worker_id in (select id from workers where contractor_id = auth.uid()));
drop policy if exists worker_adv_read on advances;
create policy worker_adv_read on advances for select using (worker_id in (select id from workers where auth_id = auth.uid()));

-- payslips (workers only ever see slips the contractor has published)
drop policy if exists contractor_slips on payslips;
create policy contractor_slips on payslips for all
  using (worker_id in (select id from workers where contractor_id = auth.uid()))
  with check (worker_id in (select id from workers where contractor_id = auth.uid()));
drop policy if exists worker_slips on payslips;
create policy worker_slips on payslips for select using (published and worker_id in (select id from workers where auth_id = auth.uid()));