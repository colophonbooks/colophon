#!/usr/bin/env bash
# Colophon の Flatpak パッケージ（配布用の 1 ファイル）を作る。Linux（x86_64）上で実行する。
#
# 使い方（リポジトリのどこからでも）:
#   bash installer/linux/build-flatpak.sh
#
# 必要なもの: Flutter、flatpak、flatpak-builder、Flathub の登録
#   flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
#
# 出力: build/installer/Colophon-<版>.flatpak
#   インストール:   flatpak install --user build/installer/Colophon-<版>.flatpak
#   アンインストール（書籍データも消す）: flatpak uninstall --delete-data io.github.colophonbooks.colophon
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo"

version="$(sed -nE 's/^version:[[:space:]]*([0-9.]+).*/\1/p' pubspec.yaml)"
if [[ -z "$version" ]]; then
  echo "pubspec.yaml に version が見つかりません" >&2
  exit 1
fi
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "このスクリプトは x86_64 用です（マニフェストが build/linux/x64 を参照しているため）" >&2
  exit 1
fi
echo "Colophon $version の Flatpak を作ります"

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
flutter build linux "${build_args[@]}"

manifest="installer/linux/io.github.colophonbooks.colophon.yml"
work="build/flatpak"
flatpak-builder --user --force-clean --install-deps-from=flathub \
  --repo="$work/repo" "$work/build-dir" "$manifest"

mkdir -p build/installer
output="build/installer/Colophon-$version.flatpak"
flatpak build-bundle "$work/repo" "$output" io.github.colophonbooks.colophon \
  --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo

echo
echo "完成: $repo/$output"
