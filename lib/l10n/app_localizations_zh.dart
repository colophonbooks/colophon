// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get ok => '确定';

  @override
  String get close => '关闭';

  @override
  String get add => '添加';

  @override
  String get rename => '重命名';

  @override
  String get continueLabel => '继续';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get discard => '放弃';

  @override
  String get keepEditing => '继续编辑';

  @override
  String get genericError => '出现错误。';

  @override
  String get processing => '正在处理…';

  @override
  String get chooseLanguageTitle => '选择语言';

  @override
  String get chooseLanguageNote => '之后可以在设置中更改。';

  @override
  String get searchTooltip => '搜索';

  @override
  String get showAsGridTooltip => '按封面显示';

  @override
  String get showAsListTooltip => '按书名显示';

  @override
  String get sortTooltip => '排序';

  @override
  String get sortRecent => '最近添加';

  @override
  String get sortTitle => '书名';

  @override
  String get menuTags => '管理标签';

  @override
  String get menuExport => '导出';

  @override
  String get menuImport => '导入';

  @override
  String get menuSettings => '设置';

  @override
  String get addBook => '添加书籍';

  @override
  String get emptyLibrary => '还没有书籍。\n点击 + 添加第一本书吧。';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已读完 $count 次',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get statusUnset => '未设置';

  @override
  String get statusUnread => '未读';

  @override
  String get statusReading => '在读';

  @override
  String get statusFinished => '已读完';

  @override
  String get categoryUnselected => '未分类';

  @override
  String get categoryImpression => '感想';

  @override
  String get categoryLearning => '收获';

  @override
  String get categoryMemo => '备忘';

  @override
  String get categoryExcerpt => '摘录';

  @override
  String get categoryOther => '其他';

  @override
  String get viewMode => '查看';

  @override
  String get editMode => '编辑';

  @override
  String get viewBookTitle => '书籍详情';

  @override
  String get saveAndView => '保存并查看';

  @override
  String get discardAndView => '放弃并查看';

  @override
  String get newBookTitle => '添加书籍';

  @override
  String get editBookTitle => '编辑书籍';

  @override
  String get fieldTitle => '书名';

  @override
  String get fieldAuthor => '作者';

  @override
  String get fieldTranslator => '译者';

  @override
  String get fieldSupervisor => '审校';

  @override
  String get fieldPublisher => '出版社';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => '版次';

  @override
  String get fieldStatus => '状态';

  @override
  String get fieldProgress => '阅读进度（%）';

  @override
  String get progressHint => '0–100（可选）';

  @override
  String get titleRequired => '请输入书名。';

  @override
  String get progressInvalid => '请输入 0 到 100 之间的整数。';

  @override
  String get pageInvalid => '请输入大于或等于 1 的整数。';

  @override
  String get isbnInvalidWarning => '此 ISBN 可能有误，但仍可保存。';

  @override
  String get isbnLookup => '通过 ISBN 获取书籍信息';

  @override
  String get isbnLookupInvalid => '请输入有效的 ISBN 以获取书籍信息。';

  @override
  String get coverSection => '封面';

  @override
  String get coverSelect => '选择图片';

  @override
  String get coverRemove => '移除图片';

  @override
  String coverResized(int width, int height) {
    return '图片已缩小为 $width × $height px。';
  }

  @override
  String get coverLoadFailed => '无法读取此图片。';

  @override
  String get readDatesSection => '读完日期';

  @override
  String get addReadDate => '添加日期';

  @override
  String get noReadDates => '暂无记录。';

  @override
  String get askAddReadDateTitle => '记录读完日期？';

  @override
  String askAddReadDateBody(String date) {
    return '是否将今天（$date）记录为读完这本书的日期？';
  }

  @override
  String get tagsSection => '标签';

  @override
  String get tagInputHint => '输入标签后按 Enter';

  @override
  String get notesSection => '笔记';

  @override
  String get addNote => '添加笔记';

  @override
  String get noteCategory => '分类';

  @override
  String get notePage => '页码';

  @override
  String get noteBody => '正文';

  @override
  String get noteBodyHint => '感想、收获、备忘、摘录…';

  @override
  String get noNotes => '还没有笔记。';

  @override
  String get addFavorite => '加入收藏';

  @override
  String get removeFavorite => '取消收藏';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get deleteNote => '删除笔记';

  @override
  String get deleteNoteConfirm => '删除这条笔记？';

  @override
  String get deleteBook => '删除书籍';

  @override
  String deleteBookConfirm(String title) {
    return '删除《$title》？此操作无法撤销。';
  }

  @override
  String get unsavedTitle => '放弃更改？';

  @override
  String get unsavedBody => '有尚未保存的更改。';

  @override
  String get saved => '已保存。';

  @override
  String get fieldCreatedAt => '添加日期';

  @override
  String get fieldUpdatedAt => '更新日期';

  @override
  String get lookupTitle => '通过 ISBN 找到的书籍信息';

  @override
  String lookupSource(String source) {
    return '来源：$source';
  }

  @override
  String get lookupNotFound => '未找到与此 ISBN 对应的书籍。';

  @override
  String get lookupFailed => '无法获取书籍信息。请检查网络连接。';

  @override
  String get lookupApply => '应用所选项';

  @override
  String lookupCurrent(String value) {
    return '当前：$value';
  }

  @override
  String get lookupRoleNote => '译者和审校可能无法被正确识别，请核对结果。';

  @override
  String get sourceNdl => '日本国立国会图书馆搜索';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => '美国国会图书馆';

  @override
  String get sourceBnf => '法国国家图书馆';

  @override
  String get sourceDnb => '德国国家图书馆';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '搜索书籍和笔记';

  @override
  String get searchConditions => '搜索条件';

  @override
  String get searchTargets => '搜索范围';

  @override
  String get targetNotes => '笔记正文';

  @override
  String get filterStatus => '状态';

  @override
  String get filterCategory => '笔记分类';

  @override
  String get filterFavorite => '收藏';

  @override
  String get favoriteNotesOnly => '仅显示收藏的笔记';

  @override
  String get filterTags => '标签（包含所有所选标签的书籍）';

  @override
  String get filterReadDate => '读完日期范围';

  @override
  String get dateFrom => '开始';

  @override
  String get dateTo => '结束';

  @override
  String get clearFilters => '清除条件';

  @override
  String get noResults => '没有符合条件的书籍或笔记。';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => '标签';

  @override
  String get noTags => '还没有标签。可在书籍的编辑页面添加标签。';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => '重命名标签';

  @override
  String get tagName => '标签名称';

  @override
  String get tagNameRequired => '请输入标签名称。';

  @override
  String get tagExists => '已存在同名标签。';

  @override
  String deleteTagConfirm(String name) {
    return '删除标签“$name”？所有书籍都将移除此标签。';
  }

  @override
  String get exportTitle => '导出';

  @override
  String get exportText => '文本';

  @override
  String get exportTextDesc => '便于阅读，但无法重新导入。';

  @override
  String get exportTextIncludeCovers => '同时导出封面（保存为 ZIP）';

  @override
  String get exportZip => 'JSON + 图片（ZIP）';

  @override
  String get exportZipDesc => '简单、开放的格式，可以导入。';

  @override
  String get exportSqlite => 'SQLite 数据库';

  @override
  String get exportSqliteDesc => '整个数据库的副本，可以导入。';

  @override
  String get exportDone => '已导出。';

  @override
  String get exportFailed => '导出失败。';

  @override
  String get exportEmpty => '没有可导出的书籍。';

  @override
  String get importTitle => '导入';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在文件中找到 $count 本书。',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => '全部替换';

  @override
  String get importModeReplaceDesc => '删除当前所有书籍，然后从文件恢复。';

  @override
  String get importModeMerge => '添加';

  @override
  String get importModeMergeDesc => '保留当前书籍并添加新书籍。已存在的书籍（ID 或 ISBN 相同）将被跳过。';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '当前登记的 $count 本书将全部被删除。是否继续？',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return '导入完成。已添加：$added 本 / 已跳过：$skipped 本';
  }

  @override
  String get importFailed => '无法导入此文件。';

  @override
  String get importInvalidFile => '此文件不包含 Colophon 数据。';

  @override
  String get importNewerVersion => '此文件由更新版本的 Colophon 创建。请更新应用。';

  @override
  String textExportHeader(String date) {
    return 'Colophon 导出（$date）';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsCover => '封面图片';

  @override
  String get settingsAutoResize => '自动缩小较大的封面图片';

  @override
  String get settingsAutoResizeDesc =>
      '添加时，超过 2000 px 或 2 MB 的图片会被缩小至长边 2000 px。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsColorTheme => '配色主题';

  @override
  String get settingsBrightness => '明暗';

  @override
  String get brightnessSystem => '跟随系统';

  @override
  String get brightnessLight => '浅色';

  @override
  String get brightnessDark => '深色';

  @override
  String get themeLeather => '皮革';

  @override
  String get themeForest => '森林';

  @override
  String get themeOcean => '海洋';

  @override
  String get themeRose => '玫瑰';

  @override
  String get themeMonochrome => '黑白';

  @override
  String get themeUniversal => '通用';

  @override
  String get themeUniversalDesc => '无论色觉类型如何都易于分辨的配色。';

  @override
  String get settingsData => '数据';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataDesc => '删除所有书籍、笔记、标签、读完日期以及显示语言等设置，恢复到初始状态。';

  @override
  String get deleteAllConfirmTitle => '要删除所有数据吗？';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已登记的 $count 本书及其笔记、标签、读完日期，以及所有设置都将被删除。',
    );
    return '$_temp0此操作无法撤销。如有需要保留的数据，请先导出。';
  }

  @override
  String get exportFirst => '先导出';

  @override
  String get proceedToDelete => '继续删除';

  @override
  String get deleteAllFinalTitle => '最终确认';

  @override
  String get deleteAllAcknowledge => '我明白删除的数据无法恢复';

  @override
  String get deleteAllButton => '全部删除';

  @override
  String get deleteAllDone => '已删除所有数据。';

  @override
  String get settingsAbout => '关于';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsDataSources => '书籍信息来源';

  @override
  String get settingsDataSourcesDesc =>
      '通过 ISBN 获取信息时，使用日本国立国会图书馆搜索、Open Library、美国国会图书馆、法国国家图书馆和德国国家图书馆。';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get settingsSync => '同步';

  @override
  String get syncGoogleDrive => '通过 Google 云端硬盘同步';

  @override
  String get syncDesc =>
      '在登录同一 Google 账号的各台设备之间保持书籍和笔记一致。数据保存在您的 Google 云端硬盘中仅供本应用使用的私有区域。';

  @override
  String get syncUnavailable => '此版本无法使用同步（构建时未包含 Google 登录设置）。';

  @override
  String get syncSignIn => '登录';

  @override
  String get syncSignOut => '退出登录';

  @override
  String syncSignedInAs(String email) {
    return '已登录：$email';
  }

  @override
  String get syncSignedIn => '已登录';

  @override
  String get syncSignInTitle => '在浏览器中登录';

  @override
  String get syncSignInBody =>
      '请在浏览器中选择您的 Google 账号，并允许 Colophon 访问。如果浏览器没有打开，或想使用其他浏览器，请复制链接并粘贴到浏览器中。';

  @override
  String get syncCopyLink => '复制链接';

  @override
  String get syncLinkCopied => '已复制链接';

  @override
  String get syncSignInDone => '已登录。';

  @override
  String get syncSignInDenied => '登录已取消。';

  @override
  String get syncSignInFailed => '无法登录。请检查网络连接后重试。';

  @override
  String get syncSignOutTitle => '要退出登录吗？';

  @override
  String get syncSignOutBody => '将停止此设备上的同步。此设备和 Google 云端硬盘中的数据都不会被删除。';

  @override
  String get syncBrowserPage => '已登录 Colophon。请关闭此标签页并返回应用。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncing => '正在同步…';

  @override
  String syncLastAt(String time) {
    return '上次同步：$time';
  }

  @override
  String get syncNever => '尚未同步';

  @override
  String get syncDone => '已同步。';

  @override
  String get syncFirstTitle => '首次同步';

  @override
  String syncFirstBody(int local, int remote) {
    return '此设备有$local本书，Google 云端硬盘中有$remote本书。请选择如何合并。同步前会自动保存此设备数据的备份。';
  }

  @override
  String get syncFirstMerge => '合并（推荐）';

  @override
  String get syncFirstMergeDesc => '保留双方的书籍。ISBN 相同的书籍合并为一本。';

  @override
  String get syncFirstUseRemote => '替换为 Google 云端硬盘的内容';

  @override
  String get syncFirstUseRemoteDesc => '仅存在于此设备的书籍和笔记将被删除。';

  @override
  String get syncFirstUseLocal => '替换为此设备的内容';

  @override
  String get syncFirstUseLocalDesc => '仅存在于 Google 云端硬盘的书籍和笔记将从所有同步的设备中删除。';

  @override
  String get syncFirstStart => '同步';

  @override
  String get syncErrorNetwork => '无法连接。请检查网络连接，稍后再试。';

  @override
  String get syncErrorAuth => 'Colophon 已无权使用您的 Google 云端硬盘。请退出登录后重新登录。';

  @override
  String get syncErrorNewerFormat => '这些数据由更新版本的 Colophon 同步。请更新应用。';

  @override
  String get syncErrorRemoteCorrupt => 'Google 云端硬盘中的同步数据已损坏，已停止同步。';

  @override
  String get syncErrorBusy => '另一台设备正在同时同步。请稍后再试。';

  @override
  String get syncErrorMissingCover => '部分封面图片尚未传到。请稍后再试。';

  @override
  String get syncErrorQuota => 'Google 云端硬盘的存储空间已满。';

  @override
  String get syncErrorLocalStorage => '无法保存到此设备。请检查可用存储空间。';

  @override
  String get syncErrorOther => '无法同步。';

  @override
  String get syncWarningUnreadable => 'Google 云端硬盘中的部分同步数据无法读取，因此此设备暂未发送更改。';

  @override
  String get deleteScopeTitle => '删除范围';

  @override
  String get deleteScopeThisPc => '仅此设备';

  @override
  String get deleteScopeThisPcDesc => '将关闭同步（退出登录）。Google 云端硬盘和其他设备上的数据会保留。';

  @override
  String get deleteScopeEverywhere => 'Google 云端硬盘和所有设备';

  @override
  String get deleteScopeEverywhereDesc => '其他设备也会在下次同步时删除书籍和笔记。';

  @override
  String get deleteEverywhereSyncFailed =>
      '无法连接 Google 云端硬盘，因此未删除任何内容。请检查网络连接后重试。';

  @override
  String get deleteEverywherePartial =>
      '已删除此设备上的书籍，但未能同步到 Google 云端硬盘。将在下次同步时同步。';

  @override
  String get deleteEverywhereProgress => '正在从 Google 云端硬盘删除…';

  @override
  String get bookDeletedElsewhere => '此书已在另一台设备上删除。';

  @override
  String get syncNeedsChoice => '需要选择首次同步的方式。请点击“立即同步”。';

  @override
  String get syncOnExitTitle => '正在与 Google 云端硬盘同步…';

  @override
  String get syncOnExitBody => '同步完成后将退出。';

  @override
  String get syncOnExitSkip => '不同步直接退出';

  @override
  String get sortStatusAscending => '状态（未设置→已读完）';

  @override
  String get sortStatusDescending => '状态（已读完→未设置）';

  @override
  String get coverFromCamera => '拍照';

  @override
  String get coverFromGallery => '从相册选择';

  @override
  String get cameraUnavailable => '无法使用相机。请确认已允许使用相机。';

  @override
  String get scanBarcode => '扫描条形码';

  @override
  String get scanBarcodeToAdd => '扫码添加';

  @override
  String get scanBarcodeHint => '请对准封底的 ISBN 条形码（以 978 或 979 开头）。如有两行，请对准上面一行。';

  @override
  String get flashlight => '手电筒';
}
