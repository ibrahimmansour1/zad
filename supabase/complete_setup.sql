-- ============================================
-- COMPLETE SUPABASE SETUP FOR ZAD ALDAIA
-- Run this in ONE GO in Supabase SQL Editor
-- This will set up EVERYTHING: schema, RLS, test data
-- ============================================

-- ============================================
-- STEP 1: CLEAN UP (if needed)
-- WARNING: This will delete ALL existing data
-- Comment out this section if you want to keep existing data
-- ============================================

-- Drop existing policies first (to avoid dependency issues)
DO $$ 
BEGIN
  -- Drop all policies on tables if they exist
  DROP POLICY IF EXISTS "Public can read active languages" ON languages;
  DROP POLICY IF EXISTS "Public can read active paths" ON paths;
  DROP POLICY IF EXISTS "Public can read active sections" ON sections;
  DROP POLICY IF EXISTS "Public can read active branches" ON branches;
  DROP POLICY IF EXISTS "Public can read active topics" ON topics;
  DROP POLICY IF EXISTS "Public can read active content items" ON content_items;
  DROP POLICY IF EXISTS "Authenticated users can read all languages" ON languages;
  DROP POLICY IF EXISTS "Authenticated users can read all paths" ON paths;
  DROP POLICY IF EXISTS "Authenticated users can read all sections" ON sections;
  DROP POLICY IF EXISTS "Authenticated users can read all branches" ON branches;
  DROP POLICY IF EXISTS "Authenticated users can read all topics" ON topics;
  DROP POLICY IF EXISTS "Authenticated users can read all content items" ON content_items;
  DROP POLICY IF EXISTS "Authenticated users can insert languages" ON languages;
  DROP POLICY IF EXISTS "Authenticated users can update languages" ON languages;
  DROP POLICY IF EXISTS "Authenticated users can delete languages" ON languages;
  DROP POLICY IF EXISTS "Authenticated users can insert paths" ON paths;
  DROP POLICY IF EXISTS "Authenticated users can update paths" ON paths;
  DROP POLICY IF EXISTS "Authenticated users can delete paths" ON paths;
  DROP POLICY IF EXISTS "Authenticated users can insert sections" ON sections;
  DROP POLICY IF EXISTS "Authenticated users can update sections" ON sections;
  DROP POLICY IF EXISTS "Authenticated users can delete sections" ON sections;
  DROP POLICY IF EXISTS "Authenticated users can insert branches" ON branches;
  DROP POLICY IF EXISTS "Authenticated users can update branches" ON branches;
  DROP POLICY IF EXISTS "Authenticated users can delete branches" ON branches;
  DROP POLICY IF EXISTS "Authenticated users can insert topics" ON topics;
  DROP POLICY IF EXISTS "Authenticated users can update topics" ON topics;
  DROP POLICY IF EXISTS "Authenticated users can delete topics" ON topics;
  DROP POLICY IF EXISTS "Authenticated users can insert content items" ON content_items;
  DROP POLICY IF EXISTS "Authenticated users can update content items" ON content_items;
  DROP POLICY IF EXISTS "Authenticated users can delete content items" ON content_items;
  
  -- Articles policies
  DROP POLICY IF EXISTS "Public can read active articles" ON articles;
  DROP POLICY IF EXISTS "Authenticated users can read all articles" ON articles;
  DROP POLICY IF EXISTS "Authenticated users can manage articles" ON articles;
  DROP POLICY IF EXISTS "Public can read active article items" ON article_items;
  DROP POLICY IF EXISTS "Authenticated users can read all article items" ON article_items;
  DROP POLICY IF EXISTS "Authenticated users can manage article items" ON article_items;
  
  -- Social policies
  DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can create their own posts" ON posts;
  DROP POLICY IF EXISTS "Users can view posts except from blocked users" ON posts;
  DROP POLICY IF EXISTS "Anonymous can view all posts" ON posts;
  DROP POLICY IF EXISTS "Users can update own posts" ON posts;
  DROP POLICY IF EXISTS "Users can delete own posts" ON posts;
  DROP POLICY IF EXISTS "Users can view own blocks" ON blocked_users;
  DROP POLICY IF EXISTS "Users can create blocks" ON blocked_users;
  DROP POLICY IF EXISTS "Users can delete own blocks" ON blocked_users;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS article_items CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS topics CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS paths CASCADE;
