# Zad Aldaia - Complete App Logic Flow

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                        │
│  (Screens, Widgets, BLoC/Cubit for State Management)       │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌───────────────────────────────── ────────────────────────────┐
│                     SERVICE LAYER                            │
│  • AuthService        • PostService                          │
│  • BlockService       • ContentService                       │
│  • StorageService                                            │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                     REPOSITORY LAYER                         │
│  • CategoriesRepo (for content hierarchy)                   │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND                          │
│  • PostgreSQL Database    • Authentication                   │
│  • Storage (Images)       • Row Level Security              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 App Initialization Flow

### main.dart Execution Sequence:

```dart
void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Setup Dependency Injection
  await setupGetIt();
  // Registers: AuthService, PostService, BlockService, ContentService, StorageService, CategoriesRepo
  
  // 3. Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  // 4. Initialize Supabase Client
  await initializeSupabase();
  // Sets up connection to: https://YOUR_PROJECT.supabase.co
  
  // 5. Determine Initial Route
  final initialRoute = await _determineInitialRoute();
  // Logic:
  //   - Check if user has seen onboarding (SharedPreferences)
  //   - Check if user is logged in (Supabase.instance.client.auth.currentUser)
  //   - Return: onboarding → login → home
  
  // 6. If user is logged in, initialize block cache
  if (currentUser != null) {
    await getIt<BlockService>().initializeCache();
    // Loads blocked user IDs into memory for fast lookup
  }
  
  // 7. Launch App
  runApp(MyApp(initialRoute: initialRoute));
}
```

---

## 🔐 Authentication Logic

### 1. Signup Flow (New User)

```
┌──────────────────────────────────────────────────────────┐
│ User fills signup form (email, password, display name)   │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ UI calls: AuthCubit.signUp(email, password, displayName) │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ AuthCubit emits: AuthStateLoading()                      │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ AuthService.signUp() → Supabase.auth.signUp()           │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ Supabase creates user in auth.users table                │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ Database Trigger: on_auth_user_created                   │
│ → INSERT into profiles (id, email, display_name)        │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ AuthService returns user (with JWT token)                │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ AuthCubit emits: AuthStateAuthenticated(user)            │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ UI navigates to Home Screen                              │
└──────────────────────────────────────────────────────────┘
```

### 2. Login Flow (Returning User)

```
User enters email/password
  ↓
AuthCubit.signIn(email, password)
  ↓
AuthService.signIn() → Supabase.auth.signInWithPassword()
  ↓
Supabase validates credentials & returns JWT
  ↓
AuthCubit emits: AuthStateAuthenticated(user)
  ↓
BlockService.initializeCache() (loads blocked users)
  ↓
Navigate to Home Screen
```

### 3. Auth State Listener

```dart
// In AuthCubit.listenToAuthChanges()
Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
  if (authState.event == AuthChangeEvent.signedIn) {
    emit(AuthStateAuthenticated(authState.session!.user));
  } else if (authState.event == AuthChangeEvent.signedOut) {
    emit(AuthStateUnauthenticated());
  }
});
```

**This ensures:**
- Token refresh happens automatically
- App reacts to logout from another device
- Session expiration handled gracefully

---

## 📚 Content Hierarchy Logic

### Database Schema Relationships:

```
languages (lang: 'en', 'ar', 'es', etc.)
   ↓ (lang FK)
paths (parent: language_id)
   ↓ (lang + parent_id FK)
sections (parent: path_id)
   ↓ (lang + parent_id FK)
branches (parent: section_id)
   ↓ (lang + parent_id FK)
topics (parent: branch_id)
   ↓ (topic_id FK)
content_items (videos, images, text)
```

### Fetching Flow:

```dart
// User at: Languages Screen
getCategories(null, 'languages')
→ SELECT * FROM languages WHERE is_active = true ORDER BY display_order
→ Returns: [Arabic, English, Spanish, ...]

// User selects: English (id: en-001)
getCategories('en-001', 'paths')
→ SELECT * FROM paths WHERE lang = 'en-001' AND is_active = true ORDER BY display_order
→ Returns: [Pillars of Islam, Stories of Prophets, ...]

// User selects: Pillars of Islam (id: path-001)
getCategories('path-001', 'sections')
→ SELECT * FROM sections WHERE parent_id = 'path-001' AND is_active = true ORDER BY display_order
→ Returns: [Prayer, Fasting, Charity, ...]

// ... continues down to topics
// Finally at topic level:
ContentService.getContentItems('topic-001')
→ SELECT * FROM content_items WHERE topic_id = 'topic-001' ORDER BY display_order
→ Returns: [{type: 'video', url: '...'}, {type: 'text', content: '...'}]
```

