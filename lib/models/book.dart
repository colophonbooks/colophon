import 'dart:typed_data';

import 'package:uuid/uuid.dart';

/// 読書ステータス。DBやエクスポートには [code] を保存し、表示言語に依存させない。
enum ReadingStatus {
  unset('unset'),
  unread('unread'),
  reading('reading'),
  finished('finished');

  const ReadingStatus(this.code);
  final String code;

  static ReadingStatus fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => ReadingStatus.unset);
}

/// ノートの分類。未選択は null で表す。
enum NoteCategory {
  impression('impression'),
  learning('learning'),
  memo('memo'),
  excerpt('excerpt'),
  other('other');

  const NoteCategory(this.code);
  final String code;

  static NoteCategory? fromCode(String? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// 時刻を持たない日付（読了日）。'yyyy-MM-dd' 形式で保存する。
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime d) => LocalDate(d.year, d.month, d.day);

  factory LocalDate.today() => LocalDate.fromDateTime(DateTime.now());

  static LocalDate? tryParse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    final d = LocalDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    final dt = d.toDateTime();
    if (dt.year != d.year || dt.month != d.month || dt.day != d.day) return null;
    return d;
  }

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() => DateTime(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => toIso().compareTo(other.toIso());

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

class Note {
  Note({
    String? uuid,
    this.category,
    this.page,
    required this.body,
    this.favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc();

  /// 端末をまたいで同じノートだと判別するための ID。
  final String uuid;
  final NoteCategory? category;
  final int? page;
  final String body;

  /// お気に入りの印。
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 本文・分類・ページのどれも入っていない（保存不要な）ノートか。お気に入りの印だけでは保存しない。
  bool get isEmpty => body.trim().isEmpty && category == null && page == null;
}

/// 書籍1冊分の全データ（書影・ノート・読了日・タグを含む）。
class Book {
  Book({
    this.id,
    required this.uuid,
    required this.title,
    this.author,
    this.translator,
    this.supervisor,
    this.publisher,
    this.isbn,
    this.edition,
    this.status = ReadingStatus.unset,
    this.progress,
    this.cover,
    this.coverType,
    this.thumbnail,
    List<Note>? notes,
    List<LocalDate>? readDates,
    List<String>? tags,
    required this.createdAt,
    required this.updatedAt,
  })  : notes = notes ?? const [],
        readDates = readDates ?? const [],
        tags = tags ?? const [];

  final int? id;
  final String uuid;
  final String title;
  final String? author;
  final String? translator;
  final String? supervisor;
  final String? publisher;
  final String? isbn;
  final String? edition;
  final ReadingStatus status;

  /// 読書中の進捗（0〜100）。未入力は null。ステータスを変えても値は保持する。
  final int? progress;

  /// 書影の画像データと MIME タイプ（例: image/jpeg）。
  final Uint8List? cover;
  final String? coverType;

  /// 一覧表示用の縮小画像。書影から自動生成する。
  final Uint8List? thumbnail;

  final List<Note> notes;
  final List<LocalDate> readDates;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book copyWith({
    int? id,
    Uint8List? thumbnail,
  }) =>
      Book(
        id: id ?? this.id,
        uuid: uuid,
        title: title,
        author: author,
        translator: translator,
        supervisor: supervisor,
        publisher: publisher,
        isbn: isbn,
        edition: edition,
        status: status,
        progress: progress,
        cover: cover,
        coverType: coverType,
        thumbnail: thumbnail ?? this.thumbnail,
        notes: notes,
        readDates: readDates,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// 一覧表示用の軽量な書籍情報（書影本体やノートは持たない）。
class BookSummary {
  const BookSummary({
    required this.id,
    required this.title,
    this.author,
    required this.status,
    this.progress,
    this.thumbnail,
    required this.readCount,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? author;
  final ReadingStatus status;
  final int? progress;
  final Uint8List? thumbnail;
  final int readCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookSummary withThumbnail(Uint8List? thumbnail) => BookSummary(
        id: id,
        title: title,
        author: author,
        status: status,
        progress: progress,
        thumbnail: thumbnail,
        readCount: readCount,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class TagUsage {
  const TagUsage({required this.id, required this.name, required this.bookCount});

  final int id;
  final String name;
  final int bookCount;
}
