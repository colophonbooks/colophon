import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/book.dart';
import 'cover_image.dart';
import 'isbn.dart';

/// JSON エクスポートの形式名とバージョン。構造を変えたらバージョンを上げる。
const backupFormatName = 'colophon';
const backupFormatVersion = 1;
const backupJsonFileName = 'books.json';

/// Colophon のデータではないファイル。
class InvalidBackupException implements Exception {}

/// 新しいバージョンのアプリで作られたファイル。
class NewerBackupException implements Exception {}

enum ImportMode { replace, merge }

class ImportResult {
  const ImportResult({required this.added, required this.skipped});
  final int added;
  final int skipped;
}

// ---------------------------------------------------------------------------
// エクスポート
// ---------------------------------------------------------------------------

/// [exportZip] を別 Isolate で実行する（書影が多いと時間がかかるため）。
Future<Uint8List> exportZipInBackground(List<Book> books) =>
    Isolate.run(() => exportZip(books));

/// books.json と covers/ フォルダを ZIP にまとめる。
Uint8List exportZip(List<Book> books, {DateTime? now}) {
  final archive = Archive();
  final entries = <Map<String, Object?>>[];
  for (final b in books) {
    String? coverPath;
    if (b.cover != null) {
      coverPath = 'covers/${b.uuid}.${extensionOfMime(b.coverType)}';
      // 画像はすでに圧縮済みなので、再圧縮せずに格納する（時間がかかるだけで小さくならない）
      archive.addFile(ArchiveFile.bytes(coverPath, b.cover!)..compression = CompressionType.none);
    }
    entries.add(_bookToJson(b, coverPath));
  }
  final json = const JsonEncoder.withIndent('  ').convert({
    'format': backupFormatName,
    'version': backupFormatVersion,
    'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
    'books': entries,
  });
  archive.addFile(ArchiveFile.bytes(backupJsonFileName, utf8.encode(json)));
  return ZipEncoder().encodeBytes(archive);
}

Map<String, Object?> _bookToJson(Book b, String? coverPath) => {
      'uuid': b.uuid,
      'title': b.title,
      'author': b.author,
      'translator': b.translator,
      'supervisor': b.supervisor,
      'publisher': b.publisher,
      'isbn': b.isbn,
      'edition': b.edition,
      'status': b.status.code,
      'progress': b.progress,
      'cover': coverPath,
      'tags': b.tags,
      'readDates': [for (final d in b.readDates) d.toIso()],
      'notes': [
        for (final n in b.notes)
          {
            'uuid': n.uuid,
            'category': n.category?.code,
            'page': n.page,
            'body': n.body,
            'favorite': n.favorite,
            'createdAt': n.createdAt.toUtc().toIso8601String(),
            'updatedAt': n.updatedAt.toUtc().toIso8601String(),
          },
      ],
      'createdAt': b.createdAt.toUtc().toIso8601String(),
      'updatedAt': b.updatedAt.toUtc().toIso8601String(),
    };

/// テキスト＋書影の ZIP に入れるテキストファイルの名前と、書影フォルダの名前。
const textExportFileName = 'colophon.txt';
const textExportCoverDir = 'covers';

/// 人が読むための整形テキスト。項目名は表示言語で出力し、入力内容はそのまま出す。
/// 書籍には通し番号（[001] など）を付ける。[coverPaths]（uuid → ZIP 内のパス）を渡すと、
/// 書影のある書籍にそのパスを書く。
String exportText(
  List<Book> books,
  AppLocalizations l, {
  DateTime? now,
  Map<String, String> coverPaths = const {},
}) {
  final out = StringBuffer();
  const rule = '========================================';
  out
    ..writeln(l.textExportHeader(_dateTimeText(now ?? DateTime.now())))
    ..writeln(l.textBookCount(books.length));

  for (final (i, b) in books.indexed) {
    out
      ..writeln()
      ..writeln(rule)
      ..writeln('[${_bookNumber(i, books.length)}] ${b.title}')
      ..writeln(rule);
    void field(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) out.writeln('$label: $value');
    }

    field(l.coverSection, coverPaths[b.uuid]);
    field(l.fieldAuthor, b.author);
    field(l.fieldTranslator, b.translator);
    field(l.fieldSupervisor, b.supervisor);
    field(l.fieldPublisher, b.publisher);
    field(l.fieldIsbn, b.isbn);
    field(l.fieldEdition, b.edition);
    final progress = b.status == ReadingStatus.reading && b.progress != null
        ? ' (${l.progressPercent(b.progress!)})'
        : '';
    field(l.fieldStatus, '${l.status(b.status)}$progress');
    if (b.readDates.isNotEmpty) {
      field(l.readDatesSection, b.readDates.map((d) => d.toIso()).join(', '));
    }
    if (b.tags.isNotEmpty) field(l.tagsSection, b.tags.join(', '));
    field(l.fieldCreatedAt, _dateTimeText(b.createdAt));
    field(l.fieldUpdatedAt, _dateTimeText(b.updatedAt));

    if (b.notes.isNotEmpty) {
      out
        ..writeln()
        ..writeln('[${l.notesSection}]');
      for (final n in b.notes) {
        // お気に入りは、どの表示言語でも同じ「★」を目印にする
        final head = [
          if (n.favorite) '★',
          if (n.category != null) '[${l.category(n.category)}]',
          if (n.page != null) 'p.${n.page}',
        ].join(' ');
        out.writeln(head.isEmpty ? '-' : '- $head');
        for (final line in n.body.split('\n')) {
          out.writeln('  $line');
        }
      }
    }
  }
  return out.toString();
}

