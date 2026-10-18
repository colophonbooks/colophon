// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get ok => 'OK';

  @override
  String get close => '閉じる';

  @override
  String get add => '追加';

  @override
  String get rename => '名前を変更';

  @override
  String get continueLabel => '続ける';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get discard => '破棄';

  @override
  String get keepEditing => '編集を続ける';

  @override
  String get genericError => 'エラーが発生しました。';

  @override
  String get processing => '処理中…';

  @override
  String get chooseLanguageTitle => '表示言語を選んでください';

  @override
  String get chooseLanguageNote => 'あとから設定画面で変更できます。';

  @override
  String get searchTooltip => '検索';

  @override
  String get showAsGridTooltip => '書影で表示';

  @override
  String get showAsListTooltip => '書籍名で表示';

  @override
  String get sortTooltip => '並び替え';

  @override
  String get sortRecent => '登録日の新しい順';

  @override
  String get sortTitle => '書籍名順';

  @override
  String get menuTags => 'タグの管理';

  @override
  String get menuExport => 'エクスポート';

  @override
  String get menuImport => 'インポート';

  @override
  String get menuSettings => '設定';

  @override
  String get addBook => '書籍を追加';

  @override
  String get emptyLibrary => 'まだ書籍がありません。\n＋ボタンから最初の一冊を登録しましょう。';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回読了',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get statusUnset => '未設定';

  @override
  String get statusUnread => '未読';

  @override
  String get statusReading => '読書中';

  @override
  String get statusFinished => '読了';

  @override
  String get categoryUnselected => '分類なし';

  @override
  String get categoryImpression => '感想';

  @override
  String get categoryLearning => '学び';

  @override
  String get categoryMemo => 'メモ';

  @override
  String get categoryExcerpt => '抜粋';

  @override
  String get categoryOther => 'その他';

  @override
  String get viewMode => '表示';

  @override
  String get editMode => '編集';

  @override
  String get viewBookTitle => '書籍の詳細';

  @override
  String get saveAndView => '保存して表示';

  @override
  String get discardAndView => '破棄して表示';

  @override
  String get newBookTitle => '書籍の登録';

  @override
  String get editBookTitle => '書籍の編集';

  @override
  String get fieldTitle => '書籍名';

  @override
  String get fieldAuthor => '著者';

  @override
  String get fieldTranslator => '翻訳者';

  @override
  String get fieldSupervisor => '監修';

  @override
  String get fieldPublisher => '出版社';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => '版数';

  @override
  String get fieldStatus => 'ステータス';

  @override
  String get fieldProgress => '読んだ割合（%）';

  @override
  String get progressHint => '0〜100（任意）';

  @override
  String get titleRequired => '書籍名を入力してください。';

  @override
  String get progressInvalid => '0〜100の整数で入力してください。';

  @override
  String get pageInvalid => '1以上の整数で入力してください。';

  @override
  String get isbnInvalidWarning => 'ISBNが正しくない可能性があります。このまま保存もできます。';

  @override
  String get isbnLookup => 'ISBNから書籍情報を取得';

  @override
  String get isbnLookupInvalid => '書籍情報を取得するには、正しいISBNを入力してください。';

  @override
  String get coverSection => '書影';

  @override
  String get coverSelect => '画像を選択';

  @override
  String get coverRemove => '画像を削除';

  @override
  String coverResized(int width, int height) {
    return '画像を $width × $height px に縮小しました。';
  }

  @override
  String get coverLoadFailed => 'この画像は読み込めませんでした。';

  @override
  String get readDatesSection => '読了日';

  @override
  String get addReadDate => '日付を追加';

  @override
  String get noReadDates => 'まだ記録がありません。';

  @override
  String get askAddReadDateTitle => '読了日を記録しますか？';

  @override
  String askAddReadDateBody(String date) {
    return '今日（$date）の日付で読了記録を追加しますか？';
  }

  @override
  String get tagsSection => 'タグ';

  @override
  String get tagInputHint => 'タグを入力して Enter';

  @override
  String get notesSection => 'ノート';

  @override
  String get addNote => 'ノートを追加';

  @override
  String get noteCategory => '分類';

  @override
  String get notePage => 'ページ';

  @override
  String get noteBody => '本文';

  @override
  String get noteBodyHint => '感想、学んだこと、メモ、抜粋など';

  @override
  String get noNotes => 'まだノートがありません。';

  @override
  String get addFavorite => 'お気に入りに追加';

  @override
  String get removeFavorite => 'お気に入りから外す';

  @override
  String get moveUp => '上へ移動';

  @override
  String get moveDown => '下へ移動';

  @override
  String get deleteNote => 'ノートを削除';

  @override
  String get deleteNoteConfirm => 'このノートを削除しますか？';

  @override
  String get deleteBook => '書籍を削除';

  @override
  String deleteBookConfirm(String title) {
    return '「$title」を削除しますか？この操作は取り消せません。';
  }

  @override
  String get unsavedTitle => '変更を破棄しますか？';

  @override
  String get unsavedBody => '保存していない変更があります。';

  @override
  String get saved => '保存しました。';

  @override
  String get fieldCreatedAt => '登録日';

  @override
  String get fieldUpdatedAt => '更新日';

  @override
  String get lookupTitle => 'ISBNから取得した書籍情報';

  @override
  String lookupSource(String source) {
    return '取得元：$source';
  }

  @override
  String get lookupNotFound => 'このISBNの書籍は見つかりませんでした。';

  @override
  String get lookupFailed => '書籍情報を取得できませんでした。インターネット接続を確認してください。';

  @override
  String get lookupApply => '選んだ項目を反映';

  @override
  String lookupCurrent(String value) {
    return '現在：$value';
  }

  @override
  String get lookupRoleNote => '翻訳者・監修は正しく判別できない場合があります。内容を確認してください。';

  @override
  String get sourceNdl => '国立国会図書館サーチ';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => '米国議会図書館';

  @override
  String get sourceBnf => 'フランス国立図書館';

  @override
  String get sourceDnb => 'ドイツ国立図書館';

  @override
  String get searchTitle => '検索';

  @override
  String get searchHint => '書籍とノートを検索';

  @override
  String get searchConditions => '検索条件';

  @override
  String get searchTargets => '検索対象';

  @override
  String get targetNotes => 'ノート本文';

  @override
  String get filterStatus => 'ステータス';

  @override
  String get filterCategory => 'ノートの分類';

  @override
  String get filterFavorite => 'お気に入り';

  @override
  String get favoriteNotesOnly => 'お気に入りのノートだけ';

  @override
  String get filterTags => 'タグ（選んだタグをすべて持つ書籍）';

  @override
  String get filterReadDate => '読了日の期間';

  @override
  String get dateFrom => '開始';

  @override
  String get dateTo => '終了';

  @override
  String get clearFilters => '条件をクリア';

  @override
  String get noResults => '条件に合う書籍・ノートはありません。';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count冊',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'タグ';

  @override
  String get noTags => 'タグはまだありません。書籍の編集画面でタグを付けられます。';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count冊',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => 'タグ名の変更';

  @override
  String get tagName => 'タグ名';

  @override
  String get tagNameRequired => 'タグ名を入力してください。';

  @override
  String get tagExists => '同じ名前のタグがすでにあります。';

  @override
  String deleteTagConfirm(String name) {
    return 'タグ「$name」を削除しますか？すべての書籍からこのタグが外れます。';
  }

  @override
  String get exportTitle => 'エクスポート';

  @override
  String get exportText => 'テキスト';

  @override
  String get exportTextDesc => '人が読むための形式です。インポートには使えません。';

  @override
  String get exportTextIncludeCovers => '書影も含める（ZIPで保存）';

  @override
  String get exportZip => 'JSON＋画像（ZIP）';

  @override
  String get exportZipDesc => 'シンプルで扱いやすい形式です。インポートできます。';

  @override
  String get exportSqlite => 'SQLiteデータベース';

  @override
  String get exportSqliteDesc => 'データベース全体のコピーです。インポートできます。';

  @override
  String get exportDone => 'エクスポートしました。';

  @override
  String get exportFailed => 'エクスポートに失敗しました。';

  @override
  String get exportEmpty => 'エクスポートする書籍がありません。';

  @override
  String get importTitle => 'インポート';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ファイルに$count冊の書籍が見つかりました。',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => 'すべて置き換える';

  @override
  String get importModeReplaceDesc => '現在の書籍をすべて削除してから、ファイルの内容で復元します。';

  @override
  String get importModeMerge => '追加する';

  @override
  String get importModeMergeDesc =>
      '現在の書籍は残したまま追加します。すでにある書籍（IDまたはISBNが同じもの）はスキップします。';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '現在登録されている$count冊はすべて削除されます。続けますか？',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return 'インポートが完了しました。追加：$added冊／スキップ：$skipped冊';
  }

  @override
  String get importFailed => 'このファイルはインポートできませんでした。';

  @override
  String get importInvalidFile => 'このファイルには Colophon のデータが含まれていません。';

  @override
  String get importNewerVersion =>
      'このファイルは新しいバージョンの Colophon で作成されています。アプリを更新してください。';

  @override
  String textExportHeader(String date) {
    return 'Colophon エクスポート（$date）';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count冊',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '表示言語';

  @override
  String get settingsCover => '書影';

  @override
  String get settingsAutoResize => '大きな書影を自動で縮小する';

  @override
  String get settingsAutoResizeDesc =>
      '登録時に、2000pxまたは2MBを超える画像を長辺2000pxに縮小します。';

  @override
  String get settingsAppearance => '表示';

  @override
  String get settingsColorTheme => '配色テーマ';

  @override
  String get settingsBrightness => '明るさ';

  @override
  String get brightnessSystem => 'OSに合わせる';

  @override
  String get brightnessLight => '明るい';

  @override
  String get brightnessDark => '暗い';

  @override
  String get themeLeather => 'レザー';

  @override
  String get themeForest => 'フォレスト';

  @override
  String get themeOcean => 'オーシャン';

  @override
  String get themeRose => 'ローズ';

  @override
  String get themeMonochrome => 'モノクロ';

  @override
  String get themeUniversal => 'ユニバーサル';

  @override
  String get themeUniversalDesc => '色覚の違いにかかわらず見分けやすい配色です。';

  @override
  String get settingsData => 'データ';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get deleteAllDataDesc => '書籍・ノート・タグ・読了日と、表示言語などの設定をすべて削除し、最初の状態に戻します。';

  @override
  String get deleteAllConfirmTitle => 'すべてのデータを削除しますか？';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '登録した$count冊の書籍とノート・タグ・読了日、設定がすべて削除されます。',
    );
    return '$_temp0この操作は取り消せません。残したいデータがあれば、先にエクスポートしてください。';
  }

  @override
  String get exportFirst => '先にエクスポート';

  @override
  String get proceedToDelete => '削除へ進む';

  @override
  String get deleteAllFinalTitle => '最終確認';

  @override
  String get deleteAllAcknowledge => '削除したデータは元に戻せないことを理解しました';

  @override
  String get deleteAllButton => 'すべて削除';

  @override
  String get deleteAllDone => 'すべてのデータを削除しました。';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String settingsVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get settingsDataSources => '書籍情報の取得元';

  @override
  String get settingsDataSourcesDesc =>
      'ISBNからの取得には、国立国会図書館サーチ、Open Library、米国議会図書館、フランス国立図書館、ドイツ国立図書館を使用しています。';

  @override
  String get settingsLicenses => 'オープンソースライセンス';

  @override
  String get settingsSync => '同期';

  @override
  String get syncGoogleDrive => 'Google ドライブで同期';

  @override
  String get syncDesc =>
      '同じ Google アカウントでログインしたパソコンどうしで、書籍とノートを揃えます。データは、あなたの Google ドライブの中にある、このアプリ専用の非公開の領域に保存されます。';

  @override
  String get syncUnavailable => 'このビルドでは同期を使えません（Google ログインの設定を含めずに作られています）。';

  @override
  String get syncSignIn => 'ログイン';

  @override
  String get syncSignOut => 'ログアウト';

  @override
  String syncSignedInAs(String email) {
    return 'ログイン中: $email';
  }

  @override
  String get syncSignedIn => 'ログイン中';

  @override
  String get syncSignInTitle => 'ブラウザでログイン';

  @override
  String get syncSignInBody =>
      'ブラウザで Google アカウントを選び、Colophon へのアクセスを許可してください。ブラウザが開かないときや、別のブラウザで開きたいときは、リンクをコピーして貼り付けてください。';

  @override
  String get syncCopyLink => 'リンクをコピー';

  @override
  String get syncLinkCopied => 'リンクをコピーしました';

  @override
  String get syncSignInDone => 'ログインしました。';

  @override
  String get syncSignInDenied => 'ログインが取り消されました。';

  @override
  String get syncSignInFailed => 'ログインできませんでした。ネットワークの接続を確認して、もう一度お試しください。';

  @override
  String get syncSignOutTitle => 'ログアウトしますか？';

  @override
  String get syncSignOutBody =>
      'このパソコンでの同期を止めます。このパソコンと Google ドライブのデータは、どちらも削除されません。';

  @override
  String get syncBrowserPage => 'Colophon にログインしました。このタブを閉じて、アプリに戻ってください。';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncing => '同期中…';

  @override
  String syncLastAt(String time) {
    return '最終同期: $time';
  }

  @override
  String get syncNever => 'まだ同期していません';

  @override
  String get syncDone => '同期しました。';

  @override
  String get syncFirstTitle => '初めての同期';

  @override
  String syncFirstBody(int local, int remote) {
    return 'このパソコンに$local冊、Google ドライブに$remote冊の書籍があります。どのように合わせるか選んでください。同期の前に、このパソコンのデータのバックアップを自動で保存します。';
  }

  @override
  String get syncFirstMerge => '統合する（おすすめ）';

  @override
  String get syncFirstMergeDesc => '両方の書籍を残します。ISBN が同じ書籍は1冊にまとめます。';

  @override
  String get syncFirstUseRemote => 'Google ドライブの内容に置き換える';

  @override
  String get syncFirstUseRemoteDesc => 'このパソコンだけにある書籍とノートは削除されます。';

  @override
  String get syncFirstUseLocal => 'このパソコンの内容に置き換える';

  @override
  String get syncFirstUseLocalDesc =>
      'Google ドライブだけにある書籍とノートは、同期しているすべてのパソコンから削除されます。';

  @override
  String get syncFirstStart => '同期する';

  @override
  String get syncErrorNetwork =>
      '接続できませんでした。ネットワークの接続を確認して、しばらくしてからもう一度お試しください。';

  @override
  String get syncErrorAuth =>
      'Google ドライブを使う許可が無効になっています。いったんログアウトして、もう一度ログインしてください。';

  @override
  String get syncErrorNewerFormat =>
      '新しいバージョンの Colophon で同期されたデータです。アプリを最新版に更新してください。';

  @override
  String get syncErrorRemoteCorrupt => 'Google ドライブの同期データが壊れているため、同期を中止しました。';

  @override
  String get syncErrorBusy => 'ほかのパソコンの同期と重なりました。しばらくしてからもう一度お試しください。';

  @override
  String get syncErrorMissingCover => '表紙の画像がまだ届いていません。しばらくしてからもう一度お試しください。';

  @override
  String get syncErrorQuota => 'Google ドライブの空き容量が足りません。';

  @override
  String get syncErrorLocalStorage => 'このパソコンへの保存に失敗しました。ディスクの空き容量を確認してください。';

  @override
  String get syncErrorOther => '同期できませんでした。';

  @override
  String get syncWarningUnreadable =>
      'Google ドライブの同期データの一部が読めなかったため、このパソコンからの送信を見合わせました。';

  @override
  String get deleteScopeTitle => '削除する範囲';

  @override
  String get deleteScopeThisPc => 'このパソコンだけ';

  @override
  String get deleteScopeThisPcDesc =>
      '同期をオフにします（ログアウトします）。Google ドライブとほかのパソコンのデータは残ります。';

  @override
  String get deleteScopeEverywhere => 'Google ドライブとすべてのパソコン';

  @override
  String get deleteScopeEverywhereDesc => 'ほかのパソコンでも、次の同期のときに書籍とノートが削除されます。';

  @override
  String get deleteEverywhereSyncFailed =>
      'Google ドライブに接続できなかったため、何も削除していません。ネットワークの接続を確認して、もう一度お試しください。';

  @override
  String get deleteEverywherePartial =>
      'このパソコンの書籍は削除しましたが、Google ドライブへの反映に失敗しました。次の同期で反映されます。';

  @override
  String get deleteEverywhereProgress => 'Google ドライブから削除しています…';

  @override
  String get bookDeletedElsewhere => 'この書籍は、ほかのパソコンで削除されました。';

  @override
  String get syncNeedsChoice => '初めての同期の方法を選ぶ必要があります。「今すぐ同期」を押してください。';

  @override
  String get syncOnExitTitle => 'Google ドライブと同期しています…';

  @override
  String get syncOnExitBody => '同期が終わったら終了します。';

  @override
  String get syncOnExitSkip => '同期せずに終了';

  @override
  String get sortStatusAscending => 'ステータス順（未設定→読了）';

  @override
  String get sortStatusDescending => 'ステータス順（読了→未設定）';
}
