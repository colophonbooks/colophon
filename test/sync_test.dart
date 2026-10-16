import 'dart:typed_data';

import 'package:colophon/data/app_database.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/sync/sync_plan.dart';
import 'package:colophon/sync/sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime t(int minute) => DateTime.utc(2026, 10, 15, 9, minute);

SyncBook sb(String uuid, int updated, {String title = '本', String? isbn, DateTime? deletedAt, List<String> tags = const [],
        List<String> readDates = const [], List<String> noteOrder = const [], String? coverHash}) =>
    deletedAt == null
        ? SyncBook(
            uuid: uuid,
            title: title,
            isbn: isbn,
            tags: tags,
            readDates: readDates,
            noteOrder: noteOrder,
            coverHash: coverHash,
            coverType: coverHash == null ? null : 'image/png',
            createdAt: t(0),
            updatedAt: t(updated),
          )
        : SyncBook.tombstone(uuid, createdAt: t(0), at: deletedAt);

SyncNote sn(String uuid, String book, int updated, {String body = 'メモ', DateTime? deletedAt}) => SyncNote(
      uuid: uuid,
      bookUuid: book,
      body: deletedAt == null ? body : '',
      createdAt: t(0),
      updatedAt: t(updated),
      deletedAt: deletedAt,
    );

SyncPlan plan(List<SyncBook> lb, List<SyncNote> ln, List<SyncBook>? rb, [List<SyncNote> rn = const [],
        FirstSyncMode? mode]) =>
    planSync(
      local: withNoteOrder(lb, ln),
      remote: rb == null ? null : withNoteOrder(rb, rn),
      firstSync: mode,
      now: t(59),
    );

/// 端末から取り出す同期データと同じく、並び順が空の書籍にはノートの並びを入れる。
SyncSnapshot withNoteOrder(List<SyncBook> books, List<SyncNote> notes) => SyncSnapshot(
      books: [
        for (final b in books)
          b.isDeleted || b.noteOrder.isNotEmpty
              ? b
              : b.copyWith(noteOrder: [
                  for (final n in notes)
                    if (n.bookUuid == b.uuid && !n.isDeleted) n.uuid,
                ]),
      ],
      notes: notes,
    );

SyncBook bookIn(SyncPlan p, String uuid) => p.merged.books.singleWhere((b) => b.uuid == uuid);
SyncNote noteIn(SyncPlan p, String uuid) => p.merged.notes.singleWhere((n) => n.uuid == uuid);

/// 2台の端末の同期を再現するための、メモリ上のクラウド。
class FakeCloud {
  SyncSnapshot? snapshot;
  final covers = <String, SyncCover>{};

  /// 同期エンジンと同じ手順で1回同期する（取得 → 統合 → この端末へ書き込み → 送信）。
  SyncPlan sync(BookRepository repo, {FirstSyncMode? mode, DateTime? now}) {
    final p = planSync(local: repo.exportSyncSnapshot(), remote: snapshot, firstSync: mode, now: now ?? t(59));
    for (final hash in p.coverHashes) {
      if (!covers.containsKey(hash)) {
        final c = repo.coverByHash(hash);
        if (c != null) covers[hash] = SyncCover(bytes: c.bytes, type: c.type, thumbnail: c.thumbnail);
      }
    }
    repo.applySync(books: p.booksToApply, notes: p.notesToApply, covers: covers);
    // JSON を経由させ、形式の往復でも内容が変わらないことを確かめる
    if (p.uploadNeeded) snapshot = SyncSnapshot.decode(p.merged.encode());
    return p;
  }
}

Book book(
  String uuid,
  int updated, {
  int? id,
  String title = 'サピエンス全史',
  String? isbn,
  List<Note> notes = const [],
  List<String> tags = const [],
  List<LocalDate> readDates = const [],
  Uint8List? cover,
}) =>
    Book(
      id: id,
      uuid: uuid,
      title: title,
      author: 'ユヴァル・ノア・ハラリ',
      isbn: isbn,
      status: ReadingStatus.reading,
      progress: 40,
      cover: cover,
      coverType: cover == null ? null : 'image/png',
      thumbnail: cover == null ? null : Uint8List.fromList([9]),
      notes: notes,
      tags: tags,
      readDates: readDates,
      createdAt: t(0),
      updatedAt: t(updated),
    );

