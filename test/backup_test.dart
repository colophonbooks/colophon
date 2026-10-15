import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/l10n/app_localizations.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/services/backup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'helpers.dart';

Uint8List _png(int w, int h) => img.encodePng(img.Image(width: w, height: h));

void main() {
  late BookRepository repo;

  setUp(() {
    repo = newRepository();
    repo.saveBook(sampleBook(
      uuid: 'uuid-1',
      title: 'サピエンス全史',
      isbn: '978-4-309-22671-2',
      status: ReadingStatus.reading,
      progress: 55,
      notes: [
        Note(category: NoteCategory.excerpt, page: 7, body: '一行目\n二行目', favorite: true),
        Note(body: '分類なし'),
      ],
      readDates: [const LocalDate(2025, 5, 5), const LocalDate(2026, 1, 1)],
      tags: ['歴史'],
    ).withCover(_png(30, 45)));
    repo.saveBook(sampleBook(uuid: 'uuid-2', title: '表紙なしの本', author: null, translator: null));
  });
  tearDown(() => repo.db.close());

  void expectSameLibrary(List<Book> actual) {
    final expected = repo.getAllBooks();
    expect(actual, hasLength(expected.length));
    for (final e in expected) {
      final a = actual.firstWhere((b) => b.uuid == e.uuid);
      expect(a.title, e.title);
      expect(a.author, e.author);
      expect(a.translator, e.translator);
      expect(a.isbn, e.isbn);
      expect(a.status, e.status);
      expect(a.progress, e.progress);
      expect(a.cover, e.cover);
      expect(a.coverType, e.coverType);
      expect(a.thumbnail != null, e.cover != null, reason: '書影があればサムネイルを作り直す');
      expect(a.tags, e.tags);
      expect(a.readDates, e.readDates);
      expect(
        a.notes.map((n) => (n.uuid, n.category, n.page, n.body, n.favorite)),
        e.notes.map((n) => (n.uuid, n.category, n.page, n.body, n.favorite)),
      );
      expect(a.createdAt, e.createdAt);
      expect(a.updatedAt, e.updatedAt);
    }
  }

  group('JSON＋画像（ZIP）', () {
    test('books.json と covers/ フォルダの構成で書き出す', () {
      final archive = ZipDecoder().decodeBytes(exportZip(repo.getAllBooks()));
      expect(archive.findFile('books.json'), isNotNull);
      expect(archive.findFile('covers/uuid-1.png'), isNotNull);

      final json = jsonDecode(utf8.decode(archive.findFile('books.json')!.content)) as Map;
      expect(json['format'], 'colophon');
      expect(json['version'], 1);
      final first = (json['books'] as List).firstWhere((b) => b['uuid'] == 'uuid-1') as Map;
      expect(first['status'], 'reading');
      expect(first['cover'], 'covers/uuid-1.png');
      expect(first['readDates'], ['2025-05-05', '2026-01-01']);
      expect((first['notes'] as List).first['category'], 'excerpt');
    });

    test('書き出したファイルから全項目を復元できる', () async {
      expectSameLibrary(await readBackup(exportZip(repo.getAllBooks())));
    });

    test('形式名が違うZIPは Colophon のデータとして扱わない', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('books.json', utf8.encode('{"format":"other","version":1,"books":[]}')));
      expect(readBackup(ZipEncoder().encodeBytes(archive)), throwsA(isA<InvalidBackupException>()));
    });

    test('新しい形式バージョンのファイルは読み込まない', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('books.json', utf8.encode('{"format":"colophon","version":99,"books":[]}')));
      expect(readBackup(ZipEncoder().encodeBytes(archive)), throwsA(isA<NewerBackupException>()));
    });

    test('不正な値は捨てて、書籍名のない項目は読み飛ばす', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes(
          'books.json',
          utf8.encode(jsonEncode({
            'format': 'colophon',
            'version': 1,
            'books': [
              {'title': ''},
              {
                'title': '最小限の本',
                'status': 'unknown',
                'progress': 150,
                'readDates': ['2026-02-30', '2026-02-28'],
                'notes': [
                  {'body': 'ok', 'page': 0, 'category': 'x'},
                  {'body': ''},
                ],
              },
            ],
          })),
        ));
      final books = await readBackup(ZipEncoder().encodeBytes(archive));
      final b = books.single;
      expect(b.title, '最小限の本');
      expect(b.uuid, isNotEmpty);
      expect(b.status, ReadingStatus.unset);
      expect(b.progress, isNull);
      expect(b.readDates, [const LocalDate(2026, 2, 28)]);
      expect(b.notes.single.page, isNull);
      expect(b.notes.single.category, isNull);
      expect(b.notes.single.favorite, isFalse, reason: '項目 favorite のない古い形式はお気に入りなし');
    });
  });

  group('SQLite', () {
    test('書き出したファイルから全項目を復元できる', () async {
      expectSameLibrary(await readBackup(exportSqlite(repo.db)));
    });

    test('Colophon 以外のファイルは読み込まない', () async {
      expect(readBackup(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<InvalidBackupException>()));
    });
  });

  group('テキスト', () {
    test('項目名は表示言語、入力内容はそのまま出力する', () {
      final text = exportText(repo.getAllBooks(), lookupAppLocalizations(const Locale('ja')));
      expect(text, contains('2冊'));
      expect(text, contains('サピエンス全史'));
      expect(text, contains('ステータス: 読書中 (55%)'));
      expect(text, contains('読了日: 2025-05-05, 2026-01-01'));
      expect(text, contains('- ★ [抜粋] p.7\n  一行目\n  二行目'), reason: 'お気に入りには★を付ける');
      expect(text, contains('\n-\n  分類なし'), reason: 'お気に入りでないノートには付けない');

      final en = exportText(repo.getAllBooks(), lookupAppLocalizations(const Locale('en')));
      expect(en, contains('Status: Reading (55%)'));
      expect(en, contains('サピエンス全史'));
    });

    test('書籍に3桁以上の通し番号を付ける', () {
      final text = exportText(repo.getAllBooks(), lookupAppLocalizations(const Locale('ja')));
      expect(text, contains('[001] サピエンス全史'));
      expect(text, contains('[002] 表紙なしの本'));
      expect(text, isNot(contains('書影:')), reason: '書影を含めない場合は書影の行を出さない');
    });

    test('書影を含めると、テキストと書影フォルダを ZIP にまとめ、テキストに書影のパスを書く', () async {
      final l = lookupAppLocalizations(const Locale('ja'));
      final archive = ZipDecoder().decodeBytes(await exportTextWithCovers(repo.getAllBooks(), l));

      expect(archive.files.map((f) => f.name), unorderedEquals(['colophon.txt', 'covers/001_サピエンス全史.png']));
      final cover = repo.getAllBooks().firstWhere((b) => b.uuid == 'uuid-1').cover;
      expect(archive.findFile('covers/001_サピエンス全史.png')!.content, cover);

      final text = utf8.decode(archive.findFile('colophon.txt')!.content);
      expect(text, contains('[001] サピエンス全史\n========================================\n書影: covers/001_サピエンス全史.png'));
      final second = text.substring(text.indexOf('[002]'));
      expect(second, isNot(contains('書影:')), reason: '書影のない本には書影の行を出さない');
    });

    test('書影のファイル名は、どの OS でも使える形にする', () {
      Book titled(String title) => sampleBook(title: title).withCover(_png(1, 1));
      expect(coverFileName('001', titled('A/B: C?')), '001_A_B_ C_.png');
      expect(coverFileName('002', titled('続く…。 ')), '002_続く…。.png');
      expect(coverFileName('003', titled('end...')), '003_end.png');
      expect(coverFileName('004', titled('...')), '004.png');
      final long = coverFileName('005', titled('あ' * 100));
      expect(long, '005_${'あ' * 60}.png');
    });
  });

  group('インポートの反映', () {
    test('置き換えでは既存の書籍を消してから復元する', () async {
      final backup = await readBackup(exportZip(repo.getAllBooks()));
      repo.saveBook(sampleBook(uuid: 'uuid-3', title: 'あとから追加'));

      final result = applyImport(repo, backup, ImportMode.replace);

      expect(result.added, 2);
      expect(repo.getAllBooks().map((b) => b.title), unorderedEquals(['サピエンス全史', '表紙なしの本']));
    });

    test('置き換えでは、同じISBNや正しくないISBNの書籍が複数あっても欠けずに復元する', () async {
      repo.saveBook(sampleBook(uuid: 'uuid-dup', title: '2冊目', isbn: '9784309226712'));
      repo.saveBook(sampleBook(uuid: 'uuid-x1', title: 'ISBN不明1', isbn: '不明'));
      repo.saveBook(sampleBook(uuid: 'uuid-x2', title: 'ISBN不明2', isbn: '不明'));
      final before = repo.countBooks();

      final backup = await readBackup(exportZip(repo.getAllBooks()));
      final result = applyImport(repo, backup, ImportMode.replace);

      expect(result.skipped, 0);
      expect(repo.countBooks(), before);
    });

    test('分類やページだけのノート（本文なし）も往復で残り、何も入っていないノートは捨てる', () async {
      repo.saveBook(sampleBook(uuid: 'uuid-n', title: 'しおり代わり', notes: [Note(page: 120, body: '')]));
      final books = await readBackup(exportZip(repo.getAllBooks()));
      expect(books.firstWhere((b) => b.uuid == 'uuid-n').notes.single.page, 120);
    });

    test('置き換えでは、ファイルにない書籍に削除済みの印を付ける（同期で他の端末にも伝わる）', () async {
      final backup = await readBackup(exportZip(repo.getAllBooks()));
      repo.saveBook(sampleBook(uuid: 'uuid-3', title: 'ファイルにない本'));

      applyImport(repo, backup, ImportMode.replace);

      final row = repo.db.select("SELECT deleted_at FROM books WHERE uuid = 'uuid-3'").single;
      expect(row['deleted_at'], isNotNull);
    });

    test('追加では、こちらで削除済みの書籍もファイルから復活させる', () async {
      final backup = await readBackup(exportZip(repo.getAllBooks()));
      final deleted = repo.getAllBooks().firstWhere((b) => b.uuid == 'uuid-2');
      repo.deleteBook(deleted.id!);

      final result = applyImport(repo, backup, ImportMode.merge);

      expect(result.added, 1);
      expect(repo.getAllBooks().map((b) => b.uuid), contains('uuid-2'));
    });

    test('追加では同じIDまたは同じISBNの書籍をスキップする', () async {
      final backup = await readBackup(exportZip(repo.getAllBooks()));
      final newcomer = sampleBook(uuid: 'uuid-new', title: '新しい本');
      // 別の端末で登録した同じ本（IDは違うがISBN-10で同一書籍）
      final sameIsbn = sampleBook(uuid: 'uuid-other', title: '別登録', isbn: '4-309-22671-X');

      final result = applyImport(repo, [...backup, newcomer, sameIsbn], ImportMode.merge);

      expect(result.added, 1);
      expect(result.skipped, 3);
      expect(repo.countBooks(), 3);
    });
  });
}

extension on Book {
  Book withCover(Uint8List png) => Book(
        uuid: uuid,
        title: title,
        author: author,
        translator: translator,
        isbn: isbn,
        status: status,
        progress: progress,
        cover: png,
        coverType: 'image/png',
        thumbnail: png,
        notes: notes,
        readDates: readDates,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
