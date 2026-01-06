# Zad Aldaia - Complete Setup & Verification Checklist

## 🎯 Overview
This document ensures your app is fully functional from database to UI.

---

## 📊 Database Setup

### Step 1: Run Complete Setup SQL
1. Open Supabase Dashboard → SQL Editor
2. Copy **entire contents** of `/supabase/complete_setup.sql`
3. Click "Run"
4. ✅ Expected: All statements execute successfully
5. ❌ If errors occur: Check error message and verify PostgreSQL versio n
 
### Step 2: Verify Database Structure
Run this query in SQL Editor:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

✅ Expected tables:
- `blocked_users`
- `branches`
- `content_items`
- `languages`
- `paths`
- `posts`
- `profiles`
- `sections`
- `topics`

### Step 3: Verify Test Data
```sql
-- Check languages
SELECT id, name, is_active FROM languages;
-- Should have 5 languages: Arabic, English, Spanish, Portuguese, Filipino

-- Check content hierarchy
SELECT 
  (SELECT COUNT(*) FROM languages) as languages,
  (SELECT COUNT(*) FROM paths) as paths,
  (SELECT COUNT(*) FROM sections) as sections,
  (SELECT COUNT(*) FROM branches) as branches,
  (SELECT COUNT(*) FROM topics) as topics,
  (SELECT COUNT(*) FROM content_items) as content_items;
-- Should have data at all levels
```

### Step 4: Verify RLS Policies
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

✅ Expected: Multiple policies for each table (read, insert, update, delete)

---

## 🔐 Authentication Flow

### Test Sequence:
1. **First Launch (No Account)**
   - ✅ Shows Onboarding Screen
   - ✅ "Get Started" navigates to Login/Signup
   - ✅ Can create new account
   - ✅ On signup success → redirects to Home

2. **Subsequent Launches (Existing Account)**
   - ✅ Skips Onboarding (shown only once)
   - ✅ If logged out → shows Login Screen
   - ✅ If logged in → goes directly to Home

3. **Login Flow**
   ```
   User enters email/password → AuthCubit.signIn()
   ↓
   Supabase Auth validates credentials
   ↓
   AuthStateAuthenticated emitted
   ↓
   BlockService.initializeCache() called
   ↓
   Navigates to Home Screen
   ```

4. **Signup Flow**
   ```
   User enters email/password → AuthCubit.signUp()
   ↓
   Supabase creates user account
   ↓
   Trigger auto-creates profile in profiles table
   ↓
   AuthStateAuthenticated emitted
   ↓
   Navigates to Home Screen
   ```

5. **Logout Flow**
   ```
   User clicks logout → AuthCubit.signOut()
   ↓
   Supabase signs out user
   ↓
   AuthStateUnauthenticated emitted
   ↓
   Navigates to Login Screen
   ```

### Verification Steps:
```bash
# Run the app
flutter run

# Check console logs for:
# - "Supabase initialized successfully"
# - "Block cache initialized: X users blocked"
# - Auth state changes
```

---

## 📚 Content Fetching Flow

### Hierarchy Navigation:
```
Languages Screen → Select Language (e.g., English)
  ↓
Paths Screen → Select Path (e.g., "Pillars of Islam")
  ↓
Sections Screen → Select Section (e.g., "Prayer")
  ↓
Branches Screen → Select Branch (e.g., "Conditions of Prayer")
  ↓
Topics Screen → Select Topic (e.g., "Purity")
  ↓
Content Items Screen → View videos, images, text
```

### Data Flow:
```dart
// Example: Fetching paths for a language
UI calls → CategoriesRepo.getCategories(languageId, 'paths')
  ↓
Supabase query: SELECT * FROM paths WHERE lang = ? AND is_active = true ORDER BY display_order
  ↓
Returns List<Category>
  ↓
UI displays in ListView
```

### Verification Points:
1. ✅ Each level loads data for selected parent
2. ✅ Items are ordered by `display_order` column
3. ✅ Only `is_active = true` items are shown to public users
4. ✅ Images load correctly (if stored in Supabase Storage)
5. ✅ Navigation stack works (back button returns to previous level)

---

## 🚫 Blocking & Privacy Flow

### Block User Flow:
```
User A blocks User B
  ↓
BlockService.blockUser(userB_id)
  ↓
INSERT into blocked_users (blocker_id=A, blocked_id=B)
  ↓
Cache updated: _blockedUserIds.add(B)
  ↓
User B's posts no longer visible to User A
```

