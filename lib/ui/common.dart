import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/book.dart';
import 'app_theme.dart';

/// はい/いいえ（またはキャンセル）の確認ダイアログ。確定なら true。
Future<bool> confirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// 処理中の表示を出しながら [task] を実行する（閉じられないダイアログ）。
Future<T> runWithProgress<T>(BuildContext context, Future<T> Function() task) async {
  final l = AppLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 20),
            Expanded(child: Text(l.processing)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

/// 書影の縮小画像。画像がなければ書籍名入りの表紙風の枠を出す。
class CoverThumbnail extends StatelessWidget {
  const CoverThumbnail({super.key, required this.bytes, required this.title, this.width, this.height});

  final Uint8List? bytes;
  final String title;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = (width ?? 100) < 80;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(small ? 3 : 6),
        child: bytes != null
            ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.secondaryContainer, scheme.tertiaryContainer],
                  ),
                ),
                child: small
                    ? Icon(Icons.menu_book_outlined, size: 20, color: scheme.onSecondaryContainer)
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: scheme.onSecondaryContainer),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}

/// ステータスの小さなラベル（アイコン＋文字）。読書中で進捗が入力されていれば % を添える。
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.progress});

  final ReadingStatus status;
  final int? progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = (theme.extension<StatusColors>() ?? StatusColors.fromScheme(theme.colorScheme))
        .of(status);
    var text = l.status(status);
    if (status == ReadingStatus.reading && progress != null) {
      text = '$text ${l.progressPercent(progress!)}';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 12, color: colors.foreground),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall?.copyWith(color: colors.foreground)),
        ],
      ),
    );
  }
}

/// 画面幅が広いときに中身を読みやすい幅に収める。
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// 日付選択で選べる範囲。インポートしたデータに範囲外の日付があっても落ちないよう、
/// 初期値は [clampPickerDate] で範囲内に収める。
final pickerFirstDate = DateTime(1900);
final pickerLastDate = DateTime(2200, 12, 31);

DateTime clampPickerDate(DateTime d) =>
    d.isBefore(pickerFirstDate) ? pickerFirstDate : (d.isAfter(pickerLastDate) ? pickerLastDate : d);

/// 年を含む日付（例: 2025年3月1日、Mar 1, 2025）。表示言語の書式に従う。
/// MaterialLocalizations.formatMediumDate は年を含まないため使わない。
String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date.toLocal());

/// ノートのお気に入りボタン（☆／★）。色だけでなく塗りつぶしの有無でも状態が分かる。
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IconButton(
      tooltip: favorite ? l.removeFavorite : l.addFavorite,
      isSelected: favorite,
      icon: const Icon(Icons.star_border),
      selectedIcon: Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
      onPressed: onPressed,
    );
  }
}