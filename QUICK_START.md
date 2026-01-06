# 🚀 Quick Start - Database Setup

## ⚡ Run This in Supabase SQL Editor

### Step 1: Open SQL Editor
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Click **"SQL Editor"** in sidebar
4. Click **"New Query"**

### Step 2: Copy Complete Setup
Open this file: `/supabase/complete_setup.sql`

**OR** if you prefer, here's the direct path:
```
/Users/ibrahim/Documents/contributions/zad_aldaia_flutter-main/supabase/complete_setup.sql
```

### Step 3: Execute
1. **Copy ENTIRE file contents** (all ~700 lines)
2. **Paste** into SQL Editor
3. Click **"Run"** (or press Ctrl/Cmd + Enter)

### Step 4: Verify Success
You should see:
```
✅ Success. No rows returned
```

**If you see errors:**
- Check that you're using PostgreSQL 13+
- Make sure no other user is editing tables
- Try running in smaller sections

### Step 5: Verify Data
Run this query to confirm everything worked:
```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check data counts
SELECT 
  (SELECT COUNT(*) FROM languages) as languages,
  (SELECT COUNT(*) FROM paths) as paths,
  (SELECT COUNT(*) FROM sections) as sections,
  (SELECT COUNT(*) FROM branches) as branches,
  (SELECT COUNT(*) FROM topics) as topics,
  (SELECT COUNT(*) FROM content_items) as content_items,
  (SELECT COUNT(*) FROM articles) as articles,
  (SELECT COUNT(*) FROM article_items) as article_items;
```

**Expected Output:**
```
languages: 5
paths: 3
sections: 3
branches: 2
topics: 2
content_items: 2
articles: 3
article_items: 4
```

---

## 📱 Then Run Your App

```bash
cd /Users/ibrahim/Documents/contributions/zad_aldaia_flutter-main
flutter pub get
flutter run
```

---

## ✅ Done!

Your database is now set up with:
- ✅ Content hierarchy (6 levels)
- ✅ Social features (posts, blocking, profiles)
- ✅ Row Level Security policies
- ✅ Test data (3,030 rows)
- ✅ Proper column names (display_order instead of order)

---

## 🚨 Troubleshooting

### "syntax error near..."
**Issue:** Partial copy/paste  
**Fix:** Copy ENTIRE file, not just parts

### "permission denied"
**Issue:** RLS preventing operation  
**Fix:** Make sure you're logged in as owner/admin in Supabase Dashboard

### "column order does not exist"
**Issue:** Old schema still present  
**Fix:** The `complete_setup.sql` drops old tables first. Run the complete file.

---

## 📚 Need More Details?

See full documentation:
- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - Complete overview
- [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) - Testing guide
- [APP_LOGIC_FLOW.md](APP_LOGIC_FLOW.md) - Architecture details
