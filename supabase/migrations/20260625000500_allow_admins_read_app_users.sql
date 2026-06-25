grant select on table public.app_users to authenticated;

drop policy if exists "Active admins can read app users" on public.app_users;
create policy "Active admins can read app users"
on public.app_users for select
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
