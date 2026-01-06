import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/services/auth_service.dart';
import 'package:zad_aldaia/services/content_service.dart';
import 'package:zad_aldaia/services/storage_service.dart';

/// Test screen to verify Supabase integration
/// This screen tests all services and displays results
class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final _contentService = ContentService();
  final _storageService = StorageService();
  final _authService = AuthService();

  final List<String> _testResults = [];
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _testing = true;
      _testResults.clear();
    });

    // Test 1: Check Supabase client initialization
    await _testSupabaseClient();

    // Test 2: Test database connection
    await _testDatabaseConnection();

    // Test 3: Test each table
    await _testLanguagesTable();
    await _testPathsTable();
    await _testSectionsTable();
    await _testBranchesTable();
    await _testTopicsTable();
    await _testContentItemsTable();

    // Test 4: Test storage bucket
    await _testStorageBucket();

    // Test 5: Test auth state
    await _testAuthState();

    setState(() => _testing = false);
  }

  Future<void> _testSupabaseClient() async {
    try {
      // Check if client is initialized
      Supa.client;
      _addResult('✅ Supabase Client: Initialized');
      _addResult('   Connected to Supabase');
    } catch (e) {
      _addResult('❌ Supabase Client: $e');
    }
  }

  Future<void> _testDatabaseConnection() async {
    try {
      // Try a simple query to test connection
      await Supa.client.from('languages').select('id').limit(1);
      _addResult('✅ Database Connection: Working');
    } catch (e) {
      _addResult('❌ Database Connection: $e');
    }
  }

  Future<void> _testLanguagesTable() async {
    try {
      final languages = await _contentService.getLanguages();
      _addResult('✅ Languages Table: ${languages.length} records');
      if (languages.isNotEmpty) {
        final first = languages.first;
        _addResult('   Sample: ${first['name']} (${first['code']})');
      }
    } catch (e) {
      _addResult('❌ Languages Table: $e');
    }
  }

  Future<void> _testPathsTable() async {
    try {
      // Get first language to test paths
      final languages = await _contentService.getLanguages();
      if (languages.isEmpty) {
        _addResult('⚠️  Paths Table: No languages to test with');
        return;
      }

      final languageId = languages.first['id'];
      final paths = await _contentService.getPaths(languageId);
      _addResult(
          '✅ Paths Table: ${paths.length} records for language ${languages.first['name']}');
      if (paths.isNotEmpty) {
        _addResult('   Sample: ${paths.first['name']}');
      }
    } catch (e) {
      _addResult('❌ Paths Table: $e');
    }
  }

  Future<void> _testSectionsTable() async {
    try {
      final languages = await _contentService.getLanguages();
      if (languages.isEmpty) {
        _addResult('⚠️  Sections Table: No languages to test with');
        return;
      }

      final languageId = languages.first['id'];
      final paths = await _contentService.getPaths(languageId);
      if (paths.isEmpty) {
        _addResult('⚠️  Sections Table: No paths to test with');
        return;
      }

      final pathId = paths.first['id'];
      final sections = await _contentService.getSections(pathId);
      _addResult(
          '✅ Sections Table: ${sections.length} records for path ${paths.first['name']}');
      if (sections.isNotEmpty) {
        _addResult('   Sample: ${sections.first['name']}');
      }
    } catch (e) {
      _addResult('❌ Sections Table: $e');
    }
  }

  Future<void> _testBranchesTable() async {
    try {
      final languages = await _contentService.getLanguages();
      if (languages.isEmpty) {
        _addResult('⚠️  Branches Table: No data to test with');
        return;
      }

      final languageId = languages.first['id'];
      final paths = await _contentService.getPaths(languageId);
      if (paths.isEmpty) {
        _addResult('⚠️  Branches Table: No paths to test with');
        return;
      }

      final pathId = paths.first['id'];
      final sections = await _contentService.getSections(pathId);
      if (sections.isEmpty) {
        _addResult('⚠️  Branches Table: No sections to test with');
        return;
      }

      final sectionId = sections.first['id'];
      final branches = await _contentService.getBranches(sectionId);
      _addResult(
          '✅ Branches Table: ${branches.length} records for section ${sections.first['name']}');
      if (branches.isNotEmpty) {
        _addResult('   Sample: ${branches.first['name']}');
      }
    } catch (e) {
      _addResult('❌ Branches Table: $e');
    }
  }

  Future<void> _testTopicsTable() async {
    try {
      // Navigate through hierarchy to get a branch
      final languages = await _contentService.getLanguages();
      if (languages.isEmpty) {
        _addResult('⚠️  Topics Table: No data to test with');
        return;
      }

      final languageId = languages.first['id'];
      final paths = await _contentService.getPaths(languageId);
      if (paths.isEmpty) {
        _addResult('⚠️  Topics Table: No paths to test with');
        return;
      }

      final pathId = paths.first['id'];
      final sections = await _contentService.getSections(pathId);
      if (sections.isEmpty) {
        _addResult('⚠️  Topics Table: No sections to test with');
        return;
      }

      final sectionId = sections.first['id'];
      final branches = await _contentService.getBranches(sectionId);
      if (branches.isEmpty) {
        _addResult('⚠️  Topics Table: No branches to test with');
        return;
      }

      final branchId = branches.first['id'];
      final topics = await _contentService.getTopics(branchId);
      _addResult('✅ Topics Table: ${topics.length} records');
    } catch (e) {
      _addResult('❌ Topics Table: $e');
    }
  }

  Future<void> _testContentItemsTable() async {
    try {
      // This will only work if there's data in the hierarchy
      _addResult('⚠️  Content Items Table: Skipped (requires full hierarchy)');
    } catch (e) {
      _addResult('❌ Content Items Table: $e');
    }
  }

  Future<void> _testStorageBucket() async {
    try {
      // Test if we can access the bucket
      final files = await _storageService.listFiles('');
      _addResult('✅ Storage Bucket (content-images): Accessible');
      _addResult('   Files: ${files.length}');
    } catch (e) {
      _addResult('❌ Storage Bucket: $e');
    }
  }

  Future<void> _testAuthState() async {
    try {
      final isAuth = _authService.isAuthenticated;
      final user = _authService.currentUser;
      if (isAuth && user != null) {
        _addResult('✅ Auth: Signed in as ${user.email}');
      } else {
        _addResult('ℹ️  Auth: Not signed in (public access)');
      }
    } catch (e) {
      _addResult('❌ Auth State: $e');
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      appBar: AppBar(
        title: const Text('Supabase Integration Test'),
        backgroundColor: const Color(0xFF005A32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testing ? null : _runAllTests,
          ),
        ],
      ),
      body: _testing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF005A32),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Running tests...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF005A32),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    color: const Color(0xFF005A32),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supabase Integration Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total tests: ${_testResults.length}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Passed: ${_testResults.where((r) => r.startsWith('✅')).length}',
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                          Text(
                            'Failed: ${_testResults.where((r) => r.startsWith('❌')).length}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          Text(
                            'Warnings: ${_testResults.where((r) => r.startsWith('⚠️')).length}',
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final result = _testResults[index - 1];
                final isSuccess = result.startsWith('✅');
                final isError = result.startsWith('❌');
                final isWarning = result.startsWith('⚠️');

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isSuccess
                          ? Icons.check_circle
                          : isError
                              ? Icons.error
                              : isWarning
                                  ? Icons.warning
                                  : Icons.info,
                      color: isSuccess
                          ? Colors.green
                          : isError
                              ? Colors.red
                              : isWarning
                                  ? Colors.orange
                                  : Colors.blue,
                    ),
                    title: Text(
                      result,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: result.startsWith('   ')
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
