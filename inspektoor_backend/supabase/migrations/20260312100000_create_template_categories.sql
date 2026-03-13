-- ── Create template_categories lookup table ───────────────────────────────────

CREATE TABLE public.template_categories (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text        NOT NULL,
  description   text,
  sort_order    integer     NOT NULL DEFAULT 99,
  is_predefined boolean     NOT NULL DEFAULT true,
  org_id        uuid        REFERENCES public.orgs(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_template_category_name_org
    UNIQUE NULLS NOT DISTINCT (name, org_id)
);

ALTER TABLE public.template_categories ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read global categories + their org's categories
CREATE POLICY "read_template_categories" ON public.template_categories
  FOR SELECT USING (
    is_predefined = true
    OR org_id IN (
      SELECT org_id FROM public.users_orgs
      WHERE user_id = auth.uid()
    )
  );

-- Org members can add custom categories scoped to their org
CREATE POLICY "insert_org_template_categories" ON public.template_categories
  FOR INSERT WITH CHECK (
    is_predefined = false
    AND org_id IN (
      SELECT org_id FROM public.users_orgs
      WHERE user_id = auth.uid()
    )
  );

-- ── Seed predefined categories ────────────────────────────────────────────────

INSERT INTO public.template_categories
  (name, description, sort_order, is_predefined, org_id)
VALUES
  ('Vehicles',           'Cars, trucks, vans, trailers, motorcycles',           1,  true, NULL),
  ('Heavy Equipment',    'Forklifts, cranes, excavators, loaders',              2,  true, NULL),
  ('Facilities',         'Buildings, warehouses, offices, retail spaces',       3,  true, NULL),
  ('Electrical Systems', 'Generators, switchboards, panels, UPS units',         4,  true, NULL),
  ('HVAC',               'Air conditioning, heating, ventilation, chillers',    5,  true, NULL),
  ('Safety Equipment',   'Fire extinguishers, harnesses, PPE, first-aid kits',  6,  true, NULL),
  ('Plumbing',           'Pipes, pumps, water heaters, drainage systems',       7,  true, NULL),
  ('IT & Technology',    'Servers, computers, network gear, surveillance',      8,  true, NULL),
  ('Construction',       'Scaffolding, site equipment, temporary structures',   9,  true, NULL),
  ('Other',              'Templates that do not fit a specific category',       99, true, NULL);

-- ── Add category_id FK to inspection_templates ────────────────────────────────

ALTER TABLE public.inspection_templates
  ADD COLUMN category_id uuid REFERENCES public.template_categories(id);

-- ── Populate category_id by matching existing text values ─────────────────────

UPDATE public.inspection_templates it
SET category_id = tc.id
FROM public.template_categories tc
WHERE tc.org_id IS NULL  -- predefined only
  AND tc.name = CASE
    WHEN lower(it.category) IN ('vehicles','vehicle','truck','semi truck','car','van','trailer','motorcycle') THEN 'Vehicles'
    WHEN lower(it.category) IN ('heavy equipment','forklift','crane','excavator','loader')                    THEN 'Heavy Equipment'
    WHEN lower(it.category) IN ('facility','facilities','warehouse','building','office','retail')             THEN 'Facilities'
    WHEN lower(it.category) IN ('electrical','electrical systems','generator','switchboard','panel','ups')    THEN 'Electrical Systems'
    WHEN lower(it.category) IN ('hvac','air conditioning','heating','ventilation','chiller')                  THEN 'HVAC'
    WHEN lower(it.category) IN ('safety','safety equipment','ppe','fire extinguisher','harness','first aid')  THEN 'Safety Equipment'
    WHEN lower(it.category) IN ('plumbing','pipes','pump','pumps','water heater','drainage')                  THEN 'Plumbing'
    WHEN lower(it.category) IN ('it','it & technology','technology','servers','computers','network')          THEN 'IT & Technology'
    WHEN lower(it.category) IN ('construction','scaffolding','site','site equipment')                         THEN 'Construction'
    ELSE 'Other'
  END;

-- ── Any rows still without a category_id → Other ─────────────────────────────

UPDATE public.inspection_templates it
SET category_id = tc.id
FROM public.template_categories tc
WHERE tc.name = 'Other'
  AND tc.org_id IS NULL
  AND it.category_id IS NULL;

-- ── Enforce NOT NULL, drop old column and indexes ─────────────────────────────

ALTER TABLE public.inspection_templates
  ALTER COLUMN category_id SET NOT NULL;

-- Drop old text-based indexes (referenced the now-removed text column)
DROP INDEX IF EXISTS public.idx_it_fts;
DROP INDEX IF EXISTS public.idx_it_trgm_category;

-- Drop the denormalized text column
ALTER TABLE public.inspection_templates DROP COLUMN category;

-- Fast FK lookup index
CREATE INDEX idx_it_category_id ON public.inspection_templates (category_id);

-- ── Update search_inspection_templates RPC ────────────────────────────────────
-- Adds p_category parameter, JOINs template_categories, returns tc.name AS category,
-- fixes p_scope default (ELSE now includes org + predefined), and enables
-- proper category chip filtering.

CREATE OR REPLACE FUNCTION public.search_inspection_templates(
  p_org       uuid,
  p_scope     text,
  p_q         text,
  p_category  text    DEFAULT NULL,
  p_sort_by   text    DEFAULT 'created_at',
  p_sort_dir  text    DEFAULT 'desc',
  p_limit     integer DEFAULT 25,
  p_offset    integer DEFAULT 0
) RETURNS TABLE (
  id                 uuid,
  org_id             uuid,
  name               text,
  category           text,
  category_id        uuid,
  schema             jsonb,
  version            integer,
  is_active          boolean,
  created_at         timestamptz,
  is_predefined      boolean,
  created_by         uuid,
  creator_first_name text,
  creator_last_name  text
) LANGUAGE sql STABLE AS $$
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
