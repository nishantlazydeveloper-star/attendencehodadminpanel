create table if not exists public.hods (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  college text not null,
  department text not null,
  role text not null default 'hod' check (role = 'hod'),
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.hods enable row level security;

drop policy if exists "Active admins can read HODs" on public.hods;
create policy "Active admins can read HODs"
on public.hods for select
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
  alter publication supabase_realtime add table public.hods;
exception
  when duplicate_object then null;
end $$;
