import 'package:colophon/data/app_database.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

void main() {
  late BookRepository repo;

  setUp(() => repo = newRepository());
  tearDown(() => repo.db.close());

  test('新規作成したDBは現在のスキーマバージョンになる', () {
    expect(readSchemaVersion(repo.db), schemaVersion);
  });

  test('v1 のDBは、既存のノートに ID を振って v2 へ移行する', () {
    final db = sqlite3.openInMemory()..execute('PRAGMA foreign_keys = ON');
    migrate(db, target: 1);
    db.execute("INSERT INTO books (uuid, title, created_at, updated_at) VALUES ('b', '旧', 'x', 'x')");
    db.execute('''
      INSERT INTO notes (book_id, position, body, created_at, updated_at)
      VALUES (1, 0, 'メモ1', 'x', 'x'), (1, 1, 'メモ2', 'x', 'x')
    ''');

    migrate(db, target: 2);

    expect(readSchemaVersion(db), 2);
    final uuids = db.select('SELECT uuid FROM notes').map((r) => r['uuid'] as String).toList();
    expect(uuids, hasLength(2));
    expect(uuids.toSet(), hasLength(2), reason: 'ノートごとに別の ID');
    for (final u in uuids) {
      expect(u, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    }
    expect(db.select('SELECT deleted_at FROM books').single['deleted_at'], isNull);
    db.close();
  });

  test('v2 のDBは、既存のノートを「お気に入りなし」として v3 へ移行する', () {
    final db = sqlite3.openInMemory()..execute('PRAGMA foreign_keys = ON');
    migrate(db, target: 2);
    db.execute("INSERT INTO books (uuid, title, created_at, updated_at) VALUES ('b', '旧', 'x', 'x')");
    db.execute("INSERT INTO notes (uuid, book_id, position, body, created_at, updated_at) VALUES ('n', 1, 0, 'メモ', 'x', 'x')");

    migrate(db);

    expect(readSchemaVersion(db), 3);
    expect(db.select('SELECT favorite FROM notes').single['favorite'], 0);
    db.close();
  });

  test('新しいバージョンのDBは開かずに例外にする', () {
    final db = sqlite3.openInMemory()..execute('PRAGMA user_version = ${schemaVersion + 1}');
    expect(() => prepareDatabase(db), throwsA(isA<NewerSchemaException>()));
    db.close();
  });

  test('書籍を関連データ込みで保存・読み込みできる', () {
    final id = repo.saveBook(sampleBook(
      status: ReadingStatus.reading,
      progress: 40,
      isbn: '978-4-309-22671-2',
      notes: [
        Note(category: NoteCategory.impression, page: 12, body: '面白い'),
        Note(body: '分類なしのメモ'),
      ],
      readDates: [const LocalDate(2026, 3, 1), const LocalDate(2025, 1, 5)],
      tags: ['歴史', '人類学'],
    ));

    final book = repo.getBook(id)!;
    expect(book.title, 'サピエンス全史');
    expect(book.translator, '柴田裕之');
    expect(book.status, ReadingStatus.reading);
    expect(book.progress, 40);
    expect(book.notes.map((n) => n.body), ['面白い', '分類なしのメモ']);
    expect(book.notes.first.category, NoteCategory.impression);
    expect(book.notes.first.page, 12);
    expect(book.notes.last.category, isNull);
    expect(book.readDates, [const LocalDate(2025, 1, 5), const LocalDate(2026, 3, 1)]);
    expect(book.tags, unorderedEquals(['歴史', '人類学']));
  });

  test('任意項目の空白だけの入力は未入力として保存する', () {
    final id = repo.saveBook(sampleBook(author: '   ', translator: ''));
    final book = repo.getBook(id)!;
    expect(book.author, isNull);
    expect(book.translator, isNull);
  });

  test('更新するとノート・読了日・タグが置き換わる', () {
    final id = repo.saveBook(sampleBook(
      notes: [Note(body: 'a'), Note(body: 'b')],
      readDates: [const LocalDate(2026, 1, 1)],
      tags: ['x'],
    ));
    final original = repo.getBook(id)!;
    repo.saveBook(sampleBook(
      id: id,
      uuid: original.uuid,
      notes: [Note(body: 'b'), Note(body: 'c')],
      readDates: const [],
      tags: ['y'],
    ));

    final book = repo.getBook(id)!;
    expect(book.notes.map((n) => n.body), ['b', 'c']);
    expect(book.readDates, isEmpty);
    expect(book.tags, ['y']);
    expect(repo.tagNames(), ['y'], reason: 'どの書籍にも付いていないタグは消える');
  });

  test('同じ読了日・大文字小文字違いのタグは重複して保存しない', () {
    final id = repo.saveBook(sampleBook(
      readDates: [const LocalDate(2026, 1, 1), const LocalDate(2026, 1, 1)],
      tags: ['SF', 'sf', ' SF '],
    ));
    final book = repo.getBook(id)!;
    expect(book.readDates, hasLength(1));
    expect(book.tags, ['SF']);
  });

  test('一覧は登録日の新しい順・書籍名順で並べ替えられ、読了回数を数える', () {
    repo.saveBook(sampleBook(title: 'B', createdAt: DateTime.utc(2026, 3, 1)));
    repo.saveBook(sampleBook(
      title: 'a',
      createdAt: DateTime.utc(2026, 2, 1),
      readDates: [const LocalDate(2026, 2, 1), const LocalDate(2026, 3, 1)],
    ));
    repo.saveBook(sampleBook(title: 'C', createdAt: DateTime.utc(2025, 12, 1)));

    expect(repo.listSummaries(sort: BookSort.recent).map((b) => b.title), ['B', 'a', 'C']);
    expect(repo.listSummaries(sort: BookSort.title).map((b) => b.title), ['a', 'B', 'C']);
    expect(repo.listSummaries(sort: BookSort.title).first.readCount, 2);
  });

  group('削除（同期に備えて削除済みの印を残す）', () {
    test('削除した書籍は読み込まれず、使われなくなったタグは消える', () {
      final keep = repo.saveBook(sampleBook(title: '残す', tags: ['共通']));
      final remove = repo.saveBook(sampleBook(
        title: '消す',
        tags: ['共通', '単独'],
        notes: [Note(body: 'メモ')],
        readDates: [const LocalDate(2026, 1, 1)],
      ));

      repo.deleteBook(remove, at: DateTime.utc(2026, 5, 1));

      expect(repo.getBook(remove), isNull);
      expect(repo.getBook(keep), isNotNull);
      expect(repo.listSummaries().map((b) => b.title), ['残す']);
      expect(repo.getAllBooks().map((b) => b.title), ['残す']);
      expect(repo.countBooks(), 1);
      expect(repo.tagNames(), ['共通']);
      expect(repo.db.select('SELECT * FROM read_records WHERE book_id = ?', [remove]), isEmpty);
    });

    test('削除した書籍とノートの行は、削除日時と ID を残して中身を消す', () {
      final id = repo.saveBook(sampleBook(notes: [Note(uuid: 'note-1', body: '秘密のメモ')]));
      repo.deleteBook(id, at: DateTime.utc(2026, 5, 1));

      final book = repo.db.select('SELECT * FROM books WHERE id = ?', [id]).single;
      expect(book['deleted_at'], '2026-05-01T00:00:00.000Z');
      expect(book['updated_at'], '2026-05-01T00:00:00.000Z');
      final note = repo.db.select("SELECT * FROM notes WHERE uuid = 'note-1'").single;
      expect(note['deleted_at'], isNotNull);
      expect(note['body'], '');
    });

    test('削除済みと同じ uuid の書籍を保存すると復活する', () {
      final id = repo.saveBook(sampleBook(uuid: 'book-1', title: '一度消した本'));
      repo.deleteBook(id);

      final revived = repo.saveBook(sampleBook(uuid: 'book-1', title: '戻した本'));

      expect(revived, id);
      expect(repo.getBook(id)!.title, '戻した本');
      expect(repo.db.select('SELECT * FROM books'), hasLength(1));
    });

    test('すべて削除しても行は残り、件数は0になる', () {
      repo.saveBook(sampleBook(title: 'A'));
      repo.saveBook(sampleBook(title: 'B'));
      repo.deleteAllBooks();
      expect(repo.countBooks(), 0);
      expect(repo.db.select('SELECT * FROM books WHERE deleted_at IS NOT NULL'), hasLength(2));
    });
  });

  group('ノートのお気に入り', () {
    test('編集画面からの保存でお気に入りが保存・読み込みされる', () {
      final id = repo.saveBook(sampleBook(notes: [
        Note(uuid: 'n-fav', body: '残したい一文', favorite: true),
        Note(uuid: 'n-plain', body: 'ふつうのメモ'),
      ]));
      expect(repo.getBook(id)!.notes.map((n) => (n.uuid, n.favorite)), [('n-fav', true), ('n-plain', false)]);
    });

    test('検索結果からの切り替えはすぐ保存され、ノートと書籍の更新日時が変わる', () {
      final id = repo.saveBook(sampleBook(notes: [Note(uuid: 'n-1', body: 'A')]));
      final at = DateTime.utc(2026, 9, 1);

      expect(repo.setNoteFavorite('n-1', true, at: at), isTrue);

      final book = repo.getBook(id)!;
      expect(book.notes.single.favorite, isTrue);
      expect(book.notes.single.updatedAt, at);
      expect(book.updatedAt, at);

      repo.setNoteFavorite('n-1', false);
      expect(repo.getBook(id)!.notes.single.favorite, isFalse);
    });

    test('存在しない・削除済みのノートは切り替えられない', () {
      final id = repo.saveBook(sampleBook(notes: [Note(uuid: 'n-1', body: 'A')]));
      repo.deleteBook(id);
      expect(repo.setNoteFavorite('n-1', true), isFalse);
      expect(repo.setNoteFavorite('unknown', true), isFalse);
    });
  });

  group('ノートの ID', () {
    test('編集してもノートの ID は変わらず、外したノートには削除済みの印が付く', () {
      final id = repo.saveBook(sampleBook(notes: [
        Note(uuid: 'n-a', body: 'A'),
        Note(uuid: 'n-b', body: 'B'),
      ]));
      final uuid = repo.getBook(id)!.uuid;

      repo.saveBook(sampleBook(id: id, uuid: uuid, notes: [Note(uuid: 'n-b', body: 'B改')]));

      expect(repo.getBook(id)!.notes.map((n) => (n.uuid, n.body)), [('n-b', 'B改')]);
      final removed = repo.db.select("SELECT deleted_at FROM notes WHERE uuid = 'n-a'").single;
      expect(removed['deleted_at'], isNotNull);
    });

    test('削除済みのノートと同じ ID で保存すると復活する', () {
      final id = repo.saveBook(sampleBook(notes: [Note(uuid: 'n-a', body: 'A')]));
      final uuid = repo.getBook(id)!.uuid;
      repo.saveBook(sampleBook(id: id, uuid: uuid, notes: const []));
      repo.saveBook(sampleBook(id: id, uuid: uuid, notes: [Note(uuid: 'n-a', body: 'A2')]));
      expect(repo.getBook(id)!.notes.single.body, 'A2');
    });
  });

  group('タグ管理', () {
    test('件数付きで一覧でき、名前を変更できる', () {
      repo.saveBook(sampleBook(tags: ['小説']));
      repo.saveBook(sampleBook(tags: ['小説', '名作']));
      final tags = repo.listTags();
      expect({for (final t in tags) t.name: t.bookCount}, {'小説': 2, '名作': 1});

      final novel = tags.firstWhere((t) => t.name == '小説');
      expect(repo.renameTag(novel.id, 'フィクション'), isTrue);
      expect(repo.tagNames(), unorderedEquals(['フィクション', '名作']));
    });

    test('別のタグと同じ名前（大文字小文字違いを含む）には変更できない', () {
      repo.saveBook(sampleBook(tags: ['SF', 'Mystery']));
      final mystery = repo.listTags().firstWhere((t) => t.name == 'Mystery');
      expect(repo.renameTag(mystery.id, 'sf'), isFalse);
      expect(repo.tagNames(), unorderedEquals(['SF', 'Mystery']));
    });

    test('ASCII以外の大文字小文字・全角半角の違いも同じタグとみなす', () {
      repo.saveBook(sampleBook(tags: ['Été']));
      repo.saveBook(sampleBook(tags: ['été', 'ＳＦ']));
      repo.saveBook(sampleBook(tags: ['sf']));
      expect({for (final t in repo.listTags()) t.name: t.bookCount}, {'Été': 2, 'ＳＦ': 2});

      final sf = repo.listTags().firstWhere((t) => t.name == 'ＳＦ');
      expect(repo.renameTag(sf.id, 'ÉTÉ'), isFalse, reason: '「Été」と衝突する');
      expect(repo.renameTag(sf.id, 'SF'), isTrue, reason: '自分自身の表記変更はできる');
    });

    test('タグの名前変更・削除は、そのタグが付いた書籍だけを更新扱いにする', () {
      final tagged = repo.saveBook(sampleBook(tags: ['小説']));
      final other = repo.saveBook(sampleBook(tags: ['実用']));
      final tag = repo.listTags().firstWhere((t) => t.name == '小説');

      repo.renameTag(tag.id, 'フィクション', at: DateTime.utc(2026, 6, 1));
      expect(repo.getBook(tagged)!.updatedAt, DateTime.utc(2026, 6, 1));
      expect(repo.getBook(other)!.updatedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));

      repo.deleteTag(tag.id, at: DateTime.utc(2026, 7, 1));
      expect(repo.getBook(tagged)!.updatedAt, DateTime.utc(2026, 7, 1));
    });

    test('タグを削除すると全書籍から外れる', () {
      final id = repo.saveBook(sampleBook(tags: ['消すタグ', '残すタグ']));
      final tag = repo.listTags().firstWhere((t) => t.name == '消すタグ');
      repo.deleteTag(tag.id);
      expect(repo.getBook(id)!.tags, ['残すタグ']);
    });
  });

  test('すべてのデータの消去では、削除済みの印も含めて全テーブルが空になる', () {
    repo.saveBook(sampleBook(tags: ['A'], notes: [Note(body: 'n')], readDates: [const LocalDate(2026, 1, 1)]));
    final deleted = repo.saveBook(sampleBook(title: '削除済み'));
    repo.deleteBook(deleted);

    repo.wipeAllData();

    for (final table in ['books', 'notes', 'read_records', 'tags', 'book_tags']) {
      expect(repo.db.select('SELECT COUNT(*) AS c FROM $table').first['c'], 0, reason: table);
    }
    expect(repo.countBooks(), 0);
  });

  test('入れ子のトランザクションは外側にまとまり、失敗時はすべて取り消される', () {
    expect(
      () => repo.transaction(() {
        repo.saveBook(sampleBook(title: '1冊目'));
        throw StateError('途中で失敗');
      }),
      throwsStateError,
    );
    expect(repo.countBooks(), 0);
  });
}
