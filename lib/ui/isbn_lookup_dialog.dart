import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../services/isbn_lookup.dart';

enum LookupField { title, author, translator, supervisor, publisher, edition }

/// 取得した書籍情報を項目ごとに選んで反映するダイアログ。
/// 反映する項目と値を返す（キャンセルなら null）。
Future<Map<LookupField, String>?> showIsbnLookupDialog(
  BuildContext context, {
  required LookupResult result,
  required Map<LookupField, String> current,
}) {
  return showDialog<Map<LookupField, String>>(
    context: context,
    builder: (_) => _IsbnLookupDialog(result: result, current: current),
  );
}

class _IsbnLookupDialog extends StatefulWidget {
  const _IsbnLookupDialog({required this.result, required this.current});

  final LookupResult result;
  final Map<LookupField, String> current;

  @override
  State<_IsbnLookupDialog> createState() => _IsbnLookupDialogState();
}

class _IsbnLookupDialogState extends State<_IsbnLookupDialog> {
  late final Map<LookupField, String> _fetched;
  late final Set<LookupField> _checked;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _fetched = {
      for (final (field, value) in [
        (LookupField.title, r.title),
        (LookupField.author, r.author),
        (LookupField.translator, r.translator),
        (LookupField.supervisor, r.supervisor),
        (LookupField.publisher, r.publisher),
        (LookupField.edition, r.edition),
      ])
        if (value != null && value.trim().isNotEmpty) field: value.trim(),
    };
    // 初期状態では、まだ空欄の項目だけを反映対象にする
    _checked = {
      for (final f in _fetched.keys)
        if ((widget.current[f] ?? '').trim().isEmpty) f,
    };
  }

  String _label(AppLocalizations l, LookupField f) => switch (f) {
        LookupField.title => l.fieldTitle,
        LookupField.author => l.fieldAuthor,
        LookupField.translator => l.fieldTranslator,
        LookupField.supervisor => l.fieldSupervisor,
        LookupField.publisher => l.fieldPublisher,
        LookupField.edition => l.fieldEdition,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(l.lookupTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in _fetched.entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _checked.contains(e.key),
                  title: Text('${_label(l, e.key)}: ${e.value}'),
                  subtitle: (widget.current[e.key] ?? '').trim().isEmpty
                      ? null
                      : Text(l.lookupCurrent(widget.current[e.key]!)),
                  onChanged: (v) => setState(() => v == true ? _checked.add(e.key) : _checked.remove(e.key)),
                ),
              const SizedBox(height: 8),
              Text(l.lookupSource(l.sourceName(widget.result.source)), style: textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(l.lookupRoleNote, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _checked.isEmpty
              ? null
              : () => Navigator.pop(context, {for (final f in _checked) f: _fetched[f]!}),
          child: Text(l.lookupApply),
        ),
      ],
    );
  }
}
