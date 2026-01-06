# 🎯 Complete Setup Guide - Run These SQLs in Order

## ✅ **Step-by-Step Setup**

### **Step 1: Add Missing Columns** (REQUIRED)
Run this first to add the required columns to your tables:

📄 **File:** `supabase/add_missing_columns.sql`

This adds:
- `is_active` column
- `order` column
- `image_url` column
- `image_identifier` column
- `description` column

**Expected result:** "Success. No rows returned"

---

### **Step 2: Insert Test Data** (OPTIONAL but RECOMMENDED)
Run this to populate your database with sample Islamic education content:

📄 **File:** `supabase/test_data.sql`

This creates:
- ✅ **4 Languages**: English, Arabic, Spanish, French
- ✅ **6 Paths**: Islamic Studies, Quran Memorization, Arabic Language, etc.
- ✅ **8 Sections**: Aqeedah, Fiqh, Seerah, Juz divisions, etc.
- ✅ **10 Branches**: Tawheed, Pillars of Iman, Salah, Zakah, etc.
- ✅ **15 Topics**: What is Tawheed, Wudu, Prayer Times, etc.
- ✅ **11 Content Items**: Detailed lessons and explanations

**Expected result:** "Success. No rows returned"

---

### **Step 3: Verify Data** (OPTIONAL)
Run this query to see your hierarchical data:

```sql
SELECT 
  l.name as language,
  p.name as path,
  s.name as section,
  b.name as branch,
  t.name as topic
FROM languages l
LEFT JOIN paths p ON p.language_id = l.id
LEFT JOIN sections s ON s.path_id = p.id
LEFT JOIN branches b ON b.section_id = s.id
LEFT JOIN topics t ON t.branch_id = b.id
ORDER BY l.name, p.name, s.name, b.name, t.name
LIMIT 50;
```

**Expected result:** A table showing the complete hierarchy

---

## 📊 **What You'll See in Your App**

After running the test data, your app will show:

### **Level 1: Languages**
```
🇬🇧 English - Learn in English
🇸🇦 العربية - تعلم بالعربية
🇪🇸 Español - Aprende en Español
🇫🇷 Français - Apprendre en Français
```

### **Level 2: Paths (for English)**
```
📚 Islamic Studies - Learn about Islam
📖 Quran Memorization - Memorize the Holy Quran
🔤 Arabic Language - Learn Arabic from scratch
```

### **Level 3: Sections (for Islamic Studies)**
```
🕌 Aqeedah (Belief) - Islamic creed and beliefs
⚖️ Fiqh (Jurisprudence) - Islamic law and rulings
📜 Seerah (Biography) - Life of Prophet Muhammad ﷺ
```

### **Level 4: Branches (for Aqeedah)**
```
☝️ Tawheed (Oneness of Allah) - The fundamental belief
✨ Pillars of Iman - Six pillars of faith
```

### **Level 5: Topics (for Tawheed)**
```
❓ What is Tawheed? - Introduction to Tawheed
📋 Types of Tawheed - Three categories of Tawheed
⚠️ Shirk (Polytheism) - The opposite of Tawheed
```

### **Level 6: Content Items (for "What is Tawheed?")**
```
📝 Definition - Tawheed means the Oneness of Allah...
⭐ Importance - Tawheed is the first pillar of Islam...
📖 Evidence - Allah says in the Quran: "Say, He is Allah..."
```

---

## 🎨 **Sample Content Included**

### **Islamic Studies Path**
- **Aqeedah**: Tawheed, Pillars of Iman
- **Fiqh**: Salah (Prayer), Zakah (Charity), Sawm (Fasting)
- **Seerah**: Early Life, Prophethood

### **Quran Memorization Path**
- Juz 1-10
- Juz 11-20
- Juz 21-30

### **Arabic Language Path**
- **Beginner Level**: Arabic Alphabet, Basic Vocabulary
- **Intermediate Level**: (ready for expansion)

---

## 🔍 **Quick Verification Queries**

### Count items at each level:
```sql
SELECT 
  (SELECT COUNT(*) FROM languages) as languages,
  (SELECT COUNT(*) FROM paths) as paths,
  (SELECT COUNT(*) FROM sections) as sections,
  (SELECT COUNT(*) FROM branches) as branches,
  (SELECT COUNT(*) FROM topics) as topics,
  (SELECT COUNT(*) FROM content_items) as content_items;
```

**Expected result:**
```
languages: 4
paths: 6
sections: 8
branches: 10
topics: 15
content_items: 11
```

### View all languages:
```sql
SELECT name, code, is_active, "order" 
FROM languages 
ORDER BY "order";
```

### View complete hierarchy for English:
```sql
SELECT 
  l.name as language,
  p.name as path,
  s.name as section,
  b.name as branch,
  t.name as topic,
  ci.title as content
FROM languages l
LEFT JOIN paths p ON p.language_id = l.id
LEFT JOIN sections s ON s.path_id = p.id
LEFT JOIN branches b ON b.section_id = s.id
LEFT JOIN topics t ON t.branch_id = b.id
LEFT JOIN content_items ci ON ci.topic_id = t.id
WHERE l.code = 'en'
ORDER BY p."order", s."order", b."order", t."order", ci."order";
```

---

## 🚀 **After Running the SQLs**

1. **Restart your Flutter app**
   ```bash
   flutter run
   ```

2. **Navigate through the hierarchy:**
   - Select **English** → See 3 paths
   - Select **Islamic Studies** → See 3 sections
   - Select **Aqeedah** → See 2 branches
   - Select **Tawheed** → See 3 topics
   - Select **What is Tawheed?** → See 3 content items

3. **Test the test screen:**
   ```dart
   Navigator.pushNamed(context, MyRoutes.supabaseTest);
   ```

---

## 📝 **Customization**

You can easily add more content by following the same pattern:

```sql
-- Add a new language
INSERT INTO languages (id, name, code, is_active, "order") VALUES
(gen_random_uuid(), 'Deutsch', 'de', true, 5);

-- Add a new path
INSERT INTO paths (id, language_id, name, is_active, "order") VALUES
(gen_random_uuid(), 'language-id-here', 'New Path', true, 1);

-- And so on...
```

---

## ✅ **Checklist**

- [ ] Run `add_missing_columns.sql`
- [ ] Run `test_data.sql`
- [ ] Run verification query
- [ ] Restart Flutter app
- [ ] Navigate through hierarchy
- [ ] Test creating new items
- [ ] Test updating items
- [ ] Test the test screen

---

**Your app is now ready with realistic Islamic education content!** 🎉
