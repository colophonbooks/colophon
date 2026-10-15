import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../models/book.dart';
import 'isbn.dart';

enum SearchField { title, author, translator, supervisor, publisher, isbn, notes }

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.fields = const {...SearchField.values},
    this.statuses = const {},
    this.categories = const {},
    this.favoritesOnly = false,
    this.tags = const {},
    this.readFrom,
    this.readTo,
  });

  final String text;
  final Set<SearchField> fields;
  final Set<ReadingStatus> statuses;

  /// ノート分類での絞り込み。null は「分類なし」を表す。
  final Set<NoteCategory?> categories;

  /// お気に入りのノートだけに絞り込む。
  final bool favoritesOnly;

  /// すべてを持つ書籍に絞り込むタグ。
  final Set<String> tags;
  final LocalDate? readFrom;
  final LocalDate? readTo;
}

class SearchResult {
  const SearchResult({required this.book, required this.matchedNotes});

  final Book book;

  /// 条件に合ったノート。書籍情報だけが一致した場合は空。
  final List<Note> matchedNotes;
}

/// 大文字小文字・全角半角の違いを吸収した比較用文字列。
String normalizeForSearch(String s) => unorm.nfkc(s).toLowerCase();

/// タグの同一判定キー（「SF」「ｓｆ」「sf」を同じタグとみなす）。
String tagKey(String name) => normalizeForSearch(name.trim());

/// 書籍とノートを検索する。
///
/// - 書籍の絞り込み（ステータス・タグ・読了日）を満たす書籍だけが対象。
/// - キーワードは空白区切りで AND。各語が、選んだ書籍情報の項目かノート本文の
///   どこかに含まれれば一致（「書名に一方・ノートに他方」でもよい）。
/// - ノート分類やお気に入りで絞り込む場合は、条件に合うノート1件にすべての語が含まれる書籍だけを返す。
List<SearchResult> searchBooks(List<Book> books, SearchQuery query) {
  final terms = normalizeForSearch(query.text)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  final wantedTags = {for (final t in query.tags) tagKey(t)};
  final byNote = query.categories.isNotEmpty || query.favoritesOnly;
  final searchNotes = query.fields.contains(SearchField.notes);

  final results = <SearchResult>[];
  for (final book in books) {
    if (query.statuses.isNotEmpty && !query.statuses.contains(book.status)) continue;
    if (wantedTags.isNotEmpty) {
      final bookTags = {for (final t in book.tags) tagKey(t)};
      if (!bookTags.containsAll(wantedTags)) continue;
    }
    if ((query.readFrom != null || query.readTo != null) &&
        !book.readDates.any((d) => _inRange(d, query.readFrom, query.readTo))) {
      continue;
    }

    if (byNote) {
      final notes = book.notes
          .where((n) => query.categories.isEmpty || query.categories.contains(n.category))
          .where((n) => !query.favoritesOnly || n.favorite)
          .where((n) => terms.isEmpty || (searchNotes && _containsAll(n.body, terms)))
          .toList();
      if (notes.isNotEmpty) results.add(SearchResult(book: book, matchedNotes: notes));
      continue;
    }

    if (terms.isEmpty) {
      results.add(SearchResult(book: book, matchedNotes: const []));
      continue;
    }

    final fields = _BookFields(book, query.fields);
    final notes = searchNotes
        ? [for (final n in book.notes) (note: n, text: normalizeForSearch(n.body))]
        : const <({Note note, String text})>[];
    final allFound = terms.every(
      (t) => fields.contains(t) || notes.any((n) => n.text.contains(t)),
    );
    if (!allFound) continue;
    results.add(SearchResult(
      book: book,
      matchedNotes: [
        for (final n in notes)
          if (terms.any(n.text.contains)) n.note,
      ],
    ));
  }
  return results;
}

bool _containsAll(String text, List<String> terms) {
  final normalized = normalizeForSearch(text);
  return terms.every(normalized.contains);
}

/// 検索対象に選ばれた書籍情報の項目。
class _BookFields {
  _BookFields(Book book, Set<SearchField> fields)
      : _text = normalizeForSearch([
          for (final f in fields)
            ...switch (f) {
              SearchField.title => [book.title],
              SearchField.author => [?book.author],
              SearchField.translator => [?book.translator],
              SearchField.supervisor => [?book.supervisor],
              SearchField.publisher => [?book.publisher],
              SearchField.isbn => [?book.isbn],
              SearchField.notes => const <String>[],
            },
        ].join('\n')),
        _isbn = fields.contains(SearchField.isbn) && book.isbn != null
            ? normalizeIsbn(book.isbn!).toLowerCase()
            : null;

  final String _text;
  final String? _isbn;

  bool contains(String term) {
    if (_text.contains(term)) return true;
    // ISBN は登録側・検索語側どちらのハイフンの有無にもかかわらず一致させる
    final isbnTerm = normalizeIsbn(term).toLowerCase();
    return _isbn != null && isbnTerm.isNotEmpty && _isbn.contains(isbnTerm);
  }
}
bool _inRange(LocalDate d, LocalDate? from, LocalDate? to) =>
    (from == null || d.compareTo(from) >= 0) && (to == null || d.compareTo(to) <= 0);
