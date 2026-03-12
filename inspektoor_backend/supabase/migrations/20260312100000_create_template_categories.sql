-- ── Create template_categories lookup table ───────────────────────────────────

CREATE TABLE public.template_categories (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text        NOT NULL,
  description   text,
  sort_order    integer     NOT NULL DEFAULT 99,
  is_predefined boolean     NOT NULL DEFAULT true,
  org_id        uuid        REFERENCES public.organizations(id) ON DELETE CASCADE,
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

-- ── Migrate existing inspection_templates records ─────────────────────────────

UPDATE public.inspection_templates
SET category = CASE
  WHEN lower(category) IN ('vehicles','vehicle','truck','semi truck','car','van','trailer','motorcycle') THEN 'Vehicles'
  WHEN lower(category) IN ('heavy equipment','forklift','crane','excavator','loader')                    THEN 'Heavy Equipment'
  WHEN lower(category) IN ('facility','facilities','warehouse','building','office','retail')             THEN 'Facilities'
  WHEN lower(category) IN ('electrical','electrical systems','generator','switchboard','panel','ups')    THEN 'Electrical Systems'
  WHEN lower(category) IN ('hvac','air conditioning','heating','ventilation','chiller')                  THEN 'HVAC'
  WHEN lower(category) IN ('safety','safety equipment','ppe','fire extinguisher','harness','first aid')  THEN 'Safety Equipment'
  WHEN lower(category) IN ('plumbing','pipes','pump','pumps','water heater','drainage')                  THEN 'Plumbing'
  WHEN lower(category) IN ('it','it & technology','technology','servers','computers','network')          THEN 'IT & Technology'
  WHEN lower(category) IN ('construction','scaffolding','site','site equipment')                         THEN 'Construction'
  ELSE 'Other'
END
WHERE category IS NOT NULL;

-- Null category → Other
UPDATE public.inspection_templates
SET category = 'Other'
WHERE category IS NULL;
