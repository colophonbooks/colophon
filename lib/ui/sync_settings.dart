import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/google_auth.dart';
import '../state/sync_controller.dart';

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
      SyncAuthState.signedIn => ListTile(
          leading: icon,
          title: Text(l.syncGoogleDrive),
          subtitle: Text(sync.accountEmail == null ? l.syncSignedIn : l.syncSignedInAs(sync.accountEmail!)),
          trailing: TextButton(onPressed: () => _signOutFlow(context), child: Text(l.syncSignOut)),
        ),
    };
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
