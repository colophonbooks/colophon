import 'package:colophon/models/book.dart';
import 'package:colophon/services/search.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final sapiens = sampleBook(
    title: 'サピエンス全史',
    author: 'ユヴァル・ノア・ハラリ',
    isbn: '978-4-309-22671-2',
    status: ReadingStatus.finished,
    tags: ['歴史', '名著'],
    readDates: [const LocalDate(2025, 6, 1)],
    notes: [
      Note(category: NoteCategory.learning, page: 30, body: '認知革命が転換点だった'),
      Note(category: NoteCategory.excerpt, body: '虚構を信じる力', favorite: true),
      Note(body: '分類なしの Memo'),
    ],
  );
  final dune = sampleBook(
    title: 'DUNE 砂の惑星',
    author: 'Frank Herbert',
    translator: '酒井昭伸',
    status: ReadingStatus.reading,
    tags: ['SF'],
    readDates: [const LocalDate(2026, 2, 1)],
    notes: [Note(category: NoteCategory.impression, body: '砂漠の描写が圧巻')],
  );
  final books = [sapiens, dune];

  List<String> titles(SearchQuery q) => searchBooks(books, q).map((r) => r.book.title).toList();

  test('条件なしなら全書籍を返す', () {
    expect(titles(const SearchQuery()), hasLength(2));
  });

  test('大文字小文字・全角半角の違いを無視して一致する', () {
    expect(titles(const SearchQuery(text: 'ｄｕｎｅ')), ['DUNE 砂の惑星']);
    expect(titles(const SearchQuery(text: 'frank')), ['DUNE 砂の惑星']);
  });

  test('空白区切りの語はすべて含む書籍だけに一致する（項目をまたいでよい）', () {
    expect(titles(const SearchQuery(text: 'dune herbert')), ['DUNE 砂の惑星']);
    expect(titles(const SearchQuery(text: 'dune ハラリ')), isEmpty);
  });

  test('検索対象から外した項目では一致しない', () {
    expect(titles(const SearchQuery(text: '酒井', fields: {SearchField.title})), isEmpty);
    expect(titles(const SearchQuery(text: '酒井', fields: {SearchField.translator})), ['DUNE 砂の惑星']);
  });

  test('ISBNはハイフンの有無にかかわらず一致する', () {
    expect(titles(const SearchQuery(text: '9784309226712')), ['サピエンス全史']);
    expect(titles(const SearchQuery(text: '978-4-309')), ['サピエンス全史']);
  });

  test('語が書籍情報とノート本文に分かれていても一致し、語を含むノートを結果に含める', () {
    final results = searchBooks(books, const SearchQuery(text: 'サピエンス 認知革命'));
    expect(results.single.book.title, 'サピエンス全史');
    expect(results.single.matchedNotes.single.body, '認知革命が転換点だった');
  });

  test('ノート本文に一致したノートを結果に含める', () {
    final results = searchBooks(books, const SearchQuery(text: '認知革命'));
    expect(results.single.book.title, 'サピエンス全史');
    expect(results.single.matchedNotes.single.page, 30);
  });

  test('ノートを検索対象から外すとノート本文には一致しない', () {
    expect(
      titles(const SearchQuery(text: '認知革命', fields: {SearchField.title, SearchField.author})),
      isEmpty,
    );
  });

  test('ノート分類で絞り込むと、その分類のノートだけを返す', () {
    final results = searchBooks(books, const SearchQuery(categories: {NoteCategory.excerpt}));
    expect(results.single.book.title, 'サピエンス全史');
    expect(results.single.matchedNotes.single.body, '虚構を信じる力');
  });

  test('分類なしのノートで絞り込める', () {
    final results = searchBooks(books, const SearchQuery(text: 'memo', categories: {null}));
    expect(results.single.matchedNotes.single.body, '分類なしの Memo');
  });

  test('ノート分類を選ぶと書籍情報だけの一致は結果に含めない', () {
    expect(titles(const SearchQuery(text: 'サピエンス', categories: {NoteCategory.learning})), isEmpty);
  });

  test('お気に入りで絞り込むと、お気に入りのノートだけを返す（語があれば語も含むもの）', () {
    final all = searchBooks(books, const SearchQuery(favoritesOnly: true));
    expect(all.single.book.title, 'サピエンス全史');
    expect(all.single.matchedNotes.single.body, '虚構を信じる力');

    expect(searchBooks(books, const SearchQuery(text: '虚構', favoritesOnly: true)), hasLength(1));
    expect(searchBooks(books, const SearchQuery(text: '認知革命', favoritesOnly: true)), isEmpty,
        reason: '語を含むノートがお気に入りでなければ一致しない');
  });

  test('お気に入りと分類の両方を選ぶと、両方を満たすノートだけ', () {
    expect(searchBooks(books, const SearchQuery(favoritesOnly: true, categories: {NoteCategory.excerpt})), hasLength(1));
    expect(searchBooks(books, const SearchQuery(favoritesOnly: true, categories: {NoteCategory.learning})), isEmpty);
  });

  test('ステータスで絞り込める', () {
    expect(titles(const SearchQuery(statuses: {ReadingStatus.reading})), ['DUNE 砂の惑星']);
  });

  test('タグは選んだものをすべて持つ書籍に絞り込む（大文字小文字は区別しない）', () {
    expect(titles(const SearchQuery(tags: {'歴史', '名著'})), ['サピエンス全史']);
    expect(titles(const SearchQuery(tags: {'歴史', 'sf'})), isEmpty);
    expect(titles(const SearchQuery(tags: {'sf'})), ['DUNE 砂の惑星']);
    expect(titles(const SearchQuery(tags: {'ＳＦ'})), ['DUNE 砂の惑星']);
  });

  test('読了日の期間で絞り込める（両端を含む）', () {
    expect(titles(const SearchQuery(readFrom: LocalDate(2026, 1, 1))), ['DUNE 砂の惑星']);
    expect(titles(const SearchQuery(readTo: LocalDate(2025, 6, 1))), ['サピエンス全史']);
    expect(
      titles(const SearchQuery(readFrom: LocalDate(2025, 7, 1), readTo: LocalDate(2025, 12, 31))),
      isEmpty,
    );
  });
}
