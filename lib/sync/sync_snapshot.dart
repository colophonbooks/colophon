import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/book.dart';

/// Google ドライブに置く同期データの形式の版。互換性のない変更をしたら上げる。
const syncFormatVersion = 1;

/// 同期データ上の書籍1冊。読了日・タグ・ノートの並び順も書籍の一部として扱い、
/// 端末どうしで食い違ったら、更新日時が新しい方の書籍をまるごと採用する。
///
/// 削除済みの書籍は、uuid と日時だけを持つ（書名などは送らない）。
class SyncBook {
  const SyncBook({
    required this.uuid,
    this.title = '',
    this.author,
    this.translator,
    this.supervisor,
    this.publisher,
    this.isbn,
    this.edition,
    this.status = 'unset',
    this.progress,
    this.coverHash,
    this.coverType,
    this.readDates = const [],
    this.tags = const [],
    this.noteOrder = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// 削除済みの印。[at] が削除日時と更新日時になる。
  factory SyncBook.tombstone(String uuid, {required DateTime createdAt, required DateTime at}) =>
      SyncBook(uuid: uuid, createdAt: createdAt, updatedAt: at, deletedAt: at);

  /// 範囲外・未知の値は、アプリが保存するときと同じ規則で直す（直さないと、書き込むたびに
  /// 値が変わって同期が落ち着かない、または DB の制約で書き込めないため）。
  factory SyncBook.fromJson(Map<String, dynamic> j) => SyncBook(
        uuid: j['uuid'] as String,
        title: j['title'] as String? ?? '',
        author: j['author'] as String?,
        translator: j['translator'] as String?,
        supervisor: j['supervisor'] as String?,
        publisher: j['publisher'] as String?,
        isbn: j['isbn'] as String?,
        edition: j['edition'] as String?,
        status: ReadingStatus.fromCode(j['status'] as String?).code,
        progress: switch (j['progress']) { final int p when p >= 0 && p <= 100 => p, _ => null },
        coverHash: j['coverHash'] as String?,
        coverType: j['coverType'] as String?,
        readDates: {
          for (final d in _strings(j['readDates']))
            if (LocalDate.tryParse(d) case final date?) date.toIso(),
        }.toList()
          ..sort(),
        tags: [
          for (final t in _strings(j['tags']))
            if (t.trim().isNotEmpty) t.trim(),
        ],
        noteOrder: _strings(j['noteOrder']),
        createdAt: _time(j['createdAt']) ?? _time(j['updatedAt']) ?? _epoch,
        updatedAt: _time(j['updatedAt']) ?? _epoch,
        deletedAt: _time(j['deletedAt']),
      );

  final String uuid;
  final String title;
  final String? author;
  final String? translator;
  final String? supervisor;
  final String? publisher;
  final String? isbn;
  final String? edition;

  /// [ReadingStatus] のコード
  final String status;
  final int? progress;

  /// 書影の SHA-256（16進）。書影の中身はこの値の名前で別ファイルとして置く。
  final String? coverHash;
  final String? coverType;

  /// 読了日（yyyy-MM-dd）
  final List<String> readDates;
  final List<String> tags;

  /// 削除されていないノートの uuid を、表示順に並べたもの
  final List<String> noteOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SyncBook copyWith({
    String? uuid,
    List<String>? readDates,
    List<String>? tags,
    List<String>? noteOrder,
    DateTime? updatedAt,
  }) =>
      SyncBook(
        uuid: uuid ?? this.uuid,
        title: title,
        author: author,
        translator: translator,
        supervisor: supervisor,
        publisher: publisher,
        isbn: isbn,
        edition: edition,
        status: status,
        progress: progress,
        coverHash: coverHash,
        coverType: coverType,
        readDates: readDates ?? this.readDates,
        tags: tags ?? this.tags,
        noteOrder: noteOrder ?? this.noteOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
      );

  Map<String, dynamic> toJson() => isDeleted
      ? {
          'uuid': uuid,
          'createdAt': _iso(createdAt),
          'updatedAt': _iso(updatedAt),
          'deletedAt': _iso(deletedAt!),
        }
      : {
          'uuid': uuid,
          'title': title,
          'author': author,
          'translator': translator,
          'supervisor': supervisor,
          'publisher': publisher,
          'isbn': isbn,
          'edition': edition,
          'status': status,
          'progress': progress,
          'coverHash': coverHash,
          'coverType': coverType,
          'readDates': readDates,
          'tags': tags,
          'noteOrder': noteOrder,
          'createdAt': _iso(createdAt),
          'updatedAt': _iso(updatedAt),
        };
}

/// 同期データ上のノート1件。ノートは書籍とは別に、1件ずつ新しい方を採用する。
class SyncNote {
  const SyncNote({
    required this.uuid,
    required this.bookUuid,
    this.category,
    this.page,
    this.body = '',
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SyncNote.fromJson(Map<String, dynamic> j) => SyncNote(
        uuid: j['uuid'] as String,
        bookUuid: j['bookUuid'] as String,
        category: NoteCategory.fromCode(j['category'] as String?)?.code,
        page: switch (j['page']) { final int p when p >= 1 => p, _ => null },
        body: j['body'] as String? ?? '',
        favorite: j['favorite'] as bool? ?? false,
        createdAt: _time(j['createdAt']) ?? _time(j['updatedAt']) ?? _epoch,
        updatedAt: _time(j['updatedAt']) ?? _epoch,
        deletedAt: _time(j['deletedAt']),
      );

  final String uuid;
  final String bookUuid;

  /// [NoteCategory] のコード
  final String? category;
  final int? page;
  final String body;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SyncNote copyWith({String? bookUuid, DateTime? updatedAt, DateTime? deletedAt}) => SyncNote(
        uuid: uuid,
        bookUuid: bookUuid ?? this.bookUuid,
        category: deletedAt == null ? category : null,
        page: deletedAt == null ? page : null,
        body: deletedAt == null ? body : '',
        favorite: deletedAt == null && favorite,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  Map<String, dynamic> toJson() => isDeleted
      ? {
          'uuid': uuid,
          'bookUuid': bookUuid,
          'createdAt': _iso(createdAt),
          'updatedAt': _iso(updatedAt),
          'deletedAt': _iso(deletedAt!),
        }
      : {
          'uuid': uuid,
          'bookUuid': bookUuid,
          'category': category,
          'page': page,
          'body': body,
          'favorite': favorite,
          'createdAt': _iso(createdAt),
          'updatedAt': _iso(updatedAt),
        };
}

/// 同期データ全体（書影の中身は含まない）。
class SyncSnapshot {
  const SyncSnapshot({this.books = const [], this.notes = const [], this.unreadableRecords = 0});

  /// 形式の版が新しすぎる場合は [UnsupportedSyncFormatException]。
  factory SyncSnapshot.fromJson(Map<String, dynamic> j) {
    final version = j['version'];
    if (version is! int || version > syncFormatVersion) throw UnsupportedSyncFormatException(version);
    // 読めない記録（uuid がないなど）は飛ばして数える。1件のせいで統合全体を止めないため
    final rawBooks = j['books'] as List? ?? const [];
    final rawNotes = j['notes'] as List? ?? const [];
    final books = [for (final b in rawBooks) ?_tryRead(() => SyncBook.fromJson(b as Map<String, dynamic>))];
    final notes = [for (final n in rawNotes) ?_tryRead(() => SyncNote.fromJson(n as Map<String, dynamic>))];
    return SyncSnapshot(
      books: books,
      notes: notes,
      unreadableRecords: rawBooks.length - books.length + rawNotes.length - notes.length,
    );
  }

  factory SyncSnapshot.decode(List<int> bytes) =>
      SyncSnapshot.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);

  final List<SyncBook> books;
  final List<SyncNote> notes;

  /// 読めずに飛ばした記録の数。0 でなければ、上書きして消してしまわないようクラウドへは送らない。
  final int unreadableRecords;

  bool get isEmpty => books.every((b) => b.isDeleted) && notes.every((n) => n.isDeleted);

  Map<String, dynamic> toJson() => {
        'format': 'colophon-sync',
        'version': syncFormatVersion,
        'books': [for (final b in books) b.toJson()],
        'notes': [for (final n in notes) n.toJson()],
      };

  List<int> encode() => utf8.encode(jsonEncode(toJson()));
}

/// 書影の中身。同期データとは別に、SHA-256 ごとに1つずつやり取りする。
class SyncCover {
  const SyncCover({required this.bytes, this.type, this.thumbnail});

  final Uint8List bytes;
  final String? type;

  /// 一覧用の縮小画像。送らずに、受け取った端末で作る。
  final Uint8List? thumbnail;
}

/// 書影の SHA-256（16進）。同じ画像なら端末が違っても同じ値になる。
String coverHashOf(List<int> bytes) => sha256.convert(bytes).toString();

/// 新しい版のアプリが書いた同期データ。古いアプリが上書きすると内容が失われるので扱わない。
class UnsupportedSyncFormatException implements Exception {
  UnsupportedSyncFormatException(this.version);
  final Object? version;
}

String _iso(DateTime d) => d.toUtc().toIso8601String();

/// 日時が読めない記録に使う。どの記録よりも古いので、統合で負ける。
final _epoch = DateTime.utc(1970);

T? _tryRead<T>(T Function() read) {
  try {
    return read();
  } on Object {
    return null;
  }
}

DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

List<String> _strings(Object? v) => [for (final s in v as List? ?? const []) s as String];