/// 通し番号（1始まり）。冊数に応じて桁をそろえ、最低3桁にする。
String _bookNumber(int index, int count) {
  final width = count.toString().length < 3 ? 3 : count.toString().length;
  return (index + 1).toString().padLeft(width, '0');
}

/// テキスト＋書影の ZIP（colophon.txt と covers/ フォルダ）を作る。
/// 書影のファイル名は「番号_書籍名.拡張子」。ZIP 作成は書影が多いと重いため別 Isolate で行う。
Future<Uint8List> exportTextWithCovers(List<Book> books, AppLocalizations l, {DateTime? now}) {
  final coverPaths = <String, String>{};
  final files = <(String, Uint8List)>[];
  for (final (i, b) in books.indexed) {
    if (b.cover == null) continue;
    final path = '$textExportCoverDir/${coverFileName(_bookNumber(i, books.length), b)}';
    coverPaths[b.uuid] = path;
    files.add((path, b.cover!));
  }
  final text = utf8.encode(exportText(books, l, now: now, coverPaths: coverPaths));
  return Isolate.run(() {
    final archive = Archive()..addFile(ArchiveFile.bytes(textExportFileName, text));
    for (final (path, bytes) in files) {
      archive.addFile(ArchiveFile.bytes(path, bytes)..compression = CompressionType.none);
    }
    return ZipEncoder().encodeBytes(archive);
  });
}

/// 書影の画像ファイル名（例: 001_サピエンス全史.jpg）。
/// どの OS でも使えるよう、ファイル名に使えない文字は「_」に置き換え、書籍名は60文字までにする。
String coverFileName(String number, Book book) {
  var title = book.title
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final runes = title.runes.toList();
  if (runes.length > 60) title = String.fromCharCodes(runes.take(60));
  // Windows は末尾のピリオド・空白をファイル名に使えない
  title = title.replaceAll(RegExp(r'[. ]+$'), '');
  final ext = extensionOfMime(book.coverType);
  return title.isEmpty ? '$number.$ext' : '${number}_$title.$ext';
}

String _dateTimeText(DateTime d) {
  final t = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${LocalDate.fromDateTime(t).toIso()} ${two(t.hour)}:${two(t.minute)}';
}