Note note(String uuid, String body, int updated, {bool favorite = false}) =>
    Note(uuid: uuid, body: body, favorite: favorite, createdAt: t(0), updatedAt: t(updated));

void main() {
  group('統合の規則（planSync）', () {
    test('クラウドにまだ何もなければ、この端末の内容をそのまま送る', () {
      final p = plan([sb('a', 1)], [sn('n', 'a', 1)], null);
      expect(p.uploadNeeded, isTrue);
      expect(p.localChanged, isFalse);
      expect(p.merged.books.single.uuid, 'a');
    });

    test('同じ内容なら、書き込みも送信もしない', () {
      final p = plan([sb('a', 1)], [sn('n', 'a', 1)], [sb('a', 1)], [sn('n', 'a', 1)]);
      expect(p.uploadNeeded, isFalse);
      expect(p.localChanged, isFalse);
    });

    test('この端末の方が新しければ送り、クラウドの方が新しければこの端末へ書き込む', () {
      final newerHere = plan([sb('a', 5, title: '新')], [], [sb('a', 1, title: '旧')]);
      expect(bookIn(newerHere, 'a').title, '新');
      expect(newerHere.uploadNeeded, isTrue);
      expect(newerHere.booksToApply, isEmpty);

      final newerThere = plan([sb('a', 1, title: '旧')], [], [sb('a', 5, title: '新')]);
      expect(bookIn(newerThere, 'a').title, '新');
      expect(newerThere.uploadNeeded, isFalse);
      expect(newerThere.booksToApply.single.title, '新');
    });

    test('片方にしかない書籍・ノートは、もう片方へ伝わる', () {
      final p = plan([sb('a', 1)], [sn('na', 'a', 1)], [sb('b', 1)], [sn('nb', 'b', 1)]);
      expect(p.merged.books.map((b) => b.uuid), unorderedEquals(['a', 'b']));
      expect(p.booksToApply.single.uuid, 'b');
      expect(p.notesToApply.single.uuid, 'nb');
      expect(p.uploadNeeded, isTrue);
    });

    test('編集より後の削除は削除が勝ち、その書籍のノートもすべて削除済みになる', () {
      final p = plan([sb('a', 9, deletedAt: t(9))], [sn('n1', 'a', 9, deletedAt: t(9))],
          [sb('a', 5, title: '編集')], [sn('n1', 'a', 2), sn('n2', 'a', 5)]);
      expect(bookIn(p, 'a').isDeleted, isTrue);
      expect(noteIn(p, 'n1').isDeleted, isTrue);
      expect(noteIn(p, 'n2').isDeleted, isTrue, reason: '削除前に別の端末で足されたノートも消える');
      expect(noteIn(p, 'n2').body, '');
      expect(p.uploadNeeded, isTrue);
    });

    test('削除より後の編集は編集が勝ち、書籍が復活する', () {
      final p = plan([sb('a', 3, deletedAt: t(3))], [], [sb('a', 7, title: '編集')]);
      expect(bookIn(p, 'a').isDeleted, isFalse);
      expect(p.booksToApply.single.title, '編集');
    });

    test('同時刻なら削除を優先し、どちらも残っているならクラウド側を採る', () {
      final del = plan([sb('a', 4, deletedAt: t(4))], [], [sb('a', 4, title: 'クラウド')]);
      expect(bookIn(del, 'a').isDeleted, isTrue);

      final tie = plan([sb('a', 4, title: 'この端末')], [], [sb('a', 4, title: 'クラウド')]);
      expect(bookIn(tie, 'a').title, 'クラウド');
      expect(tie.booksToApply.single.title, 'クラウド');
      expect(tie.uploadNeeded, isFalse);
    });

    test('ノートは書籍とは別に、1件ずつ新しい方を採る', () {
      final p = plan(
        [sb('a', 5)],
        [sn('n1', 'a', 5, body: 'この端末で直した'), sn('n2', 'a', 1, body: '古い')],
        [sb('a', 3)],
        [sn('n1', 'a', 1, body: '古い'), sn('n2', 'a', 3, body: 'クラウドで直した')],
      );
      expect(noteIn(p, 'n1').body, 'この端末で直した');
      expect(noteIn(p, 'n2').body, 'クラウドで直した');
      expect(p.notesToApply.single.uuid, 'n2');
      expect(p.uploadNeeded, isTrue);
    });

    test('削除された書籍が別の端末の編集で復活したら、書籍と一緒に消えたノートも戻る', () {
      final p = plan(
        [sb('x', 5, deletedAt: t(5))],
        [sn('n1', 'x', 5, deletedAt: t(5))],
        [sb('x', 6, title: '編集', noteOrder: ['n1'])],
        [sn('n1', 'x', 0, body: '残っていたメモ')],
      );
      expect(bookIn(p, 'x').isDeleted, isFalse);
      expect(noteIn(p, 'n1').isDeleted, isFalse);
      expect(noteIn(p, 'n1').body, '残っていたメモ');
      expect(noteIn(p, 'n1').updatedAt, t(6), reason: '書籍の更新日時にそろえて、次回から落ち着かせる');
    });

    test('個別に消したノートは、書籍が編集されても戻らない', () {
      final p = plan(
        [sb('x', 5)],
        [sn('n1', 'x', 4, deletedAt: t(4))],
        [sb('x', 6, noteOrder: ['n1'])],
        [sn('n1', 'x', 0)],
      );
      expect(noteIn(p, 'n1').isDeleted, isTrue);
    });

    test('タグは大文字小文字・全角半角の違いだけなら同じとみなす', () {
      final p = plan([sb('a', 1, tags: ['ＳＦ', '歴史'])], [], [sb('a', 1, tags: ['歴史', 'sf'])]);
      expect(p.localChanged, isFalse);
      expect(p.uploadNeeded, isFalse);
    });

    test('統合後に必要な書影は、削除されていない書籍のものだけ', () {
      final p = plan([sb('a', 1, coverHash: 'h1'), sb('b', 2, deletedAt: t(2))], [], [sb('c', 1, coverHash: 'h2')]);
      expect(p.coverHashes, {'h1', 'h2'});
    });
  });

  group('初めての同期', () {
    test('「統合」では、ISBN が同じ書籍をクラウド側の uuid で1冊にまとめる', () {
      final p = plan(
        [sb('L', 8, title: 'この端末', isbn: '978-4-309-22671-2', tags: ['歴史'], readDates: ['2026-01-01'])],
        [sn('nl', 'L', 2)],
        [sb('R', 3, title: 'クラウド', isbn: '9784309226712', tags: ['人類'], readDates: ['2025-05-05'], noteOrder: ['nr'])],
        [sn('nr', 'R', 3)],
        FirstSyncMode.merge,
      );
      final merged = bookIn(p, 'R');
      expect(merged.title, 'この端末', reason: '内容は更新日時が新しい方');
      expect(merged.tags, ['人類', '歴史']);
      expect(merged.readDates, ['2025-05-05', '2026-01-01']);
      expect(merged.noteOrder, ['nr', 'nl']);
      expect(merged.updatedAt, t(59));
      expect(bookIn(p, 'L').isDeleted, isTrue);
      expect(noteIn(p, 'nl').bookUuid, 'R');
      expect(p.booksToApply.map((b) => b.uuid), unorderedEquals(['R', 'L']));
      expect(p.uploadNeeded, isTrue);
    });

    test('「統合」でも、ISBN がない・不正な書籍はまとめない', () {
      final p = plan(
        [sb('L1', 1), sb('L2', 1, isbn: '123')],
        [],
        [sb('R1', 1), sb('R2', 1, isbn: '123')],
        [],
        FirstSyncMode.merge,
      );
      expect(p.merged.books.where((b) => !b.isDeleted).map((b) => b.uuid),
          unorderedEquals(['L1', 'L2', 'R1', 'R2']));
    });

    test('「クラウドで置き換え」では、この端末だけにあるものを削除し、クラウドへは送らない', () {
      final p = plan([sb('L', 1), sb('S', 1, title: '旧')], [sn('nl', 'L', 1)], [sb('S', 1, title: 'クラウド'), sb('R', 1)],
          [], FirstSyncMode.useRemote);
      expect(p.uploadNeeded, isFalse);
      expect(p.booksToApply.singleWhere((b) => b.uuid == 'L').isDeleted, isTrue);
      expect(p.booksToApply.singleWhere((b) => b.uuid == 'S').title, 'クラウド');
      expect(p.booksToApply.singleWhere((b) => b.uuid == 'R').isDeleted, isFalse);
      expect(p.notesToApply.single.isDeleted, isTrue);
    });

    test('「この端末で置き換え」では、両方にあって内容が違うものも、日時を今にして確実に勝たせる', () {
      final p = plan([sb('x', 1, title: 'この端末')], [sn('n', 'x', 1, body: 'この端末')], [sb('x', 9, title: 'クラウド')],
          [sn('n', 'x', 9, body: 'クラウド')], FirstSyncMode.useLocal);
      expect(bookIn(p, 'x').title, 'この端末');
      expect(bookIn(p, 'x').updatedAt, t(59));
      expect(noteIn(p, 'n').body, 'この端末');
      expect(noteIn(p, 'n').updatedAt, t(59));
      expect(p.booksToApply.single.updatedAt, t(59), reason: 'この端末にも同じ日時を書き込む');
      expect(p.notesToApply.single.updatedAt, t(59));

      // ほかの端末に残っている t9 の版より新しいので、次の同期でも負けない
      final other = planSync(
        local: SyncSnapshot(books: [sb('x', 9, title: 'クラウド', noteOrder: ['n'])], notes: [sn('n', 'x', 9, body: 'クラウド')]),
        remote: p.merged,
        now: t(59),
      );
      expect(bookIn(other, 'x').title, 'この端末');
      expect(noteIn(other, 'n').body, 'この端末');
    });

    test('「この端末で置き換え」では、クラウドだけにあるものを削除済みにして送る', () {
      final p = plan([sb('L', 1)], [], [sb('R', 1)], [sn('nr', 'R', 1)], FirstSyncMode.useLocal);
      expect(p.uploadNeeded, isTrue);
      expect(p.localChanged, isFalse);
      expect(bookIn(p, 'R').isDeleted, isTrue);
      expect(noteIn(p, 'nr').isDeleted, isTrue);
      expect(bookIn(p, 'L').isDeleted, isFalse);
    });
  });

  group('同期データの形式', () {
    test('JSON を往復しても内容が変わらず、削除済みの書籍は書名などを持たない', () {
      final snapshot = SyncSnapshot(
        books: [sb('a', 1, tags: ['t'], readDates: ['2026-01-01'], noteOrder: ['n'], coverHash: 'h'), sb('d', 2, deletedAt: t(2))],
        notes: [sn('n', 'a', 1), sn('x', 'd', 2, deletedAt: t(2))],
      );
      final back = SyncSnapshot.decode(snapshot.encode());
      expect(back.toJson(), snapshot.toJson());
      final deleted = snapshot.toJson()['books'][1] as Map<String, dynamic>;
      expect(deleted.keys, unorderedEquals(['uuid', 'createdAt', 'updatedAt', 'deletedAt']));
    });

    test('範囲外・未知の値は直して読み、読めない記録は飛ばす', () {
      final snapshot = SyncSnapshot.fromJson({
        'version': 1,
        'books': [
          {'uuid': 'a', 'title': 'T', 'status': 'weird', 'progress': 150, 'readDates': ['bad', '2026-01-01'],
           'updatedAt': '2026-10-15T09:00:00.000Z'},
          {'title': 'uuid なし'},
        ],
        'notes': [
          {'uuid': 'n', 'bookUuid': 'a', 'category': 'unknown', 'page': 0, 'body': 'x', 'updatedAt': '2026-10-15T09:00:00.000Z'},
          {'uuid': 'm'},
        ],
      });
      final b = snapshot.books.single;
      expect(b.status, 'unset');
      expect(b.progress, isNull);
      expect(b.readDates, ['2026-01-01']);
      expect(b.createdAt, b.updatedAt, reason: '作成日時がなければ更新日時で補う');
      final n = snapshot.notes.single;
      expect(n.category, isNull);
      expect(n.page, isNull);
      expect(snapshot.unreadableRecords, 2);
    });

    test('読了日は並べて重複を除き、空のタグは除いて読む', () {
      final b = SyncSnapshot.fromJson({
        'version': 1,
        'books': [
          {'uuid': 'a', 'readDates': ['2026-02-01', '2026-01-01', '2026-02-01'], 'tags': [' 歴史 ', '', '  '],
           'updatedAt': '2026-10-15T09:00:00.000Z'},
        ],
      }).books.single;
      expect(b.readDates, ['2026-01-01', '2026-02-01']);
      expect(b.tags, ['歴史']);
    });

    test('クラウドに読めない記録があれば、上書きで消さないよう送らずに知らせる', () {
      final remote = SyncSnapshot.fromJson({
        'version': 1,
        'books': [
          {'uuid': 'r', 'title': 'クラウド', 'updatedAt': '2026-10-15T09:01:00.000Z', 'createdAt': '2026-10-15T09:00:00.000Z'},
          {'title': '読めない記録'},
        ],
      });
      final p = planSync(local: SyncSnapshot(books: [sb('a', 5)]), remote: remote, now: t(59));
      expect(p.uploadNeeded, isFalse);
      expect(p.remoteUnreadable, isTrue);
      expect(p.booksToApply.single.uuid, 'r', reason: '読めた記録はこの端末へ取り込む');
    });

    test('版番号のない同期データは、壊れたものとして扱う', () {
      expect(() => SyncSnapshot.fromJson({'books': []}), throwsFormatException);
    });

    test('新しい版の形式は読まない', () {
      expect(() => SyncSnapshot.fromJson({'version': syncFormatVersion + 1}),
          throwsA(isA<UnsupportedSyncFormatException>()));
    });

    test('削除済みしかなければ空とみなす', () {
      expect(SyncSnapshot(books: [sb('d', 1, deletedAt: t(1))]).isEmpty, isTrue);
      expect(SyncSnapshot(books: [sb('a', 1)]).isEmpty, isFalse);
    });
  });

  group('2台の端末での同期', () {
    late BookRepository a;
    late BookRepository b;
    late FakeCloud cloud;

    setUp(() {
      a = BookRepository(openInMemoryDatabase());
      b = BookRepository(openInMemoryDatabase());
      cloud = FakeCloud();
    });
    tearDown(() {
      a.db.close();
      b.db.close();
    });

    Book only(BookRepository repo) => repo.getAllBooks().single;

    /// 変更がなければ、何度同期しても書き込みも送信も起きない（落ち着いた状態）
    void expectSettled(BookRepository x, BookRepository y) {
      for (final repo in [x, y, x]) {
        final p = cloud.sync(repo);
        expect(p.uploadNeeded, isFalse);
        expect(p.booksToApply, isEmpty);
        expect(p.notesToApply, isEmpty);
      }
    }

    test('片方で登録した書籍が、書影・ノートの順番・タグ・読了日ごと、もう片方に届く', () {
      final cover = Uint8List.fromList(List.generate(64, (i) => i));
      a.saveBook(book('u1', 1,
          cover: cover,
          notes: [note('n2', '二つ目', 1, favorite: true), note('n1', '一つ目', 1)],
          tags: ['歴史', '人類'],
          readDates: [LocalDate(2026, 3, 1)]));
      cloud.sync(a);
      cloud.sync(b);

      final got = only(b);
      expect(got.title, 'サピエンス全史');
      expect(got.status, ReadingStatus.reading);
      expect(got.progress, 40);
      expect(got.cover, cover);
      expect(got.thumbnail, isNotNull);
      expect(got.notes.map((n) => n.uuid), ['n2', 'n1']);
      expect(got.notes.first.favorite, isTrue);
      expect(got.tags, unorderedEquals(['歴史', '人類']));
      expect(got.readDates, [LocalDate(2026, 3, 1)]);
      expect(got.updatedAt, t(1));

      // 2回目以降は、変わっていなければ何もしない
      final again = cloud.sync(b);
      expect(again.uploadNeeded, isFalse);
      expect(again.localChanged, isFalse);
    });

    test('別々の端末で別々のノートを足すと、両方残る', () {
      a.saveBook(book('u1', 1, notes: [note('n1', '最初', 1)]));
      cloud.sync(a);
      cloud.sync(b);

      a.saveBook(book('u1', 5, id: only(a).id, notes: [note('n1', '最初', 1), note('na', 'Aで追加', 5)]));
      b.saveBook(book('u1', 6, id: only(b).id, notes: [note('n1', '最初', 1), note('nb', 'Bで追加', 6)]));
      cloud.sync(a);
      cloud.sync(b);
      cloud.sync(a);

      for (final repo in [a, b]) {
        expect(only(repo).notes.map((n) => n.body), ['最初', 'Bで追加', 'Aで追加'],
            reason: '並び順は新しい方（B）の書籍に従い、知らないノートは後ろに付く');
      }
      expectSettled(a, b);
    });

    test('片方で削除した書籍は、もう片方からも消える', () {
      a.saveBook(book('u1', 1, notes: [note('n1', 'メモ', 1)]));
      cloud.sync(a);
      cloud.sync(b);

      a.deleteBook(only(a).id!, at: t(10));
      cloud.sync(a);
      cloud.sync(b);

      expect(b.getAllBooks(), isEmpty);
      final deleted = b.exportSyncSnapshot();
      expect(deleted.books.single.isDeleted, isTrue);
      expect(deleted.notes.single.isDeleted, isTrue);
      expectSettled(a, b);
    });

    test('書影を差し替えると新しい書影が届き、外すと消える', () {
      a.saveBook(book('u1', 1, cover: Uint8List.fromList([1, 1, 1])));
      cloud.sync(a);
      cloud.sync(b);

      a.saveBook(book('u1', 2, id: only(a).id, cover: Uint8List.fromList([2, 2, 2])));
      cloud.sync(a);
      cloud.sync(b);
      expect(only(b).cover, [2, 2, 2]);

      a.saveBook(book('u1', 3, id: only(a).id));
      cloud.sync(a);
      cloud.sync(b);
      expect(only(b).cover, isNull);
      expect(b.coverByHash(coverHashOf([2, 2, 2])), isNull);
      expectSettled(a, b);
    });

    test('初めての同期の「統合」で、同じ ISBN の本が1冊になり、ノートも両方残る', () {
      a.saveBook(book('ua', 1, isbn: '9784309226712', notes: [note('na', 'Aのメモ', 1)], tags: ['A']));
      b.saveBook(book('ub', 2, isbn: '978-4-309-22671-2', notes: [note('nb', 'Bのメモ', 2)], tags: ['B']));
      cloud.sync(a);
      cloud.sync(b, mode: FirstSyncMode.merge);
      cloud.sync(a);

      for (final repo in [a, b]) {
        final got = only(repo);
        expect(got.uuid, 'ua');
        expect(got.notes.map((n) => n.body), unorderedEquals(['Aのメモ', 'Bのメモ']));
        expect(got.tags, unorderedEquals(['A', 'B']));
      }
      expectSettled(a, b);
    });

    test('端末ごとにタグの大文字小文字が違っても、同期は落ち着く', () {
      a.saveBook(book('u1', 1, tags: ['SF']));
      b.saveBook(book('u2', 2, title: '別の本', tags: ['sf']));
      cloud.sync(a);
      cloud.sync(b);
      cloud.sync(a);
      expect(a.getAllBooks(), hasLength(2));
      expectSettled(a, b);
    });

    test('ISBN でまとめた書籍の書影が、この端末にしかなくても書き込める', () {
      a.saveBook(book('ua', 1, isbn: '9784309226712'));
      cloud.sync(a);
      b.saveBook(book('ub', 5, isbn: '9784309226712', cover: Uint8List.fromList([7, 7])));
      final p = planSync(local: b.exportSyncSnapshot(), remote: cloud.snapshot, firstSync: FirstSyncMode.merge, now: t(59));
      b.applySync(books: p.booksToApply, notes: p.notesToApply);
      expect(only(b).uuid, 'ua');
      expect(only(b).cover, [7, 7]);
      expect(only(b).coverType, 'image/png');
    });

    test('1回の書き込みで書影を入れ替えても、この端末にしかない書影を失わない', () {
      final h1 = Uint8List.fromList([1]);
      final h2 = Uint8List.fromList([2]);
      b.saveBook(book('b1', 1, title: '一冊目', cover: h1));
      b.saveBook(book('b3', 1, title: '三冊目'));
      // 一冊目は h2 に差し替え、三冊目は一冊目の元の書影 h1 を使う（h1 の中身は渡さない）
      final b1 = b.exportSyncSnapshot().books.singleWhere((x) => x.uuid == 'b1');
      final b3 = b.exportSyncSnapshot().books.singleWhere((x) => x.uuid == 'b3');
      SyncBook withCover(SyncBook x, String hash, int minute) => SyncBook(
            uuid: x.uuid, title: x.title, coverHash: hash, coverType: 'image/png', createdAt: x.createdAt, updatedAt: t(minute));
      b.applySync(
        books: [withCover(b1, coverHashOf(h2), 5), withCover(b3, coverHashOf(h1), 5)],
        notes: const [],
        covers: {coverHashOf(h2): SyncCover(bytes: h2, type: 'image/png', thumbnail: h2)},
      );
      final books = {for (final x in b.getAllBooks()) x.uuid: x};
      expect(books['b1']!.cover, h2);
      expect(books['b3']!.cover, h1);
    });

    test('編集画面を開いている間に同期で届いたノートは、保存しても消えない', () {
      a.saveBook(book('u1', 1, notes: [note('n1', '最初', 1)]));
      cloud.sync(a);
      cloud.sync(b);
      final opened = only(a); // 編集画面を開いた時点の内容

      b.saveBook(book('u1', 2, id: only(b).id, notes: [note('n1', '最初', 1), note('n2', 'Bで追加', 2)]));
      cloud.sync(b);
      cloud.sync(a); // 編集画面を開いている間に届く

      a.saveBook(
        book('u1', 3, id: opened.id, notes: [note('n1', '直した', 3)]),
        removedNotes: {for (final n in opened.notes) n.uuid},
      );
      expect(only(a).notes.map((n) => n.body), ['直した', 'Bで追加']);

      a.saveBook(book('u1', 4, id: opened.id, notes: [note('n2', 'Bで追加', 2)]), removedNotes: {'n1', 'n2'});
      expect(only(a).notes.map((n) => n.body), ['Bで追加'], reason: '画面で消したノートは削除する');
    });

    test('書影の中身が届いていなければ、何も書き込まずに失敗する', () {
      a.saveBook(book('u1', 1, cover: Uint8List.fromList([5])));
      final p = planSync(local: SyncSnapshot(), remote: a.exportSyncSnapshot(), now: t(59));
      expect(() => b.applySync(books: p.booksToApply, notes: p.notesToApply), throwsStateError);
      expect(b.getAllBooks(), isEmpty);
    });

    test('この端末にない書籍の削除済みの印や、書籍のないノートは無視する', () {
      b.applySync(books: [sb('ghost', 1, deletedAt: t(1))], notes: [sn('orphan', 'ghost', 1)]);
      expect(b.exportSyncSnapshot().books, isEmpty);
      expect(b.exportSyncSnapshot().notes, isEmpty);
    });
  });
}
