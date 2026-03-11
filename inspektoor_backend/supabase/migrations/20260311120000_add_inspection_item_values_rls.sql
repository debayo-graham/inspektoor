-- inspection_item_values has RLS enabled but zero policies.
-- This migration adds CRUD policies matching the pattern used on
-- inspection_items (org membership via inspections.org_id).

-- INSERT
CREATE POLICY "insert_own_inspection_item_values"
  ON "public"."inspection_item_values"
  FOR INSERT
  WITH CHECK (
    "inspection_item_id" IN (
      SELECT ii.id FROM inspection_items ii
      JOIN inspections i ON i.id = ii.inspection_id
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- SELECT
CREATE POLICY "select_own_inspection_item_values"
  ON "public"."inspection_item_values"
  FOR SELECT
  USING (
    "inspection_item_id" IN (
      SELECT ii.id FROM inspection_items ii
      JOIN inspections i ON i.id = ii.inspection_id
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- UPDATE
CREATE POLICY "update_own_inspection_item_values"
  ON "public"."inspection_item_values"
  FOR UPDATE
  USING (
    "inspection_item_id" IN (
      SELECT ii.id FROM inspection_items ii
      JOIN inspections i ON i.id = ii.inspection_id
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    "inspection_item_id" IN (
      SELECT ii.id FROM inspection_items ii
      JOIN inspections i ON i.id = ii.inspection_id
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );

-- DELETE
CREATE POLICY "delete_own_inspection_item_values"
  ON "public"."inspection_item_values"
  FOR DELETE
  USING (
    "inspection_item_id" IN (
      SELECT ii.id FROM inspection_items ii
      JOIN inspections i ON i.id = ii.inspection_id
      WHERE i.org_id IN (
        SELECT uo.org_id FROM users_orgs uo WHERE uo.user_id = auth.uid()
      )
    )
  );
