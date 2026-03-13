

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "app";


ALTER SCHEMA "app" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."entitlement_status" AS ENUM (
    'active',
    'suspended',
    'canceled',
    'expired',
    'pending'
);


ALTER TYPE "public"."entitlement_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "app"."org_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  select nullif(auth.jwt() ->> 'org_id','')::uuid
$$;


ALTER FUNCTION "app"."org_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."asset_restore"("p_id" "uuid") RETURNS "void"
    LANGUAGE "sql"
    AS $$
  update public.assets
  set deleted_at = null,
      delete_reason = null,
      deleted_by = null
  where id = p_id
    and org_id = app.org_id()
    and deleted_at is not null;
$$;


ALTER FUNCTION "public"."asset_restore"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."asset_soft_delete"("p_id" "uuid", "p_reason" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "sql"
    AS $$
  update public.assets
  set deleted_at = now(),
      delete_reason = coalesce(p_reason, delete_reason),
      deleted_by = auth.uid()
  where id = p_id
    and org_id = app.org_id()
    and deleted_at is null;
$$;


ALTER FUNCTION "public"."asset_soft_delete"("p_id" "uuid", "p_reason" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."asset_status_id"("p_code" "text") RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  select id from public.asset_statuses where code = p_code
$$;


ALTER FUNCTION "public"."asset_status_id"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."bootstrap"() RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
with me as (
  select auth.uid() as uid
),
orgs as (
  select o.id, o.name
  from users_orgs uo
  join orgs o on o.id = uo.org_id
  where uo.user_id = (select uid from me)
  order by o.created_at asc
),
ents as (
  select e.*
  from entitlements_current e
  join users_orgs uo on uo.org_id = e.org_id
  where uo.user_id = (select uid from me)
)
select jsonb_build_object(
  'orgs',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', o.id,
            'name', o.name
          )
        )
        from orgs o
      ),
      '[]'::jsonb
    ),
  'entitlements',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'org_id', e.org_id,
            'plan_id', e.plan_id,
            'status', e.status,
            'asset_limit', e.asset_limit,
            'features', e.features,
            'source_ref', e.source_ref,
            'period_start', e.current_period_start,
            'period_end', e.current_period_end
          )
        )
        from ents e
      ),
      '[]'::jsonb
    )
);
$$;


ALTER FUNCTION "public"."bootstrap"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enforce_asset_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  current_count int;
  limit_val int;
begin
  -- If limit is NULL (unlimited), allow insert
  select asset_limit into limit_val from orgs where id = new.org_id;
  if limit_val is null then
    return new;
  end if;

  -- Count existing assets for the org
  select count(*) into current_count
  from assets
  where org_id = new.org_id;

  if current_count >= limit_val then
    raise exception 'Asset limit (%s) reached for this organization.', limit_val;
  end if;

  return new;
end
$$;


ALTER FUNCTION "public"."enforce_asset_limit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.app_users (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
begin
  insert into audit_log (org_id, actor_id, action, entity, entity_id, changes)
  values (
    -- org_id from JSON (null if not present)
    nullif((case when TG_OP = 'DELETE' then to_jsonb(OLD) else to_jsonb(NEW) end)->>'org_id','')::uuid,
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    -- id from JSON (null if not present)
    (case when TG_OP = 'DELETE' then to_jsonb(OLD) else to_jsonb(NEW) end)->>'id',
    -- full row snapshot
    case when TG_OP = 'DELETE' then to_jsonb(OLD) else to_jsonb(NEW) end
  );
  return case when TG_OP = 'DELETE' then OLD else NEW end;
end;
$$;


ALTER FUNCTION "public"."log_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) RETURNS TABLE("id" "uuid", "org_id" "uuid", "name" "text", "category" "text", "schema" "jsonb", "version" integer, "is_active" boolean, "created_at" timestamp with time zone, "is_predefined" boolean, "created_by" "uuid", "creator_first_name" "text", "creator_last_name" "text")
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    it.id,
    it.org_id,
    it.name,
    it.category,
    it.schema,
    it.version,
    it.is_active,
    it.created_at,
    it.is_predefined,
    it.created_by,
    au.first_name AS creator_first_name,
    au.last_name  AS creator_last_name
  FROM inspection_templates it
  LEFT JOIN app_users au ON au.id = it.created_by
  WHERE
    (
      CASE p_scope
        WHEN 'org_created' THEN (it.org_id = p_org)
        WHEN 'predefined'  THEN (it.is_predefined = TRUE)
        WHEN 'all'         THEN (it.org_id = p_org OR it.is_predefined = TRUE)
        ELSE                   (it.org_id = p_org)
      END
    )
    AND (
      p_q IS NULL
      OR p_q = ''
      OR it.name     ILIKE '%' || p_q || '%'
      OR it.category ILIKE '%' || p_q || '%'
    )
  ORDER BY
    CASE WHEN p_sort_by = 'name'         AND p_sort_dir = 'asc'  THEN it.name        END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'name'         AND p_sort_dir = 'desc' THEN it.name        END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'category'     AND p_sort_dir = 'asc'  THEN it.category    END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'category'     AND p_sort_dir = 'desc' THEN it.category    END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'created_at'   AND p_sort_dir = 'asc'  THEN it.created_at  END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'created_at'   AND p_sort_dir = 'desc' THEN it.created_at  END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'is_predefined'AND p_sort_dir = 'asc'  THEN it.is_predefined END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'is_predefined'AND p_sort_dir = 'desc' THEN it.is_predefined END DESC NULLS LAST,
    it.created_at DESC,
    it.id DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;


ALTER FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_category" "text" DEFAULT NULL::"text", "p_sort_by" "text" DEFAULT 'created_at'::"text", "p_sort_dir" "text" DEFAULT 'desc'::"text", "p_limit" integer DEFAULT 25, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "org_id" "uuid", "name" "text", "category" "text", "category_id" "uuid", "schema" "jsonb", "version" integer, "is_active" boolean, "created_at" timestamp with time zone, "is_predefined" boolean, "created_by" "uuid", "creator_first_name" "text", "creator_last_name" "text")
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    it.id,
    it.org_id,
    it.name,
    tc.name        AS category,
    it.category_id,
    it.schema,
    it.version,
    it.is_active,
    it.created_at,
    it.is_predefined,
    it.created_by,
    au.first_name  AS creator_first_name,
    au.last_name   AS creator_last_name
  FROM public.inspection_templates it
  JOIN public.template_categories tc ON tc.id = it.category_id
  LEFT JOIN public.app_users au ON au.id = it.created_by
  WHERE
    -- org / predefined scope
    (
      CASE p_scope
        WHEN 'org_created' THEN (it.org_id = p_org)
        WHEN 'predefined'  THEN (it.is_predefined = TRUE)
        ELSE (it.org_id = p_org OR it.is_predefined = TRUE)
      END
    )
    -- category filter
    AND (
      p_category IS NULL
      OR p_category = ''
      OR tc.name = p_category
    )
    -- full-text search
    AND (
      p_q IS NULL
      OR p_q = ''
      OR it.name ILIKE '%' || p_q || '%'
      OR tc.name ILIKE '%' || p_q || '%'
    )
  ORDER BY
    CASE WHEN p_sort_by = 'name'          AND p_sort_dir = 'asc'  THEN it.name          END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'name'          AND p_sort_dir = 'desc' THEN it.name          END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'category'      AND p_sort_dir = 'asc'  THEN tc.name          END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'category'      AND p_sort_dir = 'desc' THEN tc.name          END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'created_at'    AND p_sort_dir = 'asc'  THEN it.created_at    END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'created_at'    AND p_sort_dir = 'desc' THEN it.created_at    END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'is_predefined' AND p_sort_dir = 'asc'  THEN it.is_predefined END ASC  NULLS LAST,
    CASE WHEN p_sort_by = 'is_predefined' AND p_sort_dir = 'desc' THEN it.is_predefined END DESC NULLS LAST,
    it.created_at DESC,
    it.id DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;


ALTER FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_category" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."stamp_asset_statuses"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;


ALTER FUNCTION "public"."stamp_asset_statuses"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."stamp_assets"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.updated_by := coalesce(new.updated_by, auth.uid());
    new.updated_at := now();
    return new;
  elsif tg_op = 'UPDATE' then
    new.updated_by := coalesce(auth.uid(), new.updated_by);
    new.updated_at := now();
    return new;
  end if;
  return new;
end $$;


ALTER FUNCTION "public"."stamp_assets"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tg_entitlements_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end$$;


ALTER FUNCTION "public"."tg_entitlements_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_onboarding_v2"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_plan" "text", "p_stage" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_user_id uuid;
  v_org_id  uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Update profile (only overwrite when non-null so you can call per section)
  update app_users
     set first_name  = coalesce(p_first_name, first_name),
         middle_name = coalesce(p_middle_name, middle_name),
         last_name   = coalesce(p_last_name, last_name),
         gender      = coalesce(p_gender, gender),
         dob         = coalesce(p_dob, dob),
         updated_at  = now()
   where id = v_user_id;

  -- Create or reuse org
  if p_org_id is not null then
    v_org_id := p_org_id;
  else
    -- Try to reuse an existing draft org for this user
    select uo.org_id into v_org_id
    from users_orgs uo
    join orgs o on o.id = uo.org_id
    where uo.user_id = v_user_id
      and o.status = 'draft'
    limit 1;

    if v_org_id is null then
      insert into orgs(name, plan, asset_limit, status, onboarding_stage)
      values (coalesce(p_org_name, 'My Organization'), coalesce(p_plan,'basic'), 1, 'draft', p_stage)
      returning id into v_org_id;

      insert into users_orgs(user_id, org_id, role)
      values (v_user_id, v_org_id, 'owner')
      on conflict do nothing;
    end if;
  end if;

  -- Update org fields (only when provided)
  update orgs
     set name                    = coalesce(p_org_name, name),
         street_address          = coalesce(p_street, street_address),
         city                    = coalesce(p_city, city),
         state_province          = coalesce(p_state, state_province),
         postal_code             = coalesce(p_postal, postal_code),
         country                 = coalesce(p_country, country),
         primary_contact_name    = coalesce(p_primary_contact_name, primary_contact_name),
         primary_contact_email   = coalesce(p_primary_contact_email, primary_contact_email),
         primary_contact_phone   = coalesce(p_primary_contact_phone, primary_contact_phone),
         plan                    = coalesce(p_plan, plan),
         onboarding_stage        = coalesce(p_stage, onboarding_stage)
   where id = v_org_id;

  return v_org_id;
end;
$$;


ALTER FUNCTION "public"."upsert_onboarding_v2"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_plan" "text", "p_stage" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_onboarding_v3"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_first_name" "text", "p_primary_contact_last_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_stage" "text", "p_billing_email" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  v_user_id uuid;
  v_org_id  uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Update profile (overwrite only when non-null)
  update app_users
     set first_name  = coalesce(p_first_name, first_name),
         middle_name = coalesce(p_middle_name, middle_name),
         last_name   = coalesce(p_last_name, last_name),
         gender      = coalesce(p_gender, gender),
         dob         = coalesce(p_dob, dob),
         updated_at  = now()
   where id = v_user_id;

  -- Create or reuse a draft org
  if p_org_id is not null then
    v_org_id := p_org_id;
  else
    select uo.org_id into v_org_id
    from users_orgs uo
    join orgs o on o.id = uo.org_id
    where uo.user_id = v_user_id
      and o.status = 'draft'
    limit 1;

    if v_org_id is null then
      insert into orgs(name, asset_limit, status, onboarding_stage)
      values (coalesce(p_org_name,'My Organization'),  0, 'draft', p_stage)
      returning id into v_org_id;

      insert into users_orgs(user_id, org_id, role_id)
      select v_user_id, v_org_id, r.id
      from roles r
      where r.role_key = 'owner'
      limit 1
      on conflict do nothing;
      
    end if;
  end if;

  -- Update org details (overwrite only when non-null)
  update orgs
     set name                         = coalesce(p_org_name, name),
         street_address               = coalesce(p_street, street_address),
         city                         = coalesce(p_city, city),
         state_province               = coalesce(p_state, state_province),
         postal_code                  = coalesce(p_postal, postal_code),
         country                      = coalesce(p_country, country),
         primary_contact_first_name   = coalesce(p_primary_contact_first_name, primary_contact_first_name),
         primary_contact_last_name    = coalesce(p_primary_contact_last_name, primary_contact_last_name),
         primary_contact_email        = coalesce(p_primary_contact_email, primary_contact_email),
         primary_contact_phone        = coalesce(p_primary_contact_phone, primary_contact_phone),
         --plan                         = coalesce(p_plan, plan),
         onboarding_stage             = coalesce(p_stage, onboarding_stage),
         billing_email  = coalesce(p_billing_email, billing_email)
         --plan_id = coalesce(p_plan_id, plan_id)
   where id = v_org_id;

  return v_org_id;
end;$$;


ALTER FUNCTION "public"."upsert_onboarding_v3"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_first_name" "text", "p_primary_contact_last_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_stage" "text", "p_billing_email" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."app_errors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "org_id" "uuid",
    "env" "text" NOT NULL,
    "platform" "text",
    "app_version" "text",
    "screen" "text",
    "error_type" "text",
    "message" "text" NOT NULL,
    "stack" "text",
    "extra" "jsonb",
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_errors_env_check" CHECK (("env" = ANY (ARRAY['dev'::"text", 'prod'::"text"])))
);


ALTER TABLE "public"."app_errors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_users" (
    "id" "uuid" NOT NULL,
    "first_name" "text",
    "middle_name" "text",
    "last_name" "text",
    "display_name" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "email" "text",
    "gender" "text",
    "dob" "date"
);


ALTER TABLE "public"."app_users" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."app_users_v" AS
 SELECT "id",
    "email",
    "first_name",
    "middle_name",
    "last_name",
    TRIM(BOTH FROM "concat_ws"(' '::"text", "first_name", NULLIF("middle_name", ''::"text"), "last_name")) AS "full_name",
    "created_at"
   FROM "public"."app_users" "u";


ALTER VIEW "public"."app_users_v" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."asset_inspection_templates" (
    "asset_id" "uuid" NOT NULL,
    "inspection_template_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" DEFAULT "auth"."uid"()
);


ALTER TABLE "public"."asset_inspection_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."asset_statuses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "label" "text" NOT NULL,
    "color" "text",
    "sort_order" integer DEFAULT 100 NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL,
    "is_terminal" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."asset_statuses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "make" "text",
    "model" "text",
    "serial_or_vin" "text",
    "status" "text" DEFAULT 'active'::"text",
    "location" "text",
    "tags" "jsonb" DEFAULT '[]'::"jsonb",
    "meter_type" "text" DEFAULT 'none'::"text",
    "meter_unit" "text",
    "meter_value" numeric,
    "attributes" "jsonb" DEFAULT '{}'::"jsonb",
    "last_inspected_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_by" "uuid",
    "status_id" "uuid" DEFAULT "public"."asset_status_id"('active'::"text") NOT NULL,
    "deleted_at" timestamp with time zone,
    "deleted_by" "uuid",
    "delete_reason" "text",
    "picUrl" "text",
    "year" integer,
    CONSTRAINT "chk_assets_category" CHECK (("category" = ANY (ARRAY['vehicle'::"text", 'trailer'::"text", 'heavy_equipment'::"text", 'access_equipment'::"text", 'power_equipment'::"text", 'fluid_handling'::"text", 'safety_equipment'::"text", 'building_systems'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" bigint NOT NULL,
    "org_id" "uuid",
    "actor_id" "uuid",
    "action" "text" NOT NULL,
    "entity" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "changes" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


ALTER TABLE "public"."audit_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."consumption_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "type" "text" NOT NULL,
    "qty" numeric NOT NULL,
    "unit" "text" NOT NULL,
    "cost" numeric,
    "meter_value" numeric,
    "receipt_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."consumption_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."defects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "inspection_id" "uuid" NOT NULL,
    "item_id" "uuid",
    "severity" "text" DEFAULT 'Medium'::"text" NOT NULL,
    "description" "text" NOT NULL,
    "status" "text" DEFAULT 'Open'::"text" NOT NULL,
    "photo_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "resolved_at" timestamp with time zone
);


ALTER TABLE "public"."defects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_otp_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "challenge_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code_hash" "text" NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:10:00'::interval) NOT NULL,
    "consumed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."email_otp_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."entitlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "plan_id" "uuid",
    "source" "text" DEFAULT 'stripe'::"text" NOT NULL,
    "source_ref" "text" NOT NULL,
    "asset_limit" integer,
    "features" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "status" "public"."entitlement_status" DEFAULT 'active'::"public"."entitlement_status" NOT NULL,
    "current_period_start" timestamp with time zone,
    "current_period_end" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "entitlements_source_check" CHECK (("source" = ANY (ARRAY['stripe'::"text", 'manual'::"text"])))
);


ALTER TABLE "public"."entitlements" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."entitlements_current" AS
 SELECT "id",
    "org_id",
    "plan_id",
    "source",
    "source_ref",
    "asset_limit",
    "features",
    "status",
    "current_period_start",
    "current_period_end",
    "created_at",
    "updated_at"
   FROM "public"."entitlements" "e"
  WHERE ("status" = 'active'::"public"."entitlement_status");


ALTER VIEW "public"."entitlements_current" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "asset_id" "uuid",
    "kind" "text",
    "url" "text" NOT NULL,
    "label" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inspection_item_values" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "inspection_item_id" "uuid" NOT NULL,
    "key" "text" NOT NULL,
    "label" "text",
    "value" "text",
    "photo_url" "text",
    "comment" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."inspection_item_values" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inspection_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "inspection_id" "uuid" NOT NULL,
    "template_item_key" "text" NOT NULL,
    "type" "text" NOT NULL,
    "label" "text" NOT NULL,
    "order" integer NOT NULL,
    "config" "jsonb",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."inspection_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inspection_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid",
    "name" "text" NOT NULL,
    "schema" "jsonb" NOT NULL,
    "version" integer DEFAULT 1,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_predefined" boolean DEFAULT false NOT NULL,
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "category_id" "uuid" NOT NULL,
    CONSTRAINT "chk_visibility" CHECK ((("is_predefined" = true) OR ("org_id" IS NOT NULL)))
);


ALTER TABLE "public"."inspection_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inspections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "template_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'in_progress'::"text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone,
    "gps" "jsonb",
    "signed_by" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_by" "uuid",
    "signature_url" "text"
);


