// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_database.dart';

// ignore_for_file: type=lint
class $ArticleItemsTable extends ArticleItems
    with TableInfo<$ArticleItemsTable, ArticleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ArticleType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ArticleType>($ArticleItemsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    articleId,
    type,
    title,
    content,
    note,
    videoId,
    url,
    order,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      articleId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}article_id'],
          )!,
      type: $ArticleItemsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      order:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}order'],
          )!,
    );
  }

  @override
  $ArticleItemsTable createAlias(String alias) {
    return $ArticleItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ArticleType, String, String> $convertertype =
      const EnumNameConverter<ArticleType>(ArticleType.values);
}

class ArticleItem extends DataClass implements Insertable<ArticleItem> {
  final String id;
  final String articleId;
  final ArticleType type;
  final String? title;
  final String? content;
  final String? note;
  final String? videoId;
  final String? url;
  final int order;
  const ArticleItem({
    required this.id,
    required this.articleId,
    required this.type,
    this.title,
    this.content,
    this.note,
    this.videoId,
    this.url,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['article_id'] = Variable<String>(articleId);
    {
      map['type'] = Variable<String>(
        $ArticleItemsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || videoId != null) {
      map['video_id'] = Variable<String>(videoId);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['order'] = Variable<int>(order);
    return map;
  }

  ArticleItemsCompanion toCompanion(bool nullToAbsent) {
    return ArticleItemsCompanion(
      id: Value(id),
      articleId: Value(articleId),
      type: Value(type),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      content:
          content == null && nullToAbsent
              ? const Value.absent()
              : Value(content),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      videoId:
          videoId == null && nullToAbsent
              ? const Value.absent()
              : Value(videoId),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      order: Value(order),
    );
  }

  factory ArticleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleItem(
      id: serializer.fromJson<String>(json['id']),
      articleId: serializer.fromJson<String>(json['articleId']),
      type: $ArticleItemsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      note: serializer.fromJson<String?>(json['note']),
      videoId: serializer.fromJson<String?>(json['videoId']),
      url: serializer.fromJson<String?>(json['url']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'articleId': serializer.toJson<String>(articleId),
      'type': serializer.toJson<String>(
        $ArticleItemsTable.$convertertype.toJson(type),
      ),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String?>(content),
      'note': serializer.toJson<String?>(note),
      'videoId': serializer.toJson<String?>(videoId),
      'url': serializer.toJson<String?>(url),
      'order': serializer.toJson<int>(order),
    };
  }

  ArticleItem copyWith({
    String? id,
    String? articleId,
    ArticleType? type,
    Value<String?> title = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> videoId = const Value.absent(),
    Value<String?> url = const Value.absent(),
    int? order,
  }) => ArticleItem(
    id: id ?? this.id,
    articleId: articleId ?? this.articleId,
    type: type ?? this.type,
    title: title.present ? title.value : this.title,
    content: content.present ? content.value : this.content,
    note: note.present ? note.value : this.note,
    videoId: videoId.present ? videoId.value : this.videoId,
    url: url.present ? url.value : this.url,
    order: order ?? this.order,
  );
  ArticleItem copyWithCompanion(ArticleItemsCompanion data) {
    return ArticleItem(
      id: data.id.present ? data.id.value : this.id,
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      note: data.note.present ? data.note.value : this.note,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      url: data.url.present ? data.url.value : this.url,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleItem(')
          ..write('id: $id, ')
          ..write('articleId: $articleId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('note: $note, ')
          ..write('videoId: $videoId, ')
          ..write('url: $url, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    articleId,
    type,
    title,
    content,
    note,
    videoId,
    url,
    order,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleItem &&
          other.id == this.id &&
          other.articleId == this.articleId &&
          other.type == this.type &&
          other.title == this.title &&
          other.content == this.content &&
          other.note == this.note &&
          other.videoId == this.videoId &&
          other.url == this.url &&
          other.order == this.order);
}

class ArticleItemsCompanion extends UpdateCompanion<ArticleItem> {
  final Value<String> id;
  final Value<String> articleId;
  final Value<ArticleType> type;
  final Value<String?> title;
  final Value<String?> content;
  final Value<String?> note;
  final Value<String?> videoId;
  final Value<String?> url;
  final Value<int> order;
  final Value<int> rowid;
  const ArticleItemsCompanion({
    this.id = const Value.absent(),
    this.articleId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.note = const Value.absent(),
    this.videoId = const Value.absent(),
    this.url = const Value.absent(),
    this.order = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArticleItemsCompanion.insert({
    required String id,
    required String articleId,
    required ArticleType type,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.note = const Value.absent(),
    this.videoId = const Value.absent(),
    this.url = const Value.absent(),
    required int order,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       articleId = Value(articleId),
       type = Value(type),
       order = Value(order);
  static Insertable<ArticleItem> custom({
    Expression<String>? id,
    Expression<String>? articleId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? note,
    Expression<String>? videoId,
    Expression<String>? url,
    Expression<int>? order,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (articleId != null) 'article_id': articleId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (note != null) 'note': note,
      if (videoId != null) 'video_id': videoId,
      if (url != null) 'url': url,
      if (order != null) 'order': order,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArticleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? articleId,
    Value<ArticleType>? type,
    Value<String?>? title,
    Value<String?>? content,
    Value<String?>? note,
    Value<String?>? videoId,
    Value<String?>? url,
    Value<int>? order,
    Value<int>? rowid,
  }) {
    return ArticleItemsCompanion(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      note: note ?? this.note,
      videoId: videoId ?? this.videoId,
      url: url ?? this.url,
      order: order ?? this.order,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ArticleItemsTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleItemsCompanion(')
          ..write('id: $id, ')
          ..write('articleId: $articleId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('note: $note, ')
          ..write('videoId: $videoId, ')
          ..write('url: $url, ')
          ..write('order: $order, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(QueryExecutor e) : super(e);
  $MyDatabaseManager get managers => $MyDatabaseManager(this);
  late final $ArticleItemsTable articleItems = $ArticleItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [articleItems];
}

typedef $$ArticleItemsTableCreateCompanionBuilder =
    ArticleItemsCompanion Function({
      required String id,
      required String articleId,
      required ArticleType type,
      Value<String?> title,
      Value<String?> content,
      Value<String?> note,
      Value<String?> videoId,
      Value<String?> url,
      required int order,
      Value<int> rowid,
    });
typedef $$ArticleItemsTableUpdateCompanionBuilder =
    ArticleItemsCompanion Function({
      Value<String> id,
      Value<String> articleId,
      Value<ArticleType> type,
      Value<String?> title,
      Value<String?> content,
      Value<String?> note,
      Value<String?> videoId,
      Value<String?> url,
      Value<int> order,
      Value<int> rowid,
    });

class $$ArticleItemsTableFilterComposer
    extends Composer<_$MyDatabase, $ArticleItemsTable> {
  $$ArticleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ArticleType, ArticleType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticleItemsTableOrderingComposer
    extends Composer<_$MyDatabase, $ArticleItemsTable> {
  $$ArticleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticleItemsTableAnnotationComposer
    extends Composer<_$MyDatabase, $ArticleItemsTable> {
  $$ArticleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get articleId =>
      $composableBuilder(column: $table.articleId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ArticleType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$ArticleItemsTableTableManager
    extends
        RootTableManager<
          _$MyDatabase,
          $ArticleItemsTable,
          ArticleItem,
          $$ArticleItemsTableFilterComposer,
          $$ArticleItemsTableOrderingComposer,
          $$ArticleItemsTableAnnotationComposer,
          $$ArticleItemsTableCreateCompanionBuilder,
          $$ArticleItemsTableUpdateCompanionBuilder,
          (
            ArticleItem,
            BaseReferences<_$MyDatabase, $ArticleItemsTable, ArticleItem>,
          ),
          ArticleItem,
          PrefetchHooks Function()
        > {
  $$ArticleItemsTableTableManager(_$MyDatabase db, $ArticleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ArticleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ArticleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ArticleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> articleId = const Value.absent(),
                Value<ArticleType> type = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticleItemsCompanion(
                id: id,
                articleId: articleId,
                type: type,
                title: title,
                content: content,
                note: note,
                videoId: videoId,
                url: url,
                order: order,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String articleId,
                required ArticleType type,
                Value<String?> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                required int order,
                Value<int> rowid = const Value.absent(),
              }) => ArticleItemsCompanion.insert(
                id: id,
                articleId: articleId,
                type: type,
                title: title,
                content: content,
                note: note,
                videoId: videoId,
                url: url,
                order: order,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MyDatabase,
      $ArticleItemsTable,
      ArticleItem,
      $$ArticleItemsTableFilterComposer,
      $$ArticleItemsTableOrderingComposer,
      $$ArticleItemsTableAnnotationComposer,
      $$ArticleItemsTableCreateCompanionBuilder,
      $$ArticleItemsTableUpdateCompanionBuilder,
      (
        ArticleItem,
        BaseReferences<_$MyDatabase, $ArticleItemsTable, ArticleItem>,
      ),
      ArticleItem,
      PrefetchHooks Function()
    >;

class $MyDatabaseManager {
  final _$MyDatabase _db;
  $MyDatabaseManager(this._db);
  $$ArticleItemsTableTableManager get articleItems =>
      $$ArticleItemsTableTableManager(_db, _db.articleItems);
}