### Key Logic Points:

1. **Active Filter:** Only `is_active = true` items shown to public
2. **Ordering:** Always `ORDER BY display_order` for consistent presentation
3. **Hierarchy Navigation:** Each level needs parent_id from previous level
4. **Language Context:** `lang` propagates through paths → sections → branches → topics

---

## 📝 Social Features Logic

### 1. Creating a Post

```
┌─────────────────────────────────────────────────────┐
│ User types post content in UI                       │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ PostService.createPost(content)                     │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ BadWords.containsBadWords(content)                  │
│ → Checks against 6 language dictionaries            │
└─────────────────────────────────────────────────────┘
         ↓ YES                              ↓ NO
┌─────────────────────┐        ┌─────────────────────┐
│ throw Exception     │        │ Continue to DB      │
│ "Contains bad words"│        │                     │
└─────────────────────┘        └─────────────────────┘
                                        ↓
                      ┌─────────────────────────────────┐
                      │ Supabase INSERT into posts:     │
                      │ - author_id (current user)      │
                      │ - content (sanitized text)      │
                      │ - created_at (timestamp)        │
                      └─────────────────────────────────┘
                                        ↓
                      ┌─────────────────────────────────┐
                      │ Return success / Post ID        │
                      └─────────────────────────────────┘
```

### 2. Fetching Posts (Feed)

```sql
-- SQL Query (simplified):
SELECT 
  posts.id,
  posts.content,
  posts.created_at,
  profiles.display_name,
  profiles.avatar_url
FROM posts
JOIN profiles ON posts.author_id = profiles.id
WHERE posts.author_id NOT IN (
  -- Exclude blocked users
  SELECT blocked_id 
  FROM blocked_users 
  WHERE blocker_id = CURRENT_USER_ID
)
ORDER BY posts.created_at DESC
LIMIT 20;
```

**RLS Policy Enforcement:**
- Only authenticated users can see posts
- Each user's query automatically filtered by their blocked list
- Deleted posts immediately removed from feed

### 3. Blocking a User

```
User clicks "Block" on another user's profile
  ↓
BlockService.blockUser(targetUserId)
  ↓
Check if already blocked (in local cache)
  ↓ If not blocked:
INSERT into blocked_users (blocker_id, blocked_id, created_at)
  ↓
Update local cache: _blockedUserIds.add(targetUserId)
  ↓
UI updates: Blocked user's posts removed from feed
```

**Cache Strategy:**
- On app start: Load all blocked users into memory
- On block/unblock: Update both database AND cache
- On query: Use cache for instant check (`isBlockedSync()`)

---

## 🎯 Row Level Security (RLS) Logic

### How RLS Works:

```sql
-- Example: posts table RLS policy
CREATE POLICY "Users can only see non-blocked posts"
ON posts FOR SELECT
USING (
  author_id NOT IN (
    SELECT blocked_id 
    FROM blocked_users 
    WHERE blocker_id = auth.uid()
  )
);
```

**Effect:**
- Every SELECT query automatically filtered
- User A cannot see User B's posts if A blocked B
- No way to bypass this from client code
- Enforced at database level for security

### RLS on Content Tables:

```sql
-- Public users see only active items
CREATE POLICY "Public can read active languages"
ON languages FOR SELECT
USING (is_active = true);

-- Authenticated users see all items (for admin purposes)
CREATE POLICY "Authenticated users can read all languages"
ON languages FOR SELECT
TO authenticated
USING (true);
```

---

## 🔄 Data Synchronization

### Optimistic UI Updates:

```dart
// Example: Deleting a post
Future<void> deletePost(String postId) async {
  // 1. Immediately remove from UI (optimistic)
  localPostList.removeWhere((post) => post.id == postId);
  notifyListeners();
  
  // 2. Try to delete from database
  try {
    await Supabase.client.from('posts').delete().eq('id', postId);
  } catch (e) {
    // 3. If fails, restore in UI and show error
    localPostList.add(originalPost);
    notifyListeners();
    showErrorToast('Failed to delete');
  }
}
```

### Real-time Updates (Optional Enhancement):

```dart
// Listen for new posts in real-time
Supabase.client
  .from('posts')
  .stream(primaryKey: ['id'])
  .listen((List<Map<String, dynamic>> data) {
    // Update UI with new posts as they arrive
    updatePostsFeed(data);
  });
```

