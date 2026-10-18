import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../models/book.dart';
import '../services/app_clock.dart';
import '../services/isbn.dart';
import '../services/search.dart';
import '../sync/sync_snapshot.dart';

enum BookSort {
  recent,
  title,

  /// 未設定 → 未読 → 読書中（読んだ割合の小さい順）→ 読了（最後の読了日の古い順）
  statusAscending,

  /// 読了（最後の読了日の新しい順）→ 読書中（読んだ割合の大きい順）→ 未読 → 未設定
  statusDescending,
}

/// ステータスの並び順（未設定から読了へ）を表す SQL の式。
const _statusRank = "CASE b.status WHEN 'unset' THEN 0 WHEN 'unread' THEN 1 WHEN 'reading' THEN 2 ELSE 3 END";

/// 書籍データの読み書き。sqlite3 は同期APIなので、各メソッドも同期で完結する。
///
/// 書籍とノートは削除しても行を残し、deleted_at に削除日時を記録する（削除済みの印）。
/// 端末間で同期するときに「削除された」ことを他の端末へ伝えるためで、
/// 読み込み系のメソッドは削除済みの印が付いた行を返さない。
class BookRepository {
  BookRepository(this.db);

  final Database db;

  /// 利用者の操作でデータが変わったときに呼ぶ（自動同期の予約に使う）。
  /// 同期で書き込んだとき（[applySync]）と、すべてのデータの消去では呼ばない。
  void Function()? onChanged;

