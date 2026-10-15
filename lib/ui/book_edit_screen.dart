import 'dart:ui' show AppExitResponse;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/book.dart';
import '../services/app_clock.dart';
import '../services/cover_image.dart';
import '../services/isbn.dart';
import '../services/isbn_lookup.dart';
import '../services/search.dart';
import '../state/library_controller.dart';
import '../state/settings_controller.dart';
import 'app_theme.dart';
import 'book_viewer.dart';
import 'common.dart';
import 'isbn_lookup_dialog.dart';

/// 書籍の登録・編集画面。[bookId] が null なら新規登録。
class BookEditScreen extends StatefulWidget {
  const BookEditScreen({super.key, this.bookId});

  final int? bookId;

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

/// 未保存の変更があるままビューアへ切り替えるときの選択。
enum _LeaveEdit { save, discard }

/// 編集中のノート1件分。
class _NoteDraft {
  _NoteDraft({this.original, VoidCallback? onChanged})
      : uuid = original?.uuid ?? const Uuid().v4(),
        category = original?.category,
        favorite = original?.favorite ?? false,
        page = TextEditingController(text: original?.page?.toString() ?? ''),
        body = TextEditingController(text: original?.body ?? '') {
    if (onChanged != null) {
      page.addListener(onChanged);
      body.addListener(onChanged);
    }
  }

  final Note? original;
  final String uuid;
  NoteCategory? category;
  bool favorite;
  final TextEditingController page;
  final TextEditingController body;

  Note toNote(DateTime now) {
    final pageValue = int.tryParse(page.text.trim());
    final text = body.text;
    final changed = original == null ||
        original!.category != category ||
        original!.page != pageValue ||
        original!.body != text ||
        original!.favorite != favorite;
    return Note(
      uuid: uuid,
      category: category,
      page: pageValue,
      body: text,
      favorite: favorite,
      createdAt: original?.createdAt ?? now,
      updatedAt: changed ? now : original!.updatedAt,
    );
  }

  void dispose() {
    page.dispose();
    body.dispose();
  }
}

class _BookEditScreenState extends State<BookEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _translator = TextEditingController();
  final _supervisor = TextEditingController();
  final _publisher = TextEditingController();
  final _isbn = TextEditingController();
  final _edition = TextEditingController();
  final _progress = TextEditingController();
  final _tagInput = TextEditingController();
  final _tagFocus = FocusNode();
  late final AppLifecycleListener _lifecycle;

  Book? _original;
  late String _uuid;
  ReadingStatus _status = ReadingStatus.unset;
  Uint8List? _cover;
  String? _coverType;
  Uint8List? _thumbnail;
  final List<LocalDate> _readDates = [];
  final List<String> _tags = [];
  final List<_NoteDraft> _notes = [];
  List<String> _knownTags = const [];
  bool _dirty = false;

  /// ビューアモード（見る専用）か。登録済みの書籍はビューアモードで開く。
  late bool _viewMode;

  bool get _isNew => widget.bookId == null;