DROP TABLE IF EXISTS languages CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS blocked_users CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS is_user_blocked(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_posts_with_authors() CASCADE;

-- ============================================
-- STEP 2: ENABLE EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 3: CREATE CONTENT TABLES
-- ============================================

-- Languages table (top level)
CREATE TABLE languages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  flag_url TEXT,
  image_identifier TEXT,  -- For storage file reference
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Paths table (level 2)
CREATE TABLE paths (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  language_id UUID NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  title TEXT,
  name TEXT,  -- For compatibility
  description TEXT,
  image_url TEXT,
  image TEXT,  -- For compatibility
  image_identifier TEXT,  -- For storage file reference
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sections table (level 3)
CREATE TABLE sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  path_id UUID NOT NULL REFERENCES paths(id) ON DELETE CASCADE,
  title TEXT,
  name TEXT,  -- For compatibility
  description TEXT,
  image_url TEXT,
  image TEXT,  -- For compatibility
  image_identifier TEXT,  -- For storage file reference
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Branches table (level 4)
CREATE TABLE branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  title TEXT,
  name TEXT,  -- For compatibility
  description TEXT,
  image_url TEXT,
  image TEXT,  -- For compatibility
  image_identifier TEXT,  -- For storage file reference
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Topics table (level 5)
CREATE TABLE topics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  title TEXT,
  name TEXT,  -- For compatibility
  description TEXT,
  image_url TEXT,
  image TEXT,  -- For compatibility
  image_identifier TEXT,  -- For storage file reference
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Content Items table (level 6 - leaf nodes)
CREATE TABLE content_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT,
  content TEXT,
  media_url TEXT,
  thumbnail_url TEXT,
  duration INTEGER,
  file_size INTEGER,
  metadata JSONB,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 3B: CREATE ARTICLES TABLES (for article-based content)
-- ============================================

-- Articles table (belongs to any category level - paths, sections, branches, topics)
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID,  -- Can reference any category level
  title TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Article Items table (content within articles)
CREATE TABLE article_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'text',  -- text, image, video
  title TEXT,
  content TEXT,
  note TEXT,
  image_url TEXT,
  image_identifier TEXT,
  youtube_url TEXT,
  background_color TEXT,  -- For text/image background colors
  "order" INTEGER DEFAULT 0,  -- Using quotes since order is reserved
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 4: CREATE SOCIAL TABLES
-- ============================================

-- Profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Blocked Users table
CREATE TABLE blocked_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

-- ============================================
-- STEP 5: CREATE INDEXES
-- ============================================

CREATE INDEX idx_paths_language_id ON paths(language_id);
CREATE INDEX idx_sections_path_id ON sections(path_id);
CREATE INDEX idx_branches_section_id ON branches(section_id);
CREATE INDEX idx_topics_branch_id ON topics(branch_id);
CREATE INDEX idx_content_items_topic_id ON content_items(topic_id);

CREATE INDEX idx_languages_order ON languages(display_order);
CREATE INDEX idx_paths_order ON paths(display_order);
CREATE INDEX idx_sections_order ON sections(display_order);
CREATE INDEX idx_branches_order ON branches(display_order);
CREATE INDEX idx_topics_order ON topics(display_order);
CREATE INDEX idx_content_items_order ON content_items(display_order);

-- Article indexes
CREATE INDEX idx_articles_category_id ON articles(category_id);
CREATE INDEX idx_article_items_article_id ON article_items(article_id);
CREATE INDEX idx_article_items_order ON article_items("order");

CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked ON blocked_users(blocked_id);

-- ============================================
-- STEP 6: CREATE FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
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

CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_article_items_updated_at BEFORE UPDATE ON article_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'username',
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- STEP 7: ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 8: CREATE RLS POLICIES - CONTENT TABLES
-- ============================================

-- Languages policies
CREATE POLICY "Public can read active languages"
  ON languages FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all languages"
  ON languages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage languages"
  ON languages FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Paths policies
CREATE POLICY "Public can read active paths"
  ON paths FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all paths"
  ON paths FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage paths"
  ON paths FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Sections policies
CREATE POLICY "Public can read active sections"
  ON sections FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all sections"
  ON sections FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage sections"
  ON sections FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Branches policies
CREATE POLICY "Public can read active branches"
  ON branches FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all branches"
  ON branches FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage branches"
  ON branches FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Topics policies
CREATE POLICY "Public can read active topics"
  ON topics FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all topics"
  ON topics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage topics"
  ON topics FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Content Items policies
CREATE POLICY "Public can read active content items"
  ON content_items FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all content items"
  ON content_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage content items"
  ON content_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Articles policies
CREATE POLICY "Public can read active articles"
  ON articles FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all articles"
  ON articles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage articles"
  ON articles FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Article Items policies
CREATE POLICY "Public can read active article items"
  ON article_items FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can read all article items"
  ON article_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage article items"
  ON article_items FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================
-- STEP 9: CREATE RLS POLICIES - SOCIAL TABLES
-- ============================================

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Posts policies
CREATE POLICY "Users can create their own posts"
  ON posts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can view posts except from blocked users"
  ON posts FOR SELECT
  TO authenticated
  USING (
    NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE blocker_id = auth.uid()
      AND blocked_id = posts.author_id
    )
    AND NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE blocker_id = posts.author_id
      AND blocked_id = auth.uid()
    )
  );