  void _changed() => onChanged?.call();

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
    // 読書中は読んだ割合（未入力は 0%）、読了は最後の読了日（ない本はその中の最後）で並べ、
    // 残りは書籍名順にする
    final order = switch (sort) {
      BookSort.recent => 'b.created_at DESC, b.id DESC',
      BookSort.title => 'b.title COLLATE NOCASE ASC, b.id ASC',
      BookSort.statusAscending => '''
        $_statusRank ASC,
        CASE WHEN b.status = 'reading' THEN COALESCE(b.progress, 0) END ASC,
        CASE WHEN b.status = 'finished' THEN last_read IS NULL END ASC,
        CASE WHEN b.status = 'finished' THEN last_read END ASC,
        b.title COLLATE NOCASE ASC, b.id ASC''',
      BookSort.statusDescending => '''
        $_statusRank DESC,
        CASE WHEN b.status = 'reading' THEN COALESCE(b.progress, 0) END DESC,
        CASE WHEN b.status = 'finished' THEN last_read IS NULL END ASC,
        CASE WHEN b.status = 'finished' THEN last_read END DESC,
        b.title COLLATE NOCASE ASC, b.id ASC''',
    };
    final tags = _tagsByBook();
    final rows = db.select('''
      SELECT b.id, b.title, b.author, b.status, b.progress, b.thumbnail, b.created_at, b.updated_at,
             (SELECT COUNT(*) FROM read_records r WHERE r.book_id = b.id) AS read_count,
             (SELECT MAX(finished_on) FROM read_records r WHERE r.book_id = b.id) AS last_read
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
  /// - [removedNotes] を渡した場合は、そこに含まれるノートだけに削除済みの印を付け、渡されなかった
  ///   ほかのノートは後ろに残す（編集画面を開いている間に同期で届いたノートを消さないため）
  int saveBook(Book book, {Set<String>? removedNotes}) => transaction(() {
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
          book.cover == null ? null : coverHashOf(book.cover!),
          _ts(book.createdAt),
          _ts(book.updatedAt),
        ];
        final id = book.id ?? _idOfUuid(book.uuid);
        if (id == null) {
          db.execute('''
            INSERT INTO books (uuid, title, author, translator, supervisor, publisher, isbn,
              edition, status, progress, cover, cover_type, thumbnail, cover_hash, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', values);
        } else {
          db.execute('''
            UPDATE books SET uuid = ?, title = ?, author = ?, translator = ?, supervisor = ?,
              publisher = ?, isbn = ?, edition = ?, status = ?, progress = ?, cover = ?,
              cover_type = ?, thumbnail = ?, cover_hash = ?, created_at = ?, updated_at = ?, deleted_at = NULL
            WHERE id = ?
          ''', [...values, id]);
          db.execute('DELETE FROM read_records WHERE book_id = ?', [id]);
          db.execute('DELETE FROM book_tags WHERE book_id = ?', [id]);
        }
        final bookId = id ?? db.lastInsertRowId;

        _saveNotes(bookId, book.notes, deletedAt: book.updatedAt, removedNotes: removedNotes);

        for (final d in book.readDates.toSet()) {
          db.execute('INSERT INTO read_records (book_id, finished_on) VALUES (?, ?)', [bookId, d.toIso()]);
        }

        _addTags(bookId, book.tags);
        _deleteUnusedTags();
        _changed();
        return bookId;
      });

  void _addTags(int bookId, List<String> tags) {
    for (final name in _uniqueTagNames(tags)) {
      final key = tagKey(name);
      db.execute('INSERT OR IGNORE INTO tags (name, name_key) VALUES (?, ?)', [name, key]);
      db.execute('''
        INSERT OR IGNORE INTO book_tags (book_id, tag_id)
        SELECT ?, id FROM tags WHERE name_key = ?
      ''', [bookId, key]);
    }
  }

  int? _idOfUuid(String uuid) {
    final rows = db.select('SELECT id FROM books WHERE uuid = ?', [uuid]);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  void _saveNotes(int bookId, List<Note> notes, {required DateTime deletedAt, Set<String>? removedNotes}) {
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
    if (removedNotes == null) {
      db.execute('''
        UPDATE notes SET deleted_at = ?, updated_at = ?, body = ''
        WHERE book_id = ? AND deleted_at IS NULL
          AND uuid NOT IN (${List.filled(kept.length, '?').join(', ')})
      ''', [_ts(deletedAt), _ts(deletedAt), bookId, ...kept]);
      return;
    }
    final removed = removedNotes.difference(kept.toSet()).toList();
    db.execute('''
      UPDATE notes SET deleted_at = ?, updated_at = ?, body = ''
      WHERE book_id = ? AND deleted_at IS NULL AND uuid IN (${List.filled(removed.length, '?').join(', ')})
    ''', [_ts(deletedAt), _ts(deletedAt), bookId, ...removed]);
    _orderNotes(bookId, kept);
  }

  /// ノート1件のお気に入りを切り替えて、すぐ保存する（検索結果から操作する場合）。
  /// 同期で変更が伝わるよう、ノートとその書籍の更新日時も更新する。対象がなければ false。
  bool setNoteFavorite(String noteUuid, bool favorite, {DateTime? at}) => transaction(() {
        final ts = _ts(at ?? AppClock.now());
        db.execute('''
          UPDATE notes SET favorite = ?, updated_at = ?
          WHERE uuid = ? AND deleted_at IS NULL
        ''', [favorite ? 1 : 0, ts, noteUuid]);
        if (db.updatedRows == 0) return false;
        db.execute('''
          UPDATE books SET updated_at = ?
          WHERE id = (SELECT book_id FROM notes WHERE uuid = ?)
        ''', [ts, noteUuid]);
        _changed();
        return true;
      });

  /// 書籍に削除済みの印を付ける。ノートにも印を付け、書影・読了日・タグは消す。
  void deleteBook(int id, {DateTime? at}) => transaction(() {
        _markDeleted(id, (at ?? AppClock.now()).toUtc());
        _deleteUnusedTags();
        _changed();
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

  /// すべての書籍に削除済みの印を付ける（インポートの「すべて置き換える」、すべてのデータの削除で使用）。
  ///
  /// [afterEachUpdate] なら、印の日時を各書籍の更新日時より必ず後にする。時計が進んでいた端末で
  /// 未来の日時が付いた書籍も、同期で確実に削除されるようにするため。
  void deleteAllBooks({DateTime? at, bool afterEachUpdate = false}) => transaction(() {
        final now = (at ?? AppClock.now()).toUtc();
        for (final r in db.select('SELECT id, updated_at FROM books WHERE deleted_at IS NULL')) {
          final after = DateTime.parse(r['updated_at'] as String).add(const Duration(microseconds: 1));
          _markDeleted(r['id'] as int, afterEachUpdate && after.isAfter(now) ? after : now);
        }
        _deleteUnusedTags();
        _changed();
      });

  void _markDeleted(int id, DateTime at) {
    final ts = _ts(at);
    db.execute('''
      UPDATE books SET deleted_at = ?, updated_at = ?, cover = NULL, cover_type = NULL, thumbnail = NULL,
        cover_hash = NULL
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
        _changed();
        return true;
      });

  /// タグを削除する（付いていた書籍は更新扱いになる）。
  void deleteTag(int id, {DateTime? at}) => transaction(() {
        _touchBooksWithTag(id, at);
        db.execute('DELETE FROM tags WHERE id = ?', [id]);
        _changed();
      });

  void _touchBooksWithTag(int tagId, DateTime? at) => db.execute('''
        UPDATE books SET updated_at = ?
        WHERE id IN (SELECT book_id FROM book_tags WHERE tag_id = ?)
      ''', [_ts(at ?? AppClock.now()), tagId]);

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

  // ---------------------------------------------------------------------------
  // Google ドライブ同期
  // ---------------------------------------------------------------------------

  /// 削除済みの印も含めた全データを、同期データの形で取り出す（書影の中身は含まない）。
  SyncSnapshot exportSyncSnapshot() => transaction(() {
        // v4 より前に保存した書影には SHA-256 がないので、ここで埋める
        for (final r in db.select('SELECT id, cover FROM books WHERE cover IS NOT NULL AND cover_hash IS NULL')) {
          db.execute('UPDATE books SET cover_hash = ? WHERE id = ?', [coverHashOf(r['cover'] as Uint8List), r['id']]);
        }
        final tags = _tagsByBook();
        final readDates = <int, List<String>>{};
        for (final r in db.select('SELECT book_id, finished_on FROM read_records ORDER BY finished_on')) {
          (readDates[r['book_id'] as int] ??= []).add(r['finished_on'] as String);
        }
        final noteOrder = <int, List<String>>{};
        for (final r in db.select(
            'SELECT book_id, uuid FROM notes WHERE deleted_at IS NULL ORDER BY book_id, position, id')) {
          (noteOrder[r['book_id'] as int] ??= []).add(r['uuid'] as String);
        }

        final books = <SyncBook>[];
        for (final r in db.select('''
          SELECT id, uuid, title, author, translator, supervisor, publisher, isbn, edition, status, progress,
                 cover_hash, cover_type, created_at, updated_at, deleted_at
          FROM books ORDER BY id
        ''')) {
          final id = r['id'] as int;
          final createdAt = DateTime.parse(r['created_at'] as String);
          final deletedAt = r['deleted_at'] as String?;
          books.add(deletedAt != null
              ? SyncBook(
                  uuid: r['uuid'] as String,
                  createdAt: createdAt,
                  updatedAt: DateTime.parse(r['updated_at'] as String),
                  deletedAt: DateTime.parse(deletedAt),
                )
              : SyncBook(
                  uuid: r['uuid'] as String,
                  title: r['title'] as String,
                  author: r['author'] as String?,
                  translator: r['translator'] as String?,
                  supervisor: r['supervisor'] as String?,
                  publisher: r['publisher'] as String?,
                  isbn: r['isbn'] as String?,
                  edition: r['edition'] as String?,
                  status: r['status'] as String,
                  progress: r['progress'] as int?,
                  coverHash: r['cover_hash'] as String?,
                  coverType: r['cover_hash'] == null ? null : r['cover_type'] as String?,
                  readDates: readDates[id] ?? const [],
                  tags: tags[id] ?? const [],
                  noteOrder: noteOrder[id] ?? const [],
                  createdAt: createdAt,
                  updatedAt: DateTime.parse(r['updated_at'] as String),
                ));
        }

        final notes = <SyncNote>[
          for (final r in db.select('''
            SELECT n.uuid, b.uuid AS book_uuid, n.category, n.page, n.body, n.favorite,
                   n.created_at, n.updated_at, n.deleted_at
            FROM notes n JOIN books b ON b.id = n.book_id ORDER BY n.id
          '''))
            SyncNote(
              uuid: r['uuid'] as String,
              bookUuid: r['book_uuid'] as String,
              category: r['category'] as String?,
              page: r['page'] as int?,
              body: r['body'] as String,
              favorite: r['favorite'] == 1,
              createdAt: DateTime.parse(r['created_at'] as String),
              updatedAt: DateTime.parse(r['updated_at'] as String),
              deletedAt: r['deleted_at'] == null ? null : DateTime.parse(r['deleted_at'] as String),
            ),
        ];
        return SyncSnapshot(books: books, notes: notes);
      });

  /// SHA-256 が [hash] の書影。クラウドへ送るときに使う。なければ null。
  SyncCover? coverByHash(String hash) {
    final rows = db.select(
        'SELECT cover, cover_type, thumbnail FROM books WHERE cover_hash = ? AND cover IS NOT NULL LIMIT 1', [hash]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return SyncCover(
      bytes: r['cover'] as Uint8List,
      type: r['cover_type'] as String?,
      thumbnail: r['thumbnail'] as Uint8List?,
    );
  }

  /// 同期で決まった内容を書き込む。日時は渡された値をそのまま使う。
  ///
  /// 書影が変わる書籍の書影は [covers]（SHA-256 → 中身）で渡す。足りなければ [StateError] で
  /// 何も書き込まずに終える。削除済みの印は、ノートの付け替えが済んでから最後に付ける。
  void applySync({
    required List<SyncBook> books,
    required List<SyncNote> notes,
    Map<String, SyncCover> covers = const {},
  }) =>
      transaction(() {
        // 書影は書き込みを始める前にすべて確保する。途中で別の書籍の書影を差し替えると、
        // この端末にしかない書影が消えて見つからなくなるため
        final available = {...covers};
        for (final b in books) {
          final hash = b.coverHash;
          if (b.isDeleted || hash == null || available.containsKey(hash)) continue;
          if (coverByHash(hash) case final local?) available[hash] = local;
        }
        final touched = <int, List<String>>{};
        for (final b in books.where((b) => !b.isDeleted)) {
          touched[_applySyncBook(b, available)] = b.noteOrder;
        }
        for (final n in notes) {
          final bookId = _applySyncNote(n);
          if (bookId != null) touched.putIfAbsent(bookId, () => const []);
        }
        for (final b in books.where((b) => b.isDeleted)) {
          final id = _idOfUuid(b.uuid);
          if (id == null) continue;
          _markDeleted(id, b.deletedAt!);
          db.execute('UPDATE books SET updated_at = ? WHERE id = ?', [_ts(b.updatedAt), id]);
          touched.remove(id);
        }
        touched.forEach(_orderNotes);
        _deleteUnusedTags();
      });

  int _applySyncBook(SyncBook b, Map<String, SyncCover> covers) {
    final id = _idOfUuid(b.uuid);
    final values = [
      b.title,
      _blankToNull(b.author),
      _blankToNull(b.translator),
      _blankToNull(b.supervisor),
      _blankToNull(b.publisher),
      _blankToNull(b.isbn),
      _blankToNull(b.edition),
      ReadingStatus.fromCode(b.status).code,
      b.progress,
      _ts(b.createdAt),
      _ts(b.updatedAt),
    ];
    final currentHash = id == null
        ? null
        : db.select('SELECT cover_hash FROM books WHERE id = ?', [id]).first['cover_hash'] as String?;
    final keepCover = id != null && b.coverHash == currentHash;
    final SyncCover? cover;
    if (keepCover || b.coverHash == null) {
      cover = null;
    } else {
      cover = covers[b.coverHash] ?? (throw StateError('cover ${b.coverHash} was not provided'));
    }

    final int bookId;
    if (id == null) {
      db.execute('''
        INSERT INTO books (uuid, title, author, translator, supervisor, publisher, isbn, edition, status,
          progress, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [b.uuid, ...values]);
      bookId = db.lastInsertRowId;
    } else {
      db.execute('''
        UPDATE books SET title = ?, author = ?, translator = ?, supervisor = ?, publisher = ?, isbn = ?,
          edition = ?, status = ?, progress = ?, created_at = ?, updated_at = ?, deleted_at = NULL
        WHERE id = ?
      ''', [...values, id]);
      bookId = id;
      db.execute('DELETE FROM read_records WHERE book_id = ?', [id]);
      db.execute('DELETE FROM book_tags WHERE book_id = ?', [id]);
    }
    if (!keepCover) {
      db.execute(
        'UPDATE books SET cover = ?, thumbnail = ?, cover_hash = ? WHERE id = ?',
        [cover?.bytes, cover?.thumbnail, cover == null ? null : b.coverHash, bookId],
      );
    }
    // 画像の種類は同期データの値にそろえる（書影の中身と別に届くため、受け取った側の判定と食い違わないように）
    db.execute('UPDATE books SET cover_type = ? WHERE id = ?',
        [b.coverHash == null ? null : (b.coverType ?? cover?.type), bookId]);
    for (final d in b.readDates.toSet()) {
      if (LocalDate.tryParse(d) case final date?) {
        db.execute('INSERT INTO read_records (book_id, finished_on) VALUES (?, ?)', [bookId, date.toIso()]);
      }
    }
    _addTags(bookId, b.tags);
    return bookId;
  }

  /// ノート1件を書き込み、その書籍の id を返す。書籍がこの端末になければ書き込まずに null。
  int? _applySyncNote(SyncNote n) {
    final bookId = _idOfUuid(n.bookUuid);
    if (bookId == null) return null;
    db.execute('''
      INSERT INTO notes (uuid, book_id, position, category, page, body, favorite, created_at, updated_at, deleted_at)
      VALUES (?, ?, (SELECT COALESCE(MAX(position), -1) + 1 FROM notes WHERE book_id = ?), ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (uuid) DO UPDATE SET
        book_id = excluded.book_id, category = excluded.category, page = excluded.page, body = excluded.body,
        favorite = excluded.favorite, created_at = excluded.created_at, updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at
    ''', [
      n.uuid,
      bookId,
      bookId,
      n.isDeleted ? null : NoteCategory.fromCode(n.category)?.code,
      n.isDeleted ? null : n.page,
      n.isDeleted ? '' : n.body,
      !n.isDeleted && n.favorite ? 1 : 0,
      _ts(n.createdAt),
      _ts(n.updatedAt),
      n.deletedAt == null ? null : _ts(n.deletedAt!),
    ]);
    return bookId;
  }

  /// ノートの並び順を [order]（uuid の並び）にそろえる。[order] にないノートは、今の順のまま後ろに付ける。
  void _orderNotes(int bookId, List<String> order) {
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    final rows = db.select(
        'SELECT id, uuid FROM notes WHERE book_id = ? AND deleted_at IS NULL ORDER BY position, created_at, id',
        [bookId]);
    final ids = [
      for (final (i, r) in rows.indexed) (rank: rank[r['uuid']] ?? order.length + i, id: r['id'] as int),
    ]..sort((a, b) => a.rank.compareTo(b.rank));
    for (final (position, entry) in ids.indexed) {
      db.execute('UPDATE notes SET position = ? WHERE id = ?', [position, entry.id]);
    }
  }

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
