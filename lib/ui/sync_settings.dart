import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/google_auth.dart';
import '../state/sync_controller.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_plan.dart';

/// 設定画面の「同期」欄。ログイン状態に応じて表示とボタンを切り替える。
class SyncSettingsSection extends StatelessWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sync = context.watch<SyncController>();
    const icon = Icon(Icons.cloud_sync_outlined);

    return switch (sync.state) {
      SyncAuthState.unavailable => ListTile(
          leading: icon,
          enabled: false,
          title: Text(l.syncGoogleDrive),
          subtitle: Text(l.syncUnavailable),
        ),
      SyncAuthState.loading => ListTile(
          leading: icon,
          title: Text(l.syncGoogleDrive),
          trailing: const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      SyncAuthState.signedOut || SyncAuthState.signingIn => ListTile(
          leading: icon,
          title: Text(l.syncGoogleDrive),
          subtitle: Text(l.syncDesc),
          trailing: FilledButton.tonal(
            onPressed: sync.state == SyncAuthState.signedOut ? () => syncSignInFlow(context) : null,
            child: Text(l.syncSignIn),
          ),
        ),
      SyncAuthState.signedIn => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: icon,
              title: Text(l.syncGoogleDrive),
              subtitle: Text(sync.accountEmail == null ? l.syncSignedIn : l.syncSignedInAs(sync.accountEmail!)),
              trailing: TextButton(
                onPressed: sync.syncing ? null : () => _signOutFlow(context),
                child: Text(l.syncSignOut),
              ),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(sync.syncing
                  ? l.syncing
                  : sync.lastSyncAt == null
                      ? l.syncNever
                      : l.syncLastAt(formatDateTime(context, sync.lastSyncAt!))),
              subtitle: _status(context, sync),
              trailing: sync.syncing
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : FilledButton.tonalIcon(
                      icon: const Icon(Icons.sync),
                      label: Text(l.syncNow),
                      onPressed: () => syncNowFlow(context),
                    ),
            ),
          ],
        ),
    };
  }

  /// 失敗・注意があれば、その内容（失敗は赤字）。
  Widget? _status(BuildContext context, SyncController sync) {
    final l = AppLocalizations.of(context);
    if (sync.lastFailure case final failure?) {
      return Text(syncFailureMessage(l, failure), style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
    if (sync.needsFirstChoice) return Text(l.syncNeedsChoice);
    if (sync.lastRemoteUnreadable) return Text(l.syncWarningUnreadable);
    return null;
  }
}

String formatDateTime(BuildContext context, DateTime time) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(time.toLocal());

String syncFailureMessage(AppLocalizations l, SyncFailure failure) => switch (failure) {
      SyncFailure.network => l.syncErrorNetwork,
      SyncFailure.auth => l.syncErrorAuth,
      SyncFailure.newerFormat => l.syncErrorNewerFormat,
      SyncFailure.remoteCorrupt => l.syncErrorRemoteCorrupt,
      SyncFailure.busy => l.syncErrorBusy,
      SyncFailure.missingCover => l.syncErrorMissingCover,
      SyncFailure.quota => l.syncErrorQuota,
      SyncFailure.localStorage => l.syncErrorLocalStorage,
      SyncFailure.other => l.syncErrorOther,
    };

/// 今すぐ同期する。初めての同期で両方にデータがあれば、扱いを選んでもらってから同期する。
Future<void> syncNowFlow(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final sync = context.read<SyncController>();
  final messenger = ScaffoldMessenger.of(context);
  var result = await sync.syncNow();
  if (result case SyncNeedsFirstChoice(:final localBooks, :final remoteBooks)) {
    if (!context.mounted) return;
    final mode = await showDialog<FirstSyncMode>(
      context: context,
      builder: (_) => _FirstSyncDialog(localBooks: localBooks, remoteBooks: remoteBooks),
    );
    if (mode == null) return;
    result = await sync.syncNow(firstSync: mode);
  }
  if (result is SyncDone) {
    messenger.showSnackBar(SnackBar(content: Text(result.remoteUnreadable ? l.syncWarningUnreadable : l.syncDone)));
  } else if (sync.lastFailure case final failure?) {
    messenger.showSnackBar(SnackBar(content: Text(syncFailureMessage(l, failure))));
  }
}

/// 初めての同期で、この端末とクラウドの両方にデータがあるときの選択。
class _FirstSyncDialog extends StatefulWidget {
  const _FirstSyncDialog({required this.localBooks, required this.remoteBooks});

  final int localBooks;
  final int remoteBooks;

  @override
  State<_FirstSyncDialog> createState() => _FirstSyncDialogState();
}

class _FirstSyncDialogState extends State<_FirstSyncDialog> {
  FirstSyncMode _mode = FirstSyncMode.merge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    RadioListTile<FirstSyncMode> option(FirstSyncMode mode, String title, String desc) => RadioListTile(
          contentPadding: EdgeInsets.zero,
          value: mode,
          title: Text(title),
          subtitle: Text(desc),
        );
    return AlertDialog(
      title: Text(l.syncFirstTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: RadioGroup<FirstSyncMode>(
            groupValue: _mode,
            onChanged: (m) => setState(() => _mode = m ?? _mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.syncFirstBody(widget.localBooks, widget.remoteBooks)),
                const SizedBox(height: 12),
                option(FirstSyncMode.merge, l.syncFirstMerge, l.syncFirstMergeDesc),
                option(FirstSyncMode.useRemote, l.syncFirstUseRemote, l.syncFirstUseRemoteDesc),
                option(FirstSyncMode.useLocal, l.syncFirstUseLocal, l.syncFirstUseLocalDesc),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _mode), child: Text(l.syncFirstStart)),
      ],
    );
  }
}

