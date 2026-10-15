# Colophon

日本語 | [English](README.md)

本好きのための書籍管理アプリです。蔵書の登録、読書ステータス、書影、ノート（感想・学び・メモ・抜粋）、タグ、読了日を管理できます。

- 対応OS: Windows / macOS / Linux（iPhone / iPad / Android は今後対応予定）
- 表示言語: English / 日本語 / 简体中文 / Français / Español / Deutsch / 한국어

## 主な機能

| 機能 | 内容 |
|---|---|
| 書籍の登録 | 書籍名（必須）、著者、翻訳者、監修、出版社、ISBN、版数 |
| ISBN から取得 | ISBN の国番号に応じて各国の国立図書館と Open Library に問い合わせ（日本→国立国会図書館、フランス→フランス国立図書館など）、反映する項目を選べます |
| 書影 | 画像を手動で設定。大きな画像（長辺2000px超または2MB超）は自動で縮小（設定で無効化可） |
| ビューアモード | 書籍を見る専用で表示。入力済みの項目と、分類・ページ付きのノートだけをすっきり表示し、必要なときに編集モードへ切り替え |
| 一覧 | 書籍名の一覧／書影の一覧を切り替え。登録日の新しい順・書籍名順で並べ替え |
| ステータス | 未設定（初期値）・未読・読書中・読了。読書中は読んだ割合（%）を任意で入力 |
| 読了日 | 複数回の読了を記録。2回以上読んだ本は一覧に回数を表示 |
| ノート | 何件でも追加可。分類（感想・学び・メモ・抜粋・その他／なし）とページは任意。お気に入り（★）を付けて、あとから絞り込める |
| タグ | 1冊に複数。タグ管理画面で名前の変更・削除 |
| 検索 | 書籍情報とノート本文を検索。検索対象・ステータス・ノート分類・タグ・読了日で絞り込み |
| エクスポート | テキスト（読む用。書影を含めて ZIP にすることも可）、JSON＋画像（ZIP）、SQLite |
| インポート | ZIP または SQLite から「すべて置き換える」か「追加する（重複はスキップ）」で復元 |
| データの削除 | 設定画面から、書籍・ノート・設定をすべて削除して最初の状態に戻せる（二段階の確認つき） |
| 表示 | 配色テーマ6種類（レザー・フォレスト・オーシャン・ローズ・モノクロ・色覚に配慮したユニバーサル）と明るさ（OSに合わせる／明るい／暗い） |
| 同期（任意） | ご自身の Google ドライブを通して、複数のパソコンで同じ本棚を使えます。設定画面で Google にログインするまでは無効で、ログイン後は自動で同期します |

## 開発環境

Flutter 3.47 以降（stable）でビルドします。各OSの環境の作り方とビルドの詳しい手順は [BUILDING.ja.md](BUILDING.ja.md)、設計書は [docs/design/](docs/design/basic-design.ja.md) を参照してください。

```sh
flutter pub get
flutter run -d windows        # 開発中の起動
flutter test                  # 自動テスト
flutter build windows         # 配布用ビルド → build/windows/x64/runner/Release/
```

Google ドライブ同期を使うには、ビルド時に Google の OAuth クライアント ID を渡す必要があります。渡さずにビルドしたアプリでは、同期が「使えません」と表示されるだけです。[BUILDING.ja.md](BUILDING.ja.md) の「Google ドライブ同期」を参照してください。

## フォルダ構成

```
lib/
  main.dart / app.dart     起動処理・アプリ全体の設定
  models/                  データの型（書籍・ノート・読了日など）
  data/                    SQLite のスキーマと読み書き
  services/                画面に依存しない処理（ISBN・書影・検索・エクスポート/インポート・ISBN取得・Google ログイン）
  sync/                    Google ドライブ同期（データ形式・統合の規則・Drive との通信・同期の手順）
  state/                   画面が参照する状態（設定・書籍一覧・同期）
  ui/                      画面
  l10n/                    表示言語ごとの文言（app_*.arb）
test/                      自動テスト
```

## データの保存場所