### Verification:
1. Create 2 test accounts
2. Post from Account B
3. Login as Account A → verify you see the post
4. Block Account B → verify post disappears
5. Check database:
   ```sql
   SELECT * FROM blocked_users WHERE blocker_id = 'account_a_id';
   ```

---

## 📝 Posts & Social Features

### Create Post Flow:
```
User writes post → PostService.createPost(content)
  ↓
Bad words filter checks content (multilingual)
  ↓
If clean: INSERT into posts (author_id, content, created_at)
  ↓
If contains bad words: throw Exception
  ↓
Post appears in feed
```

### Get Posts Flow:
```
User opens feed → PostService.getPosts()
  ↓
Query: SELECT posts.*, profiles.* 
       FROM posts 
       JOIN profiles ON posts.author_id = profiles.id
       WHERE posts.author_id NOT IN (blocked users)
       ORDER BY created_at DESC
  ↓
Returns List<Post> with author info
  ↓
UI displays in feed
```

### Verification:
1. ✅ Create post with normal content → succeeds
2. ✅ Try creating post with bad words → fails with error
3. ✅ Blocked users' posts don't appear in your feed
4. ✅ Can delete own posts
5. ✅ Cannot delete others' posts

---

## 🔍 Testing Bad Words Filter

Test with these phrases (should be **rejected**):
- English: "This is stupid"
- Arabic: "هذا غبي" (contains a bad word)
- Spanish: "Eres tonto"
- Multiple words: "This post is stupid and dumb"

Test with these phrases (should be **accepted**):
- "This is a great post"
- "مرحبا بك" (Arabic: Welcome)
- "Hola amigos"

---

## 🛠️ Dependency Injection Verification

All services should be registered in `setupGetIt()`:

```bash
# Check registration
grep "registerLazySingleton" lib/core/di/dependency_injection.dart
```

✅ Expected registrations:
- `AuthService`
- `PostService`
- `BlockService`
- `ContentService`
- `StorageService`
- `CategoriesRepo`

---

## 🚨 Common Issues & Solutions

### Issue: "column order does not exist"
**Solution:** You're using old schema. Run `/supabase/complete_setup.sql` instead.

### Issue: "relation profiles does not exist"
**Solution:** Profile auto-creation trigger failed. Check if trigger exists:
```sql
SELECT * FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created';
```

### Issue: Posts not showing
**Check:**
1. RLS policies enabled on `posts` table
2. User is authenticated
3. Posts exist in database: `SELECT * FROM posts;`

### Issue: Images not loading
**Check:**
1. Supabase Storage bucket created (name: `content-images` or similar)
2. Bucket is public
3. `image_identifier` column has correct path

### Issue: App crashes on startup
**Check console for:**
- Supabase connection errors (invalid URL/anon key)
- Missing dependencies: run `flutter pub get`
- Platform-specific issues: clean build `flutter clean && flutter pub get`

---

## ✅ Final Verification Checklist

- [ ] Database setup completed without errors
- [ ] Test data exists (5 languages, multiple paths/sections/etc.)
- [ ] RLS policies active on all tables
- [ ] Can signup new account
- [ ] Profile auto-created after signup
- [ ] Can login with existing account
- [ ] Onboarding shows only on first run
- [ ] Can navigate language → path → section → branch → topic → content
- [ ] Items display in correct order (by display_order)
- [ ] Can create posts
- [ ] Bad words filter works
- [ ] Can block/unblock users
- [ ] Blocked users' posts hidden from feed
- [ ] Can logout successfully
- [ ] No critical errors in console

---

## 🎉 Success Criteria

Your app is **fully functional** when:
1. ✅ A new user can signup → see onboarding → navigate content → create post
2. ✅ Returning user auto-logs in → browses content → interacts with posts
3. ✅ Privacy features work (blocking prevents posts from appearing)
4. ✅ Content hierarchy displays correctly at all 6 levels
5. ✅ No SQL errors, no authentication errors, no missing services

---

## 📞 Need Help?

If you encounter issues:
1. Check Supabase Dashboard → Logs (API logs, Database logs)
2. Check Flutter console output
3. Verify environment: `flutter doctor`
4. Verify Supabase credentials in `main.dart` match your project

**Last Updated:** 2025 - After fixing PostgreSQL reserved keyword issue