---

## 🛡️ Error Handling Strategy

### Network Errors:

```dart
try {
  await PostService.getPosts();
} on PostgrestException catch (e) {
  // Database-specific error (e.g., constraint violation)
  handleDatabaseError(e.message);
} on AuthException catch (e) {
  // Authentication error (e.g., token expired)
  handleAuthError(e.message);
  // Redirect to login
} catch (e) {
  // Generic error
  showGenericError('Something went wrong');
}
```

### User-Friendly Messages:

| Error Code | User Message |
|-----------|-------------|
| `PGRST116` | "You don't have permission to do this" |
| `23505` (unique violation) | "This item already exists" |
| `23503` (foreign key) | "Related item not found" |
| Network timeout | "Check your internet connection" |
| Token expired | "Please log in again" |

---

## 📊 Performance Optimizations

### 1. Lazy Loading:
- GetIt services registered as `registerLazySingleton`
- Only instantiated when first accessed
- Reduces app startup time

### 2. Block Cache:
- Loads all blocked users on app start (typically < 100 IDs)
- Subsequent checks are instant (no DB query)
- Invalidated on block/unblock actions

### 3. Pagination (Recommended for posts):
```dart
Future<List<Post>> getPosts({int page = 0, int pageSize = 20}) async {
  final offset = page * pageSize;
  return await Supabase.client
    .from('posts')
    .select()
    .order('created_at', ascending: false)
    .range(offset, offset + pageSize - 1);
}
```

### 4. Image Caching:
- Use `cached_network_image` package
- Images cached locally after first load
- Reduces bandwidth usage

---

## 🧪 Testing Strategy

### Unit Tests:
```dart
test('BadWords filter catches profanity', () {
  expect(BadWords.containsBadWords('This is stupid'), isTrue);
  expect(BadWords.containsBadWords('This is great'), isFalse);
});

test('BlockService adds user to cache', () async {
  await blockService.blockUser('user123');
  expect(blockService.isBlockedSync('user123'), isTrue);
});
```

### Integration Tests:
```dart
testWidgets('User can create post', (tester) async {
  // Navigate to create post screen
  await tester.tap(find.byIcon(Icons.add));
  
  // Enter text
  await tester.enterText(find.byType(TextField), 'Test post');
  
  // Submit
  await tester.tap(find.text('Post'));
  
  // Verify post appears in feed
  expect(find.text('Test post'), findsOneWidget);
});
```

---

## 🚨 Critical Logic Checks

### ✅ Always Verify:

1. **User is authenticated before:**
   - Creating posts
   - Blocking users
   - Updating profile

2. **Data validation before:**
   - Saving to database (non-null fields)
   - Displaying in UI (handle null values)

3. **RLS policies enforce:**
   - Users can't see blocked posts
   - Users can only update own data
   - Public users see only active content

4. **Bad words filter runs:**
   - Before creating posts
   - Before updating profile bio
   - On any user-generated content

5. **Navigation state:**
   - User can't access home without auth
   - Back button works at all levels
   - Logout clears navigation stack

---

## 📈 Future Enhancements

### Recommended Features:

1. **Real-time Notifications:**
   - Use Supabase Realtime subscriptions
   - Notify users of new posts, comments, likes

2. **Search Functionality:**
   - Full-text search on content items
   - Search posts by keyword

3. **Analytics:**
   - Track user engagement (views, time spent)
   - Popular content insights

4. **Offline Support:**
   - Cache content for offline viewing
   - Sync posts when back online

5. **Moderation:**
   - Admin dashboard to manage users/posts
   - Report inappropriate content

---

## 🎉 Summary

Your app follows this logic flow:

1. **Initialization:** Setup DI → Supabase → Auth check → Navigate
2. **Authentication:** Signup/Login → Profile creation → Block cache → Home
3. **Content:** Hierarchical navigation (6 levels) → Ordered by display_order
4. **Social:** Create posts → Bad words filter → RLS blocks → Feed updates
5. **Privacy:** Block users → Cache update → Posts filtered from feed
6. **Security:** RLS enforces all permissions at database level

**Every action is:**
- ✅ Validated (bad words, auth status)
- ✅ Secured (RLS policies)
- ✅ Cached (block list for performance)
- ✅ Error-handled (try-catch with user messages)

This ensures a **robust, secure, and performant** app experience.
