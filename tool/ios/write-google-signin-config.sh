#!/bin/sh
# iPhone・iPad の Google ログインに要る URL スキームを、ios/Flutter/GoogleSignIn.xcconfig に書き出す（Mac で実行）。
#
# 使い方（リポジトリのルートで）:
#   sh tool/ios/write-google-signin-config.sh
#
# iOS 用のクライアント ID は、パソコン版と同じく dart-defines.json（既定は ~/.colophon/dart-defines.json、
# COLOPHON_DART_DEFINES で変えられる）の COLOPHON_GOOGLE_IOS_CLIENT_ID に書いておく。リポジトリには入れない。
# ログインした後にアプリへ戻るための URL スキームは、クライアント ID を逆順にしたもの
#（例: 123-abc.apps.googleusercontent.com → com.googleusercontent.apps.123-abc）で、
# Info.plist が $(GOOGLE_IOS_URL_SCHEME) として読み込む。
set -eu

defines="${COLOPHON_DART_DEFINES:-$HOME/.colophon/dart-defines.json}"
if [ ! -f "$defines" ]; then
  echo "設定ファイルがありません: $defines" >&2
  exit 1
fi
# plutil は JSON も読める（macOS に標準で入っている）
client_id=$(plutil -extract COLOPHON_GOOGLE_IOS_CLIENT_ID raw -o - "$defines" 2>/dev/null || true)
case "$client_id" in
  *.apps.googleusercontent.com) ;;
  *)
    echo "$defines に COLOPHON_GOOGLE_IOS_CLIENT_ID（…apps.googleusercontent.com）がありません" >&2
    exit 1
    ;;
esac
scheme="com.googleusercontent.apps.${client_id%.apps.googleusercontent.com}"

out="$(cd "$(dirname "$0")/../.." && pwd)/ios/Flutter/GoogleSignIn.xcconfig"
printf '// tool/ios/write-google-signin-config.sh が作るファイル（Git には入れない）\nGOOGLE_IOS_URL_SCHEME = %s\n' "$scheme" > "$out"
echo "書き出しました: $out"