/// ブラウザでログインする。待っている間は URL のコピーと中止ができるダイアログを出す。
Future<void> syncSignInFlow(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final sync = context.read<SyncController>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  var dialogOpen = false;
  try {
    await sync.signIn(
      successPage: '<h1>Colophon</h1><p>${const HtmlEscape().convert(l.syncBrowserPage)}</p>',
      openBrowser: (uri) async {
        // 待ち受けが始まってから呼ばれるので、ここでダイアログを出す
        dialogOpen = true;
        showDialog<void>(
          context: navigator.context,
          barrierDismissible: false,
          builder: (_) => ChangeNotifierProvider.value(value: sync, child: const _SignInDialog()),
        ).then((_) => dialogOpen = false);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
    messenger.showSnackBar(SnackBar(content: Text(l.syncSignInDone)));
    // ログインしたらすぐ同期する（初めての同期の扱いも、ここで選んでもらう）
    if (dialogOpen) navigator.pop();
    dialogOpen = false;
    if (context.mounted) await syncNowFlow(context);
  } on GoogleSignInException catch (e) {
    switch (e.failure) {
      case GoogleSignInFailure.cancelled:
        break;
      case GoogleSignInFailure.denied:
        messenger.showSnackBar(SnackBar(content: Text(l.syncSignInDenied)));
      case GoogleSignInFailure.invalidResponse || GoogleSignInFailure.failed:
        messenger.showSnackBar(SnackBar(content: Text(l.syncSignInFailed)));
    }
  } finally {
    if (dialogOpen) navigator.pop();
  }
}

class _SignInDialog extends StatelessWidget {
  const _SignInDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sync = context.watch<SyncController>();
    final uri = sync.pendingAuthorizationUri;

    return AlertDialog(
      title: Text(l.syncSignInTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.syncSignInBody),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        if (uri != null)
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(l.syncCopyLink),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: uri.toString()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.syncLinkCopied)));
              }
            },
          ),
        TextButton(onPressed: sync.cancelSignIn, child: Text(l.cancel)),
      ],
    );
  }
}

Future<void> _signOutFlow(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final sync = context.read<SyncController>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.syncSignOutTitle),
      content: Text(l.syncSignOutBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.syncSignOut)),
      ],
    ),
  );
  if (ok == true) await sync.signOut();
}