CREATE POLICY "Anonymous can view all posts"
  ON posts FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- Blocked Users policies
CREATE POLICY "Users can view own blocks"
  ON blocked_users FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid());

CREATE POLICY "Users can create blocks"
  ON blocked_users FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "Users can delete own blocks"
  ON blocked_users FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid());

-- ============================================
-- STEP 10: INSERT SAMPLE/TEST DATA
-- ============================================

-- Insert languages
INSERT INTO languages (id, name, code, flag_url, display_order, is_active) VALUES
  ('11111111-1111-1111-1111-111111111111', 'English', 'english', 'assets/images/flags/english.png', 1, true),
  ('22222222-2222-2222-2222-222222222222', 'Español', 'espanol', 'assets/images/flags/espanol.png', 2, true),
  ('33333333-3333-3333-3333-333333333333', 'Português', 'portugues', 'assets/images/flags/portugues.png', 3, true),
  ('44444444-4444-4444-4444-444444444444', 'Français', 'francais', 'assets/images/flags/francais.png', 4, true),
  ('55555555-5555-5555-5555-555555555555', 'Filipino', 'filipino', 'assets/images/flags/filipino.png', 5, true);

-- Insert paths for English
INSERT INTO paths (id, language_id, title, name, description, image_url, display_order, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
   'Pillars of Islam', 'Pillars of Islam', 'Learn about the five pillars of Islam', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true),
  
  ('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 
   'Pillars of Faith', 'Pillars of Faith', 'Understanding the six pillars of Iman', 
   'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 2, true),
  
  ('a3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 
   'Prophet Stories', 'Prophet Stories', 'Stories of the Prophets (peace be upon them)', 
   'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=400', 3, true);

-- Insert sections for Pillars of Islam
INSERT INTO sections (id, path_id, title, name, description, image_url, display_order, is_active) VALUES
  ('a1111111-1111-2222-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
   'Shahada', 'Shahada', 'The declaration of faith',
   'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 1, true),
  
  ('a2222222-2222-2222-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
   'Salah', 'Salah', 'The five daily prayers',
   'https://images.unsplash.com/photo-1590076215667-875d4ef2d7de?w=400', 2, true),
  
  ('a3333333-3333-2222-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
   'Zakat', 'Zakat', 'Obligatory charity',
   'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=400', 3, true);

-- Insert branches for Salah
INSERT INTO branches (id, section_id, title, name, description, display_order, is_active) VALUES
  ('b1111111-1111-1111-1111-111111111111', 'a2222222-2222-2222-1111-111111111111',
   'How to Perform Wudu', 'How to Perform Wudu', 'Learn ablution before prayer', 1, true),
  
  ('b2222222-2222-1111-1111-111111111111', 'a2222222-2222-2222-1111-111111111111',
   'How to Pray', 'How to Pray', 'Step by step guide to Salah', 2, true);

-- Insert topics for How to Perform Wudu
INSERT INTO topics (id, branch_id, title, name, description, display_order, is_active) VALUES
  ('c1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111',
   'Introduction to Wudu', 'Introduction to Wudu', 'What is Wudu', 1, true),
  
  ('c2222222-2222-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111',
   'Steps of Wudu', 'Steps of Wudu', 'Complete steps of ablution', 2, true);

-- Insert content items
INSERT INTO content_items (id, topic_id, type, title, content, media_url, display_order, is_active) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111',
   'text', 'What is Wudu?',
   '<h2>What is Wudu?</h2><p>Wudu is the Islamic ritual washing before prayers.</p>',
   NULL, 1, true),
  
  ('d2222222-2222-1111-1111-111111111111', 'c2222222-2222-1111-1111-111111111111',
   'text', 'Complete Steps',
   '<h2>Steps of Wudu</h2><ol><li>Make intention</li><li>Say Bismillah</li><li>Wash hands 3 times</li></ol>',
   NULL, 1, true);

-- Insert articles (linked to categories/topics for the articles feature)
INSERT INTO articles (id, category_id, title, is_active) VALUES
  ('e1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111',
   'Understanding Wudu (Ablution)', true),
  
  ('e2222222-2222-1111-1111-111111111111', 'c2222222-2222-1111-1111-111111111111',
   'Step-by-Step Wudu Guide', true),
  
  ('e3333333-3333-1111-1111-111111111111', 'a1111111-1111-2222-1111-111111111111',
   'The Importance of Shahada', true);

-- Insert article items with notes and background colors
INSERT INTO article_items (id, article_id, type, title, content, note, background_color, "order", is_active) VALUES
  ('f1111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111',
   'text', 'What is Wudu?',
   'Wudu (ablution) is the Islamic procedure for cleansing parts of the body. It is a ritual purification required before performing prayers. The Prophet Muhammad (peace be upon him) said: "No prayer is accepted without purification."',
   'Important: Wudu must be performed with clean water. If water is not available, Tayammum (dry ablution) can be performed.',
   '#E5F3FF',
   1, true),
  
  ('f2222222-2222-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111',
   'text', 'When is Wudu Required?',
   'Wudu is required: Before performing Salah (prayer), Before touching the Quran, Before Tawaf (circumambulation of the Kaaba).',
   'Tip: It is recommended to be in a state of Wudu at all times.',
   '#FFF9E5',
   2, true),
  
  ('f3333333-3333-1111-1111-111111111111', 'e2222222-2222-1111-1111-111111111111',
   'text', 'Steps of Wudu',
   '1. Intention (Niyyah) - Make the intention in your heart. 2. Say Bismillah - Begin with the name of Allah. 3. Wash hands - Wash both hands up to the wrists three times. 4. Rinse mouth - Rinse the mouth three times. 5. Clean nose - Sniff water into the nose and blow it out three times. 6. Wash face - Wash the face three times. 7. Wash arms - Wash both arms up to the elbows three times. 8. Wipe head - Wipe the head with wet hands once. 9. Wash feet - Wash both feet up to the ankles three times.',
   'Note: Each step should be done thoroughly. Do not rush through the process.',
   '#E5FFE5',
   1, true),
  
  ('f4444444-4444-1111-1111-111111111111', 'e3333333-3333-1111-1111-111111111111',
   'text', 'The Shahada',
   'The Shahada is the Islamic declaration of belief in one God (Allah) and the prophethood of Muhammad. Arabic: أشهد أن لا إله إلا الله وأشهد أن محمداً رسول الله. Translation: "I bear witness that there is no god but Allah, and I bear witness that Muhammad is the Messenger of Allah."',
   'This is the first pillar of Islam and the most important declaration a Muslim makes.',
   '#FFE5E5',
   1, true);

-- ============================================
-- STORAGE SETUP (Run this separately if needed)
-- ============================================
-- NOTE: Storage buckets cannot be created via SQL.
-- You must create them manually in the Supabase Dashboard:
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket"
-- 3. Name it "images"
-- 4. Check "Public bucket" to allow public access
-- 5. Click "Create bucket"

-- ============================================
-- DONE! Your database is ready
-- ============================================

-- Verify the setup
SELECT 'Languages' as table_name, COUNT(*) as count FROM languages
UNION ALL
SELECT 'Paths', COUNT(*) FROM paths
UNION ALL
SELECT 'Sections', COUNT(*) FROM sections
UNION ALL
SELECT 'Branches', COUNT(*) FROM branches
UNION ALL
SELECT 'Topics', COUNT(*) FROM topics
UNION ALL
SELECT 'Content Items', COUNT(*) FROM content_items
UNION ALL
SELECT 'Articles', COUNT(*) FROM articles
UNION ALL
SELECT 'Article Items', COUNT(*) FROM article_items
ORDER BY table_name;
