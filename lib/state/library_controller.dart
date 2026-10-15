import 'package:flutter/foundation.dart';

import '../data/book_repository.dart';
import '../models/book.dart';

/// 書籍一覧の状態。保存・削除・インポートの後に [reload] で最新化する。
class LibraryController extends ChangeNotifier {
  LibraryController(this.repository, [this._sort = BookSort.recent]) {
    reload();
  }

  final BookRepository repository;
  BookSort _sort;
  List<BookSummary> _books = const [];

  List<BookSummary> get books => _books;

  set sort(BookSort value) {
    if (value == _sort) return;
    _sort = value;
    reload();
  }

  void reload() {
    // 変更のない書籍は前回と同じサムネイルのオブジェクトを使い回す。
    // Image.memory はバイト列の同一性で画像キャッシュを引くため、毎回新しい配列にすると
    // 全書影のデコードがやり直しになる。
    final previous = {for (final b in _books) b.id: b};
    _books = [
      for (final b in repository.listSummaries(sort: _sort))
        if (previous[b.id] case final p? when p.updatedAt == b.updatedAt && p.thumbnail != null)
          b.withThumbnail(p.thumbnail)
        else
          b,
    ];
    notifyListeners();
  }
}
