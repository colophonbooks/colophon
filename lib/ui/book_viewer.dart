import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/book.dart';
import 'common.dart';

/// 書籍のビューアモード（見る専用）。未入力の項目は見出しごと出さない。
/// 文字は選択してコピーできる（ノートの抜粋を引用したいときのため）。
class BookViewer extends StatelessWidget {
  const BookViewer({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fields = [
      (l.fieldAuthor, book.author),
      (l.fieldTranslator, book.translator),
      (l.fieldSupervisor, book.supervisor),
      (l.fieldPublisher, book.publisher),
      (l.fieldIsbn, book.isbn),
      (l.fieldEdition, book.edition),
    ].where((f) => f.$2 != null && f.$2!.trim().isNotEmpty).toList();

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(book.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final (label, value) in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$label  ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              TextSpan(text: value, style: theme.textTheme.bodyMedium),
            ])),
          ),
        const SizedBox(height: 8),
        StatusBadge(status: book.status, progress: book.progress),
      ],
    );

    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (book.cover != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoverThumbnail(bytes: book.thumbnail ?? book.cover, title: book.title, width: 120, height: 176),
                        const SizedBox(width: 20),
                        Expanded(child: info),
                      ],
                    )
                  else
                    info,
                  if (book.readDates.isNotEmpty) ...[
                    _Heading(l.readDatesSection),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in book.readDates)
                          Chip(
                            avatar: const Icon(Icons.event_available, size: 18),
                            label: Text(formatDate(context, d.toDateTime())),
                          ),
                      ],
                    ),
                  ],
                  if (book.tags.isNotEmpty) ...[
                    _Heading(l.tagsSection),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final t in book.tags) Chip(label: Text(t))],
                    ),
                  ],
                  if (book.notes.isNotEmpty) ...[
                    _Heading(l.notesSection),
                    for (final (i, n) in book.notes.indexed) ...[
                      if (i > 0) const Divider(height: 32),
                      _NoteView(note: n),
                    ],
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      '${l.fieldCreatedAt}: ${formatDate(context, book.createdAt)}   '
                      '${l.fieldUpdatedAt}: ${formatDate(context, book.updatedAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// ノート1件。分類とページ（入力されていれば）を小さな見出しにし、その下に本文を出す。
/// お気に入りには★を出すが、ビューアでは切り替えない。
class _NoteView extends StatelessWidget {
  const _NoteView({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final caption = [
      if (note.category != null) l.category(note.category),
      if (note.page != null) 'p.${note.page}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption.isNotEmpty || note.favorite)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    caption,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                if (note.favorite)
                  Tooltip(
                    message: l.filterFavorite,
                    child: Icon(Icons.star, size: 20, color: theme.colorScheme.primary,
                        semanticLabel: l.filterFavorite),
                  ),
              ],
            ),
          ),
        Text(note.body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
      ],
    );
  }
}
