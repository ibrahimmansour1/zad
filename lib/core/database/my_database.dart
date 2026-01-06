import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/article_type.dart';
import 'my_database_tables.dart';

part 'my_database.g.dart';

@DriftDatabase(tables: [ArticleItems])
class MyDatabase extends _$MyDatabase {
  MyDatabase()
    : super(
        driftDatabase(
          name: "my_database",
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