アプリ用のフォルダに `colophon.db`（SQLite）として保存します。

- Windows: `%APPDATA%\colophonbooks\Colophon\`
- macOS: `~/Library/Containers/io.github.colophonbooks.colophon/Data/Library/Application Support/io.github.colophonbooks.colophon/`
- Linux: `~/.local/share/io.github.colophonbooks.colophon/`（Flatpak 版は `~/.var/app/io.github.colophonbooks.colophon/`）

Google ドライブ同期を使うと、同じフォルダに `sync-state.json`（このパソコンで最後に同期した日時など）と `sync-backups/`（初めての同期の前に自動で取るバックアップ。エクスポートと同じ ZIP 形式で、新しいもの3つを残す）も作られます。Google のログイン情報は OS の安全な保管場所に保存します（Windows: 同じフォルダの暗号化されたファイル、macOS: キーチェーン、Linux: デスクトップの鍵束）。

### データの削除

アプリの「設定 → データ → すべてのデータを削除」で、書籍・ノート・設定をすべて消して最初の状態に戻せます（二段階で確認します）。同期のためにログインしている場合は、「このパソコンだけ」（同期をオフにします。Google ドライブとほかのパソコンのデータは残ります）か「Google ドライブとすべてのパソコン」かを選びます。

Google ドライブ上のデータだけを消すには、ブラウザで Google ドライブを開き、設定の「アプリを管理」で Colophon の「オプション」から、非表示のアプリデータを削除します（英語の画面では Manage apps → Options → Delete hidden app data。日本語の画面の表記は、時期によって異なる場合があります）。

アンインストール時の扱いは OS によって違います。

| 配布形式 | アンインストール時の書籍データ |
|---|---|
| Windows インストーラー | 削除するか確認する（既定は残す） |
| macOS（.dmg） | 残る。アプリ内の削除機能か、上のフォルダの削除で消す |
| Linux Flatpak | `flatpak uninstall --delete-data` で一緒に消える |
| Linux .deb | 残る。アプリ内の削除機能か、上のフォルダの削除で消す |

配布用パッケージの作り方は [BUILDING.ja.md](BUILDING.ja.md) を参照してください。

表示言語や自動縮小の設定は端末ごとの設定として別に保存し、エクスポートには含めません。

## エクスポート形式（JSON＋画像）

ZIP の中身は次のとおりです。

```
books.json
covers/{uuid}.jpg    （書影がある書籍のみ。拡張子は画像形式に合わせる）
```

```json
{
  "format": "colophon",
  "version": 1,
  "exportedAt": "2026-10-14T03:00:00.000Z",
  "books": [
    {
      "uuid": "…",
      "title": "サピエンス全史",
      "author": "ユヴァル・ノア・ハラリ",
      "translator": "柴田裕之",
      "supervisor": null,
      "publisher": "河出書房新社",
      "isbn": "978-4-309-22671-2",
      "edition": null,
      "status": "reading",
      "progress": 40,
      "cover": "covers/….jpg",
      "tags": ["歴史"],
      "readDates": ["2026-01-02"],
      "notes": [
        { "uuid": "…", "category": "learning", "page": 30, "body": "…", "favorite": true, "createdAt": "…", "updatedAt": "…" }
      ],
      "createdAt": "…",
      "updatedAt": "…"
    }
  ]
}
```

- `status`: `unset` / `unread` / `reading` / `finished`
- `category`: `impression` / `learning` / `memo` / `excerpt` / `other` / `null`（分類なし）
- 日時は UTC の ISO 8601、読了日は `yyyy-MM-dd`
- 書籍とノートの `uuid` は端末をまたいで同じものを指す ID（ノートの `uuid` がない古いファイルも読み込めます）
- `favorite`: ノートがお気に入りかどうか（項目がなければ `false`）

## Google ドライブ同期

同じ Google アカウントでログインしたパソコンどうしで、同じ本棚を使えるようにする機能です。有効にするまでは動きません。

**有効にするには**: 「設定 → 同期 → ログイン」を押し、ブラウザで Google アカウントを選んで許可すると、すぐに最初の同期が始まります。このパソコンと Google ドライブの両方にすでに本がある場合は、「統合する」（ISBN が同じ本は1冊にまとめる）、「Google ドライブの内容に置き換える」、「このパソコンの内容に置き換える」から選びます。何かを変える前に、このパソコンの本棚のバックアップを保存します。

**同期するもの**: 書籍、ノート、タグ、読了日、書影。表示言語や配色テーマなどの設定は、パソコンごとのままです。

**同期のタイミング**: アプリの起動から数秒後、最後の変更から30秒後（編集を続けている場合も、最初の変更から最長5分後）、送っていない変更があるときはアプリの終了前、「今すぐ同期」を押したとき。通信できないなどの一時的な失敗は、自動で再試行します。

**2台で同じ本を変えていた場合**: 書籍ごと・ノートごとに、後から保存した方を採用します。別々のパソコンで足したノートは、両方残ります。削除も、ほかのパソコンに伝わります。

**プライバシー**:

- データは、ご自身の Google ドライブにだけ送られます。Colophon は独自のサーバーを持ちません
- Google ドライブの「アプリの非表示データ」の領域に保存します。ドライブのファイル一覧には表示されず、Colophon 以外からは開けません
- Colophon が求める権限は、自身の非表示データ領域の読み書き（`drive.appdata`）だけです。ほかのファイルは見えません
- 「ログアウト」すると、そのパソコンでの同期を止め、Colophon のアクセス許可を取り消します。パソコンにも Google ドライブにも、データは残ります

仕組みの概要:

- 書籍・ノートを削除しても行は残し、`deleted_at` に削除日時を記録する（削除をほかの端末へ伝えるため）。中身（書影・本文）は消す
- 書籍・ノートは `uuid` で同一性を判定し、`updated_at` で新旧を比べる。時刻は Google のサーバー時刻との差で補正する
- タグの名前変更・削除は、そのタグが付いた書籍の `updated_at` を更新する（タグは書籍と一緒に伝わる）
- Google ドライブには、全記録をまとめた1ファイル（`colophon-sync.json`）と、書影ごとに SHA-256 を名前にした1ファイルずつを置く。変わった書影だけをやり取りするため
- 送る前に、ほかのパソコンがその間に送っていないかを確かめ、送っていれば統合し直してから送る

## 表示言語を追加するには

1. `lib/l10n/app_en.arb` をコピーして `app_{言語コード}.arb` を作り、訳文を入れる
2. `lib/state/settings_controller.dart` の `supportedLanguages` に1行追加する
3. `flutter gen-l10n`（`flutter run` でも自動生成されます）

## 書籍情報の取得元

ISBN からの取得には、次の公開 API（登録不要）を使用しています。取得結果には出典を表示します。

- [国立国会図書館サーチ](https://ndlsearch.ndl.go.jp/)
- [Open Library](https://openlibrary.org/developers/api)
- [米国議会図書館](https://www.loc.gov/)（SRU）
- [フランス国立図書館](https://catalogue.bnf.fr/)（SRU。データは Licence Ouverte）
- [ドイツ国立図書館](https://www.dnb.de/)（SRU。データは CC0）

## AI の利用について

Colophon は、AI によるコーディング支援（Anthropic の Claude。Claude Code を使用）を受けて開発しています。コードと文書の大部分は AI が下書きしたものです。すべての変更はメンテナーが確認・試験して採否を決め、プロジェクトの責任はメンテナーが負います。

AI の支援を受けたコミットには、その旨を示す `Co-Authored-By:` 行を末尾に付けています。最初のコミットにはこの行がありませんが、同じく大部分を AI の支援で作成しています。

## ライセンス

Colophon は [MIT ライセンス](LICENSE) で公開しています。使用しているサードパーティのパッケージには、それぞれのライセンス（BSD-3-Clause・MIT・Apache-2.0・MPL-2.0）が適用されます。それらの表記はアプリに同梱しており、**設定 → オープンソースライセンス** で確認できます。
