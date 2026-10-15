import 'package:colophon/data/app_database.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:uuid/uuid.dart';

BookRepository newRepository() => BookRepository(openInMemoryDatabase());

Book sampleBook({
  int? id,
  String? uuid,
  String title = 'サピエンス全史',
  String? author = 'ユヴァル・ノア・ハラリ',
  String? translator = '柴田裕之',
  String? isbn,
  ReadingStatus status = ReadingStatus.unset,
  int? progress,
  List<Note> notes = const [],
  List<LocalDate> readDates = const [],
  List<String> tags = const [],
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.utc(2026, 1, 2, 3, 4, 5);
  return Book(
    id: id,
    uuid: uuid ?? const Uuid().v4(),
    title: title,
    author: author,
    translator: translator,
    isbn: isbn,
    status: status,
    progress: progress,
    notes: notes,
    readDates: readDates,
    tags: tags,
    createdAt: at,
    updatedAt: at,
  );
}
