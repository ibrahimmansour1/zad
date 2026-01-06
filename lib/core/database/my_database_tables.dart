
import 'package:drift/drift.dart';
import 'package:zad_aldaia/core/models/article_type.dart';

class ArticleItems extends Table {
  TextColumn get id => text()(); // Primary key, non-nullable

  TextColumn get articleId => text()();

  TextColumn get type => textEnum<ArticleType>()();

  TextColumn get title => text().nullable()();

  TextColumn get content => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get videoId => text().nullable()();

  TextColumn get url => text().nullable()();

  IntColumn get order => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