ALTER TABLE "public"."inspections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."operators" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "license_no" "text",
    "phone" "text",
    "photo_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."operators" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."orgs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "asset_limit" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'draft'::"text",
    "onboarding_stage" "text",
    "street_address" "text",
    "city" "text",
    "state_province" "text",
    "postal_code" "text",
    "country" "text",
    "primary_contact_email" "text",
    "primary_contact_phone" "text",
    "primary_contact_first_name" "text",
    "primary_contact_last_name" "text",
    "stripe_customer_id" "text",
    "stripe_subscription_id" "text",
    "billing_email" "text",
    "plan_id" "uuid",
    CONSTRAINT "orgs_asset_limit_nonneg" CHECK ((("asset_limit" IS NULL) OR ("asset_limit" >= 0))),
    CONSTRAINT "orgs_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'active'::"text", 'suspended'::"text"])))
);


ALTER TABLE "public"."orgs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "stripe_customer_id" "text",
    "stripe_session_id" "text",
    "stripe_payment_intent_id" "text",
    "stripe_invoice_id" "text",
    "amount_paid_cents" integer NOT NULL,
    "currency" "text" DEFAULT 'usd'::"text" NOT NULL,
    "card_last4" "text",
    "payment_method_brand" "text",
    "receipt_url" "text",
    "status" "text" NOT NULL,
    "paid_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "payment_method_type" "text"
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "stripe_price_id" "text" NOT NULL,
    "interval" "text" NOT NULL,
    "currency" "text" DEFAULT 'usd'::"text" NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "is_per_asset" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "asset_limit" integer,
    CONSTRAINT "plans_interval_check" CHECK (("interval" = ANY (ARRAY['month'::"text", 'year'::"text"])))
);


ALTER TABLE "public"."plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_key" "text" NOT NULL,
    "label" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_role_key_check" CHECK (("role_key" ~ '^[a-z_]+$'::"text"))
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "stripe_customer_id" "text" NOT NULL,
    "stripe_subscription_id" "text" NOT NULL,
    "quantity" integer NOT NULL,
    "status" "text" NOT NULL,
    "current_period_end" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "plan_id" "uuid"
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."template_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 99 NOT NULL,
    "is_predefined" boolean DEFAULT true NOT NULL,
    "org_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."template_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users_orgs" (
    "user_id" "uuid" NOT NULL,
    "org_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_id" "uuid" NOT NULL
);


ALTER TABLE "public"."users_orgs" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."user_orgs_expanded" AS
 SELECT "uo"."user_id",
    "uo"."org_id",
    "uo"."id",
    "uo"."role_id",
    "r"."role_key",
    "r"."label" AS "role_label"
   FROM ("public"."users_orgs" "uo"
     JOIN "public"."roles" "r" ON (("r"."id" = "uo"."role_id")));


ALTER VIEW "public"."user_orgs_expanded" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_errors"
    ADD CONSTRAINT "app_errors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."asset_inspection_templates"
    ADD CONSTRAINT "asset_inspection_templates_pkey" PRIMARY KEY ("asset_id", "inspection_template_id");



ALTER TABLE ONLY "public"."asset_statuses"
    ADD CONSTRAINT "asset_statuses_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."asset_statuses"
    ADD CONSTRAINT "asset_statuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumption_logs"
    ADD CONSTRAINT "consumption_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."defects"
    ADD CONSTRAINT "defects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_otp_codes"
    ADD CONSTRAINT "email_otp_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."entitlements"
    ADD CONSTRAINT "entitlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inspection_item_values"
    ADD CONSTRAINT "inspection_item_values_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inspection_items"
    ADD CONSTRAINT "inspection_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inspections"
    ADD CONSTRAINT "inspections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."operators"
    ADD CONSTRAINT "operators_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orgs"
    ADD CONSTRAINT "orgs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_stripe_session_id_key" UNIQUE ("stripe_session_id");



ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_stripe_price_id_key" UNIQUE ("stripe_price_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_role_key_key" UNIQUE ("role_key");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."template_categories"
    ADD CONSTRAINT "template_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inspection_templates"
    ADD CONSTRAINT "templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."template_categories"
    ADD CONSTRAINT "uq_template_category_name_org" UNIQUE NULLS NOT DISTINCT ("name", "org_id");



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "users_orgs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "users_orgs_user_org_unique" UNIQUE ("user_id", "org_id");



CREATE INDEX "assets_org_name_idx" ON "public"."assets" USING "btree" ("org_id", "name");



CREATE UNIQUE INDEX "entitlements_org_active_uidx" ON "public"."entitlements" USING "btree" ("org_id") WHERE ("status" = 'active'::"public"."entitlement_status");



CREATE UNIQUE INDEX "entitlements_org_source_uidx" ON "public"."entitlements" USING "btree" ("org_id", "source_ref");



CREATE INDEX "entitlements_source_ref_idx" ON "public"."entitlements" USING "btree" ("source_ref");



CREATE INDEX "idx_asset_templates_template" ON "public"."asset_inspection_templates" USING "btree" ("inspection_template_id");



CREATE INDEX "idx_assets_org" ON "public"."assets" USING "btree" ("org_id");



CREATE INDEX "idx_consumption_org" ON "public"."consumption_logs" USING "btree" ("org_id");



CREATE INDEX "idx_defects_org" ON "public"."defects" USING "btree" ("org_id");



CREATE INDEX "idx_email_otp_challenge" ON "public"."email_otp_codes" USING "btree" ("challenge_id");



CREATE INDEX "idx_email_otp_user" ON "public"."email_otp_codes" USING "btree" ("user_id");



CREATE INDEX "idx_files_org" ON "public"."files" USING "btree" ("org_id");



CREATE INDEX "idx_inspection_items_inspection_id" ON "public"."inspection_items" USING "btree" ("inspection_id");



CREATE INDEX "idx_inspections_org" ON "public"."inspections" USING "btree" ("org_id");



CREATE INDEX "idx_it_category_id" ON "public"."inspection_templates" USING "btree" ("category_id");



