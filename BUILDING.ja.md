# ビルド手順

日本語 | [English](BUILDING.md)

Colophon を Windows / macOS / Linux でビルドするための、環境の準備とビルドの手順です。

## 最初に知っておくこと

- **各OS版は、そのOS上でしかビルドできません。** Windows 版は Windows、macOS 版は Mac、Linux 版は Linux でビルドします（Flutter はほかのOS向けのビルドに対応していません）。
- **初回のビルドにはインターネット接続が必要です。** 依存パッケージと、SQLite のビルド済みライブラリを自動でダウンロードします。
- 必要な Flutter のバージョンは **3.47 以降（stable チャンネル）** です。`pubspec.yaml` で Dart 3.13.5 以降を指定しているため、それより古い Flutter ではビルドできません。

| | Windows | macOS | Linux |
|---|---|---|---|
| OS | Windows 10 / 11（64bit） | 最新またはひとつ前の macOS | Ubuntu 22.04 以降など（64bit） |
| 必須ツール | Git、Visual Studio 2022（C++ によるデスクトップ開発） | Xcode | Git、clang、CMake、Ninja、GTK 3 の開発用パッケージ |
| OS の設定 | 開発者モードを有効にする | Xcode のライセンスに同意する | ― |
| ビルド結果 | `build\windows\x64\runner\Release\` | `build/macos/Build/Products/Release/Colophon.app` | `build/linux/x64/release/bundle/` |

---

## Windows

### 1. Git をインストールする

[Git for Windows](https://git-scm.com/download/win) をインストールします。インストーラーの選択肢は既定のままで問題ありません。

### 2. Visual Studio 2022 をインストールする

次のどちらかをインストールし、インストーラーでワークロード **「C++ によるデスクトップ開発」（Desktop development with C++）** を選びます。

- [Visual Studio 2022 Community](https://visualstudio.microsoft.com/ja/vs/community/)（無料の統合開発環境）
- [Build Tools for Visual Studio 2022](https://visualstudio.microsoft.com/ja/downloads/#build-tools-for-visual-studio-2022)（ビルドに必要な部分だけ。画面を使わないなら軽くて十分）

あわせて、「個別のコンポーネント」から **「最新の v143 ビルド ツール用 C++ ATL」**（C++ ATL for latest v143 build tools）も選んでください。同期のログイン情報を保存する部品のビルドに必要です。

> Visual Studio と Visual Studio **Code** は別の製品です。VS Code をエディターとして使う場合でも、ビルドには上記が必要です。

### 3. 開発者モードを有効にする

Flutter のプラグインがシンボリックリンクを使うため、Windows の開発者モードが必要です。

- Windows 11: 「設定」→「システム」→「開発者向け」→「開発者モード」をオン
- Windows 10: 「設定」→「更新とセキュリティ」→「開発者向け」→「開発者モード」をオン

PowerShell で `start ms-settings:developers` を実行しても、同じ設定画面が開きます。

### 4. Flutter SDK をインストールする

PowerShell で次を実行します（`C:\src\flutter` に配置する例。パスに空白や日本語を含む場所は避けてください）。

```powershell
New-Item -ItemType Directory -Force C:\src | Out-Null
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter

# ユーザーの PATH に追加する（新しく開いたターミナルから有効）
$p = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$p;C:\src\flutter\bin", 'User')
```

ターミナルを開き直して、環境を確認します。

```powershell
flutter --version
flutter doctor
```

`flutter doctor` の結果で **Flutter** と **Visual Studio - develop Windows apps** に `[√]` が付いていれば準備完了です（Android や Chrome の項目は Windows 版のビルドには関係ありません）。

### 5. ビルドする

→ [共通のビルド手順](#共通のビルド手順) へ。ビルドのコマンドは `flutter build windows --release` です。

### 配布するとき

- `build\windows\x64\runner\Release\` **フォルダごと** 配布します。`colophon.exe` だけでは動きません（同じフォルダの DLL や `data` フォルダが必要です）。
- 署名していないため、初回起動時に Windows SmartScreen の警告が出ることがあります（「詳細情報」→「実行」で起動できます）。

---

## macOS

### 1. Xcode をインストールする

App Store から [Xcode](https://apps.apple.com/jp/app/xcode/id497799835) をインストールし、一度起動して追加コンポーネントのインストールを済ませます。

続けてターミナルで次を実行し、コマンドラインツールの設定とライセンスへの同意を行います。

```sh
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
sudo xcodebuild -license
```

> **CocoaPods は不要です。** Flutter 3.44 以降は Swift Package Manager で依存関係を管理し、このアプリが使うプラグインもすべて対応しています。

### 2. Flutter SDK をインストールする

Git は Xcode のコマンドラインツールに含まれています。

```sh
mkdir -p ~/development
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter

# zsh（macOS の標準シェル）の PATH に追加する
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

環境を確認します。

```sh
flutter --version
flutter doctor
```

`flutter doctor` で **Flutter** と **Xcode - develop for iOS and macOS** に `[√]` が付いていれば準備完了です。

### 3. ビルドする

→ [共通のビルド手順](#共通のビルド手順) へ。ビルドのコマンドは `flutter build macos --release` です。

### 配布するとき

- `build/macos/Build/Products/Release/Colophon.app` を配布します。
- 署名・公証（notarization）をしていないアプリは、Gatekeeper によって開けないことがあります。自分の Mac で試すだけなら、Finder で `Colophon.app` を右クリック →「開く」で起動できます。
- ほかの人へ広く配布する場合は、Apple Developer Program への登録と、署名・公証が必要です（この手順書の範囲外です）。

---

## Linux

Ubuntu / Debian 系での手順です。ほかのディストリビューションでは、同等のパッケージをそれぞれのパッケージマネージャーで入れてください。

### 1. 必要なパッケージをインストールする

```sh
sudo apt-get update -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev libsecret-1-dev
```

`libsecret-1-dev` は、同期のログイン情報をデスクトップの鍵束に保存する部品のビルドに使います。

> `libstdc++-12-dev` が見つからない場合は、そのディストリビューションで提供されている版（例: `libstdc++-14-dev`）を指定してください。

### 2. Flutter SDK をインストールする

```sh
mkdir -p ~/development
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter

# bash の PATH に追加する（zsh を使っている場合は ~/.zshrc）
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

環境を確認します。

```sh
flutter --version
flutter doctor
```

`flutter doctor` で **Flutter** と **Linux toolchain - develop for Linux desktop** に `[√]` が付いていれば準備完了です。

### 3. ビルドする

→ [共通のビルド手順](#共通のビルド手順) へ。ビルドのコマンドは `flutter build linux --release` です。

### 実行・配布するとき

- `build/linux/x64/release/bundle/` **フォルダごと** 配布し、中の `colophon` を実行します（ARM64 の環境では `build/linux/arm64/release/bundle/`）。
- 書影の選択やエクスポートの保存先を選ぶ画面には **xdg-desktop-portal** を使います。GNOME / KDE などの一般的なデスクトップ環境には標準で入っています。最小構成の環境でファイル選択画面が開かない場合は、`xdg-desktop-portal` と、デスクトップ環境に合ったバックエンド（`xdg-desktop-portal-gtk` など）をインストールしてください。

---

## 共通のビルド手順

ここからはどのOSでも同じです。

### 1. ソースコードを取得する

```sh
git clone https://github.com/colophonbooks/colophon.git
cd colophon
```

### 2. 依存パッケージを取得する

```sh
flutter pub get
```

画面の文言（`lib/l10n/app_*.arb`）から生成される多言語用のコードは、`flutter pub get` や `flutter run` / `flutter build` のときに自動で作られます。

### 3. 自動テストを実行する（任意）

```sh
flutter test
```

すべてのテストが成功すると、最後に `All tests passed!` と表示されます。

### 4. 開発中の起動

ソースを変更しながら動作を確かめるときは、デバッグ版で起動します。起動中にターミナルで `r` を押すと、変更がすぐ反映されます（ホットリロード）。

```sh
flutter run -d windows   # macOS なら -d macos、Linux なら -d linux
```

### 5. 配布用（リリース版）のビルド

```sh
flutter build windows --release   # Windows
flutter build macos --release     # macOS
flutter build linux --release     # Linux
```

ビルド結果の場所は、[最初の表](#最初に知っておくこと) の「ビルド結果」の行を参照してください。

アプリのバージョン番号は `pubspec.yaml` の `version:`（例: `1.0.0+1`。`+` の後ろはビルド番号）で決まります。

---

## 配布用パッケージ（インストーラー）の作成

各 OS 向けの作成スクリプトは `installer/` にあります。どれも古いビルド結果を消してから（`flutter clean`）リリース版をビルドし、`build/installer/` に出力します。

| OS | 作るもの | コマンド | 出力 |
|---|---|---|---|
| Windows | インストーラー（Inno Setup） | `powershell -ExecutionPolicy Bypass -File installer\windows\build-installer.ps1` | `Colophon-Setup-<版>.exe` |
| macOS | ディスクイメージ | `bash installer/macos/build-dmg.sh` | `Colophon-<版>.dmg` |
| Linux | Flatpak | `bash installer/linux/build-flatpak.sh` | `Colophon-<版>.flatpak` |
| Linux | .deb（Ubuntu・Debian 系） | `bash installer/linux/build-deb.sh` | `colophon_<版>_<アーキテクチャ>.deb` |

版番号は `pubspec.yaml` の `version:` から取ります。

### Windows

- **追加で必要なもの**: Inno Setup 6（`winget install --id JRSoftware.InnoSetup -e --scope user` で、管理者権限なしで入れられる）。
- **インストール先**: 使う人ごと（`%LOCALAPPDATA%\Programs\Colophon`）。管理者権限は不要です。
- **VC++ ランタイム**: Visual Studio の再配布用フォルダから3つの DLL を同梱するので、ランタイムを入れていない PC でも起動できます。
- **アンインストール**: 「設定 → アプリ」から行います。最後に「書籍データも削除しますか？」と聞き、既定は「いいえ」（データを残す）です。画面を出さないアンインストール（`/SILENT` など）では、データは残します。

### macOS

- `.dmg` を開いて、Colophon を「Applications」へドラッグすればインストールできます。
- macOS にはアンインストーラーの仕組みがないため、データの消し方を記した `How to uninstall.txt` を `.dmg` に同梱します。消す場合は、アプリの「設定 → データ → すべてのデータを削除」を使うか、`~/Library/Containers/io.github.colophonbooks.colophon` を削除します。
- 署名・公証はしていません。広く配布する場合は Apple Developer Program への登録が必要です。

### Linux

| 形式 | 追加で必要なもの | インストール | アンインストール |
|---|---|---|---|
| Flatpak | `flatpak`、`flatpak-builder`、Flathub の登録 | `flatpak install --user Colophon-<版>.flatpak` | `flatpak uninstall --delete-data io.github.colophonbooks.colophon`（書籍データも消える） |
| .deb | `dpkg-deb`（Debian 系なら標準） | `sudo apt install ./colophon_<版>_amd64.deb` | `sudo apt remove colophon`（書籍データは残る） |

- `.deb` でアンインストールしても、書籍データ（`~/.local/share/io.github.colophonbooks.colophon`）は残ります。Debian の決まりで、パッケージは利用者のホームフォルダに触れないためです。消す場合は、先にアプリの「すべてのデータを削除」を使ってください。
- Flatpak 版のデータは `~/.var/app/io.github.colophonbooks.colophon` にあります。
- Flatpak の設定ファイルの `runtime-version` は、新しい版が出たら更新してください。

### アプリアイコンを作り直す

アイコンの図柄と色は `tool/icon/generate.mjs` に書いてあります。直したら次を実行すると、Windows（`.ico`）・macOS（`AppIcon.appiconset`）・Linux（`installer/linux/icons/`）のアイコンがまとめて作り直されます。書き出されたファイルもコミットしてください（アプリのビルドだけなら Node.js は不要です）。

```bash
npm install --prefix tool/icon      # 初回だけ。描画用の Chrome も自動で入る
node tool/icon/generate.mjs
```

- **必要なもの**: Node.js 18 以降。
- インストール済みの Chrome を使う場合は、環境変数 `CHROME_PATH` に Chrome の実行ファイルの場所を指定します。
- Windows のアイコンは前回のビルド結果に残りやすいため、作り直した後は `flutter clean` してからビルドしてください（配布用スクリプトは毎回 clean します）。

---
## Google ドライブ同期の設定（任意）

同期機能を使えるアプリをビルドするには、Google の OAuth クライアント ID が必要です。ID はリポジトリに含めず、ビルド時に渡します。渡さずにビルドしたアプリでは、設定画面の同期欄が「使えません」と表示されるだけで、ほかの機能はそのまま使えます。

### 1. Google Cloud でクライアントを作る

1. [Google Cloud コンソール](https://console.cloud.google.com/)でプロジェクトを作る
2. 「Google Drive API」を有効にする
3. 「Google Auth Platform」で、アプリ名・サポートのメールアドレスを入力し、対象を「外部」にする
4. 「データアクセス」で、スコープ `https://www.googleapis.com/auth/drive.appdata` だけを追加する
5. 「クライアント」で、種類が「デスクトップアプリ」のクライアントを作り、JSON をダウンロードする

`drive.appdata` は Google の区分で「非機密」のスコープです。デスクトップアプリのクライアントシークレットは、Google の説明どおり秘密として扱えない値で、Colophon は PKCE と組み合わせて使います。

### 2. 設定ファイルを用意する

リポジトリの外（例: `~/.colophon/dart-defines.json`。Windows では `%USERPROFILE%\.colophon\dart-defines.json`）に、次の形式で保存します。値は、ダウンロードした JSON の `client_id` と `client_secret` です。

```json
{
  "COLOPHON_GOOGLE_CLIENT_ID": "xxxxxxxx.apps.googleusercontent.com",
  "COLOPHON_GOOGLE_CLIENT_SECRET": "xxxxxxxx"
}
```

### 3. ビルド・起動のときに渡す

```sh
flutter run -d windows --dart-define-from-file=$HOME/.colophon/dart-defines.json
flutter build windows --release --dart-define-from-file=$HOME/.colophon/dart-defines.json
```

配布用パッケージの作成スクリプト（`installer/`）は、`~/.colophon/dart-defines.json` があれば自動で読み込みます。別の場所に置く場合は、環境変数 `COLOPHON_DART_DEFINES` にその場所を指定します。ファイルがなければ警告を出し、同期を使えないアプリを作ります。

### 4. 配布する前に

Google Auth Platform の「対象」で、公開ステータスを「テスト中」から「本番環境」に切り替えます。「テスト中」のままだと、テストユーザーに登録したアカウントしかログインできず、ログイン情報も7日で切れます。

### 試験用の本棚で動かす

開発中のアプリで普段の本棚を開くと、データベースが新しい版へ移行され、配布中の版で開けなくなることがあります。試すときは、ビルド時に `COLOPHON_DATA_DIR` で別のフォルダを指定します。

```sh
flutter run -d windows --dart-define-from-file=$HOME/.colophon/dart-defines.json \
  --dart-define=COLOPHON_DATA_DIR=$HOME/.colophon/pc-a
```

本棚・同期の記録・設定・Google のログイン情報を、普段の版とは別に保存します。フォルダ名ごとに分かれるので、フォルダ名を変えて2つビルドして同時に動かすと、1台のパソコンで2台分の同期を試せます。

---

## うまくいかないとき

| 症状 | 対処 |
|---|---|
| 何が足りないか分からない | `flutter doctor -v` を実行し、`[X]` や `[!]` の付いた項目の指示に従う |
| Windows で `Building with plugins requires symlink support.` と出る | 開発者モードを有効にする（[Windows の手順 3](#3-開発者モードを有効にする)） |
| Windows で `Unable to find suitable Visual Studio toolchain` と出る | Visual Studio Installer で「C++ によるデスクトップ開発」が入っているか確認する |
| Windows で `atlstr.h` が見つからないと出る | Visual Studio Installer で「最新の v143 ビルド ツール用 C++ ATL」を追加する（[Windows の手順 2](#2-visual-studio-2022-をインストールする)） |
| Linux で `libsecret` に関するエラーが出る | `libsecret-1-dev` を入れる（[Linux の手順 1](#1-必要なパッケージをインストールする)） |
| Flatpak の作成で `flatpak-builder: コマンドが見つかりません` と出る | `flatpak` と `flatpak-builder` を入れる（例: `sudo apt install flatpak flatpak-builder`）。ディストリビューションの版が古くて失敗する場合は、Flathub の `org.flatpak.Builder` を使う |
| Flatpak の作成で `Unable to load summary from remote flathub` と出る | `flatpak remotes --user -d` で flathub の URL を確認する。`https://dl.flathub.org/repo/` でなければ、`flatpak remote-delete --user flathub` で消してから、`flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo` で登録し直す（末尾の `flathub.flatpakrepo` まで含める） |
| 設定画面の同期欄が「このビルドでは同期を使えません」になる | クライアント ID を渡さずにビルドしている。[Google ドライブ同期の設定](#google-ドライブ同期の設定任意)を参照 |
| Linux で GTK や `pkg-config` に関するエラーが出る | [Linux の手順 1](#1-必要なパッケージをインストールする) のパッケージがすべて入っているか確認する |
| 以前は通ったビルドが急に失敗する | `flutter clean` → `flutter pub get` を実行してからビルドし直す |
| リリース版で、新しく使い始めたアイコン（★など）が表示されず空白になる | リリース版は使用中のアイコンだけを残すようにアイコン用フォントを小さくするが、繰り返しビルドすると古いフォントが使い回されることがある。`flutter clean` → `flutter pub get` を実行してからビルドし直す（デバッグ版や `flutter test` では起きない） |
| Flutter のバージョンが古いと言われる | `flutter upgrade` で stable の最新版に更新する |

アプリの機能やデータ形式については [README.ja.md](README.ja.md) を参照してください。
