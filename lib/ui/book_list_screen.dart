import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../state/library_controller.dart';
import '../state/settings_controller.dart';
import 'book_edit_screen.dart';
import 'common.dart';
import 'data_transfer.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tag_manager_screen.dart';

enum _MenuAction { tags, export, import, settings }

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    final books = context.watch<LibraryController>().books;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.searchTooltip,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            tooltip: settings.gridView ? l.showAsListTooltip : l.showAsGridTooltip,
            icon: Icon(settings.gridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
            onPressed: () => settings.setGridView(!settings.gridView),
          ),
          PopupMenuButton<BookSort>(
            tooltip: l.sortTooltip,
            icon: const Icon(Icons.sort),
            initialValue: settings.sort,
            onSelected: (sort) {
              settings.setSort(sort);
              context.read<LibraryController>().sort = sort;
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: BookSort.recent, child: Text(l.sortRecent)),
              PopupMenuItem(value: BookSort.title, child: Text(l.sortTitle)),
              PopupMenuItem(value: BookSort.statusAscending, child: Text(l.sortStatusAscending)),
              PopupMenuItem(value: BookSort.statusDescending, child: Text(l.sortStatusDescending)),
            ],
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => switch (action) {
              _MenuAction.tags => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const TagManagerScreen()),
                ),
              _MenuAction.export => runExport(context),
              _MenuAction.import => runImport(context),
              _MenuAction.settings => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                ),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _MenuAction.tags, child: Text(l.menuTags)),
              PopupMenuItem(value: _MenuAction.export, child: Text(l.menuExport)),
              PopupMenuItem(value: _MenuAction.import, child: Text(l.menuImport)),
              PopupMenuItem(value: _MenuAction.settings, child: Text(l.menuSettings)),
            ],
          ),
        ],
      ),
      body: ScreenBody(child: books.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.emptyLibrary, textAlign: TextAlign.center),
              ),
            )
          : settings.gridView
              ? _BookGrid(books: books)
              : _BookList(books: books)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.addBook),
        onPressed: () => openBookEditor(context),
      ),
    );
  }
}

Future<void> openBookEditor(BuildContext context, {int? bookId}) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => BookEditScreen(bookId: bookId)),
    );

class _BookList extends StatelessWidget {
  const _BookList({required this.books});

  final List<BookSummary> books;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: books.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final b = books[i];
        final subtitle = [
          if (b.author != null) b.author!,
          if (b.tags.isNotEmpty) b.tags.map((t) => '#$t').join(' '),
        ];
        return ContentWidth(
          maxWidth: 960,
          child: ListTile(
            leading: CoverThumbnail(bytes: b.thumbnail, title: b.title, width: 36, height: 52),
            title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: subtitle.isEmpty
                ? null
                : Text(subtitle.join('  ·  '), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: b.status, progress: b.progress),
                if (b.readCount >= 2) ...[
                  const SizedBox(height: 4),
                  Text(l.readCount(b.readCount), style: textTheme.labelSmall),
                ],
              ],
            ),
            onTap: () => openBookEditor(context, bookId: b.id),
          ),
        );
      },
    );
  }
}

class _BookGrid extends StatelessWidget {
  const _BookGrid({required this.books});

  final List<BookSummary> books;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final b = books[i];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => openBookEditor(context, bookId: b.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(6),
                  child: CoverThumbnail(
                    bytes: b.thumbnail,
                    title: b.title,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: b.status, progress: b.progress),
                  if (b.readCount >= 2) Text(l.readCount(b.readCount), style: textTheme.labelSmall),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
