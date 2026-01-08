-- ============================================
-- Admin Features Database Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- PHASE 1: Fix Ordering System
-- ============================================

-- 1.1 Add display_order to articles table
ALTER TABLE articles ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_articles_display_order ON articles(display_order);

-- 1.2 Rename 'order' to 'display_order' for consistency
-- Note: Check if columns exist before renaming to avoid errors
DO $$
BEGIN
  -- paths table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'paths' AND column_name = 'order') THEN
    ALTER TABLE paths RENAME COLUMN "order" TO display_order;
  END IF;
  
  -- sections table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sections' AND column_name = 'order') THEN
    ALTER TABLE sections RENAME COLUMN "order" TO display_order;
  END IF;
  
  -- branches table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branches' AND column_name = 'order') THEN
    ALTER TABLE branches RENAME COLUMN "order" TO display_order;
  END IF;
  
  -- topics table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'topics' AND column_name = 'order') THEN
    ALTER TABLE topics RENAME COLUMN "order" TO display_order;
  END IF;
  
  -- content_items table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'content_items' AND column_name = 'order') THEN
    ALTER TABLE content_items RENAME COLUMN "order" TO display_order;
  END IF;
  
  -- article_items table
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'article_items' AND column_name = 'order') THEN
    ALTER TABLE article_items RENAME COLUMN "order" TO display_order;
  END IF;
END $$;

-- 1.3 Ensure display_order columns exist with proper defaults
ALTER TABLE paths ALTER COLUMN display_order SET DEFAULT 0;
ALTER TABLE sections ALTER COLUMN display_order SET DEFAULT 0;
ALTER TABLE branches ALTER COLUMN display_order SET DEFAULT 0;
ALTER TABLE topics ALTER COLUMN display_order SET DEFAULT 0;
ALTER TABLE content_items ALTER COLUMN display_order SET DEFAULT 0;

-- For article_items, keep 'order' column as well for backwards compatibility
ALTER TABLE article_items ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Sync existing order values to display_order if article_items has an 'order' column
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'article_items' AND column_name = 'order') THEN
    UPDATE article_items SET display_order = COALESCE("order", 0) WHERE display_order = 0 AND "order" IS NOT NULL;
  END IF;
END $$;

-- 1.4 Create atomic swap function for ordering
CREATE OR REPLACE FUNCTION swap_display_order(
  p_table TEXT,
  p_id1 UUID,
  p_order1 INTEGER,
  p_id2 UUID,
  p_order2 INTEGER
) RETURNS VOID AS $$
BEGIN
  -- Validate table name (security measure)
  IF p_table NOT IN ('languages', 'paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items') THEN
    RAISE EXCEPTION 'Invalid table name: %', p_table;
  END IF;
  
  -- Perform atomic swap
  EXECUTE format('UPDATE %I SET display_order = $1, updated_at = NOW() WHERE id = $2', p_table) USING p_order1, p_id1;
  EXECUTE format('UPDATE %I SET display_order = $1, updated_at = NOW() WHERE id = $2', p_table) USING p_order2, p_id2;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1.5 Create function to get next display order for new items
CREATE OR REPLACE FUNCTION get_next_display_order(
  p_table TEXT,
  p_parent_field TEXT,
  p_parent_id UUID
) RETURNS INTEGER AS $$
DECLARE
  v_max_order INTEGER;
BEGIN
  -- Validate table name (security measure)
  IF p_table NOT IN ('paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items') THEN
    RAISE EXCEPTION 'Invalid table name: %', p_table;
  END IF;
  
  EXECUTE format('SELECT COALESCE(MAX(display_order), -1) + 1 FROM %I WHERE %I = $1', p_table, p_parent_field)
    INTO v_max_order
    USING p_parent_id;
  
  RETURN v_max_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1.6 Create function to normalize display orders (fill gaps)
CREATE OR REPLACE FUNCTION normalize_display_order(
  p_table TEXT,
  p_parent_field TEXT,
  p_parent_id UUID
) RETURNS VOID AS $$
DECLARE
  v_record RECORD;
  v_new_order INTEGER := 0;