/// データベース全体を1つの SQLite ファイルとして書き出す。
Uint8List exportSqlite(Database db) {
  final dir = Directory.systemTemp.createTempSync('colophon_export');
  try {
    final path = p.join(dir.path, 'colophon.sqlite');
    db.execute("VACUUM INTO '${path.replaceAll("'", "''")}'");
    return File(path).readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

// ---------------------------------------------------------------------------
// インポート（ファイル → Book のリスト）
// ---------------------------------------------------------------------------

/// ファイル内容から形式を判定して読み込む。
Future<List<Book>> readBackup(Uint8List bytes) async {
  if (_startsWith(bytes, utf8.encode('SQLite format 3\u0000'))) return readSqliteBackup(bytes);
  if (_startsWith(bytes, const [0x50, 0x4B, 0x03, 0x04])) return readZipBackup(bytes);
  throw InvalidBackupException();
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

Future<List<Book>> readZipBackup(Uint8List bytes) async {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw InvalidBackupException();
  }
  final jsonFile = archive.findFile(backupJsonFileName);
  if (jsonFile == null) throw InvalidBackupException();

  final Object? data;
  try {
    data = jsonDecode(utf8.decode(jsonFile.content));
  } catch (_) {
    throw InvalidBackupException();
  }
  if (data is! Map || data['format'] != backupFormatName || data['books'] is! List) {
    throw InvalidBackupException();
  }
  final version = data['version'];
  if (version is! int) throw InvalidBackupException();
  if (version > backupFormatVersion) throw NewerBackupException();

  final books = <Book>[];
  for (final entry in data['books'] as List) {
    if (entry is! Map) continue;
    final title = _str(entry['title']);
    if (title == null) continue;

    Uint8List? cover;
    final coverPath = _str(entry['cover']);
    if (coverPath != null) {
      final file = archive.findFile(coverPath);
      if (file != null) cover = Uint8List.fromList(file.content);
    }
    final coverType = cover == null ? null : mimeTypeOf(cover);
    if (coverType == null) cover = null;

    final now = DateTime.now().toUtc();
    final createdAt = _date(entry['createdAt']) ?? now;
    books.add(Book(
      uuid: _str(entry['uuid']) ?? const Uuid().v4(),
      title: title,
      author: _str(entry['author']),
      translator: _str(entry['translator']),
      supervisor: _str(entry['supervisor']),
      publisher: _str(entry['publisher']),
      isbn: _str(entry['isbn']),
      edition: _str(entry['edition']),
      status: ReadingStatus.fromCode(entry['status'] as String?),
      progress: _int(entry['progress'], min: 0, max: 100),
      cover: cover,
      coverType: coverType,
      thumbnail: cover == null ? null : await makeThumbnail(cover),
      tags: [
        if (entry['tags'] is List) ...(entry['tags'] as List).map(_str).whereType<String>(),
      ],
      readDates: [
        if (entry['readDates'] is List)
          ...(entry['readDates'] as List).map((d) => LocalDate.tryParse(_str(d))).whereType<LocalDate>(),
      ],
      notes: [
        if (entry['notes'] is List)
          for (final n in entry['notes'] as List)
            if (n is Map)
              Note(
                uuid: _str(n['uuid']),
                category: NoteCategory.fromCode(n['category'] as String?),
                page: _int(n['page'], min: 1),
                body: n['body'] is String ? n['body'] as String : '',
                // 古いファイル（項目なし）はお気に入りなし
                favorite: n['favorite'] == true,
                createdAt: _date(n['createdAt']) ?? createdAt,
                updatedAt: _date(n['updatedAt']) ?? createdAt,
              ),
      ]..removeWhere((n) => n.isEmpty),
      createdAt: createdAt,
      updatedAt: _date(entry['updatedAt']) ?? createdAt,
    ));
  }
  return books;
}

Future<List<Book>> readSqliteBackup(Uint8List bytes) async {
  final dir = Directory.systemTemp.createTempSync('colophon_import');
  Database? db;
  try {
    final path = p.join(dir.path, 'import.sqlite');
    File(path).writeAsBytesSync(bytes);
    try {
      db = sqlite3.open(path);
      final hasBooks = db
          .select("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'books'")
          .isNotEmpty;
      if (!hasBooks || readSchemaVersion(db) < 1) throw InvalidBackupException();
      // 古いバージョンのファイルは一時コピー上で現在のスキーマへ更新してから読む
      prepareDatabase(db);
    } on NewerSchemaException {
      throw NewerBackupException();
    } on SqliteException {
      throw InvalidBackupException();
    }
    final books = BookRepository(db).getAllBooks();
    return [
      for (final b in books)
        if (b.cover != null && b.thumbnail == null)
          b.copyWith(thumbnail: await makeThumbnail(b.cover!))
        else
          b,
    ];
  } finally {
    db?.close();
    dir.deleteSync(recursive: true);
  }
}

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

int? _int(Object? v, {int? min, int? max}) {
  if (v is! int) return null;
  if (min != null && v < min) return null;
  if (max != null && v > max) return null;
  return v;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

// ---------------------------------------------------------------------------
// インポート（Book のリスト → DB）
// ---------------------------------------------------------------------------

/// 読み込んだ書籍をDBへ反映する。全体を1トランザクションで行い、失敗時は何も変えない。
///
/// [ImportMode.merge] では、ID（uuid）または ISBN が既存の書籍と同じものをスキップする。
/// [ImportMode.replace] では ID の重複だけをスキップする（同じ ISBN の本を複数冊
/// 登録している利用者もいるため、ISBN で間引くと復元で書籍が欠ける）。
ImportResult applyImport(BookRepository repo, List<Book> books, ImportMode mode) {
  return repo.transaction(() {
    if (mode == ImportMode.replace) repo.deleteAllBooks();
    final uuids = repo.existingUuids();
    final isbnKeys = repo.existingIsbnKeys();
    var added = 0;
    var skipped = 0;
    for (final book in books) {
      final key = mode == ImportMode.merge ? isbnMatchKey(book.isbn) : null;
      if (uuids.contains(book.uuid) || (key != null && isbnKeys.contains(key))) {
        skipped++;
        continue;
      }
      repo.saveBook(Book(
        uuid: book.uuid,
        title: book.title,
        author: book.author,
        translator: book.translator,
        supervisor: book.supervisor,
        publisher: book.publisher,
        isbn: book.isbn,
        edition: book.edition,
        status: book.status,
        progress: book.progress,
        cover: book.cover,
        coverType: book.coverType,
        thumbnail: book.thumbnail,
        notes: book.notes,
        readDates: book.readDates,
        tags: book.tags,
        createdAt: book.createdAt,
        updatedAt: book.updatedAt,
      ));
      uuids.add(book.uuid);
      if (key != null) isbnKeys.add(key);
      added++;
    }
    return ImportResult(added: added, skipped: skipped);
  });
}
