#!/usr/bin/env bash
# Colophon の macOS 用ディスクイメージ（.dmg）を作る。Mac 上で実行する。
#
# 使い方（リポジトリのどこからでも）:
#   bash installer/macos/build-dmg.sh
#
# 出力: build/installer/Colophon-<版>.dmg
#   開くと Colophon.app と「Applications」フォルダへの近道が並び、ドラッグでインストールできる。
#
# 注意: 署名・公証（notarization）はしていない。広く配布する場合は Apple Developer Program に登録し、
# codesign と notarytool で署名・公証すること。
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo"

version="$(sed -nE 's/^version:[[:space:]]*([0-9.]+).*/\1/p' pubspec.yaml)"
if [[ -z "$version" ]]; then
  echo "pubspec.yaml に version が見つかりません" >&2
  exit 1
fi
echo "Colophon $version の .dmg を作ります"

# Google ドライブ同期のクライアント設定（リポジトリには含めない。BUILDING.md 参照）
defines="${COLOPHON_DART_DEFINES:-$HOME/.colophon/dart-defines.json}"
build_args=(--release)
if [[ -f "$defines" ]]; then
  build_args+=("--dart-define-from-file=$defines")
  echo "同期の設定: $defines"
else
  echo "警告: 同期の設定ファイルがないため、同期を使えないアプリになります（$defines）" >&2
fi

# 繰り返しビルドするとアイコン用フォントの間引き結果が古いまま残ることがあるため、毎回 clean する
flutter clean
flutter pub get
flutter build macos "${build_args[@]}"

app="build/macos/Build/Products/Release/Colophon.app"
if [[ ! -d "$app" ]]; then
  echo "$app が見つかりません" >&2
  exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
cp "$repo/installer/macos/UNINSTALL.txt" "$stage/How to uninstall.txt"

mkdir -p build/installer
output="build/installer/Colophon-$version.dmg"
hdiutil create -volname "Colophon $version" -srcfolder "$stage" -ov -format UDZO "$output"

echo
echo "完成: $repo/$output"
