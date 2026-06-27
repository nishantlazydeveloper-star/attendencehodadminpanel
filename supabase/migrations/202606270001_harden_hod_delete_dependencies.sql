create or replace function public.delete_hod_cascade(p_hod_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_hod_email text;
  v_auth_user_id uuid;
  v_auth_email text;
  v_email text;
  v_has_app_users boolean;
  v_has_app_auth_user_id boolean;
  v_has_app_firestore_uid boolean;
  v_has_app_email boolean;
  v_has_app_role boolean;
  v_where_parts text[] := '{}';
  v_where_sql text;
  v_reference record;
  v_rows_affected integer := 0;
  v_references_detached integer := 0;
  v_detached_by_column jsonb := '{}'::jsonb;
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

  select u.id, u.email
  into v_auth_user_id, v_auth_email
  from auth.users u
  where u.id = p_hod_id
     or (
       nullif(v_hod_email, '') is not null
       and lower(u.email) = lower(v_hod_email)
     )
  order by (u.id = p_hod_id) desc
  limit 1
  for update;

  v_email := nullif(coalesce(v_hod_email, v_auth_email, ''), '');

  if v_auth_user_id is not null then
    for v_reference in
      select
        namespace.nspname as table_schema,
        relation.relname as table_name,
        attribute.attname as column_name
      from pg_catalog.pg_constraint constraint_definition
      join pg_catalog.pg_class relation
        on relation.oid = constraint_definition.conrelid
      join pg_catalog.pg_namespace namespace
        on namespace.oid = relation.relnamespace
      join pg_catalog.pg_attribute attribute
        on attribute.attrelid = constraint_definition.conrelid
       and attribute.attnum = constraint_definition.conkey[1]
      where constraint_definition.contype = 'f'
        and constraint_definition.confrelid = 'auth.users'::regclass
        and constraint_definition.confdeltype in ('a', 'r')
        and cardinality(constraint_definition.conkey) = 1
        and namespace.nspname = 'public'
        and not attribute.attnotnull
    loop
      execute format(
        'update %I.%I set %I = null where %I = $1',
        v_reference.table_schema,
        v_reference.table_name,
        v_reference.column_name,
        v_reference.column_name
      )
      using v_auth_user_id;

      get diagnostics v_rows_affected = row_count;
      if v_rows_affected > 0 then
        v_references_detached := v_references_detached + v_rows_affected;
        v_detached_by_column := v_detached_by_column || jsonb_build_object(
          format('%I.%I', v_reference.table_name, v_reference.column_name),
          v_rows_affected
        );
      end if;
    end loop;
  end if;

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
      v_where_parts := array_append(
        v_where_parts,
        'auth_user_id = coalesce($1, $2)'
      );
    end if;

    if v_has_app_firestore_uid then
      v_where_parts := array_append(
        v_where_parts,
        'firestore_uid in (coalesce($1, $2)::text, $2::text)'
      );
    end if;

    if v_has_app_email and v_email is not null then
      v_where_parts := array_append(v_where_parts, 'lower(email) = lower($3)');
    end if;

    if array_length(v_where_parts, 1) is not null then
      v_where_sql := '(' || array_to_string(v_where_parts, ' or ') || ')';
      if v_has_app_role then
        v_where_sql := v_where_sql || ' and lower(role::text) = ''hod''';
      end if;

      execute 'delete from public.app_users where ' || v_where_sql
      using v_auth_user_id, p_hod_id, v_email;
      get diagnostics v_app_users_deleted = row_count;
    end if;
  end if;

  delete from public.hods
  where id = p_hod_id;
  get diagnostics v_hods_deleted = row_count;

  if v_auth_user_id is not null then
    delete from auth.users
    where id = v_auth_user_id;
    get diagnostics v_auth_users_deleted = row_count;
  end if;

  v_already_deleted :=
    v_hods_deleted = 0
    and v_app_users_deleted = 0
    and v_auth_users_deleted = 0
    and v_references_detached = 0;

  return jsonb_build_object(
    'success', true,
    'id', p_hod_id,
    'auth_user_id', v_auth_user_id,
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
    ),
    'references_detached', v_references_detached,
    'detached_by_column', v_detached_by_column
  );
end;
$$;

revoke all on function public.delete_hod_cascade(uuid) from public;
grant execute on function public.delete_hod_cascade(uuid) to service_role;