BEGIN
  -- Validate table name
  IF p_table NOT IN ('paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items') THEN
    RAISE EXCEPTION 'Invalid table name: %', p_table;
  END IF;
  
  -- Update each record with sequential order
  FOR v_record IN EXECUTE format(
    'SELECT id FROM %I WHERE %I = $1 ORDER BY display_order ASC', 
    p_table, p_parent_field
  ) USING p_parent_id
  LOOP
    EXECUTE format('UPDATE %I SET display_order = $1 WHERE id = $2', p_table)
      USING v_new_order, v_record.id;
    v_new_order := v_new_order + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PHASE 2: Soft Delete System Enhancement
-- ============================================

-- 2.1 Add soft delete columns to all content tables
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['languages', 'paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items'])
  LOOP
    -- Add is_deleted column
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false', t);
    
    -- Add deleted_at column
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE', t);
    
    -- Add deleted_by column
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS deleted_by UUID', t);
    
    -- Create index for faster queries
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_is_deleted ON %I(is_deleted)', t, t);
  END LOOP;
END $$;

-- 2.2 Create cascade soft delete function
CREATE OR REPLACE FUNCTION cascade_soft_delete(
  p_id UUID,
  p_table TEXT,
  p_deleted_by UUID DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
  v_child_table TEXT;
  v_parent_field TEXT;
  v_child_record RECORD;
  v_deleted_count INTEGER := 0;
  v_child_deleted INTEGER := 0;
BEGIN
  -- Mark this item as deleted
  EXECUTE format(
    'UPDATE %I SET is_deleted = true, deleted_at = NOW(), deleted_by = $1 WHERE id = $2',
    p_table
  ) USING p_deleted_by, p_id;
  v_deleted_count := 1;
  
  -- Determine child table based on hierarchy
  v_child_table := CASE p_table
    WHEN 'languages' THEN 'paths'
    WHEN 'paths' THEN 'sections'
    WHEN 'sections' THEN 'branches'
    WHEN 'branches' THEN 'topics'
    WHEN 'topics' THEN 'content_items'
    WHEN 'articles' THEN 'article_items'
    ELSE NULL
  END;
  
  -- Determine parent field name
  v_parent_field := CASE p_table
    WHEN 'languages' THEN 'language_id'
    WHEN 'paths' THEN 'path_id'
    WHEN 'sections' THEN 'section_id'
    WHEN 'branches' THEN 'branch_id'
    WHEN 'topics' THEN 'topic_id'
    WHEN 'articles' THEN 'article_id'
    ELSE NULL
  END;
  
  -- Recursively delete children
  IF v_child_table IS NOT NULL THEN
    FOR v_child_record IN EXECUTE format(
      'SELECT id FROM %I WHERE %I = $1 AND is_deleted = false',
      v_child_table, v_parent_field
    ) USING p_id
    LOOP
      SELECT cascade_soft_delete(v_child_record.id, v_child_table, p_deleted_by) INTO v_child_deleted;
      v_deleted_count := v_deleted_count + v_child_deleted;
    END LOOP;
  END IF;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2.3 Create restore function with parent validation
CREATE OR REPLACE FUNCTION restore_with_validation(
  p_id UUID,
  p_table TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_parent_table TEXT;
  v_parent_field TEXT;
  v_parent_id UUID;
  v_parent_deleted BOOLEAN;
BEGIN
  -- Determine parent table and field
  v_parent_table := CASE p_table
    WHEN 'paths' THEN 'languages'
    WHEN 'sections' THEN 'paths'
    WHEN 'branches' THEN 'sections'
    WHEN 'topics' THEN 'branches'
    WHEN 'content_items' THEN 'topics'
    WHEN 'article_items' THEN 'articles'
    ELSE NULL
  END;
  
  v_parent_field := CASE p_table
    WHEN 'paths' THEN 'language_id'
    WHEN 'sections' THEN 'path_id'
    WHEN 'branches' THEN 'section_id'
    WHEN 'topics' THEN 'branch_id'
    WHEN 'content_items' THEN 'topic_id'
    WHEN 'article_items' THEN 'article_id'
    ELSE NULL
  END;
  
  -- Check if parent exists and is not deleted
  IF v_parent_table IS NOT NULL THEN
    EXECUTE format('SELECT %I FROM %I WHERE id = $1', v_parent_field, p_table)
      INTO v_parent_id
      USING p_id;
    
    IF v_parent_id IS NOT NULL THEN
      EXECUTE format('SELECT is_deleted FROM %I WHERE id = $1', v_parent_table)
        INTO v_parent_deleted
        USING v_parent_id;
      
      IF v_parent_deleted = true THEN
        RAISE EXCEPTION 'Cannot restore: Parent item is deleted. Restore parent first.';
      END IF;
    END IF;
  END IF;
  
  -- Restore the item
  EXECUTE format(
    'UPDATE %I SET is_deleted = false, deleted_at = NULL, deleted_by = NULL WHERE id = $1',
    p_table
  ) USING p_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2.4 Create auto-purge function for old deleted items
CREATE OR REPLACE FUNCTION purge_old_deleted_items(
  p_retention_days INTEGER DEFAULT 30
) RETURNS TABLE(table_name TEXT, deleted_count INTEGER) AS $$
DECLARE
  t TEXT;
  v_deleted INTEGER;
BEGIN
  -- Process tables in order (children first to avoid FK violations)
  FOR t IN SELECT unnest(ARRAY[
    'content_items', 'article_items', 'topics', 'branches', 
    'sections', 'paths', 'languages', 'articles', 'content_references'
  ])
  LOOP
    EXECUTE format(
      'DELETE FROM %I WHERE is_deleted = true AND deleted_at < NOW() - INTERVAL ''%s days''',
      t, p_retention_days
    );
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    
    table_name := t;
    deleted_count := v_deleted;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PHASE 3: Content References System
-- ============================================

-- 3.1 Create content_references table
CREATE TABLE IF NOT EXISTS content_references (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- The original content being referenced
  original_id UUID NOT NULL,
  original_table TEXT NOT NULL CHECK (original_table IN ('articles', 'article_items', 'content_items', 'topics', 'branches', 'sections', 'paths')),
  
  -- Where this reference appears
  parent_id UUID NOT NULL,
  parent_table TEXT NOT NULL,
  parent_field TEXT NOT NULL, -- e.g., 'topic_id', 'article_id'
  
  -- Display properties
  display_order INTEGER DEFAULT 0,
  custom_title TEXT, -- Optional override title for this reference
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  
  -- Soft delete
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID,
  
  -- Orphan tracking (when original is deleted)
  is_orphaned BOOLEAN DEFAULT false,
  orphaned_at TIMESTAMP WITH TIME ZONE,
  
  -- Prevent duplicate references
  CONSTRAINT unique_reference UNIQUE(original_id, parent_id)
);

-- 3.2 Create indexes for content_references
CREATE INDEX IF NOT EXISTS idx_content_refs_original ON content_references(original_id);
CREATE INDEX IF NOT EXISTS idx_content_refs_parent ON content_references(parent_id);
CREATE INDEX IF NOT EXISTS idx_content_refs_deleted ON content_references(is_deleted);
CREATE INDEX IF NOT EXISTS idx_content_refs_orphaned ON content_references(is_orphaned);

-- 3.3 Create trigger to update updated_at
CREATE TRIGGER update_content_references_updated_at 
  BEFORE UPDATE ON content_references
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3.4 Create function to check if content has references
CREATE OR REPLACE FUNCTION has_references(
  p_content_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM content_references 
  WHERE original_id = p_content_id AND is_deleted = false;
  
  RETURN v_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.5 Create function to get all references for content
CREATE OR REPLACE FUNCTION get_references(
  p_content_id UUID
) RETURNS TABLE(
  ref_id UUID,
  parent_id UUID,
  parent_table TEXT,
  display_order INTEGER,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cr.id,
    cr.parent_id,
    cr.parent_table,
    cr.display_order,
    cr.created_at
  FROM content_references cr
  WHERE cr.original_id = p_content_id 
    AND cr.is_deleted = false
    AND cr.is_orphaned = false
  ORDER BY cr.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3.6 Create function to mark references as orphaned when original is deleted
CREATE OR REPLACE FUNCTION orphan_references_on_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- When content is soft-deleted, mark its references as orphaned
  IF NEW.is_deleted = true AND OLD.is_deleted = false THEN
    UPDATE content_references
    SET is_orphaned = true, orphaned_at = NOW()
    WHERE original_id = NEW.id;
  END IF;
  
  -- When content is restored, un-orphan its references
  IF NEW.is_deleted = false AND OLD.is_deleted = true THEN
    UPDATE content_references
    SET is_orphaned = false, orphaned_at = NULL
    WHERE original_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply orphan trigger to all content tables
CREATE TRIGGER orphan_refs_articles AFTER UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION orphan_references_on_delete();

CREATE TRIGGER orphan_refs_article_items AFTER UPDATE ON article_items
  FOR EACH ROW EXECUTE FUNCTION orphan_references_on_delete();

CREATE TRIGGER orphan_refs_content_items AFTER UPDATE ON content_items
  FOR EACH ROW EXECUTE FUNCTION orphan_references_on_delete();

CREATE TRIGGER orphan_refs_topics AFTER UPDATE ON topics
  FOR EACH ROW EXECUTE FUNCTION orphan_references_on_delete();

-- 3.7 RLS Policies for content_references
ALTER TABLE content_references ENABLE ROW LEVEL SECURITY;

-- Public can read non-deleted, non-orphaned references
CREATE POLICY "Public can read active references"
  ON content_references FOR SELECT
  USING (is_deleted = false AND is_orphaned = false);

-- Authenticated users can read all references
CREATE POLICY "Authenticated can read all references"
  ON content_references FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can manage references
CREATE POLICY "Authenticated can insert references"
  ON content_references FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated can update references"
  ON content_references FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated can delete references"
  ON content_references FOR DELETE
  TO authenticated
  USING (true);

-- ============================================
-- PHASE 4: Update Existing RLS Policies
-- ============================================

-- Update existing SELECT policies to exclude deleted items
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['languages', 'paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items'])
  LOOP
    -- Drop existing public read policy if exists
    EXECUTE format('DROP POLICY IF EXISTS "Public can read active %s" ON %I', t, t);
    
    -- Create new policy that excludes deleted items
    EXECUTE format(
      'CREATE POLICY "Public can read active %s" ON %I FOR SELECT USING (is_active = true AND (is_deleted = false OR is_deleted IS NULL))',
      t, t
    );
  END LOOP;
END $$;

-- ============================================
-- PHASE 5: Utility Views
-- ============================================

-- 5.1 View for recycle bin - all deleted items across tables
-- Note: Using NULL for image_identifier where column may not exist
CREATE OR REPLACE VIEW recycle_bin_view AS
SELECT 
  id, 'languages' as table_name, name as title, NULL::uuid as parent_id, 
  deleted_at, deleted_by, NULL::text as image_identifier
FROM languages WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'paths', title, language_id as parent_id, deleted_at, deleted_by, 
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='paths' AND column_name='image_identifier') 
    THEN image_identifier ELSE NULL END as image_identifier
FROM paths WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'sections', title, path_id as parent_id, deleted_at, deleted_by,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='sections' AND column_name='image_identifier')
    THEN image_identifier ELSE NULL END as image_identifier
FROM sections WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'branches', title, section_id as parent_id, deleted_at, deleted_by,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='branches' AND column_name='image_identifier')
    THEN image_identifier ELSE NULL END as image_identifier
