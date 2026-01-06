-- ============================================
-- Supabase SQL Schema for Zad Aldaia Flutter App
-- ============================================
-- This schema supports a hierarchical content structure:
-- Languages → Paths → Sections → Branches → Topics → Content Items
-- 
-- IMPORTANT: Run this in your Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Languages table (top level)
CREATE TABLE IF NOT EXISTS languages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE, -- e.g., 'en', 'es', 'pt', 'fr', 'fil'
  flag_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Paths table (level 2)
CREATE TABLE IF NOT EXISTS paths (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  language_id UUID NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  "order" INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sections table (level 3)
CREATE TABLE IF NOT EXISTS sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  path_id UUID NOT NULL REFERENCES paths(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  "order" INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Branches table (level 4)
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  "order" INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Topics table (level 5)
CREATE TABLE IF NOT EXISTS topics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  "order" INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Content Items table (level 6 - leaf nodes)
CREATE TABLE IF NOT EXISTS content_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'text', 'image', 'video', 'audio', 'pdf', etc.
  title TEXT,
  content TEXT, -- For text content or HTML
  media_url TEXT, -- For images, videos, etc.
  thumbnail_url TEXT,
  duration INTEGER, -- For videos/audio (in seconds)
  file_size INTEGER, -- In bytes
  metadata JSONB, -- Additional flexible data
  "order" INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES for better query performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_paths_language_id ON paths(language_id);
CREATE INDEX IF NOT EXISTS idx_sections_path_id ON sections(path_id);
CREATE INDEX IF NOT EXISTS idx_branches_section_id ON branches(section_id);
CREATE INDEX IF NOT EXISTS idx_topics_branch_id ON topics(branch_id);
CREATE INDEX IF NOT EXISTS idx_content_items_topic_id ON content_items(topic_id);

CREATE INDEX IF NOT EXISTS idx_paths_order ON paths("order");
CREATE INDEX IF NOT EXISTS idx_sections_order ON sections("order");
CREATE INDEX IF NOT EXISTS idx_branches_order ON branches("order");
CREATE INDEX IF NOT EXISTS idx_topics_order ON topics("order");
CREATE INDEX IF NOT EXISTS idx_content_items_order ON content_items("order");

-- ============================================
-- TRIGGERS for updated_at timestamps
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_languages_updated_at BEFORE UPDATE ON languages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_paths_updated_at BEFORE UPDATE ON paths
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sections_updated_at BEFORE UPDATE ON sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_topics_updated_at BEFORE UPDATE ON topics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_items_updated_at BEFORE UPDATE ON content_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- Public read access for all active content
CREATE POLICY "Public can read active languages"
  ON languages FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can read active paths"
  ON paths FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can read active sections"
  ON sections FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can read active branches"
  ON branches FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can read active topics"
  ON topics FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can read active content items"
  ON content_items FOR SELECT
  USING (is_active = true);

-- Authenticated users can read all content (including inactive)
CREATE POLICY "Authenticated users can read all languages"
  ON languages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read all paths"
  ON paths FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read all sections"
  ON sections FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read all branches"
  ON branches FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read all topics"
  ON topics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read all content items"
  ON content_items FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can insert/update/delete (admin functionality)
CREATE POLICY "Authenticated users can insert languages"
  ON languages FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update languages"
  ON languages FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete languages"
  ON languages FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert paths"
  ON paths FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update paths"
  ON paths FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete paths"
  ON paths FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert sections"
  ON sections FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update sections"
  ON sections FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete sections"
  ON sections FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert branches"
  ON branches FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update branches"
  ON branches FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete branches"
  ON branches FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert topics"
  ON topics FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update topics"
  ON topics FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete topics"
  ON topics FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert content items"
  ON content_items FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update content items"
  ON content_items FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete content items"
  ON content_items FOR DELETE
  TO authenticated
  USING (true);

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample languages
INSERT INTO languages (name, code, flag_url) VALUES
  ('English', 'english', 'assets/images/flags/english.png'),
  ('Español', 'espanol', 'assets/images/flags/espanol.png'),
  ('Português', 'portugues', 'assets/images/flags/portugues.png'),
  ('Français', 'francais', 'assets/images/flags/francais.png'),
  ('Filipino', 'filipino', 'assets/images/flags/filipino.png')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- STORAGE BUCKET SETUP
-- ============================================
-- Run this separately in Supabase Dashboard → Storage
-- 
-- 1. Create a bucket named 'content-images'
-- 2. Set it to PUBLIC
-- 3. Add the following policies:
--
-- Policy: "Public can read images"
-- - Operation: SELECT
-- - Policy: (bucket_id = 'content-images')
--
-- Policy: "Authenticated users can upload images"
-- - Operation: INSERT
-- - Policy: (bucket_id = 'content-images' AND auth.role() = 'authenticated')
--
-- Policy: "Authenticated users can update images"
-- - Operation: UPDATE
-- - Policy: (bucket_id = 'content-images' AND auth.role() = 'authenticated')
--
-- Policy: "Authenticated users can delete images"
-- - Operation: DELETE
-- - Policy: (bucket_id = 'content-images' AND auth.role() = 'authenticated')
-- ============================================
