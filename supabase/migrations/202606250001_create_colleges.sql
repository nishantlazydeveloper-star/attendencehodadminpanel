create table if not exists public.colleges (
  id uuid primary key default gen_random_uuid(),
  college_name text not null,
  college_code text not null unique,
  city text not null,
  state text not null,
  status text not null default 'Active' check (status in ('Active', 'Inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.colleges enable row level security;

drop policy if exists "Active admins can read colleges" on public.colleges;
create policy "Active admins can read colleges"
on public.colleges for select
to authenticated
using (
  exists (
    select 1
    from public.admins
    where admins.id = auth.uid()
      and admins.role = 'admin'
      and admins.is_active = true
  )
);

drop policy if exists "Active admins can insert colleges" on public.colleges;
create policy "Active admins can insert colleges"
on public.colleges for insert
to authenticated
with check (
  exists (
    select 1
    from public.admins
    where admins.id = auth.uid()
      and admins.role = 'admin'
      and admins.is_active = true
  )
);

drop policy if exists "Active admins can update colleges" on public.colleges;
create policy "Active admins can update colleges"
on public.colleges for update
to authenticated
using (
  exists (
    select 1
    from public.admins
    where admins.id = auth.uid()
      and admins.role = 'admin'
      and admins.is_active = true
  )
)
with check (
  exists (
    select 1
    from public.admins
    where admins.id = auth.uid()
      and admins.role = 'admin'
      and admins.is_active = true
  )
);

drop policy if exists "Active admins can delete colleges" on public.colleges;
create policy "Active admins can delete colleges"
on public.colleges for delete
to authenticated
using (
  exists (
    select 1
    from public.admins
    where admins.id = auth.uid()
      and admins.role = 'admin'
      and admins.is_active = true
  )
);

do $$
begin
  alter publication supabase_realtime add table public.colleges;
exception
  when duplicate_object then null;
end $$;
