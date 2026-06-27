create or replace function public.delete_hod_cascade(p_hod_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_hod_email text;
  v_auth_email text;
  v_email text;
  v_has_app_users boolean;
  v_has_app_auth_user_id boolean;
  v_has_app_firestore_uid boolean;
  v_has_app_email boolean;
  v_has_app_role boolean;
  v_where_parts text[] := '{}';
  v_where_sql text;
  v_hods_deleted integer := 0;
  v_app_users_deleted integer := 0;
  v_auth_users_deleted integer := 0;
  v_already_deleted boolean;
begin
  select h.email
  into v_hod_email
  from public.hods h
  where h.id = p_hod_id
  for update;

  select u.email
  into v_auth_email
  from auth.users u
  where u.id = p_hod_id
  for update;

  v_email := nullif(coalesce(v_hod_email, v_auth_email, ''), '');

  v_has_app_users := to_regclass('public.app_users') is not null;

  if v_has_app_users then
    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'app_users'
        and column_name = 'auth_user_id'
    )
    into v_has_app_auth_user_id;

    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'app_users'
        and column_name = 'firestore_uid'
    )
    into v_has_app_firestore_uid;

    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'app_users'
        and column_name = 'email'
    )
    into v_has_app_email;

    select exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'app_users'
        and column_name = 'role'
    )
    into v_has_app_role;

    if v_has_app_auth_user_id then
      v_where_parts := array_append(v_where_parts, 'auth_user_id = $1');
    end if;

    if v_has_app_firestore_uid then
      v_where_parts := array_append(v_where_parts, 'firestore_uid = $1::text');
    end if;

    if v_has_app_email and v_email is not null then
      v_where_parts := array_append(v_where_parts, 'lower(email) = lower($2)');
    end if;

    if array_length(v_where_parts, 1) is not null then
      v_where_sql := '(' || array_to_string(v_where_parts, ' or ') || ')';
      if v_has_app_role then
        v_where_sql := v_where_sql || ' and lower(role::text) = ''hod''';
      end if;

      execute 'delete from public.app_users where ' || v_where_sql
      using p_hod_id, v_email;
      get diagnostics v_app_users_deleted = row_count;
    end if;
  end if;

  delete from public.hods
  where id = p_hod_id;
  get diagnostics v_hods_deleted = row_count;

  delete from auth.users
  where id = p_hod_id;
  get diagnostics v_auth_users_deleted = row_count;

  v_already_deleted :=
    v_hods_deleted = 0 and
    v_app_users_deleted = 0 and
    v_auth_users_deleted = 0;

  return jsonb_build_object(
    'success', true,
    'id', p_hod_id,
    'message',
      case
        when v_already_deleted then 'HOD was already deleted.'
        else 'HOD deleted successfully.'
      end,
    'already_deleted', v_already_deleted,
    'deleted', jsonb_build_object(
      'hods', v_hods_deleted,
      'app_users', v_app_users_deleted,
      'auth_users', v_auth_users_deleted
    )
  );
end;
$$;

revoke all on function public.delete_hod_cascade(uuid) from public;
grant execute on function public.delete_hod_cascade(uuid) to service_role;
