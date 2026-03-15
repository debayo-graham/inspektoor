-- Add status column to inspection_items
-- Tracks whether the inspector completed or skipped each item.
-- Plain text with CHECK constraint (only 2–3 values, no lookup table needed).

ALTER TABLE inspection_items
  ADD COLUMN status text NOT NULL DEFAULT 'completed'
  CONSTRAINT inspection_items_status_check
    CHECK (status IN ('completed', 'skipped'));

-- Backfill existing skipped items from sentinel value rows
UPDATE inspection_items ii
SET status = 'skipped'
WHERE EXISTS (
  SELECT 1 FROM inspection_item_values iv
  WHERE iv.inspection_item_id = ii.id
    AND iv.key = 'skipped'
    AND iv.value = 'skipped'
);
