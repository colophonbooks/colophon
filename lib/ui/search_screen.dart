import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/book.dart';
import '../services/search.dart';
import '../state/library_controller.dart';
import 'book_list_screen.dart';
import 'app_theme.dart';
import 'common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;

  List<Book> _index = const [];
  List<String> _allTags = const [];
  List<SearchResult> _results = const [];

  Set<SearchField> _fields = {...SearchField.values};
  final Set<ReadingStatus> _statuses = {};
  final Set<NoteCategory?> _categories = {};
  bool _favoritesOnly = false;
  final Set<String> _tags = {};
  LocalDate? _readFrom;
  LocalDate? _readTo;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  /// 検索対象のデータを読み込み直す（書籍を編集して戻ったときにも呼ぶ）。
  void _loadIndex() {
    final repo = context.read<BookRepository>();
    _index = repo.getAllBooks(withImages: false);
    _allTags = repo.tagNames();
    _tags.removeWhere((t) => !_allTags.contains(t));
    _search();
  }

  void _search() {
    setState(() {
      _results = searchBooks(
        _index,
        SearchQuery(
          text: _text.text,
          fields: _fields,
          statuses: _statuses,
          categories: _categories,
          favoritesOnly: _favoritesOnly,
          tags: _tags,
          readFrom: _readFrom,
          readTo: _readTo,
        ),
      );
    });
  }

  void _update(VoidCallback fn) {
    fn();
    _search();
  }

  bool get _hasOptions =>
      _fields.length != SearchField.values.length ||
      _statuses.isNotEmpty ||
      _categories.isNotEmpty ||
      _favoritesOnly ||
      _tags.isNotEmpty ||
      _readFrom != null ||
      _readTo != null;

  /// 検索結果のノートのお気に入りは、押した時点で保存する。
  void _toggleFavorite(Note note) {
    context.read<BookRepository>().setNoteFavorite(note.uuid, !note.favorite);
    _loadIndex();
  }

  Future<void> _pickDate({required bool from}) async {
    final current = from ? _readFrom : _readTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: clampPickerDate((current ?? LocalDate.today()).toDateTime()),
      firstDate: pickerFirstDate,
      lastDate: pickerLastDate,
    );
    if (picked == null) return;
    _update(() => from
        ? _readFrom = LocalDate.fromDateTime(picked)
        : _readTo = LocalDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final thumbnails = {
      for (final b in context.watch<LibraryController>().books) b.id: b.thumbnail,
    };
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _text,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            suffixIcon: _text.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _update(_text.clear),
                  ),
          ),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 200), _search);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ContentWidth(maxWidth: 960, child: _buildOptions(l))),
          SliverToBoxAdapter(
            child: ContentWidth(
              maxWidth: 960,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  _results.isEmpty ? l.noResults : l.resultCount(_results.length),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _results.length,
            itemBuilder: (context, i) => ContentWidth(
              maxWidth: 960,
              child: _ResultTile(
                result: _results[i],
                thumbnail: thumbnails[_results[i].book.id],
                onToggleFavorite: _toggleFavorite,
                onTap: () async {
                  await openBookEditor(context, bookId: _results[i].book.id);
                  if (mounted) _loadIndex();
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildOptions(AppLocalizations l) {
    final textTheme = Theme.of(context).textTheme;
    Widget group(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );

    return ExpansionTile(
      leading: Icon(_hasOptions ? Icons.filter_alt : Icons.filter_alt_outlined),
      title: Text(l.searchConditions),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group(l.searchTargets, [
          for (final f in SearchField.values)
            FilterChip(
              label: Text(l.searchField(f)),
              selected: _fields.contains(f),
              onSelected: (on) => _update(() => _fields = on ? {..._fields, f} : ({..._fields}..remove(f))),
            ),
        ]),
        group(l.filterStatus, [
          for (final s in ReadingStatus.values)
            FilterChip(
              avatar: Icon(statusIcon(s), size: 18),
              label: Text(l.status(s)),
              selected: _statuses.contains(s),
              onSelected: (on) => _update(() => on ? _statuses.add(s) : _statuses.remove(s)),
            ),
        ]),
        group(l.filterCategory, [
          for (final c in <NoteCategory?>[...NoteCategory.values, null])
            FilterChip(
              label: Text(l.category(c)),
              selected: _categories.contains(c),
              onSelected: (on) => _update(() => on ? _categories.add(c) : _categories.remove(c)),
            ),
        ]),
        group(l.filterFavorite, [
          FilterChip(
            avatar: const Icon(Icons.star, size: 18),
            label: Text(l.favoriteNotesOnly),
            selected: _favoritesOnly,
            onSelected: (on) => _update(() => _favoritesOnly = on),
          ),
        ]),
        if (_allTags.isNotEmpty)
          group(l.filterTags, [
            for (final t in _allTags)
              FilterChip(
                label: Text(t),
                selected: _tags.contains(t),
                onSelected: (on) => _update(() => on ? _tags.add(t) : _tags.remove(t)),
              ),
          ]),
        group(l.filterReadDate, [
          InputChip(
            avatar: const Icon(Icons.event, size: 18),
            label: Text(_readFrom == null ? l.dateFrom : formatDate(context, _readFrom!.toDateTime())),
            onPressed: () => _pickDate(from: true),
            onDeleted: _readFrom == null ? null : () => _update(() => _readFrom = null),
          ),
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('–')),
          InputChip(
            avatar: const Icon(Icons.event, size: 18),
            label: Text(_readTo == null ? l.dateTo : formatDate(context, _readTo!.toDateTime())),
            onPressed: () => _pickDate(from: false),
            onDeleted: _readTo == null ? null : () => _update(() => _readTo = null),
          ),
        ]),
        if (_hasOptions)
          TextButton.icon(
            icon: const Icon(Icons.clear_all),
            label: Text(l.clearFilters),
            onPressed: () => _update(() {
              _fields = {...SearchField.values};
              _statuses.clear();
              _categories.clear();
              _favoritesOnly = false;
              _tags.clear();
              _readFrom = null;
              _readTo = null;
            }),
          ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.thumbnail,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final SearchResult result;
  final Uint8List? thumbnail;
  final VoidCallback onTap;
  final ValueChanged<Note> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final book = result.book;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverThumbnail(bytes: thumbnail, title: book.title, width: 36, height: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.titleSmall),
                  if (book.author != null) Text(book.author!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  StatusBadge(status: book.status, progress: book.progress),
                  for (final n in result.matchedNotes)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [l.category(n.category), if (n.page != null) 'p.${n.page}'].join('  ·  '),
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(n.body, maxLines: 4, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          FavoriteButton(favorite: n.favorite, onPressed: () => onToggleFavorite(n)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
