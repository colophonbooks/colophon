import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../models/book.dart';
import '../services/isbn.dart';
import '../services/search.dart';

enum BookSort { recent, title }

/// 書籍データの読み書き。sqlite3 は同期APIなので、各メソッドも同期で完結する。
///
/// 書籍とノートは削除しても行を残し、deleted_at に削除日時を記録する（削除済みの印）。
/// 端末間で同期するときに「削除された」ことを他の端末へ伝えるためで、
/// 読み込み系のメソッドは削除済みの印が付いた行を返さない。
class BookRepository {
  BookRepository(this.db);

  final Database db;

  /// トランザクション内で [action] を実行する。入れ子で呼ばれた場合は外側にまとめる
  /// （インポートで複数冊の保存を1つのトランザクションにするため）。
  T transaction<T>(T Function() action) {
    if (!db.autocommit) return action();
    db.execute('BEGIN');
    try {
      final result = action();
      db.execute('COMMIT');
      return result;
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  int countBooks() =>
      db.select('SELECT COUNT(*) AS c FROM books WHERE deleted_at IS NULL').first['c'] as int;

  List<BookSummary> listSummaries({BookSort sort = BookSort.recent}) {
    final order = switch (sort) {
      BookSort.recent => 'b.created_at DESC, b.id DESC',
      BookSort.title => 'b.title COLLATE NOCASE ASC, b.id ASC',
    };
    final tags = _tagsByBook();
    final rows = db.select('''
      SELECT b.id, b.title, b.author, b.status, b.progress, b.thumbnail, b.created_at, b.updated_at,
             (SELECT COUNT(*) FROM read_records r WHERE r.book_id = b.id) AS read_count
      FROM books b
      WHERE b.deleted_at IS NULL
      ORDER BY $order
    ''');
    return [
      for (final r in rows)
        BookSummary(
          id: r['id'] as int,
          title: r['title'] as String,
          author: r['author'] as String?,
          status: ReadingStatus.fromCode(r['status'] as String?),
          progress: r['progress'] as int?,
          thumbnail: r['thumbnail'] as Uint8List?,
          readCount: r['read_count'] as int,
          tags: tags[r['id'] as int] ?? const [],
          createdAt: DateTime.parse(r['created_at'] as String),
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  Book? getBook(int id) {
    final rows = db.select('SELECT * FROM books WHERE id = ? AND deleted_at IS NULL', [id]);
    if (rows.isEmpty) return null;
    return _readBooks(rows, withImages: true).single;
  }

  /// 全書籍を関連データ込みで読み込む。検索では画像が不要なので [withImages] を false にする。
  List<Book> getAllBooks({bool withImages = true}) {
    final columns = withImages
        ? '*'
        : 'id, uuid, title, author, translator, supervisor, publisher, isbn, edition, '
            'status, progress, cover_type, created_at, updated_at';
    final rows = db.select(
        'SELECT $columns FROM books WHERE deleted_at IS NULL ORDER BY created_at, id');
    return _readBooks(rows, withImages: withImages);
  }

  List<Book> _readBooks(ResultSet rows, {required bool withImages}) {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r['id'] as int).toList();
    final idFilter = ids.length == 1 ? 'AND book_id = ${ids.single}' : '';
    final notes = <int, List<Note>>{};
    for (final r in db.select(
        'SELECT * FROM notes WHERE deleted_at IS NULL $idFilter ORDER BY book_id, position')) {
      (notes[r['book_id'] as int] ??= []).add(Note(
        uuid: r['uuid'] as String,
        category: NoteCategory.fromCode(r['category'] as String?),
        page: r['page'] as int?,
        body: r['body'] as String,
        favorite: r['favorite'] == 1,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
      ));
    }
    final readDates = <int, List<LocalDate>>{};
    for (final r in db.select(
        'SELECT book_id, finished_on FROM read_records WHERE 1 = 1 $idFilter ORDER BY finished_on')) {
      final d = LocalDate.tryParse(r['finished_on'] as String?);
      if (d != null) (readDates[r['book_id'] as int] ??= []).add(d);
    }
    final tags = _tagsByBook();

    return [
      for (final r in rows)
        Book(
          id: r['id'] as int,
          uuid: r['uuid'] as String,
          title: r['title'] as String,
          author: r['author'] as String?,
          translator: r['translator'] as String?,
          supervisor: r['supervisor'] as String?,
          publisher: r['publisher'] as String?,
          isbn: r['isbn'] as String?,
          edition: r['edition'] as String?,
          status: ReadingStatus.fromCode(r['status'] as String?),
          progress: r['progress'] as int?,
          cover: withImages ? r['cover'] as Uint8List? : null,
          coverType: r['cover_type'] as String?,
          thumbnail: withImages ? r['thumbnail'] as Uint8List? : null,
          notes: notes[r['id']] ?? const [],
          readDates: readDates[r['id']] ?? const [],
          tags: tags[r['id']] ?? const [],
          createdAt: DateTime.parse(r['created_at'] as String),
          updatedAt: DateTime.parse(r['updated_at'] as String),
        ),
    ];
  }

  Map<int, List<String>> _tagsByBook() {
    final result = <int, List<String>>{};
    for (final r in db.select('''
      SELECT bt.book_id, t.name FROM book_tags bt JOIN tags t ON t.id = bt.tag_id
      ORDER BY t.name_key
    ''')) {
      (result[r['book_id'] as int] ??= []).add(r['name'] as String);
    }
    return result;
  }

  /// 書籍を保存し、その id を返す。ノート・読了日・タグは渡された内容にそろえる。
  /// 日時は [book] の値をそのまま書き込む（更新日時の設定は呼び出し側の責務）。
  ///
  /// - 同じ uuid の削除済み書籍があれば、それを復活させる（インポートで削除済みの本を戻す場合）
  /// - ノートは uuid で突き合わせて更新し、渡されなかったノートは削除済みの印を付ける
  int saveBook(Book book) => transaction(() {
        final values = [
          book.uuid,
          book.title,
          _blankToNull(book.author),
          _blankToNull(book.translator),
          _blankToNull(book.supervisor),
          _blankToNull(book.publisher),
          _blankToNull(book.isbn),
          _blankToNull(book.edition),
          book.status.code,
          book.progress,
          book.cover,
          book.cover == null ? null : book.coverType,
          book.cover == null ? null : book.thumbnail,
          _ts(book.createdAt),
          _ts(book.updatedAt),
        ];
        final id = book.id ?? _idOfUuid(book.uuid);
        if (id == null) {
          db.execute('''
            INSERT INTO books (uuid, title, author, translator, supervisor, publisher, isbn,
              edition, status, progress, cover, cover_type, thumbnail, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', values);
        } else {
          db.execute('''
            UPDATE books SET uuid = ?, title = ?, author = ?, translator = ?, supervisor = ?,
              publisher = ?, isbn = ?, edition = ?, status = ?, progress = ?, cover = ?,
              cover_type = ?, thumbnail = ?, created_at = ?, updated_at = ?, deleted_at = NULL
            WHERE id = ?
          ''', [...values, id]);
          db.execute('DELETE FROM read_records WHERE book_id = ?', [id]);
          db.execute('DELETE FROM book_tags WHERE book_id = ?', [id]);
        }
        final bookId = id ?? db.lastInsertRowId;

        _saveNotes(bookId, book.notes, deletedAt: book.updatedAt);

        for (final d in book.readDates.toSet()) {
          db.execute('INSERT INTO read_records (book_id, finished_on) VALUES (?, ?)', [bookId, d.toIso()]);
        }

        for (final name in _uniqueTagNames(book.tags)) {
          final key = tagKey(name);
          db.execute('INSERT OR IGNORE INTO tags (name, name_key) VALUES (?, ?)', [name, key]);
          db.execute('''
            INSERT OR IGNORE INTO book_tags (book_id, tag_id)
            SELECT ?, id FROM tags WHERE name_key = ?
          ''', [bookId, key]);
        }
        _deleteUnusedTags();
        return bookId;
      });

  int? _idOfUuid(String uuid) {
    final rows = db.select('SELECT id FROM books WHERE uuid = ?', [uuid]);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  void _saveNotes(int bookId, List<Note> notes, {required DateTime deletedAt}) {
    final upsert = db.prepare('''
      INSERT INTO notes (uuid, book_id, position, category, page, body, favorite, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (uuid) DO UPDATE SET
        book_id = excluded.book_id, position = excluded.position, category = excluded.category,
        page = excluded.page, body = excluded.body, favorite = excluded.favorite,
        created_at = excluded.created_at, updated_at = excluded.updated_at, deleted_at = NULL
    ''');
    try {
      var position = 0;
      for (final n in notes) {
        upsert.execute([
          n.uuid,
          bookId,
          position++,
          n.category?.code,
          n.page,
          n.body,
          n.favorite ? 1 : 0,
          _ts(n.createdAt),
          _ts(n.updatedAt),
        ]);
      }
    } finally {
      upsert.close();
    }
    final kept = notes.map((n) => n.uuid).toList();
    db.execute('''
      UPDATE notes SET deleted_at = ?, updated_at = ?, body = ''
      WHERE book_id = ? AND deleted_at IS NULL
        AND uuid NOT IN (${List.filled(kept.length, '?').join(', ')})
    ''', [_ts(deletedAt), _ts(deletedAt), bookId, ...kept]);
  }

  /// ノート1件のお気に入りを切り替えて、すぐ保存する（検索結果から操作する場合）。
  /// 同期で変更が伝わるよう、ノートとその書籍の更新日時も更新する。対象がなければ false。
  bool setNoteFavorite(String noteUuid, bool favorite, {DateTime? at}) => transaction(() {
        final ts = _ts(at ?? DateTime.now());
        db.execute('''
          UPDATE notes SET favorite = ?, updated_at = ?
          WHERE uuid = ? AND deleted_at IS NULL
        ''', [favorite ? 1 : 0, ts, noteUuid]);
        if (db.updatedRows == 0) return false;
        db.execute('''
          UPDATE books SET updated_at = ?
          WHERE id = (SELECT book_id FROM notes WHERE uuid = ?)
        ''', [ts, noteUuid]);
        return true;
      });

  /// 書籍に削除済みの印を付ける。ノートにも印を付け、書影・読了日・タグは消す。
  void deleteBook(int id, {DateTime? at}) => transaction(() {
        _markDeleted(id, (at ?? DateTime.now()).toUtc());
        _deleteUnusedTags();
      });

  /// すべてのデータを物理的に消去する（設定画面の「すべてのデータを削除」）。
  /// 削除済みの印も残さない。VACUUM でファイルを詰め直し、消した内容がファイル内に残らないようにする。
  void wipeAllData() {
    transaction(() {
      for (final table in ['book_tags', 'read_records', 'notes', 'tags', 'books']) {
        db.execute('DELETE FROM $table');
      }
    });
    db.execute('VACUUM');
  }

  /// すべての書籍に削除済みの印を付ける（インポートの「すべて置き換える」で使用）。
  void deleteAllBooks({DateTime? at}) => transaction(() {
        final now = (at ?? DateTime.now()).toUtc();
        for (final r in db.select('SELECT id FROM books WHERE deleted_at IS NULL')) {
          _markDeleted(r['id'] as int, now);
        }
        _deleteUnusedTags();
      });

  void _markDeleted(int id, DateTime at) {
    final ts = _ts(at);
    db.execute('''
      UPDATE books SET deleted_at = ?, updated_at = ?, cover = NULL, cover_type = NULL, thumbnail = NULL
      WHERE id = ?
    ''', [ts, ts, id]);
    db.execute('''
      UPDATE notes SET deleted_at = ?, updated_at = ?, body = ''
      WHERE book_id = ? AND deleted_at IS NULL
    ''', [ts, ts, id]);
    db.execute('DELETE FROM read_records WHERE book_id = ?', [id]);
    db.execute('DELETE FROM book_tags WHERE book_id = ?', [id]);
  }

  List<String> tagNames() =>
      [for (final r in db.select('SELECT name FROM tags ORDER BY name_key')) r['name'] as String];

  List<TagUsage> listTags() => [
        for (final r in db.select('''
          SELECT t.id, t.name, COUNT(bt.book_id) AS c
          FROM tags t LEFT JOIN book_tags bt ON bt.tag_id = t.id
          GROUP BY t.id ORDER BY t.name_key
        '''))
          TagUsage(id: r['id'] as int, name: r['name'] as String, bookCount: r['c'] as int),
      ];

  /// タグ名を変更する。同名（大文字小文字・全角半角を区別しない）の別タグがあれば false。
  /// タグは書籍の属性として同期するため、そのタグが付いた書籍を更新扱いにする。
  bool renameTag(int id, String newName, {DateTime? at}) => transaction(() {
        final name = newName.trim();
        final key = tagKey(name);
        final clash = db.select('SELECT id FROM tags WHERE name_key = ? AND id <> ?', [key, id]);
        if (clash.isNotEmpty) return false;
        _touchBooksWithTag(id, at);
        db.execute('UPDATE tags SET name = ?, name_key = ? WHERE id = ?', [name, key, id]);
        return true;
      });

  /// タグを削除する（付いていた書籍は更新扱いになる）。
  void deleteTag(int id, {DateTime? at}) => transaction(() {
        _touchBooksWithTag(id, at);
        db.execute('DELETE FROM tags WHERE id = ?', [id]);
      });

  void _touchBooksWithTag(int tagId, DateTime? at) => db.execute('''
        UPDATE books SET updated_at = ?
        WHERE id IN (SELECT book_id FROM book_tags WHERE tag_id = ?)
      ''', [_ts(at ?? DateTime.now()), tagId]);

  Set<String> existingUuids() => {
        for (final r in db.select('SELECT uuid FROM books WHERE deleted_at IS NULL'))
          r['uuid'] as String,
      };

  Set<String> existingIsbnKeys() => {
        for (final r in db.select(
            'SELECT isbn FROM books WHERE isbn IS NOT NULL AND deleted_at IS NULL'))
          ?isbnMatchKey(r['isbn'] as String),
      };

  void _deleteUnusedTags() =>
      db.execute('DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM book_tags)');

  static Iterable<String> _uniqueTagNames(List<String> tags) {
    final seen = <String>{};
    return tags.map((t) => t.trim()).where((t) => t.isNotEmpty && seen.add(tagKey(t)));
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String _ts(DateTime d) => d.toUtc().toIso8601String();
}
