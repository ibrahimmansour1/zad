# Admin Panel Features - Complete System Design

## Executive Summary

This document provides a comprehensive design for 6 critical admin panel features:
1. **Ordering Articles Inside Subcategories**
2. **Fix Ordering Bug (Critical)**
3. **Admin Copy/Clone/Paste System**
4. **Recycle Bin (Soft Delete System)**
5. **Reference System (No Duplication)**
6. **Admin ↔ User Mode Switch**

---

## Table of Contents

1. [Current System Analysis](#current-system-analysis)
2. [1️⃣ Article Ordering System](#1️⃣-article-ordering-system)
3. [2️⃣ Ordering Bug Root Cause & Fix](#2️⃣-ordering-bug-root-cause--fix)
4. [3️⃣ Copy/Clone/Paste System](#3️⃣-copyclonepaste-system)
5. [4️⃣ Recycle Bin Enhancement](#4️⃣-recycle-bin-enhancement)
6. [5️⃣ Reference System](#5️⃣-reference-system)
7. [6️⃣ Admin/User Mode Switch](#6️⃣-adminuser-mode-switch)
8. [Database Schema Changes](#database-schema-changes)
9. [Implementation Roadmap](#implementation-roadmap)

---

## Current System Analysis

### Content Hierarchy
```
Languages → Paths → Sections → Branches → Topics → Content Items
                                              ↓
                              (Legacy: Categories → Articles → Article Items)
```

### Current Data Models

| Table | Has `order`/`display_order` | Parent Field |
|-------|---------------------------|--------------|
| `languages` | No | - |
| `paths` | `order` INTEGER | `language_id` |
| `sections` | `order` INTEGER | `path_id` |
| `branches` | `order` INTEGER | `section_id` |
| `topics` | `order` INTEGER | `branch_id` |
| `content_items` | `order` INTEGER | `topic_id` |
| `articles` | ❌ **NO ORDER FIELD** | `category_id` |
| `article_items` | `order` INTEGER | `article_id` |

### Current Ordering Implementation

**Location:** `items_repo.dart`, `categories_repo.dart`

```dart
// Current buggy swap implementation
Future<bool> swapItemsOrder(String id1, String id2, int index1, int index2) async {
  await _supabase.from('article_items').update({'order': index2}).eq('id', id1);
  await _supabase.from('article_items').update({'order': index1}).eq('id', id2);
  return true;
}
```

---

## 1️⃣ Article Ordering System

### Problem
Articles within subcategories (topics/categories) cannot be explicitly ordered. They are fetched without any deterministic order.

### Solution

#### 1.1 Add `display_order` to Articles Table

```sql
ALTER TABLE articles ADD COLUMN display_order INTEGER DEFAULT 0;
CREATE INDEX idx_articles_display_order ON articles(display_order);
```

#### 1.2 Update Article Model

```dart
class Article {
  String id;
  String? categoryId;
  String? title;
  int displayOrder; // NEW
  // ... other fields
}
```

#### 1.3 Add Ordering UI to Articles Screen

The ArticlesScreen should have:
- Move up/down buttons (like categories)
- A popup menu with ordering options
- Drag-and-drop reordering (optional enhancement)

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| New article created | Assign `max(display_order) + 1` within the category |
| Article moved to different category | Assign `max(display_order) + 1` in new category |
| Article deleted | No re-normalization needed (gaps allowed) |
| Bulk import | Assign sequential order starting from max |

---

## 2️⃣ Ordering Bug Root Cause & Fix

### Root Cause Analysis

The current ordering system has **THREE critical bugs**:

#### Bug 1: Non-Atomic Swaps
```dart
// CURRENT: Two separate updates - NOT atomic!
await _supabase.from('article_items').update({'order': index2}).eq('id', id1);
await _supabase.from('article_items').update({'order': index1}).eq('id', id2);
```

**Problem:** If the second update fails, orders become inconsistent.

#### Bug 2: Using List Index Instead of Stored Order Value
```dart
// CURRENT: Uses UI list index, not actual database order value
_swapItems(item.id, prevItemId, index, index - 1)
```

**Problem:** The `index` in the UI list may not match the `order` value in the database, especially after multiple swaps without reload.

#### Bug 3: Parallel Updates in `ContentOrderingService`
```dart
await Future.wait([
  _supabase.from(tableName).update({'display_order': order2}).eq('id', id1),
  _supabase.from(tableName).update({'display_order': order1}).eq('id', id2),
]);
```

**Problem:** Parallel updates can cause race conditions in some databases.

### Solution: Deterministic Ordering System

#### Principle 1: Use Stored Order Values, Not UI Indices

```dart
Future<void> swapItems(String id1, String id2) async {
  // 1. Fetch ACTUAL order values from database
  final item1 = await _fetchItem(id1);
  final item2 = await _fetchItem(id2);
  
  // 2. Swap using actual values
  await _atomicSwap(id1, item2.order, id2, item1.order);
}
```

#### Principle 2: Use Database Transactions for Atomicity

```dart
// PostgreSQL function for atomic swap
CREATE OR REPLACE FUNCTION swap_order(
  p_table TEXT,
  p_id1 UUID,
  p_id2 UUID
) RETURNS VOID AS $$
DECLARE
  v_order1 INT;
  v_order2 INT;
BEGIN
  -- Get current orders
  EXECUTE format('SELECT display_order FROM %I WHERE id = $1', p_table) INTO v_order1 USING p_id1;
  EXECUTE format('SELECT display_order FROM %I WHERE id = $1', p_table) INTO v_order2 USING p_id2;
  
  -- Swap atomically
  EXECUTE format('UPDATE %I SET display_order = $1 WHERE id = $2', p_table) USING v_order2, p_id1;
  EXECUTE format('UPDATE %I SET display_order = $1 WHERE id = $2', p_table) USING v_order1, p_id2;
END;
$$ LANGUAGE plpgsql;
```

#### Principle 3: Normalize Orders Periodically

Over time, gaps in order values can accumulate. Add a normalization function:

```dart
Future<void> normalizeOrders({
  required String tableName,
  required String parentField,
  required String parentId,
}) async {
  final items = await _supabase
    .from(tableName)
    .select('id')
    .eq(parentField, parentId)
    .order('display_order');
  
  for (int i = 0; i < items.length; i++) {
    await _supabase.from(tableName)
      .update({'display_order': i})
      .eq('id', items[i]['id']);
  }
}
```

#### Implementation: Enhanced Ordering Service

```dart
class ContentOrderingService {
  /// Move item up (swap with previous item)
  Future<bool> moveUp({
    required String itemId,
    required String tableName,
    required String parentField,
    required String parentId,
  }) async {
    final items = await _getOrderedItems(tableName, parentField, parentId);
    final currentIndex = items.indexWhere((i) => i['id'] == itemId);
    
    if (currentIndex <= 0) return false; // Already first
    
    final prevItem = items[currentIndex - 1];
    return await _swapOrders(
      tableName,
      itemId, items[currentIndex]['display_order'],
      prevItem['id'], prevItem['display_order'],
    );
  }
  
  /// Move item down (swap with next item)
  Future<bool> moveDown({
    required String itemId,
    required String tableName,
    required String parentField,
    required String parentId,
  }) async {
    final items = await _getOrderedItems(tableName, parentField, parentId);
    final currentIndex = items.indexWhere((i) => i['id'] == itemId);
    
    if (currentIndex >= items.length - 1) return false; // Already last
    
    final nextItem = items[currentIndex + 1];
    return await _swapOrders(
      tableName,
      itemId, items[currentIndex]['display_order'],
      nextItem['id'], nextItem['display_order'],
    );
  }
  
  Future<bool> _swapOrders(
    String tableName,
    String id1, int order1,
    String id2, int order2,
  ) async {
    // Use RPC call for atomic swap
    await _supabase.rpc('swap_display_order', params: {
      'p_table': tableName,
      'p_id1': id1,
      'p_order1': order2,  // Swapped!
      'p_id2': id2,
      'p_order2': order1,  // Swapped!
    });
    return true;
  }
}
```

### Why This Solution Works

1. **Fetches actual order values** from DB before swap
2. **Atomic transaction** ensures both updates succeed or both fail
3. **No reliance on UI state** which can become stale
4. **Deterministic** - same input always produces same output

---

## 3️⃣ Copy/Clone/Paste System

### Current State
- `ContentClipboardService` exists - stores content in memory
- `ContentPasteService` exists - deep copies content

### Enhanced Design

#### 3.1 Paste Modes

| Mode | Behavior |
|------|----------|
| **Clone** | Create independent copy with new IDs |
| **Reference** | Create a reference link (see section 5) |
| **Move** | Remove from source, paste to destination |

#### 3.2 Enhanced Clipboard Content

```dart
class ClipboardContent {
  final String sourceId;
  final String sourceType;
  final String sourcePath; // Full path: lang/path/section/branch/topic
  final Map<String, dynamic> data;
  final DateTime copiedAt;
  final bool includeChildren; // Whether to copy child content
}
```

#### 3.3 UI Flow

```
[Admin selects item] → [Context menu: Copy]
                     ↓
[Admin navigates to destination]
                     ↓
[Paste button appears] → [Dialog: "How would you like to paste?"]
                              • Clone as new content
                              • Paste as reference
                              • Move here (removes from original)
                     ↓
[Execute paste operation]
```

#### 3.4 Path Re-mapping

When pasting into a different language/category:

```dart
Future<String> pasteWithRemap({
  required String targetParentId,
  required PasteMode mode,
}) async {
  final content = _clipboard.getCopiedContent();
  
  // Determine new path structure
  final targetPath = await _resolveParentPath(targetParentId);
  
  // If crossing language boundaries, prompt for translation
  if (content.sourcePath.split('/').first != targetPath.split('/').first) {
    // Show translation prompt or warning
  }
  
  // Execute paste based on mode
  switch (mode) {
    case PasteMode.clone:
      return await _deepClone(content, targetParentId);
    case PasteMode.reference:
      return await _createReference(content, targetParentId);
    case PasteMode.move:
      return await _moveContent(content, targetParentId);
  }
}
```

#### 3.5 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Paste into same location | Add "(Copy)" suffix, increment order |
| Paste across languages | Warning dialog, proceed with clone |
| Clipboard expires | Auto-clear after 30 minutes |
| Source deleted while in clipboard | Show error on paste attempt |
| Reference paste | Create `content_references` entry |

---

## 4️⃣ Recycle Bin Enhancement

### Current State
- `SoftDeleteService` exists with basic soft delete
- `RecycleBinScreen` shows deleted items by table

### Enhanced Design

#### 4.1 Retention Policy

```dart
const Duration RECYCLE_BIN_RETENTION = Duration(days: 30);
```

Items older than 30 days are auto-purged by a scheduled function.

#### 4.2 Cascade Soft Delete

When a parent is deleted, all children must also be soft-deleted:

```dart
Future<void> cascadeSoftDelete({
  required String id,
  required String tableName,
}) async {
  // Mark this item as deleted
  await _softDelete(id, tableName);
  
  // Find and delete all children
  final childTable = _getChildTableName(tableName);
  if (childTable != null) {
    final children = await _getChildren(id, tableName, childTable);
    for (final child in children) {
      await cascadeSoftDelete(id: child['id'], tableName: childTable);
    }
  }
}
```

#### 4.3 Reference Handling on Delete

```dart
Future<void> softDeleteWithReferenceCheck({
  required String id,
  required String tableName,
}) async {
  // Check for references
  final references = await _getReferences(id);
  
  if (references.isNotEmpty) {
    // Option 1: Block deletion
    throw ReferenceExistsException(
      'Cannot delete: ${references.length} references exist',
      references: references,
    );
    
    // Option 2: Cascade delete references
    // for (final ref in references) {
    //   await softDelete(ref.id, 'content_references');
    // }
  }
  
  await cascadeSoftDelete(id: id, tableName: tableName);
}
```

#### 4.4 Restore with Parent Check

```dart
Future<void> restoreWithValidation({
  required String id,
  required String tableName,
}) async {
  final item = await _getItem(id, tableName);
  final parentField = _getParentField(tableName);
  
  // Check if parent exists and is not deleted
  if (item[parentField] != null) {
    final parentTable = _getParentTable(tableName);
    final parent = await _getItem(item[parentField], parentTable);
    
    if (parent == null || parent['is_deleted'] == true) {
      throw ParentDeletedException(
        'Cannot restore: Parent is deleted. Restore parent first.',
      );
    }
  }
  
  await _restore(id, tableName);
}
```

#### 4.5 Enhanced UI

```dart
class RecycleBinItem {
  final String id;
  final String type;
  final String title;
  final DateTime deletedAt;
  final String? deletedBy;
  final int daysUntilPermanentDeletion;
  final List<String> childrenIds; // For restore preview
  final List<String> referenceIds; // References that will break
}
```

---

## 5️⃣ Reference System

### Core Principle
> An article or item must exist in **one place only** as the original content.
> References are **pointers**, not copies.

### 5.1 Database Schema

```sql
CREATE TABLE content_references (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- The original content being referenced
  original_id UUID NOT NULL,
  original_table TEXT NOT NULL, -- 'articles', 'article_items', 'content_items', etc.
  
  -- Where this reference appears
  parent_id UUID NOT NULL,
  parent_table TEXT NOT NULL, -- The container table
  
  -- Display properties
  display_order INTEGER DEFAULT 0,
  custom_title TEXT, -- Optional override title
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  UNIQUE(original_id, parent_id) -- Prevent duplicate references
);

CREATE INDEX idx_refs_original ON content_references(original_id);
CREATE INDEX idx_refs_parent ON content_references(parent_id);
```

### 5.2 Reference Model

```dart
class ContentReference {
  final String id;
  final String originalId;
  final String originalTable;
  final String parentId;
  final String parentTable;
  final int displayOrder;
  final String? customTitle;
  final DateTime createdAt;
  final bool isDeleted;
  
  // Resolved at runtime
  Map<String, dynamic>? originalContent;
  String? originalPath;
}
```

### 5.3 Reference Resolution

```dart
class ReferenceService {
  /// Resolve a reference to get the original content
  Future<Map<String, dynamic>?> resolveReference(ContentReference ref) async {
    return await _supabase
      .from(ref.originalTable)
      .select()
      .eq('id', ref.originalId)
      .eq('is_deleted', false)
      .maybeSingle();
  }
  
  /// Get full path to original content for navigation
  Future<String> getOriginalPath(ContentReference ref) async {
    final original = await resolveReference(ref);
    if (original == null) return '';
    
    // Build path based on table type
    return await _buildContentPath(ref.originalId, ref.originalTable);
  }
  
  /// Check if content has any references
  Future<List<ContentReference>> getReferences(String contentId) async {
    final refs = await _supabase
      .from('content_references')
      .select()
      .eq('original_id', contentId)
      .eq('is_deleted', false);
    
    return refs.map((r) => ContentReference.fromJson(r)).toList();
  }
}
```

### 5.4 UI Behavior

#### Creating a Reference

```dart
// In paste dialog
showDialog(
  child: AlertDialog(
    title: Text('Add Content'),
    content: Column(
      children: [
        ListTile(
          leading: Icon(Icons.content_copy),
          title: Text('Clone as new content'),
          subtitle: Text('Creates independent copy'),
          onTap: () => _paste(PasteMode.clone),
        ),
        ListTile(
          leading: Icon(Icons.link),
          title: Text('Add as reference'),
          subtitle: Text('Links to original, updates automatically'),
          onTap: () => _paste(PasteMode.reference),
        ),
      ],
    ),
  ),
);
```

#### Displaying References

```dart
Widget buildContentItem(dynamic item) {
  if (item is ContentReference) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        children: [
          // Reference indicator
          Container(
            color: Colors.blue.shade50,
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.blue),
                Text(' Reference', style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
          // Resolved content
          FutureBuilder(
            future: _resolveReference(item),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildResolvedContent(snapshot.data);
              }
              return CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
  return _buildNormalItem(item);
}
```

#### Clicking a Reference

```dart
void onReferenceTap(ContentReference ref) async {
  // Navigate to original content location
  final path = await _referenceService.getOriginalPath(ref);
  Navigator.pushNamed(context, path);
}
```

### 5.5 Original Content Movement

When original content is moved:

```dart
Future<void> moveContent({
  required String contentId,
  required String newParentId,
  required String tableName,
}) async {
  // Update content's parent
  final parentField = _getParentField(tableName);
  await _supabase
    .from(tableName)
    .update({parentField: newParentId})
    .eq('id', contentId);
  
  // References automatically still work because they point to ID, not location!
  // No reference updates needed.
}
```

### 5.6 Original Content Deletion

**Recommended Strategy: Block Deletion**

```dart
Future<void> deleteContent(String id, String tableName) async {
  final refs = await _referenceService.getReferences(id);
  
  if (refs.isNotEmpty) {
    throw ContentHasReferencesException(
      message: 'Cannot delete: This content is referenced in ${refs.length} locations.',
      references: refs,
      options: [
        'Delete all references first',
        'Replace references with clones',
        'Move references to recycle bin',
      ],
    );
  }
  
  await _softDelete(id, tableName);
}
```

**Alternative: Orphan References**

```dart
// Mark reference as orphaned instead of deleting
await _supabase
  .from('content_references')
  .update({'is_orphaned': true, 'orphaned_at': DateTime.now()})
  .eq('original_id', id);
```

### 5.7 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Original deleted | Block deletion OR mark references as orphaned |
| Original moved | References still work (point to ID) |
| Reference clicked | Navigate to original location |
| Original updated | All references see new content immediately |
| Original restored from bin | References automatically work again |
| Circular references | Prevented by unique constraint + validation |

---

## 6️⃣ Admin/User Mode Switch

### Current State
- `AdminModeService` exists - toggles mode via SharedPreferences
- `AdminModeToggle` widget appears in app bar
- `AdminModeQuickToggle` is a compact version

### Issues with Current Implementation
1. Toggle visible to non-admin users
2. Placed in navigation bar (should be in menu)
3. No clear visual indication of current mode

### Enhanced Design

#### 6.1 Visibility Logic

```dart
class AdminModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = getIt<AdminAuthService>();
    final modeService = getIt<AdminModeService>();
    
    // ONLY show if admin is logged in
    if (!authService.isAdminLoggedIn) {
      return SizedBox.shrink();
    }
    
    return _buildToggle(modeService);
  }
}
```

#### 6.2 Placement in Menu

Remove from app bar, add to drawer/menu:

```dart
// In app drawer/menu
Drawer(
  child: ListView(
    children: [
      // ... other menu items
      
      // Admin section - only visible to admins
      if (authService.isAdminLoggedIn) ...[
        Divider(),
        ListTile(
          leading: Icon(Icons.admin_panel_settings),
          title: Text('Admin Controls'),
        ),
        AdminModeToggleInMenu(), // New widget for menu placement
        ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Recycle Bin'),
          onTap: () => Navigator.pushNamed(context, MyRoutes.recycleBin),
        ),
      ],
    ],
  ),
)
```

#### 6.3 Clear Mode Indication

Add a persistent banner when in admin mode:

```dart
class AdminModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modeService = getIt<AdminModeService>();
    
    if (!modeService.isAdminMode) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      color: Colors.red.shade600,
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'ADMIN MODE - Changes affect live content',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 6.4 Permission Logic

```dart
class AdminModeService extends ChangeNotifier {
  Future<void> enableAdminMode() async {
    final authService = getIt<AdminAuthService>();
    
    // Double-check admin is logged in
    if (!authService.isAdminLoggedIn) {
      throw UnauthorizedException('Admin login required');
    }
    
    // Verify session is still valid
    final isSessionValid = await authService.verifySession();
    if (!isSessionValid) {
      throw SessionExpiredException('Admin session expired');
    }
    
    _isAdminMode = true;
    await _saveToPrefs();
    notifyListeners();
  }
  
  /// Auto-disable admin mode when session expires
  void onSessionExpired() {
    if (_isAdminMode) {
      _isAdminMode = false;
      _saveToPrefs();
      notifyListeners();
    }
  }
}
```

#### 6.5 UX Flow

```
[User opens app]
      ↓
[Is admin logged in?]
      ↓ NO
[Menu shows normal items only]
      ↓
[Admin logs in]
      ↓
[Menu now shows "Admin Controls" section]
      ↓
[Admin toggles "Admin Mode" switch]
      ↓
[Red banner appears at top]
[Admin-only buttons appear throughout app]
      ↓
[Admin toggles off OR session expires]
      ↓
[Banner disappears, admin buttons hidden]
```

---

## Database Schema Changes

### Required SQL Migrations

```sql
-- 1. Add display_order to articles
ALTER TABLE articles ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_articles_display_order ON articles(display_order);

-- 2. Standardize order column names (use display_order everywhere)
ALTER TABLE paths RENAME COLUMN "order" TO display_order;
ALTER TABLE sections RENAME COLUMN "order" TO display_order;
ALTER TABLE branches RENAME COLUMN "order" TO display_order;
ALTER TABLE topics RENAME COLUMN "order" TO display_order;
ALTER TABLE content_items RENAME COLUMN "order" TO display_order;
ALTER TABLE article_items RENAME COLUMN "order" TO display_order;

-- 3. Add soft delete columns to all tables
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['languages', 'paths', 'sections', 'branches', 'topics', 'content_items', 'articles', 'article_items'])
  LOOP
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS deleted_by UUID', t);
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_deleted ON %I(is_deleted)', t, t);
  END LOOP;
END $$;

-- 4. Create content_references table
CREATE TABLE IF NOT EXISTS content_references (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  original_id UUID NOT NULL,
  original_table TEXT NOT NULL,
  parent_id UUID NOT NULL,
  parent_table TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  custom_title TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  is_orphaned BOOLEAN DEFAULT false,
  orphaned_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(original_id, parent_id)
);

CREATE INDEX idx_refs_original ON content_references(original_id);
CREATE INDEX idx_refs_parent ON content_references(parent_id);
CREATE INDEX idx_refs_deleted ON content_references(is_deleted);

-- 5. Create atomic swap function
CREATE OR REPLACE FUNCTION swap_display_order(
  p_table TEXT,
  p_id1 UUID,
  p_order1 INTEGER,
  p_id2 UUID,
  p_order2 INTEGER
) RETURNS VOID AS $$
BEGIN
  EXECUTE format('UPDATE %I SET display_order = $1, updated_at = NOW() WHERE id = $2', p_table) USING p_order1, p_id1;
  EXECUTE format('UPDATE %I SET display_order = $1, updated_at = NOW() WHERE id = $2', p_table) USING p_order2, p_id2;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create recycle bin auto-purge function
CREATE OR REPLACE FUNCTION purge_old_deleted_items()
RETURNS void AS $$
DECLARE
  retention_days INTEGER := 30;
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['content_items', 'article_items', 'topics', 'branches', 'sections', 'paths', 'languages', 'articles', 'content_references'])
  LOOP
    EXECUTE format(
      'DELETE FROM %I WHERE is_deleted = true AND deleted_at < NOW() - INTERVAL ''%s days''',
      t, retention_days
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule purge (run daily via pg_cron or Supabase scheduled function)
-- SELECT cron.schedule('0 3 * * *', 'SELECT purge_old_deleted_items()');
```

---

## Implementation Roadmap

### Phase 1: Critical Bug Fix (Week 1)
1. ✅ Fix ordering bug with atomic swaps
2. Add `display_order` to articles
3. Update all models to use standardized column name
4. Create database migration

### Phase 2: Reference System (Week 2)
1. Create `content_references` table
2. Implement `ReferenceService`
3. Update UI to display references
4. Add reference creation flow to paste dialog

### Phase 3: Enhanced Copy/Paste (Week 2-3)
1. Add paste modes to `ContentPasteService`
2. Implement move operation
3. Add path re-mapping for cross-language paste
4. Update clipboard expiration

### Phase 4: Recycle Bin Enhancement (Week 3)
1. Add cascade soft delete
2. Implement reference handling on delete
3. Add parent validation on restore
4. Add auto-purge scheduled function

### Phase 5: Admin Mode Polish (Week 4)
1. Move toggle to menu
2. Add admin mode banner
3. Add session expiration handling
4. Clean up visibility logic

---

## Summary

This design provides:

✅ **Deterministic ordering** with atomic database operations
✅ **No duplication** via reference system
✅ **Safe deletion** with recycle bin and reference checks
✅ **Flexible content reuse** via clone/reference paste modes
✅ **Clear admin UX** with proper permissions and visual feedback

The system is designed to be:
- **Scalable** - Works with any content hierarchy depth
- **Maintainable** - Clear separation of concerns
- **Robust** - Handles edge cases and race conditions
- **User-friendly** - Clear UI feedback and intuitive workflows
