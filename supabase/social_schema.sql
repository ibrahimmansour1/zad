-- ============================================
-- Supabase SQL Schema for Social Features
-- Posts and Blocked Users
-- ============================================
-- Run this in your Supabase SQL Editor AFTER the main schema
-- This adds social features to your existing Zad Aldaia app
-- ============================================

-- ============================================
-- USER PROFILES TABLE (optional, for display names/avatars)
-- Links to auth.users
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create profile automatically when user signs up
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
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- POSTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);

-- Trigger to update updated_at
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- BLOCKED USERS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS blocked_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Prevent duplicate blocks
  UNIQUE(blocker_id, blocked_id),
  
  -- Prevent self-blocking
  CHECK (blocker_id != blocked_id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES POLICIES
-- ============================================

-- Anyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Users can update only their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can insert their own profile (for edge cases)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- ============================================
-- POSTS POLICIES
-- ============================================

-- Users can insert their own posts only
CREATE POLICY "Users can create their own posts"
  ON posts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);

-- Users can see posts EXCEPT from users they have blocked OR users who blocked them
CREATE POLICY "Users can view posts except from blocked users"
  ON posts FOR SELECT
  TO authenticated
  USING (
    -- Post is not from someone the current user blocked
    NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE blocker_id = auth.uid()
      AND blocked_id = posts.author_id
    )
    AND
    -- Post is not from someone who blocked the current user
    NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE blocker_id = posts.author_id
      AND blocked_id = auth.uid()
    )
  );

-- Anonymous users can see all posts (optional, remove if you want auth-only)
CREATE POLICY "Anonymous can view all posts"
  ON posts FOR SELECT
  TO anon
  USING (true);

-- Users can update only their own posts
CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- Users can delete only their own posts
CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  TO authenticated
  USING (auth.uid() = author_id);

-- ============================================
-- BLOCKED USERS POLICIES
-- ============================================

-- Users can only see their own blocks
CREATE POLICY "Users can view own blocks"
  ON blocked_users FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid());

-- Users can only create blocks where they are the blocker
CREATE POLICY "Users can create blocks"
  ON blocked_users FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid());

-- Users can only delete their own blocks
CREATE POLICY "Users can delete own blocks"
  ON blocked_users FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid());

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if a user is blocked
CREATE OR REPLACE FUNCTION is_user_blocked(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blocked_users
    WHERE blocker_id = auth.uid()
    AND blocked_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get posts with author info (useful for efficient queries)
CREATE OR REPLACE FUNCTION get_posts_with_authors()
RETURNS TABLE (
  id UUID,
  author_id UUID,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  author_display_name TEXT,
  author_avatar_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.author_id,
    p.content,
    p.created_at,
    COALESCE(pr.display_name, 'Anonymous') as author_display_name,
    pr.avatar_url as author_avatar_url
  FROM posts p
  LEFT JOIN profiles pr ON p.author_id = pr.id
  WHERE NOT EXISTS (
    SELECT 1 FROM blocked_users bu
    WHERE bu.blocker_id = auth.uid()
    AND bu.blocked_id = p.author_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM blocked_users bu
    WHERE bu.blocker_id = p.author_id
    AND bu.blocked_id = auth.uid()
  )
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on the functions
GRANT EXECUTE ON FUNCTION is_user_blocked(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_posts_with_authors() TO authenticated;