FROM branches WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'topics', title, branch_id as parent_id, deleted_at, deleted_by,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='topics' AND column_name='image_identifier')
    THEN image_identifier ELSE NULL END as image_identifier
FROM topics WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'content_items', title, topic_id as parent_id, deleted_at, deleted_by, NULL::text as image_identifier
FROM content_items WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'articles', title, category_id as parent_id, deleted_at, deleted_by, NULL::text as image_identifier
FROM articles WHERE is_deleted = true
UNION ALL
SELECT 
  id, 'article_items', title, article_id as parent_id, deleted_at, deleted_by,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='article_items' AND column_name='image_identifier')
    THEN image_identifier ELSE NULL END as image_identifier
FROM article_items WHERE is_deleted = true
ORDER BY deleted_at DESC;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Run these to verify migration success:

-- Check display_order columns exist
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE column_name = 'display_order' 
  AND table_schema = 'public'
ORDER BY table_name;

-- Check is_deleted columns exist
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE column_name = 'is_deleted' 
  AND table_schema = 'public'
ORDER BY table_name;

-- Check content_references table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'content_references' 
  AND table_schema = 'public';

-- Check functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    'swap_display_order', 
    'cascade_soft_delete', 
    'restore_with_validation',
    'has_references',
    'get_references',
    'purge_old_deleted_items'
  );