CREATE INDEX "idx_it_created_at" ON "public"."inspection_templates" USING "btree" ("created_at");



CREATE INDEX "idx_it_is_predefined" ON "public"."inspection_templates" USING "btree" ("is_predefined");



CREATE INDEX "idx_it_org_id" ON "public"."inspection_templates" USING "btree" ("org_id");



CREATE INDEX "idx_it_org_pre" ON "public"."inspection_templates" USING "btree" ("org_id", "is_predefined");



CREATE INDEX "idx_it_trgm_name" ON "public"."inspection_templates" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_item_values_inspection_item_id" ON "public"."inspection_item_values" USING "btree" ("inspection_item_id");



CREATE INDEX "idx_item_values_key" ON "public"."inspection_item_values" USING "btree" ("key");



CREATE INDEX "idx_payments_invoice" ON "public"."payments" USING "btree" ("stripe_invoice_id");



CREATE INDEX "idx_payments_org_id" ON "public"."payments" USING "btree" ("org_id");



CREATE INDEX "idx_payments_pi" ON "public"."payments" USING "btree" ("stripe_payment_intent_id");



CREATE INDEX "idx_payments_session" ON "public"."payments" USING "btree" ("stripe_session_id");



CREATE INDEX "idx_plans_code" ON "public"."plans" USING "btree" ("lower"("code"));



CREATE INDEX "idx_subs_org" ON "public"."subscriptions" USING "btree" ("org_id");



CREATE INDEX "idx_templates_org" ON "public"."inspection_templates" USING "btree" ("org_id");



CREATE INDEX "idx_users_orgs_org" ON "public"."users_orgs" USING "btree" ("org_id");



CREATE INDEX "idx_users_orgs_user" ON "public"."users_orgs" USING "btree" ("user_id");



CREATE UNIQUE INDEX "uix_payments_invoice" ON "public"."payments" USING "btree" ("stripe_invoice_id");



CREATE UNIQUE INDEX "uix_payments_pi" ON "public"."payments" USING "btree" ("stripe_payment_intent_id");



CREATE UNIQUE INDEX "uix_payments_session" ON "public"."payments" USING "btree" ("stripe_session_id");



CREATE UNIQUE INDEX "uix_roles_code" ON "public"."roles" USING "btree" ("role_key");



CREATE UNIQUE INDEX "uix_user_orgs_user_org" ON "public"."users_orgs" USING "btree" ("user_id", "org_id");



CREATE UNIQUE INDEX "uniq_assets_org_name_active" ON "public"."assets" USING "btree" ("org_id", "name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "user_orgs_org_role_idx" ON "public"."users_orgs" USING "btree" ("org_id", "role_id");



CREATE UNIQUE INDEX "user_orgs_user_org_uidx" ON "public"."users_orgs" USING "btree" ("user_id", "org_id");



CREATE UNIQUE INDEX "users_orgs_user_org_uniq" ON "public"."users_orgs" USING "btree" ("user_id", "org_id");



CREATE UNIQUE INDEX "ux_subs_stripe_sub_id" ON "public"."subscriptions" USING "btree" ("stripe_subscription_id");



CREATE OR REPLACE TRIGGER "assets_stamp_bi" BEFORE INSERT ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."stamp_assets"();



CREATE OR REPLACE TRIGGER "assets_stamp_bu" BEFORE UPDATE ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."stamp_assets"();



CREATE OR REPLACE TRIGGER "entitlements_updated_at" BEFORE UPDATE ON "public"."entitlements" FOR EACH ROW EXECUTE FUNCTION "public"."tg_entitlements_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_app_users" AFTER INSERT OR DELETE OR UPDATE ON "public"."app_users" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_assets" AFTER INSERT OR DELETE OR UPDATE ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_consumption_logs" AFTER INSERT OR DELETE OR UPDATE ON "public"."consumption_logs" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_defects" AFTER INSERT OR DELETE OR UPDATE ON "public"."defects" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_files" AFTER INSERT OR DELETE OR UPDATE ON "public"."files" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_inspections" AFTER INSERT OR DELETE OR UPDATE ON "public"."inspections" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_operators" AFTER INSERT OR DELETE OR UPDATE ON "public"."operators" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_orgs" AFTER INSERT OR DELETE OR UPDATE ON "public"."orgs" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_audit_templates" AFTER INSERT OR DELETE OR UPDATE ON "public"."inspection_templates" FOR EACH ROW EXECUTE FUNCTION "public"."log_change"();



CREATE OR REPLACE TRIGGER "trg_enforce_asset_limit" BEFORE INSERT ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_asset_limit"();



CREATE OR REPLACE TRIGGER "trg_stamp_asset_statuses" BEFORE UPDATE ON "public"."asset_statuses" FOR EACH ROW EXECUTE FUNCTION "public"."stamp_asset_statuses"();



CREATE OR REPLACE TRIGGER "update_inspection_item_values_updated_at" BEFORE UPDATE ON "public"."inspection_item_values" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_inspection_items_updated_at" BEFORE UPDATE ON "public"."inspection_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_inspections_updated_at" BEFORE UPDATE ON "public"."inspections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."app_errors"
    ADD CONSTRAINT "app_errors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."asset_inspection_templates"
    ADD CONSTRAINT "asset_inspection_templates_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."asset_inspection_templates"
    ADD CONSTRAINT "asset_inspection_templates_inspection_template_id_fkey" FOREIGN KEY ("inspection_template_id") REFERENCES "public"."inspection_templates"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumption_logs"
    ADD CONSTRAINT "consumption_logs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumption_logs"
    ADD CONSTRAINT "consumption_logs_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."defects"
    ADD CONSTRAINT "defects_inspection_id_fkey" FOREIGN KEY ("inspection_id") REFERENCES "public"."inspections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."defects"
    ADD CONSTRAINT "defects_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."entitlements"
    ADD CONSTRAINT "entitlements_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."entitlements"
    ADD CONSTRAINT "entitlements_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");



ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "fk_assets_status" FOREIGN KEY ("status_id") REFERENCES "public"."asset_statuses"("id");