  @override
  void initState() {
    super.initState();
    final repo = context.read<BookRepository>();
    _knownTags = repo.tagNames();
    final book = widget.bookId == null ? null : repo.getBook(widget.bookId!);
    _uuid = book?.uuid ?? const Uuid().v4();
    _viewMode = book != null;
    _load(book);
    for (final c in [_title, _author, _translator, _supervisor, _publisher, _isbn, _edition, _progress, _tagInput]) {
      c.addListener(_markDirty);
    }
    // デスクトップでウィンドウを閉じる（×・Alt+F4・Cmd+Q）ときも未保存の確認を出す
    _lifecycle = AppLifecycleListener(onExitRequested: _onExitRequested);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final c in [_title, _author, _translator, _supervisor, _publisher, _isbn, _edition, _progress, _tagInput]) {
      c.dispose();
    }
    _tagFocus.dispose();
    for (final n in _notes) {
      n.dispose();
    }
    super.dispose();
  }

  /// 入力欄を [book] の内容にそろえる（初回表示と、変更を破棄してビューアへ戻るときに使う）。
  void _load(Book? book) {
    _original = book;
    _title.text = book?.title ?? '';
    _author.text = book?.author ?? '';
    _translator.text = book?.translator ?? '';
    _supervisor.text = book?.supervisor ?? '';
    _publisher.text = book?.publisher ?? '';
    _isbn.text = book?.isbn ?? '';
    _edition.text = book?.edition ?? '';
    _progress.text = book?.progress?.toString() ?? '';
    _tagInput.clear();
    _status = book?.status ?? ReadingStatus.unset;
    _cover = book?.cover;
    _coverType = book?.coverType;
    _thumbnail = book?.thumbnail;
    _readDates
      ..clear()
      ..addAll(book?.readDates ?? const []);
    _tags
      ..clear()
      ..addAll(book?.tags ?? const []);
    for (final n in _notes) {
      n.dispose();
    }
    _notes
      ..clear()
      ..addAll((book?.notes ?? const []).map((n) => _NoteDraft(original: n, onChanged: _markDirty)));
    // 入力欄への代入で _markDirty が呼ばれるため、読み込み後に未変更へ戻す
    _dirty = false;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _change(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  // ---------------------------------------------------------------------------
  // 保存・削除
  // ---------------------------------------------------------------------------

  /// 保存ボタン（Ctrl+S／⌘S）。登録済みの書籍は保存後にビューアへ戻り、新規登録は一覧へ戻る
  /// （新規は戻るべきビューアがなく、続けて別の本を登録しやすいため）。
  void _save() {
    if (!_saveBook()) return;
    showMessage(context, AppLocalizations.of(context).saved);
    if (_isNew) {
      _close();
    } else {
      setState(() => _viewMode = true);
    }
  }

  /// 入力チェックをして保存する。画面は閉じない。保存できたら true。
  bool _saveBook() {
    if (!_formKey.currentState!.validate()) return false;
    final l = AppLocalizations.of(context);
    final now = AppClock.now();
    _commitPendingTag();
    // 進捗欄は「読書中」以外では非表示で検証されないため、範囲外の値はここで捨てる
    final progress = int.tryParse(_progress.text.trim());
    final book = Book(
      id: _original?.id,
      uuid: _uuid,
      title: _title.text.trim(),
      author: _author.text,
      translator: _translator.text,
      supervisor: _supervisor.text,
      publisher: _publisher.text,
      isbn: _isbn.text,
      edition: _edition.text,
      status: _status,
      progress: (progress != null && progress >= 0 && progress <= 100) ? progress : null,
      cover: _cover,
      coverType: _coverType,
      thumbnail: _thumbnail,
      notes: [
        for (final n in _notes) n.toNote(now),
      ]..removeWhere((n) => n.isEmpty),
      readDates: [..._readDates]..sort(),
      tags: _tags,
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );
    final repo = context.read<BookRepository>();
    try {
      // 削除するのは、この画面で消したノートだけ（開いている間に同期で届いたノートは残す）
      final id = repo.saveBook(book, removedNotes: {for (final n in _original?.notes ?? const <Note>[]) n.uuid});
      _load(repo.getBook(id));
    } catch (_) {
      showMessage(context, l.genericError);
      return false;
    }
    context.read<LibraryController>().reload();
    return true;
  }

  // ---------------------------------------------------------------------------
  // ビューアモード／編集モードの切り替え
  // ---------------------------------------------------------------------------

  Future<void> _setViewMode(bool view) async {
    if (view == _viewMode) return;
    if (!view || !_dirty) {
      setState(() => _viewMode = view);
      return;
    }
    // ビューアには常に保存済みの内容を出すため、未保存の変更があれば先に決めてもらう
    final l = AppLocalizations.of(context);
    final choice = await showDialog<_LeaveEdit>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.unsavedTitle),
        content: Text(l.unsavedBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, _LeaveEdit.discard), child: Text(l.discardAndView)),
          FilledButton(onPressed: () => Navigator.pop(context, _LeaveEdit.save), child: Text(l.saveAndView)),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == _LeaveEdit.save) {
      if (!_saveBook()) return;
      showMessage(context, l.saved);
    } else {
      _load(_original);
    }
    setState(() => _viewMode = true);
  }

  /// タグ欄に入力したまま Enter を押していない文字も、保存時にタグとして扱う。
  void _commitPendingTag() {
    final tag = _tagInput.text.trim();
    if (tag.isNotEmpty && !_tags.any((t) => tagKey(t) == tagKey(tag))) _tags.add(tag);
    _tagInput.clear();
  }

  Future<AppExitResponse> _onExitRequested() async {
    if (!_dirty) return AppExitResponse.exit;
    final l = AppLocalizations.of(context);
    final discard = await confirmDialog(
      context,
      title: l.unsavedTitle,
      message: l.unsavedBody,
      confirmLabel: l.discard,
      destructive: true,
    );
    return discard ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      message: l.deleteBookConfirm(_original!.title),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.read<BookRepository>().deleteBook(_original!.id!);
    context.read<LibraryController>().reload();
    _close();
  }

  /// 未保存扱いを解除して画面を閉じる。PopScope の canPop は再描画後に反映されるため、
  /// 再描画を待ってから閉じる。
  void _close() {
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _confirmLeave() async {
    final l = AppLocalizations.of(context);
    final discard = await confirmDialog(
      context,
      title: l.unsavedTitle,
      message: l.unsavedBody,
      confirmLabel: l.discard,
      destructive: true,
    );
    if (discard && mounted) _close();
  }

  // ---------------------------------------------------------------------------
  // 書影
  // ---------------------------------------------------------------------------

  Future<void> _pickCover() async {
    final l = AppLocalizations.of(context);
    final autoResize = context.read<SettingsController>().autoResize;
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final processed = await runWithProgress(context, () => processCover(bytes, autoResize: autoResize));
      if (!mounted) return;
      _change(() {
        _cover = processed.bytes;
        _coverType = processed.mimeType;
        _thumbnail = processed.thumbnail;
      });
      if (processed.resized) showMessage(context, l.coverResized(processed.width, processed.height));
    } on CoverImageException {
      if (mounted) showMessage(context, l.coverLoadFailed);
    }
  }

  // ---------------------------------------------------------------------------
  // ステータス・読了日
  // ---------------------------------------------------------------------------

  Future<void> _changeStatus(ReadingStatus? status) async {
    if (status == null || status == _status) return;
    _change(() => _status = status);
    if (status != ReadingStatus.finished) return;
    final today = LocalDate.today();
    if (_readDates.contains(today)) return;
    final l = AppLocalizations.of(context);
    final add = await confirmDialog(
      context,
      title: l.askAddReadDateTitle,
      message: l.askAddReadDateBody(formatDate(context, today.toDateTime())),
      confirmLabel: l.add,
    );
    if (add && mounted) _change(() => _readDates.add(today));
  }

  Future<void> _pickReadDate({LocalDate? current}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: clampPickerDate((current ?? LocalDate.today()).toDateTime()),
      firstDate: pickerFirstDate,
      lastDate: pickerLastDate,
    );
    if (picked == null || !mounted) return;
    final date = LocalDate.fromDateTime(picked);
    _change(() {
      if (current != null) _readDates.remove(current);
      if (!_readDates.contains(date)) _readDates.add(date);
      _readDates.sort();
    });
  }

  // ---------------------------------------------------------------------------
  // ISBN
  // ---------------------------------------------------------------------------

  Future<void> _lookupIsbn() async {
    final l = AppLocalizations.of(context);
    if (!isValidIsbn(_isbn.text)) {
      showMessage(context, l.isbnLookupInvalid);
      return;
    }
    final service = context.read<IsbnLookupService>();
    LookupResult? result;
    try {
      result = await runWithProgress(context, () => service.lookup(_isbn.text));
    } on LookupException {
      if (mounted) showMessage(context, l.lookupFailed);
      return;
    }
    if (!mounted) return;
    if (result == null) {
      showMessage(context, l.lookupNotFound);
      return;
    }
    final fields = {
      LookupField.title: _title,
      LookupField.author: _author,
      LookupField.translator: _translator,
      LookupField.supervisor: _supervisor,
      LookupField.publisher: _publisher,
      LookupField.edition: _edition,
    };
    final selected = await showIsbnLookupDialog(
      context,
      result: result,
      current: {for (final e in fields.entries) e.key: e.value.text},
    );
    if (selected == null || !mounted) return;
    setState(() {
      for (final e in selected.entries) {
        fields[e.key]!.text = e.value;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 画面
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? l.newBookTitle : (_viewMode ? l.viewBookTitle : l.editBookTitle)),
          actions: [
            if (!_isNew)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, icon: const Icon(Icons.visibility_outlined), label: Text(l.viewMode)),
                    ButtonSegment(value: false, icon: const Icon(Icons.edit_outlined), label: Text(l.editMode)),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (s) => _setViewMode(s.single),
                ),
              ),
            if (!_viewMode) ...[
              if (!_isNew)
                IconButton(
                  tooltip: l.deleteBook,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l.save),
                  onPressed: _save,
                ),
              ),
            ],
          ],
        ),
        body: _viewMode ? BookViewer(book: _original!) : CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCoverSection(l),
                        const SizedBox(height: 16),
                        ..._buildBibliographicFields(l),
                        const SizedBox(height: 8),
                        ..._buildStatusFields(l),
                        _SectionTitle(l.readDatesSection),
                        _buildReadDates(l),
                        _SectionTitle(l.tagsSection),
                        _TagEditor(
                          controller: _tagInput,
                          focusNode: _tagFocus,
                          tags: _tags,
                          knownTags: _knownTags,
                          onAdd: (t) => _change(() => _tags.add(t)),
                          onRemove: (t) => _change(() => _tags.remove(t)),
                        ),
                        _SectionTitle(l.notesSection),
                        ..._buildNotes(l),
                        if (!_isNew) _buildTimestamps(l),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection(AppLocalizations l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _pickCover,
          child: CoverThumbnail(
            bytes: _thumbnail ?? _cover,
            title: _title.text,
            width: 120,
            height: 176,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: Text(l.coverSelect),
                onPressed: _pickCover,
              ),
              if (_cover != null)
                TextButton.icon(
                  icon: const Icon(Icons.hide_image_outlined),
                  label: Text(l.coverRemove),
                  onPressed: () => _change(() {
                    _cover = null;
                    _coverType = null;
                    _thumbnail = null;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBibliographicFields(AppLocalizations l) {
    final isbnText = _isbn.text.trim();
    final isbnSuspicious = isbnText.isNotEmpty && !isValidIsbn(isbnText);
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(controller: c, decoration: InputDecoration(labelText: label)),
        );
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _title,
          autofocus: _isNew,
          decoration: InputDecoration(labelText: '${l.fieldTitle} *'),
          // 書影がないときの仮表紙に書籍名を出しているため、入力のたびに再描画する
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.titleRequired : null,
        ),
      ),
      field(_author, l.fieldAuthor),
      field(_translator, l.fieldTranslator),
      field(_supervisor, l.fieldSupervisor),
      field(_publisher, l.fieldPublisher),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _isbn,
                decoration: InputDecoration(
                  labelText: l.fieldIsbn,
                  helperText: isbnSuspicious ? l.isbnInvalidWarning : null,
                  helperMaxLines: 2,
                  helperStyle: isbnSuspicious
                      ? TextStyle(color: Theme.of(context).colorScheme.tertiary)
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: IconButton.filledTonal(
                tooltip: l.isbnLookup,
                icon: const Icon(Icons.travel_explore),
                onPressed: _lookupIsbn,
              ),
            ),
          ],
        ),
      ),
      field(_edition, l.fieldEdition),
    ];
  }

  List<Widget> _buildStatusFields(AppLocalizations l) {
    return [
      DropdownButtonFormField<ReadingStatus>(
        initialValue: _status,
        decoration: InputDecoration(labelText: l.fieldStatus),
        items: [
          for (final s in ReadingStatus.values)
            DropdownMenuItem(
              value: s,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(statusIcon(s), size: 18), const SizedBox(width: 8), Text(l.status(s))],
              ),
            ),
        ],
        onChanged: _changeStatus,
      ),
      if (_status == ReadingStatus.reading)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
            controller: _progress,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.fieldProgress, hintText: l.progressHint, suffixText: '%'),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return null;
              final n = int.tryParse(t);
              return (n == null || n < 0 || n > 100) ? l.progressInvalid : null;
            },
          ),
        ),
    ];
  }

  Widget _buildReadDates(AppLocalizations l) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_readDates.isEmpty) Text(l.noReadDates, style: Theme.of(context).textTheme.bodySmall),
        for (final d in _readDates)
          InputChip(
            avatar: const Icon(Icons.event_available, size: 18),
            label: Text(formatDate(context, d.toDateTime())),
            onPressed: () => _pickReadDate(current: d),
            onDeleted: () => _change(() => _readDates.remove(d)),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l.addReadDate),
          onPressed: _pickReadDate,
        ),
      ],
    );
  }

  List<Widget> _buildNotes(AppLocalizations l) {
    return [
      if (_notes.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.noNotes, style: Theme.of(context).textTheme.bodySmall),
        ),
      for (var i = 0; i < _notes.length; i++)
        _NoteCard(
          key: ObjectKey(_notes[i]),
          draft: _notes[i],
          canMoveUp: i > 0,
          canMoveDown: i < _notes.length - 1,
          onCategoryChanged: (c) => _change(() => _notes[i].category = c),
          onFavoriteToggled: () => _change(() => _notes[i].favorite = !_notes[i].favorite),
          onMoveUp: () => _change(() => _notes.insert(i - 1, _notes.removeAt(i))),
          onMoveDown: () => _change(() => _notes.insert(i + 1, _notes.removeAt(i))),
          onDelete: () async {
            final draft = _notes[i];
            if (draft.body.text.trim().isNotEmpty) {
              final ok = await confirmDialog(
                context,
                message: l.deleteNoteConfirm,
                confirmLabel: l.delete,
                destructive: true,
              );
              if (!ok) return;
            }
            _change(() => _notes.remove(draft));
            draft.dispose();
          },
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.note_add_outlined),
          label: Text(l.addNote),
          onPressed: () => _change(() => _notes.add(_NoteDraft(onChanged: _markDirty))),
        ),
      ),
    ];
  }

  Widget _buildTimestamps(AppLocalizations l) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        '${l.fieldCreatedAt}: ${formatDate(context, _original!.createdAt)}   '
        '${l.fieldUpdatedAt}: ${formatDate(context, _original!.updatedAt)}',
        style: style,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    super.key,
    required this.draft,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onCategoryChanged,
    required this.onFavoriteToggled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final _NoteDraft draft;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<NoteCategory?> onCategoryChanged;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<NoteCategory?>(
                          initialValue: draft.category,
                          isDense: true,
                          decoration: InputDecoration(labelText: l.noteCategory),
                          items: [
                            for (final c in <NoteCategory?>[null, ...NoteCategory.values])
                              DropdownMenuItem(value: c, child: Text(l.category(c))),
                          ],
                          onChanged: onCategoryChanged,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: draft.page,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(labelText: l.notePage, isDense: true),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return null;
                            final n = int.tryParse(t);
                            return (n == null || n < 1) ? l.pageInvalid : null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                FavoriteButton(favorite: draft.favorite, onPressed: onFavoriteToggled),
                IconButton(
                  tooltip: l.moveUp,
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: canMoveUp ? onMoveUp : null,
                ),
                IconButton(
                  tooltip: l.moveDown,
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: canMoveDown ? onMoveDown : null,
                ),
                IconButton(
                  tooltip: l.deleteNote,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextFormField(
                controller: draft.body,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l.noteBody,
                  hintText: l.noteBodyHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// タグの入力欄。既存タグを候補として表示し、Enter で追加する。
class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.controller,
    required this.focusNode,
    required this.tags,
    required this.knownTags,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> tags;
  final List<String> knownTags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  /// 矢印キーで候補を選んだか。選んでいれば Enter で候補を、そうでなければ入力どおりの文字を追加する。
  bool _navigated = false;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text != _lastText) {
      _lastText = widget.controller.text;
      _navigated = false;
    }
  }

  void _add(String raw) {
    final tag = raw.trim();
    widget.controller.clear();
    if (tag.isEmpty) return;
    if (!widget.tags.any((t) => tagKey(t) == tagKey(tag))) widget.onAdd(tag);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in widget.tags)
                  InputChip(label: Text(t), onDeleted: () => widget.onRemove(t)),
              ],
            ),
          ),
        Autocomplete<String>(
          textEditingController: widget.controller,
          focusNode: widget.focusNode,
          optionsBuilder: (value) {
            final q = normalizeForSearch(value.text.trim());
            if (q.isEmpty) return const [];
            final current = {for (final t in widget.tags) tagKey(t)};
            return widget.knownTags.where(
              (t) => !current.contains(tagKey(t)) && normalizeForSearch(t).contains(q),
            );
          },
          onSelected: _add,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                        event.logicalKey == LogicalKeyboardKey.arrowUp)) {
                  _navigated = true;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: l.tagInputHint,
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                onSubmitted: (v) {
                  if (_navigated) {
                    onFieldSubmitted();
                  } else {
                    _add(v);
                  }
                  focusNode.requestFocus();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}