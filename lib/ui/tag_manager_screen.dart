import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../state/library_controller.dart';
import 'common.dart';

enum _TagAction { rename, delete }

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  List<TagUsage> _tags = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _tags = context.read<BookRepository>().listTags());
    context.read<LibraryController>().reload();
  }

  Future<void> _rename(TagUsage tag) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<BookRepository>();
    final controller = TextEditingController(text: tag.name);
    String? error;
    final renamed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final name = controller.text.trim();
            if (name.isEmpty) {
              setDialogState(() => error = l.tagNameRequired);
            } else if (!repo.renameTag(tag.id, name)) {
              setDialogState(() => error = l.tagExists);
            } else {
              Navigator.pop(context, true);
            }
          }

          return AlertDialog(
            title: Text(l.renameTag),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l.tagName, errorText: error),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              FilledButton(onPressed: submit, child: Text(l.save)),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (renamed == true && mounted) _reload();
  }

  Future<void> _delete(TagUsage tag) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      message: l.deleteTagConfirm(tag.name),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.read<BookRepository>().deleteTag(tag.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tagsTitle)),
      body: _tags.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.noTags, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final t in _tags)
                  ContentWidth(
                    child: ListTile(
                      leading: const Icon(Icons.sell_outlined),
                      title: Text(t.name),
                      subtitle: Text(l.tagBookCount(t.bookCount)),
                      trailing: PopupMenuButton<_TagAction>(
                        onSelected: (a) => a == _TagAction.rename ? _rename(t) : _delete(t),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: _TagAction.rename, child: Text(l.rename)),
                          PopupMenuItem(value: _TagAction.delete, child: Text(l.delete)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
