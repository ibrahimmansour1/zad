-- ============================================
-- TEST DATA FOR ZAD ALDAIA APP
-- ============================================
-- This creates a complete hierarchical structure:
-- Languages → Paths → Sections → Branches → Topics → Content Items
-- Run this in Supabase SQL Editor after adding the missing columns
-- ============================================

-- First, make sure columns exist (run add_missing_columns.sql first!)

-- ============================================
-- 1. INSERT LANGUAGES (Top Level)
-- ============================================

INSERT INTO languages (id, name, code, is_active, "order", image_url, description, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'English', 'en', true, 1, 'https://flagcdn.com/w320/gb.png', 'Learn in English', NOW()),
('550e8400-e29b-41d4-a716-446655440002', 'العربية', 'ar', true, 2, 'https://flagcdn.com/w320/sa.png', 'تعلم بالعربية', NOW()),
('550e8400-e29b-41d4-a716-446655440003', 'Español', 'es', true, 3, 'https://flagcdn.com/w320/es.png', 'Aprende en Español', NOW()),
('550e8400-e29b-41d4-a716-446655440004', 'Français', 'fr', true, 4, 'https://flagcdn.com/w320/fr.png', 'Apprendre en Français', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. INSERT PATHS (Learning Paths)
-- ============================================

-- English Paths
INSERT INTO paths (id, language_id, name, is_active, "order", image_url, description, created_at) VALUES
('650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Islamic Studies', true, 1, 'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 'Learn about Islam', NOW()),
('650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Quran Memorization', true, 2, 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 'Memorize the Holy Quran', NOW()),
('650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Arabic Language', true, 3, 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400', 'Learn Arabic from scratch', NOW())
ON CONFLICT (id) DO NOTHING;

-- Arabic Paths
INSERT INTO paths (id, language_id, name, is_active, "order", image_url, description, created_at) VALUES
('650e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440002', 'الدراسات الإسلامية', true, 1, 'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 'تعلم عن الإسلام', NOW()),
('650e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440002', 'حفظ القرآن', true, 2, 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 'احفظ القرآن الكريم', NOW())
ON CONFLICT (id) DO NOTHING;

-- Spanish Paths
INSERT INTO paths (id, language_id, name, is_active, "order", image_url, description, created_at) VALUES
('650e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440003', 'Estudios Islámicos', true, 1, 'https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=400', 'Aprende sobre el Islam', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. INSERT SECTIONS
-- ============================================

-- Islamic Studies → Sections
INSERT INTO sections (id, path_id, name, is_active, "order", image_url, description, created_at) VALUES
('750e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 'Aqeedah (Belief)', true, 1, 'https://images.unsplash.com/photo-1584286595398-a59f21d25e0f?w=400', 'Islamic creed and beliefs', NOW()),
('750e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440001', 'Fiqh (Jurisprudence)', true, 2, 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 'Islamic law and rulings', NOW()),
('750e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440001', 'Seerah (Biography)', true, 3, 'https://images.unsplash.com/photo-1604881991720-f91add269bed?w=400', 'Life of Prophet Muhammad ﷺ', NOW())
ON CONFLICT (id) DO NOTHING;

-- Quran Memorization → Sections
INSERT INTO sections (id, path_id, name, is_active, "order", image_url, description, created_at) VALUES
('750e8400-e29b-41d4-a716-446655440011', '650e8400-e29b-41d4-a716-446655440002', 'Juz 1-10', true, 1, 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 'First 10 parts of Quran', NOW()),
('750e8400-e29b-41d4-a716-446655440012', '650e8400-e29b-41d4-a716-446655440002', 'Juz 11-20', true, 2, 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 'Parts 11-20 of Quran', NOW()),
('750e8400-e29b-41d4-a716-446655440013', '650e8400-e29b-41d4-a716-446655440002', 'Juz 21-30', true, 3, 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=400', 'Last 10 parts of Quran', NOW())
ON CONFLICT (id) DO NOTHING;

-- Arabic Language → Sections
INSERT INTO sections (id, path_id, name, is_active, "order", image_url, description, created_at) VALUES
('750e8400-e29b-41d4-a716-446655440021', '650e8400-e29b-41d4-a716-446655440003', 'Beginner Level', true, 1, 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400', 'Start learning Arabic', NOW()),
('750e8400-e29b-41d4-a716-446655440022', '650e8400-e29b-41d4-a716-446655440003', 'Intermediate Level', true, 2, 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400', 'Improve your Arabic', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. INSERT BRANCHES
-- ============================================

-- Aqeedah → Branches
INSERT INTO branches (id, section_id, name, is_active, "order", image_url, description, created_at) VALUES
('850e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440001', 'Tawheed (Oneness of Allah)', true, 1, 'https://images.unsplash.com/photo-1584286595398-a59f21d25e0f?w=400', 'The fundamental belief in Islam', NOW()),
('850e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440001', 'Pillars of Iman', true, 2, 'https://images.unsplash.com/photo-1584286595398-a59f21d25e0f?w=400', 'Six pillars of faith', NOW())
ON CONFLICT (id) DO NOTHING;

-- Fiqh → Branches
INSERT INTO branches (id, section_id, name, is_active, "order", image_url, description, created_at) VALUES
('850e8400-e29b-41d4-a716-446655440011', '750e8400-e29b-41d4-a716-446655440002', 'Salah (Prayer)', true, 1, 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 'Learn how to pray', NOW()),
('850e8400-e29b-41d4-a716-446655440012', '750e8400-e29b-41d4-a716-446655440002', 'Zakah (Charity)', true, 2, 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 'Islamic charity rules', NOW()),
('850e8400-e29b-41d4-a716-446655440013', '750e8400-e29b-41d4-a716-446655440002', 'Sawm (Fasting)', true, 3, 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=400', 'Fasting in Ramadan', NOW())
ON CONFLICT (id) DO NOTHING;

-- Seerah → Branches
INSERT INTO branches (id, section_id, name, is_active, "order", image_url, description, created_at) VALUES
('850e8400-e29b-41d4-a716-446655440021', '750e8400-e29b-41d4-a716-446655440003', 'Early Life', true, 1, 'https://images.unsplash.com/photo-1604881991720-f91add269bed?w=400', 'Birth and childhood of the Prophet', NOW()),
('850e8400-e29b-41d4-a716-446655440022', '750e8400-e29b-41d4-a716-446655440003', 'Prophethood', true, 2, 'https://images.unsplash.com/photo-1604881991720-f91add269bed?w=400', 'Receiving the revelation', NOW())
ON CONFLICT (id) DO NOTHING;

-- Beginner Arabic → Branches
INSERT INTO branches (id, section_id, name, is_active, "order", image_url, description, created_at) VALUES
('850e8400-e29b-41d4-a716-446655440031', '750e8400-e29b-41d4-a716-446655440021', 'Arabic Alphabet', true, 1, 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400', 'Learn the Arabic letters', NOW()),
('850e8400-e29b-41d4-a716-446655440032', '750e8400-e29b-41d4-a716-446655440021', 'Basic Vocabulary', true, 2, 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400', 'Common Arabic words', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5. INSERT TOPICS
-- ============================================

-- Tawheed → Topics
INSERT INTO topics (id, branch_id, name, is_active, "order", image_url, description, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440001', 'What is Tawheed?', true, 1, NULL, 'Introduction to Tawheed', NOW()),
('950e8400-e29b-41d4-a716-446655440002', '850e8400-e29b-41d4-a716-446655440001', 'Types of Tawheed', true, 2, NULL, 'Three categories of Tawheed', NOW()),
('950e8400-e29b-41d4-a716-446655440003', '850e8400-e29b-41d4-a716-446655440001', 'Shirk (Polytheism)', true, 3, NULL, 'The opposite of Tawheed', NOW())
ON CONFLICT (id) DO NOTHING;

-- Pillars of Iman → Topics
INSERT INTO topics (id, branch_id, name, is_active, "order", image_url, description, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440011', '850e8400-e29b-41d4-a716-446655440002', 'Belief in Allah', true, 1, NULL, 'First pillar of faith', NOW()),
('950e8400-e29b-41d4-a716-446655440012', '850e8400-e29b-41d4-a716-446655440002', 'Belief in Angels', true, 2, NULL, 'Second pillar of faith', NOW()),
('950e8400-e29b-41d4-a716-446655440013', '850e8400-e29b-41d4-a716-446655440002', 'Belief in Books', true, 3, NULL, 'Third pillar of faith', NOW())
ON CONFLICT (id) DO NOTHING;

-- Salah → Topics
INSERT INTO topics (id, branch_id, name, is_active, "order", image_url, description, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440021', '850e8400-e29b-41d4-a716-446655440011', 'Wudu (Ablution)', true, 1, NULL, 'How to perform wudu', NOW()),
('950e8400-e29b-41d4-a716-446655440022', '850e8400-e29b-41d4-a716-446655440011', 'Prayer Times', true, 2, NULL, 'Five daily prayers', NOW()),
('950e8400-e29b-41d4-a716-446655440023', '850e8400-e29b-41d4-a716-446655440011', 'How to Pray', true, 3, NULL, 'Step by step prayer guide', NOW())
ON CONFLICT (id) DO NOTHING;

-- Arabic Alphabet → Topics
INSERT INTO topics (id, branch_id, name, is_active, "order", image_url, description, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440031', '850e8400-e29b-41d4-a716-446655440031', 'Alif to Daal', true, 1, NULL, 'First 8 letters', NOW()),
('950e8400-e29b-41d4-a716-446655440032', '850e8400-e29b-41d4-a716-446655440031', 'Dhaal to Saad', true, 2, NULL, 'Letters 9-16', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 6. INSERT CONTENT ITEMS (Optional - for topics)
-- ============================================

-- What is Tawheed? → Content Items
INSERT INTO content_items (id, topic_id, type, title, content, image_url, "order", is_active, created_at) VALUES
('a50e8400-e29b-41d4-a716-446655440001', '950e8400-e29b-41d4-a716-446655440001', 'text', 'Definition', 'Tawheed means the Oneness of Allah. It is the foundation of Islamic belief and the most important concept in Islam.', NULL, 1, true, NOW()),
('a50e8400-e29b-41d4-a716-446655440002', '950e8400-e29b-41d4-a716-446655440001', 'text', 'Importance', 'Tawheed is the first pillar of Islam. Without it, no deed is accepted by Allah.', NULL, 2, true, NOW()),
('a50e8400-e29b-41d4-a716-446655440003', '950e8400-e29b-41d4-a716-446655440001', 'text', 'Evidence', 'Allah says in the Quran: "Say, He is Allah, [who is] One" (Surah Al-Ikhlas 112:1)', NULL, 3, true, NOW())
ON CONFLICT (id) DO NOTHING;

-- Wudu → Content Items
INSERT INTO content_items (id, topic_id, type, title, content, image_url, "order", is_active, created_at) VALUES
('a50e8400-e29b-41d4-a716-446655440011', '950e8400-e29b-41d4-a716-446655440021', 'text', 'Step 1', 'Make the intention (niyyah) in your heart to perform wudu for the sake of Allah.', NULL, 1, true, NOW()),
('a50e8400-e29b-41d4-a716-446655440012', '950e8400-e29b-41d4-a716-446655440021', 'text', 'Step 2', 'Say "Bismillah" (In the name of Allah) and wash both hands up to the wrists three times.', NULL, 2, true, NOW()),
('a50e8400-e29b-41d4-a716-446655440013', '950e8400-e29b-41d4-a716-446655440021', 'text', 'Step 3', 'Rinse your mouth three times, swirling water around.', NULL, 3, true, NOW()),
('a50e8400-e29b-41d4-a716-446655440014', '950e8400-e29b-41d4-a716-446655440021', 'text', 'Step 4', 'Rinse your nose three times by sniffing water in and blowing it out.', NULL, 4, true, NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- VERIFICATION QUERY
-- ============================================
-- Run this to verify data was inserted:

-- SELECT 
--   l.name as language,
--   p.name as path,
--   s.name as section,
--   b.name as branch,
--   t.name as topic
-- FROM languages l
-- LEFT JOIN paths p ON p.language_id = l.id
-- LEFT JOIN sections s ON s.path_id = p.id
-- LEFT JOIN branches b ON b.section_id = s.id
-- LEFT JOIN topics t ON t.branch_id = b.id
-- ORDER BY l.name, p.name, s.name, b.name, t.name;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
-- If you see "Success. No rows returned" - that's good!
-- The data has been inserted.
-- Now run the verification query above to see your data.
-- ============================================