ALTER TABLE ONLY "public"."inspection_templates"
    ADD CONSTRAINT "fk_templates_created_by" FOREIGN KEY ("created_by") REFERENCES "public"."app_users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inspection_item_values"
    ADD CONSTRAINT "inspection_item_values_inspection_item_id_fkey" FOREIGN KEY ("inspection_item_id") REFERENCES "public"."inspection_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inspection_items"
    ADD CONSTRAINT "inspection_items_inspection_id_fkey" FOREIGN KEY ("inspection_id") REFERENCES "public"."inspections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inspection_templates"
    ADD CONSTRAINT "inspection_templates_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."template_categories"("id");



ALTER TABLE ONLY "public"."inspections"
    ADD CONSTRAINT "inspections_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inspections"
    ADD CONSTRAINT "inspections_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inspections"
    ADD CONSTRAINT "inspections_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."inspection_templates"("id");



ALTER TABLE ONLY "public"."operators"
    ADD CONSTRAINT "operators_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orgs"
    ADD CONSTRAINT "orgs_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");



ALTER TABLE ONLY "public"."template_categories"
    ADD CONSTRAINT "template_categories_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inspection_templates"
    ADD CONSTRAINT "templates_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "user_orgs_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "users_orgs_org_fk" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "users_orgs_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."orgs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_orgs"
    ADD CONSTRAINT "users_orgs_user_fk" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow users to assign templates to assets" ON "public"."asset_inspection_templates" FOR INSERT WITH CHECK ((("asset_id" IN ( SELECT "a"."id"
   FROM ("public"."assets" "a"
     JOIN "public"."users_orgs" "uo" ON (("uo"."org_id" = "a"."org_id")))
  WHERE ("uo"."user_id" = "auth"."uid"()))) AND (("inspection_template_id" IN ( SELECT "it"."id"
   FROM ("public"."inspection_templates" "it"
     JOIN "public"."users_orgs" "uo" ON (("uo"."org_id" = "it"."org_id")))
  WHERE ("uo"."user_id" = "auth"."uid"()))) OR ("inspection_template_id" IN ( SELECT "inspection_templates"."id"
   FROM "public"."inspection_templates"
  WHERE ("inspection_templates"."is_predefined" = true))))));



CREATE POLICY "Allow users to remove templates from assets" ON "public"."asset_inspection_templates" FOR DELETE USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Allow users to update their own template assignments" ON "public"."asset_inspection_templates" FOR UPDATE USING (("created_by" = "auth"."uid"())) WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "Allow users to view templates assigned to assets" ON "public"."asset_inspection_templates" FOR SELECT USING (("asset_id" IN ( SELECT "a"."id"
   FROM ("public"."assets" "a"
     JOIN "public"."users_orgs" "uo" ON (("uo"."org_id" = "a"."org_id")))
  WHERE ("uo"."user_id" = "auth"."uid"()))));



CREATE POLICY "Read templates" ON "public"."inspection_templates" FOR SELECT USING ((("org_id" = (("auth"."jwt"() ->> 'org_id'::"text"))::"uuid") OR ("is_predefined" = true)));



CREATE POLICY "admin_delete_any_template" ON "public"."inspection_templates" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "administrators can manage roles" ON "public"."roles" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."users_orgs" "uo"
     JOIN "public"."roles" "r" ON (("r"."id" = "uo"."role_id")))
  WHERE (("uo"."user_id" = "auth"."uid"()) AND ("r"."role_key" = 'administrator'::"text")))));



