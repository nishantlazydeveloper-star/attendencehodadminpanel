do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'colleges'
      and column_name = 'name'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'colleges'
      and column_name = 'college_name'
  ) then
    alter table public.colleges rename column name to college_name;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'colleges'
      and column_name = 'code'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'colleges'
      and column_name = 'college_code'
  ) then
    alter table public.colleges rename column code to college_code;
  end if;

  alter table public.colleges
    add column if not exists college_name text,
    add column if not exists college_code text,
    add column if not exists city text,
    add column if not exists state text,
    add column if not exists status text not null default 'Active';

  update public.colleges
  set
    college_name = coalesce(nullif(college_name, ''), 'Unnamed College'),
    college_code = coalesce(nullif(college_code, ''), id::text),
    city = coalesce(city, ''),
    state = coalesce(state, ''),
    status = coalesce(nullif(status, ''), 'Active');

  alter table public.colleges
    alter column college_name set not null,
    alter column college_code set not null,
    alter column city set not null,
    alter column state set not null,
    alter column status set not null;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'colleges'
      and column_name = 'address'
  ) then
    alter table public.colleges drop column address;
  end if;
end $$;
