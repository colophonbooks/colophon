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

# 繰り返しビルドするとアイコン用フォントの間引き結果が古いまま残ることがあるため、毎回 clean する
flutter clean
flutter pub get
flutter build macos --release

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
