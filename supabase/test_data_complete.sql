-- ============================================
-- Supabase Test Data for Zad Aldaia Flutter App
-- ============================================
-- Run this in your Supabase SQL Editor AFTER running:
-- 1. schema.sql (main content schema)
-- 2. social_schema.sql (posts and blocked users)
--
-- This creates sample content for testing the app
-- ============================================

-- ============================================
-- CLEAR EXISTING TEST DATA (Optional)
-- Uncomment if you want to reset
-- ============================================
-- DELETE FROM content_items;
-- DELETE FROM topics;
-- DELETE FROM branches;
-- DELETE FROM sections;
-- DELETE FROM paths;
-- DELETE FROM languages WHERE code IN ('english', 'espanol', 'portugues', 'francais', 'filipino');

-- ============================================
-- 1. LANGUAGES (Top Level)
-- ============================================
INSERT INTO languages (id, name, code, flag_url, is_active) VALUES
  ('11111111-1111-1111-1111-111111111111', 'English', 'english', 'assets/images/flags/english.png', true),
  ('22222222-2222-2222-2222-222222222222', 'Español', 'espanol', 'assets/images/flags/espanol.png', true),
  ('33333333-3333-3333-3333-333333333333', 'Português', 'portugues', 'assets/images/flags/portugues.png', true),
  ('44444444-4444-4444-4444-444444444444', 'Français', 'francais', 'assets/images/flags/francais.png', true),
  ('55555555-5555-5555-5555-555555555555', 'Filipino', 'filipino', 'assets/images/flags/filipino.png', true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  flag_url = EXCLUDED.flag_url,
  is_active = EXCLUDED.is_active;

-- ============================================
-- 2. PATHS (Main Categories) - English
-- ============================================
INSERT INTO paths (id, language_id, title, description, image_url, "order", is_active) VALUES
  -- English paths
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 
   'Pillars of Islam', 'Learn about the five pillars of Islam', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true),
  
  ('a2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 
   'Pillars of Faith', 'Understanding the six pillars of Iman', 
   'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 2, true),
  
  ('a3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 
   'Prophet Stories', 'Stories of the Prophets (peace be upon them)', 
   'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=400', 3, true),
  
  ('a4444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 
   'Daily Duas', 'Essential supplications for daily life', 
   'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 4, true),
  
  ('a5555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 
   'Quran Learning', 'Learn to read and understand the Quran', 
   'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 5, true);

-- Spanish paths
INSERT INTO paths (id, language_id, title, description, image_url, "order", is_active) VALUES
  ('b1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 
   'Pilares del Islam', 'Aprende sobre los cinco pilares del Islam', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true),
  
  ('b2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 
   'Pilares de la Fe', 'Entendiendo los seis pilares del Iman', 
   'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 2, true);

-- Portuguese paths
INSERT INTO paths (id, language_id, title, description, image_url, "order", is_active) VALUES
  ('c1111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 
   'Pilares do Islã', 'Aprenda sobre os cinco pilares do Islã', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true);

-- French paths
INSERT INTO paths (id, language_id, title, description, image_url, "order", is_active) VALUES
  ('d1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 
   'Piliers de l''Islam', 'Apprendre les cinq piliers de l''Islam', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true);

-- Filipino paths
INSERT INTO paths (id, language_id, title, description, image_url, "order", is_active) VALUES
  ('e1111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 
   'Mga Haligi ng Islam', 'Alamin ang limang haligi ng Islam', 
   'https://images.unsplash.com/photo-1564769625657-435cc22e5c59?w=400', 1, true);

-- ============================================
-- 3. SECTIONS (Sub-categories) - English Pillars of Islam
-- ============================================
INSERT INTO sections (id, path_id, title, description, image_url, "order", is_active) VALUES
  ('s1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
   'Shahada', 'The declaration of faith - La ilaha illallah Muhammadur Rasulullah',
   'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 1, true),
  
  ('s2222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111',
   'Salah (Prayer)', 'The five daily prayers - the second pillar of Islam',
   'https://images.unsplash.com/photo-1590076215667-875d4ef2d7de?w=400', 2, true),
  
  ('s3333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111',
   'Zakat', 'Obligatory charity - purification of wealth',
   'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=400', 3, true),
  
  ('s4444444-4444-4444-4444-444444444444', 'a1111111-1111-1111-1111-111111111111',
   'Sawm (Fasting)', 'Fasting during the month of Ramadan',
   'https://images.unsplash.com/photo-1564121211835-e88c852648ab?w=400', 4, true),
  
  ('s5555555-5555-5555-5555-555555555555', 'a1111111-1111-1111-1111-111111111111',
   'Hajj (Pilgrimage)', 'The pilgrimage to Mecca',
   'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 5, true);

-- Sections for Pillars of Faith
INSERT INTO sections (id, path_id, title, description, image_url, "order", is_active) VALUES
  ('s6666666-6666-6666-6666-666666666666', 'a2222222-2222-2222-2222-222222222222',
   'Belief in Allah', 'Understanding Tawheed - the oneness of Allah',
   'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 1, true),
  
  ('s7777777-7777-7777-7777-777777777777', 'a2222222-2222-2222-2222-222222222222',
   'Belief in Angels', 'Understanding the angels of Allah',
   'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 2, true),
  
  ('s8888888-8888-8888-8888-888888888888', 'a2222222-2222-2222-2222-222222222222',
   'Belief in Books', 'The divine scriptures sent by Allah',
   'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 3, true);

-- Sections for Prophet Stories
INSERT INTO sections (id, path_id, title, description, image_url, "order", is_active) VALUES
  ('s9999999-9999-9999-9999-999999999999', 'a3333333-3333-3333-3333-333333333333',
   'Prophet Adam (AS)', 'The first human and prophet',
   'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=400', 1, true),
  
  ('saaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a3333333-3333-3333-3333-333333333333',
   'Prophet Nuh (AS)', 'Prophet Noah and the great flood',
   'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=400', 2, true),
  
  ('sbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'a3333333-3333-3333-3333-333333333333',
   'Prophet Ibrahim (AS)', 'The friend of Allah',
   'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=400', 3, true);

-- ============================================
-- 4. BRANCHES (Topics within Sections)
-- ============================================
-- Shahada branches
INSERT INTO branches (id, section_id, title, description, "order", is_active) VALUES
  ('br111111-1111-1111-1111-111111111111', 's1111111-1111-1111-1111-111111111111',
   'Meaning of Shahada', 'Understanding what the testimony of faith means', 1, true),
  
  ('br222222-2222-2222-2222-222222222222', 's1111111-1111-1111-1111-111111111111',
   'Conditions of Shahada', 'The seven conditions for a valid Shahada', 2, true),
  
  ('br333333-3333-3333-3333-333333333333', 's1111111-1111-1111-1111-111111111111',
   'How to Take Shahada', 'Steps to become a Muslim', 3, true);

-- Salah branches
INSERT INTO branches (id, section_id, title, description, "order", is_active) VALUES
  ('br444444-4444-4444-4444-444444444444', 's2222222-2222-2222-2222-222222222222',
   'How to Perform Wudu', 'Learn the purification before prayer', 1, true),
  
  ('br555555-5555-5555-5555-555555555555', 's2222222-2222-2222-2222-222222222222',
   'Prayer Times', 'Understanding the five daily prayer times', 2, true),
  
  ('br666666-6666-6666-6666-666666666666', 's2222222-2222-2222-2222-222222222222',
   'How to Pray', 'Step by step guide to performing Salah', 3, true);

-- Zakat branches
INSERT INTO branches (id, section_id, title, description, "order", is_active) VALUES
  ('br777777-7777-7777-7777-777777777777', 's3333333-3333-3333-3333-333333333333',
   'Who Must Pay Zakat', 'Conditions for Zakat obligation', 1, true),
  
  ('br888888-8888-8888-8888-888888888888', 's3333333-3333-3333-3333-333333333333',
   'How to Calculate Zakat', 'Calculating 2.5% of your wealth', 2, true);

-- ============================================
-- 5. TOPICS (Lessons within Branches)
-- ============================================
INSERT INTO topics (id, branch_id, title, description, "order", is_active) VALUES
  -- Meaning of Shahada topics
  ('t1111111-1111-1111-1111-111111111111', 'br111111-1111-1111-1111-111111111111',
   'La ilaha illallah', 'There is no god but Allah', 1, true),
  
  ('t2222222-2222-2222-2222-222222222222', 'br111111-1111-1111-1111-111111111111',
   'Muhammadur Rasulullah', 'Muhammad is the Messenger of Allah', 2, true),
  
  -- How to Perform Wudu topics
  ('t3333333-3333-3333-3333-333333333333', 'br444444-4444-4444-4444-444444444444',
   'Introduction to Wudu', 'What is Wudu and why is it important', 1, true),
  
  ('t4444444-4444-4444-4444-444444444444', 'br444444-4444-4444-4444-444444444444',
   'Steps of Wudu', 'The complete steps of ablution', 2, true),
  
  ('t5555555-5555-5555-5555-555555555555', 'br444444-4444-4444-4444-444444444444',
   'What Breaks Wudu', 'Things that nullify your ablution', 3, true),
  
  -- How to Pray topics
  ('t6666666-6666-6666-6666-666666666666', 'br666666-6666-6666-6666-666666666666',
   'Fajr Prayer', 'The dawn prayer - 2 Rakaat', 1, true),
  
  ('t7777777-7777-7777-7777-777777777777', 'br666666-6666-6666-6666-666666666666',
   'Dhuhr Prayer', 'The noon prayer - 4 Rakaat', 2, true),
  
  ('t8888888-8888-8888-8888-888888888888', 'br666666-6666-6666-6666-666666666666',
   'Asr Prayer', 'The afternoon prayer - 4 Rakaat', 3, true);

-- ============================================
-- 6. CONTENT ITEMS (Actual Content)
-- ============================================
INSERT INTO content_items (id, topic_id, type, title, content, media_url, "order", is_active) VALUES
  -- La ilaha illallah content
  ('ci111111-1111-1111-1111-111111111111', 't1111111-1111-1111-1111-111111111111',
   'text', 'What does La ilaha illallah mean?',
   '<h2>La ilaha illallah</h2><p>This is the first part of the Shahada, meaning "There is no god but Allah."</p><p>This statement has two parts:</p><ul><li><strong>Negation:</strong> La ilaha - There is no god</li><li><strong>Affirmation:</strong> illallah - except Allah</li></ul><p>This means we deny worship to anything other than Allah, and we affirm that only Allah deserves worship.</p>',
   NULL, 1, true),
  
  ('ci222222-2222-2222-2222-222222222222', 't1111111-1111-1111-1111-111111111111',
   'video', 'Understanding Tawheed (Video)',
   'Watch this video to understand the concept of Tawheed better.',
   'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 2, true),
  
  -- Introduction to Wudu content
  ('ci333333-3333-3333-3333-333333333333', 't3333333-3333-3333-3333-333333333333',
   'text', 'What is Wudu?',
   '<h2>What is Wudu (Ablution)?</h2><p>Wudu is the Islamic ritual washing performed before prayers. It is an act of worship and purification.</p><p><strong>Allah says in the Quran:</strong></p><blockquote>"O you who believe! When you intend to offer prayer, wash your faces and your hands up to the elbows, wipe your heads, and wash your feet up to the ankles." (Al-Ma''idah 5:6)</blockquote>',
   NULL, 1, true),
  
  ('ci444444-4444-4444-4444-444444444444', 't3333333-3333-3333-3333-333333333333',
   'image', 'Wudu Diagram',
   'Visual guide showing the parts of the body washed during Wudu',
   'https://images.unsplash.com/photo-1590076215667-875d4ef2d7de?w=800', 2, true),
  
  -- Steps of Wudu content
  ('ci555555-5555-5555-5555-555555555555', 't4444444-4444-4444-4444-444444444444',
   'text', 'Complete Steps of Wudu',
   '<h2>How to Perform Wudu</h2><ol><li><strong>Make intention (Niyyah)</strong> - Intend in your heart to perform Wudu for prayer</li><li><strong>Say Bismillah</strong> - "In the name of Allah"</li><li><strong>Wash hands 3 times</strong> - Starting with the right hand</li><li><strong>Rinse mouth 3 times</strong> - Using right hand</li><li><strong>Clean nose 3 times</strong> - Sniff water and blow it out</li><li><strong>Wash face 3 times</strong> - From hairline to chin, ear to ear</li><li><strong>Wash arms 3 times</strong> - From fingertips to elbows, right first</li><li><strong>Wipe head once</strong> - From front to back and back to front</li><li><strong>Clean ears once</strong> - Inside and outside</li><li><strong>Wash feet 3 times</strong> - Including ankles, right foot first</li></ol>',
   NULL, 1, true),
  
  -- Fajr Prayer content
  ('ci666666-6666-6666-6666-666666666666', 't6666666-6666-6666-6666-666666666666',
   'text', 'How to Pray Fajr',
   '<h2>Fajr (Dawn Prayer)</h2><p>Fajr consists of <strong>2 Rakaat</strong> (units of prayer).</p><h3>Time</h3><p>From dawn until just before sunrise.</p><h3>Sunnah Prayers</h3><p>2 Rakaat Sunnah before the Fard prayer. The Prophet ﷺ never left these even when traveling.</p>',
   NULL, 1, true);

-- ============================================
-- 7. CREATE A TEST ADMIN USER
-- Run this AFTER creating the auth user in Supabase Dashboard
-- Or use the Supabase Auth API
-- ============================================
-- You can create a test user in Supabase Dashboard:
-- 1. Go to Authentication > Users
-- 2. Click "Add user"
-- 3. Enter: admin@zadaldaia.com / password123
-- 4. Then run:
-- INSERT INTO profiles (id, username, display_name)
-- SELECT id, 'admin', 'Admin User'
-- FROM auth.users WHERE email = 'admin@zadaldaia.com';

-- ============================================
-- VERIFICATION QUERIES
-- Run these to verify data was inserted correctly
-- ============================================
-- SELECT 'Languages' as table_name, COUNT(*) as count FROM languages;
-- SELECT 'Paths' as table_name, COUNT(*) as count FROM paths;
-- SELECT 'Sections' as table_name, COUNT(*) as count FROM sections;
-- SELECT 'Branches' as table_name, COUNT(*) as count FROM branches;
-- SELECT 'Topics' as table_name, COUNT(*) as count FROM topics;
-- SELECT 'Content Items' as table_name, COUNT(*) as count FROM content_items;

-- ============================================
-- SAMPLE QUERY: Get full content hierarchy for English
-- ============================================
-- SELECT 
--   l.name as language,
--   p.title as path,
--   s.title as section,
--   b.title as branch,
--   t.title as topic,
--   ci.title as content_title,
--   ci.type as content_type
-- FROM languages l
-- JOIN paths p ON p.language_id = l.id
-- JOIN sections s ON s.path_id = p.id
-- JOIN branches b ON b.section_id = s.id
-- JOIN topics t ON t.branch_id = b.id
-- JOIN content_items ci ON ci.topic_id = t.id
-- WHERE l.code = 'english'
-- ORDER BY p."order", s."order", b."order", t."order", ci."order";
