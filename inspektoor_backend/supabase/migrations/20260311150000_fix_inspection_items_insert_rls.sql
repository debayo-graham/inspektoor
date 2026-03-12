-- All four RLS policies on inspection_items use auth.jwt() ->> 'org_id'
-- which requires a custom JWT claim that doesn't exist. Replace them with
-- the same users_orgs pattern used by inspections and inspection_item_values.

-- INSERT
DROP POLICY IF EXISTS "insert_own_inspection_items" ON "public"."inspection_items";
CREATE POLICY "insert_own_inspection_items"
  ON "public"."inspection_items"
  FOR INSERT
  WITH CHECK (
    "inspection_id" IN (
      SELECT i.id FROM inspections i
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- SELECT
DROP POLICY IF EXISTS "select_own_inspection_items" ON "public"."inspection_items";
CREATE POLICY "select_own_inspection_items"
  ON "public"."inspection_items"
  FOR SELECT
  USING (
    "inspection_id" IN (
      SELECT i.id FROM inspections i
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- UPDATE
DROP POLICY IF EXISTS "update_own_inspection_items" ON "public"."inspection_items";
CREATE POLICY "update_own_inspection_items"
  ON "public"."inspection_items"
  FOR UPDATE
  USING (
    "inspection_id" IN (
      SELECT i.id FROM inspections i
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    "inspection_id" IN (
      SELECT i.id FROM inspections i
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- DELETE
DROP POLICY IF EXISTS "delete_own_inspection_items" ON "public"."inspection_items";
CREATE POLICY "delete_own_inspection_items"
  ON "public"."inspection_items"
  FOR DELETE
  USING (
    "inspection_id" IN (
      SELECT i.id FROM inspections i
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );
