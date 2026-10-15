import '../models/book.dart';
import '../services/isbn_lookup.dart';
import '../services/search.dart';
import 'app_localizations.dart';

/// 内部コード（enum）を表示言語の文言に変換する。
extension AppLabels on AppLocalizations {
  String status(ReadingStatus s) => switch (s) {
        ReadingStatus.unset => statusUnset,
        ReadingStatus.unread => statusUnread,
        ReadingStatus.reading => statusReading,
        ReadingStatus.finished => statusFinished,
      };

  String category(NoteCategory? c) => switch (c) {
        null => categoryUnselected,
        NoteCategory.impression => categoryImpression,
        NoteCategory.learning => categoryLearning,
        NoteCategory.memo => categoryMemo,
        NoteCategory.excerpt => categoryExcerpt,
        NoteCategory.other => categoryOther,
      };

  String searchField(SearchField f) => switch (f) {
        SearchField.title => fieldTitle,
        SearchField.author => fieldAuthor,
        SearchField.translator => fieldTranslator,
        SearchField.supervisor => fieldSupervisor,
        SearchField.publisher => fieldPublisher,
        SearchField.isbn => fieldIsbn,
        SearchField.notes => targetNotes,
      };

  String sourceName(LookupSource s) => switch (s) {
        LookupSource.ndl => sourceNdl,
        LookupSource.openLibrary => sourceOpenLibrary,
        LookupSource.loc => sourceLoc,
        LookupSource.bnf => sourceBnf,
        LookupSource.dnb => sourceDnb,
      };
}