ALTER TABLE "public"."app_errors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_users_insert_own_row" ON "public"."app_users" FOR INSERT TO "authenticated" WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "app_users_select_own_row" ON "public"."app_users" FOR SELECT TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "app_users_update_own_row" ON "public"."app_users" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."asset_inspection_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."asset_statuses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."assets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "authenticated can read roles" ON "public"."roles" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."consumption_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."defects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "delete_org_templates" ON "public"."inspection_templates" FOR DELETE TO "authenticated" USING ((("is_predefined" = false) AND ("org_id" IN ( SELECT "uo"."org_id"
   FROM "public"."users_orgs" "uo"
  WHERE ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "delete_own_inspection_item_values" ON "public"."inspection_item_values" FOR DELETE USING (("inspection_item_id" IN ( SELECT "ii"."id"
   FROM ("public"."inspection_items" "ii"
     JOIN "public"."inspections" "i" ON (("i"."id" = "ii"."inspection_id")))
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "delete_own_inspection_items" ON "public"."inspection_items" FOR DELETE USING (("inspection_id" IN ( SELECT "i"."id"
   FROM "public"."inspections" "i"
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



ALTER TABLE "public"."email_otp_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."entitlements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "entitlements.noclientwrite" ON "public"."entitlements" TO "authenticated" USING (false) WITH CHECK (false);



CREATE POLICY "entitlements.select.members" ON "public"."entitlements" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."users_orgs" "uo"
  WHERE (("uo"."org_id" = "entitlements"."org_id") AND ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "errors_insert_self" ON "public"."app_errors" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."files" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ins_assets" ON "public"."assets" FOR INSERT TO "authenticated" WITH CHECK (("org_id" = "app"."org_id"()));



CREATE POLICY "insert org templates" ON "public"."inspection_templates" FOR INSERT TO "authenticated" WITH CHECK ((("is_predefined" = false) AND ("org_id" = ((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'org_id'::"text"))::"uuid") AND ("created_by" = "auth"."uid"())));



CREATE POLICY "insert_org_template_categories" ON "public"."template_categories" FOR INSERT WITH CHECK ((("is_predefined" = false) AND ("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))));



CREATE POLICY "insert_org_templates" ON "public"."inspection_templates" FOR INSERT TO "authenticated" WITH CHECK ((("is_predefined" = false) AND ("org_id" IN ( SELECT "uo"."org_id"
   FROM "public"."users_orgs" "uo"
  WHERE ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "insert_own_inspection_item_values" ON "public"."inspection_item_values" FOR INSERT WITH CHECK (("inspection_item_id" IN ( SELECT "ii"."id"
   FROM ("public"."inspection_items" "ii"
     JOIN "public"."inspections" "i" ON (("i"."id" = "ii"."inspection_id")))
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "insert_own_inspection_items" ON "public"."inspection_items" FOR INSERT WITH CHECK (("inspection_id" IN ( SELECT "i"."id"
   FROM "public"."inspections" "i"
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



ALTER TABLE "public"."inspection_item_values" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inspection_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inspection_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inspections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."operators" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org can read its payments" ON "public"."payments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."users_orgs" "uo"
  WHERE (("uo"."org_id" = "payments"."org_id") AND ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "org member can read own org" ON "public"."orgs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."users_orgs" "uo"
  WHERE (("uo"."org_id" = "orgs"."id") AND ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "org member delete on assets" ON "public"."assets" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member delete on consumption_logs" ON "public"."consumption_logs" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member delete on defects" ON "public"."defects" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member delete on files" ON "public"."files" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member delete on inspections" ON "public"."inspections" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member delete on operators" ON "public"."operators" FOR DELETE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on assets" ON "public"."assets" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on consumption_logs" ON "public"."consumption_logs" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on defects" ON "public"."defects" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on files" ON "public"."files" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on inspections" ON "public"."inspections" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member insert on operators" ON "public"."operators" FOR INSERT WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on assets" ON "public"."assets" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on consumption_logs" ON "public"."consumption_logs" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on defects" ON "public"."defects" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on files" ON "public"."files" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on inspections" ON "public"."inspections" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member select on operators" ON "public"."operators" FOR SELECT USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on assets" ON "public"."assets" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on consumption_logs" ON "public"."consumption_logs" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on defects" ON "public"."defects" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on files" ON "public"."files" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on inspections" ON "public"."inspections" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org member update on operators" ON "public"."operators" FOR UPDATE USING (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))) WITH CHECK (("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"()))));



CREATE POLICY "org members can read each other" ON "public"."app_users" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."users_orgs" "u_me"
     JOIN "public"."users_orgs" "u_them" ON ((("u_them"."user_id" = "app_users"."id") AND ("u_them"."org_id" = "u_me"."org_id"))))
  WHERE ("u_me"."user_id" = "auth"."uid"()))));



ALTER TABLE "public"."orgs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."plans" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "plans are readable by all users" ON "public"."plans" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "read asset statuses" ON "public"."asset_statuses" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "read own app_user" ON "public"."app_users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "read_template_categories" ON "public"."template_categories" FOR SELECT USING ((("is_predefined" = true) OR ("org_id" IN ( SELECT "users_orgs"."org_id"
   FROM "public"."users_orgs"
  WHERE ("users_orgs"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sel_assets" ON "public"."assets" FOR SELECT TO "authenticated" USING ((("deleted_at" IS NULL) AND ("org_id" = "app"."org_id"())));



CREATE POLICY "select_own_inspection_item_values" ON "public"."inspection_item_values" FOR SELECT USING (("inspection_item_id" IN ( SELECT "ii"."id"
   FROM ("public"."inspection_items" "ii"
     JOIN "public"."inspections" "i" ON (("i"."id" = "ii"."inspection_id")))
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "select_own_inspection_items" ON "public"."inspection_items" FOR SELECT USING (("inspection_id" IN ( SELECT "i"."id"
   FROM "public"."inspections" "i"
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "select_visible_templates" ON "public"."inspection_templates" FOR SELECT TO "authenticated" USING (("is_active" AND ("is_predefined" OR ("org_id" IN ( SELECT "uo"."org_id"
   FROM "public"."users_orgs" "uo"
  WHERE ("uo"."user_id" = "auth"."uid"()))))));



ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."template_categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "upd_assets" ON "public"."assets" FOR UPDATE TO "authenticated" USING (("org_id" = "app"."org_id"())) WITH CHECK (("org_id" = "app"."org_id"()));



CREATE POLICY "update own app_user" ON "public"."app_users" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "update_org_templates" ON "public"."inspection_templates" FOR UPDATE TO "authenticated" USING ((("is_predefined" = false) AND ("org_id" IN ( SELECT "uo"."org_id"
   FROM "public"."users_orgs" "uo"
  WHERE ("uo"."user_id" = "auth"."uid"()))))) WITH CHECK ((("is_predefined" = false) AND ("org_id" IN ( SELECT "uo"."org_id"
   FROM "public"."users_orgs" "uo"
  WHERE ("uo"."user_id" = "auth"."uid"())))));



CREATE POLICY "update_own_inspection_item_values" ON "public"."inspection_item_values" FOR UPDATE USING (("inspection_item_id" IN ( SELECT "ii"."id"
   FROM ("public"."inspection_items" "ii"
     JOIN "public"."inspections" "i" ON (("i"."id" = "ii"."inspection_id")))
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"())))))) WITH CHECK (("inspection_item_id" IN ( SELECT "ii"."id"
   FROM ("public"."inspection_items" "ii"
     JOIN "public"."inspections" "i" ON (("i"."id" = "ii"."inspection_id")))
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "update_own_inspection_items" ON "public"."inspection_items" FOR UPDATE USING (("inspection_id" IN ( SELECT "i"."id"
   FROM "public"."inspections" "i"
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"())))))) WITH CHECK (("inspection_id" IN ( SELECT "i"."id"
   FROM "public"."inspections" "i"
  WHERE ("i"."org_id" IN ( SELECT "uo"."org_id"
           FROM "public"."users_orgs" "uo"
          WHERE ("uo"."user_id" = "auth"."uid"()))))));



CREATE POLICY "user can read own memberships" ON "public"."users_orgs" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "users can view their org subscriptions" ON "public"."subscriptions" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."users_orgs" "uo"
  WHERE (("uo"."user_id" = "auth"."uid"()) AND ("uo"."org_id" = "subscriptions"."org_id")))));



ALTER TABLE "public"."users_orgs" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."subscriptions";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."asset_restore"("p_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."asset_restore"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."asset_restore"("p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."asset_soft_delete"("p_id" "uuid", "p_reason" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."asset_soft_delete"("p_id" "uuid", "p_reason" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."asset_soft_delete"("p_id" "uuid", "p_reason" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."asset_status_id"("p_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."asset_status_id"("p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."asset_status_id"("p_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."bootstrap"() TO "anon";
GRANT ALL ON FUNCTION "public"."bootstrap"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."bootstrap"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_asset_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_asset_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_asset_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_category" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_category" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_inspection_templates"("p_org" "uuid", "p_scope" "text", "p_q" "text", "p_category" "text", "p_sort_by" "text", "p_sort_dir" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."stamp_asset_statuses"() TO "anon";
GRANT ALL ON FUNCTION "public"."stamp_asset_statuses"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."stamp_asset_statuses"() TO "service_role";



GRANT ALL ON FUNCTION "public"."stamp_assets"() TO "anon";
GRANT ALL ON FUNCTION "public"."stamp_assets"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."stamp_assets"() TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."tg_entitlements_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."tg_entitlements_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tg_entitlements_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_onboarding_v2"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_plan" "text", "p_stage" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_onboarding_v2"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_plan" "text", "p_stage" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_onboarding_v2"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_plan" "text", "p_stage" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_onboarding_v3"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_first_name" "text", "p_primary_contact_last_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_stage" "text", "p_billing_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_onboarding_v3"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_first_name" "text", "p_primary_contact_last_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_stage" "text", "p_billing_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_onboarding_v3"("p_first_name" "text", "p_middle_name" "text", "p_last_name" "text", "p_gender" "text", "p_dob" "date", "p_org_id" "uuid", "p_org_name" "text", "p_street" "text", "p_city" "text", "p_state" "text", "p_postal" "text", "p_country" "text", "p_primary_contact_first_name" "text", "p_primary_contact_last_name" "text", "p_primary_contact_email" "text", "p_primary_contact_phone" "text", "p_stage" "text", "p_billing_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";


















GRANT ALL ON TABLE "public"."app_errors" TO "anon";
GRANT ALL ON TABLE "public"."app_errors" TO "authenticated";
GRANT ALL ON TABLE "public"."app_errors" TO "service_role";



GRANT ALL ON TABLE "public"."app_users" TO "anon";
GRANT ALL ON TABLE "public"."app_users" TO "authenticated";
GRANT ALL ON TABLE "public"."app_users" TO "service_role";



GRANT ALL ON TABLE "public"."app_users_v" TO "anon";
GRANT ALL ON TABLE "public"."app_users_v" TO "authenticated";
GRANT ALL ON TABLE "public"."app_users_v" TO "service_role";



GRANT ALL ON TABLE "public"."asset_inspection_templates" TO "anon";
GRANT ALL ON TABLE "public"."asset_inspection_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."asset_inspection_templates" TO "service_role";



GRANT ALL ON TABLE "public"."asset_statuses" TO "anon";
GRANT ALL ON TABLE "public"."asset_statuses" TO "authenticated";
GRANT ALL ON TABLE "public"."asset_statuses" TO "service_role";



GRANT ALL ON TABLE "public"."assets" TO "anon";
GRANT ALL ON TABLE "public"."assets" TO "authenticated";
GRANT ALL ON TABLE "public"."assets" TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "anon";
GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."consumption_logs" TO "anon";
GRANT ALL ON TABLE "public"."consumption_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."consumption_logs" TO "service_role";



GRANT ALL ON TABLE "public"."defects" TO "anon";
GRANT ALL ON TABLE "public"."defects" TO "authenticated";
GRANT ALL ON TABLE "public"."defects" TO "service_role";



GRANT ALL ON TABLE "public"."email_otp_codes" TO "anon";
GRANT ALL ON TABLE "public"."email_otp_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."email_otp_codes" TO "service_role";



GRANT ALL ON TABLE "public"."entitlements" TO "anon";
GRANT ALL ON TABLE "public"."entitlements" TO "authenticated";
GRANT ALL ON TABLE "public"."entitlements" TO "service_role";



GRANT ALL ON TABLE "public"."entitlements_current" TO "anon";
GRANT ALL ON TABLE "public"."entitlements_current" TO "authenticated";
GRANT ALL ON TABLE "public"."entitlements_current" TO "service_role";



GRANT ALL ON TABLE "public"."files" TO "anon";
GRANT ALL ON TABLE "public"."files" TO "authenticated";
GRANT ALL ON TABLE "public"."files" TO "service_role";



GRANT ALL ON TABLE "public"."inspection_item_values" TO "anon";
GRANT ALL ON TABLE "public"."inspection_item_values" TO "authenticated";
GRANT ALL ON TABLE "public"."inspection_item_values" TO "service_role";



GRANT ALL ON TABLE "public"."inspection_items" TO "anon";
GRANT ALL ON TABLE "public"."inspection_items" TO "authenticated";
GRANT ALL ON TABLE "public"."inspection_items" TO "service_role";



GRANT ALL ON TABLE "public"."inspection_templates" TO "anon";
GRANT ALL ON TABLE "public"."inspection_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."inspection_templates" TO "service_role";



GRANT ALL ON TABLE "public"."inspections" TO "anon";
GRANT ALL ON TABLE "public"."inspections" TO "authenticated";
GRANT ALL ON TABLE "public"."inspections" TO "service_role";



GRANT ALL ON TABLE "public"."operators" TO "anon";
GRANT ALL ON TABLE "public"."operators" TO "authenticated";
GRANT ALL ON TABLE "public"."operators" TO "service_role";



GRANT ALL ON TABLE "public"."orgs" TO "anon";
GRANT ALL ON TABLE "public"."orgs" TO "authenticated";
GRANT ALL ON TABLE "public"."orgs" TO "service_role";



GRANT ALL ON TABLE "public"."payments" TO "anon";
GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT ALL ON TABLE "public"."plans" TO "anon";
GRANT ALL ON TABLE "public"."plans" TO "authenticated";
GRANT ALL ON TABLE "public"."plans" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."template_categories" TO "anon";
GRANT ALL ON TABLE "public"."template_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."template_categories" TO "service_role";



GRANT ALL ON TABLE "public"."users_orgs" TO "anon";
GRANT ALL ON TABLE "public"."users_orgs" TO "authenticated";
GRANT ALL ON TABLE "public"."users_orgs" TO "service_role";



GRANT ALL ON TABLE "public"."user_orgs_expanded" TO "anon";
GRANT ALL ON TABLE "public"."user_orgs_expanded" TO "authenticated";
GRANT ALL ON TABLE "public"."user_orgs_expanded" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























