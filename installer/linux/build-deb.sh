#!/usr/bin/env bash
# Colophon の .deb パッケージ（Ubuntu・Debian 系）を作る。Linux 上で実行する。
#
# 使い方（リポジトリのどこからでも）:
#   bash installer/linux/build-deb.sh
#
# 必要なもの: Flutter、dpkg-deb（Debian 系なら標準で入っている）
#
# 出力: build/installer/colophon_<版>_<アーキテクチャ>.deb
#   インストール:     sudo apt install ./build/installer/colophon_<版>_amd64.deb
#   アンインストール: sudo apt remove colophon
#
# 注意: Debian の決まりで、パッケージは利用者のホームフォルダに触れない。アンインストールしても
# 書籍データ（~/.local/share/io.github.colophonbooks.colophon）は残る。消す場合は、先にアプリの
# 「設定 → データ → すべてのデータを削除」を使うか、そのフォルダを削除する。
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo"

version="$(sed -nE 's/^version:[[:space:]]*([0-9.]+).*/\1/p' pubspec.yaml)"
if [[ -z "$version" ]]; then
  echo "pubspec.yaml に version が見つかりません" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) arch=amd64; flutter_arch=x64 ;;
  aarch64) arch=arm64; flutter_arch=arm64 ;;
  *) echo "未対応のアーキテクチャです: $(uname -m)" >&2; exit 1 ;;
esac
echo "Colophon $version の .deb（$arch）を作ります"

# 繰り返しビルドするとアイコン用フォントの間引き結果が古いまま残ることがあるため、毎回 clean する
flutter clean
flutter pub get
flutter build linux --release

bundle="build/linux/$flutter_arch/release/bundle"
id="io.github.colophonbooks.colophon"
root="build/deb/colophon_${version}_${arch}"
rm -rf "$root"

install -d "$root/opt/colophon" "$root/usr/bin" "$root/DEBIAN"
cp -r "$bundle/." "$root/opt/colophon/"
ln -s /opt/colophon/colophon "$root/usr/bin/colophon"
install -Dm644 "installer/linux/$id.desktop" "$root/usr/share/applications/$id.desktop"
install -Dm644 "installer/linux/$id.metainfo.xml" "$root/usr/share/metainfo/$id.metainfo.xml"
install -d "$root/usr/share/icons"
cp -r installer/linux/icons/hicolor "$root/usr/share/icons/"
install -Dm644 LICENSE "$root/usr/share/doc/colophon/copyright"

installed_size="$(du -sk "$root" | cut -f1)"
cat > "$root/DEBIAN/control" <<EOF
Package: colophon
Version: $version
Architecture: $arch
Maintainer: colophonbooks <https://github.com/colophonbooks>
Installed-Size: $installed_size
Depends: libgtk-3-0t64 | libgtk-3-0
Recommends: xdg-desktop-portal
Section: misc
Priority: optional
Homepage: https://github.com/colophonbooks
Description: A book library for book lovers
 Keep track of the books you own, your reading status, cover images,
 notes, tags, and the dates you finished each book.
EOF

mkdir -p build/installer
output="build/installer/colophon_${version}_${arch}.deb"
dpkg-deb --build --root-owner-group "$root" "$output"

echo
echo "完成: $repo/$output"
