// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get ok => '확인';

  @override
  String get close => '닫기';

  @override
  String get add => '추가';

  @override
  String get rename => '이름 변경';

  @override
  String get continueLabel => '계속';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get discard => '버리기';

  @override
  String get keepEditing => '계속 편집';

  @override
  String get genericError => '문제가 발생했어요.';

  @override
  String get processing => '처리 중…';

  @override
  String get chooseLanguageTitle => '언어를 선택하세요';

  @override
  String get chooseLanguageNote => '나중에 설정에서 변경할 수 있어요.';

  @override
  String get searchTooltip => '검색';

  @override
  String get showAsGridTooltip => '표지로 보기';

  @override
  String get showAsListTooltip => '제목으로 보기';

  @override
  String get sortTooltip => '정렬';

  @override
  String get sortRecent => '최근 추가순';

  @override
  String get sortTitle => '제목순';

  @override
  String get menuTags => '태그 관리';

  @override
  String get menuExport => '내보내기';

  @override
  String get menuImport => '가져오기';

  @override
  String get menuSettings => '설정';

  @override
  String get addBook => '책 추가';

  @override
  String get emptyLibrary => '아직 책이 없어요.\n+ 버튼을 눌러 첫 책을 추가해 보세요.';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회 완독',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get statusUnset => '미설정';

  @override
  String get statusUnread => '읽지 않음';

  @override
  String get statusReading => '읽는 중';

  @override
  String get statusFinished => '완독';

  @override
  String get categoryUnselected => '분류 없음';

  @override
  String get categoryImpression => '감상';

  @override
  String get categoryLearning => '배운 점';

  @override
  String get categoryMemo => '메모';

  @override
  String get categoryExcerpt => '발췌';

  @override
  String get categoryOther => '기타';

  @override
  String get viewMode => '보기';

  @override
  String get editMode => '편집';

  @override
  String get viewBookTitle => '책 정보';

  @override
  String get saveAndView => '저장하고 보기';

  @override
  String get discardAndView => '버리고 보기';

  @override
  String get newBookTitle => '새 책';

  @override
  String get editBookTitle => '책 편집';

  @override
  String get fieldTitle => '제목';

  @override
  String get fieldAuthor => '저자';

  @override
  String get fieldTranslator => '번역';

  @override
  String get fieldSupervisor => '감수';

  @override
  String get fieldPublisher => '출판사';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => '판';

  @override
  String get fieldStatus => '상태';

  @override
  String get fieldProgress => '진행률(%)';

  @override
  String get progressHint => '0–100(선택)';

  @override
  String get titleRequired => '제목을 입력하세요.';

  @override
  String get progressInvalid => '0부터 100 사이의 정수를 입력하세요.';

  @override
  String get pageInvalid => '1 이상의 정수를 입력하세요.';

  @override
  String get isbnInvalidWarning => 'ISBN이 올바르지 않을 수 있어요. 그래도 저장할 수 있어요.';

  @override
  String get isbnLookup => 'ISBN으로 책 정보 가져오기';

  @override
  String get isbnLookupInvalid => '책 정보를 가져오려면 올바른 ISBN을 입력하세요.';

  @override
  String get coverSection => '표지';

  @override
  String get coverSelect => '이미지 선택';

  @override
  String get coverRemove => '이미지 삭제';

  @override
  String coverResized(int width, int height) {
    return '이미지를 $width × $height px로 줄였어요.';
  }

  @override
  String get coverLoadFailed => '이 이미지를 읽을 수 없어요.';

  @override
  String get readDatesSection => '완독일';

  @override
  String get addReadDate => '날짜 추가';

  @override
  String get noReadDates => '아직 기록이 없어요.';

  @override
  String get askAddReadDateTitle => '완독일을 기록할까요?';

  @override
  String askAddReadDateBody(String date) {
    return '오늘($date)을 이 책의 완독일로 추가할까요?';
  }

  @override
  String get tagsSection => '태그';

  @override
  String get tagInputHint => '태그를 입력하고 Enter를 누르세요';

  @override
  String get notesSection => '노트';

  @override
  String get addNote => '노트 추가';

  @override
  String get noteCategory => '분류';

  @override
  String get notePage => '페이지';

  @override
  String get noteBody => '본문';

  @override
  String get noteBodyHint => '감상, 배운 점, 메모, 발췌…';

  @override
  String get noNotes => '아직 노트가 없어요.';

  @override
  String get addFavorite => '즐겨찾기에 추가';

  @override
  String get removeFavorite => '즐겨찾기에서 제거';

  @override
  String get moveUp => '위로 이동';

  @override
  String get moveDown => '아래로 이동';

  @override
  String get deleteNote => '노트 삭제';

  @override
  String get deleteNoteConfirm => '이 노트를 삭제할까요?';

  @override
  String get deleteBook => '책 삭제';

  @override
  String deleteBookConfirm(String title) {
    return '‘$title’을(를) 삭제할까요? 이 작업은 되돌릴 수 없어요.';
  }

  @override
  String get unsavedTitle => '변경 사항을 버릴까요?';

  @override
  String get unsavedBody => '저장하지 않은 변경 사항이 있어요.';

  @override
  String get saved => '저장했어요.';

  @override
  String get fieldCreatedAt => '추가일';

  @override
  String get fieldUpdatedAt => '수정일';

  @override
  String get lookupTitle => 'ISBN으로 찾은 책 정보';

  @override
  String lookupSource(String source) {
    return '출처: $source';
  }

  @override
  String get lookupNotFound => '이 ISBN에 해당하는 책을 찾지 못했어요.';

  @override
  String get lookupFailed => '정보를 가져오지 못했어요. 인터넷 연결을 확인하세요.';

  @override
  String get lookupApply => '선택한 항목 적용';

  @override
  String lookupCurrent(String value) {
    return '현재: $value';
  }

  @override
  String get lookupRoleNote => '번역자와 감수자는 정확하게 구분되지 않을 수 있어요. 결과를 확인하세요.';

  @override
  String get sourceNdl => '일본 국립국회도서관 서치';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => '미국 의회도서관';

  @override
  String get sourceBnf => '프랑스 국립도서관';

  @override
  String get sourceDnb => '독일 국립도서관';

  @override
  String get searchTitle => '검색';

  @override
  String get searchHint => '책과 노트 검색';

  @override
  String get searchConditions => '검색 조건';

  @override
  String get searchTargets => '검색 대상';

  @override
  String get targetNotes => '노트 본문';

  @override
  String get filterStatus => '상태';

  @override
  String get filterCategory => '노트 분류';

  @override
  String get filterFavorite => '즐겨찾기';

  @override
  String get favoriteNotesOnly => '즐겨찾기한 노트만';

  @override
  String get filterTags => '태그(선택한 태그가 모두 있는 책)';

  @override
  String get filterReadDate => '완독일 기간';

  @override
  String get dateFrom => '시작';

  @override
  String get dateTo => '종료';

  @override
  String get clearFilters => '조건 지우기';

  @override
  String get noResults => '조건에 맞는 책이나 노트가 없어요.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count권',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => '태그';

  @override
  String get noTags => '아직 태그가 없어요. 책 편집 화면에서 태그를 추가할 수 있어요.';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count권',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => '태그 이름 변경';

  @override
  String get tagName => '태그 이름';

  @override
  String get tagNameRequired => '태그 이름을 입력하세요.';

  @override
  String get tagExists => '같은 이름의 태그가 이미 있어요.';

  @override
  String deleteTagConfirm(String name) {
    return '‘$name’ 태그를 삭제할까요? 모든 책에서 이 태그가 제거돼요.';
  }

  @override
  String get exportTitle => '내보내기';

  @override
  String get exportText => '텍스트';

  @override
  String get exportTextDesc => '읽기 쉬운 형식이에요. 다시 가져올 수는 없어요.';

  @override
  String get exportTextIncludeCovers => '표지도 포함(ZIP으로 저장)';

  @override
  String get exportZip => 'JSON + 이미지(ZIP)';

  @override
  String get exportZipDesc => '단순하고 개방된 형식이에요. 가져올 수 있어요.';

  @override
  String get exportSqlite => 'SQLite 데이터베이스';

  @override
  String get exportSqliteDesc => '데이터베이스 전체의 사본이에요. 가져올 수 있어요.';

  @override
  String get exportDone => '내보냈어요.';

  @override
  String get exportFailed => '내보내지 못했어요.';

  @override
  String get exportEmpty => '내보낼 책이 없어요.';

  @override
  String get importTitle => '가져오기';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일에서 책 $count권을 찾았어요.',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => '모두 바꾸기';

  @override
  String get importModeReplaceDesc => '현재 책을 모두 삭제한 뒤 파일에서 복원해요.';

  @override
  String get importModeMerge => '추가하기';

  @override
  String get importModeMergeDesc =>
      '현재 책은 그대로 두고 새 책을 추가해요. 이미 있는 책(ID 또는 ISBN이 같은 책)은 건너뛰어요.';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '현재 등록된 책 $count권이 모두 삭제돼요. 계속할까요?',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return '가져오기를 완료했어요. 추가: $added권 / 건너뜀: $skipped권';
  }

  @override
  String get importFailed => '이 파일을 가져올 수 없어요.';

  @override
  String get importInvalidFile => '이 파일에는 Colophon 데이터가 없어요.';

  @override
  String get importNewerVersion =>
      '이 파일은 더 새로운 버전의 Colophon에서 만들어졌어요. 앱을 업데이트하세요.';

  @override
  String textExportHeader(String date) {
    return 'Colophon 내보내기($date)';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count권',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsCover => '표지 이미지';

  @override
  String get settingsAutoResize => '큰 표지 이미지 자동으로 줄이기';

  @override
  String get settingsAutoResizeDesc =>
      '2000 px 또는 2 MB를 넘는 이미지는 추가할 때 긴 변 기준 2000 px로 줄여요.';

  @override
  String get settingsAppearance => '화면';

  @override
  String get settingsColorTheme => '색상 테마';

  @override
  String get settingsBrightness => '밝기';

  @override
  String get brightnessSystem => '시스템 설정 따르기';

  @override
  String get brightnessLight => '밝게';

  @override
  String get brightnessDark => '어둡게';

  @override
  String get themeLeather => '레더';

  @override
  String get themeForest => '포레스트';

  @override
  String get themeOcean => '오션';

  @override
  String get themeRose => '로즈';

  @override
  String get themeMonochrome => '흑백';

  @override
  String get themeUniversal => '유니버설';

  @override
  String get themeUniversalDesc => '색각 유형과 관계없이 구별하기 쉬운 색상입니다.';

  @override
  String get settingsData => '데이터';

  @override
  String get deleteAllData => '모든 데이터 삭제';

  @override
  String get deleteAllDataDesc =>
      '모든 책, 노트, 태그, 완독일과 표시 언어 등의 설정을 삭제하고 처음 상태로 되돌립니다.';

  @override
  String get deleteAllConfirmTitle => '모든 데이터를 삭제할까요?';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '등록한 책 $count권과 노트, 태그, 완독일, 모든 설정이 삭제됩니다.',
    );
    return '$_temp0 이 작업은 되돌릴 수 없습니다. 남기고 싶은 데이터가 있으면 먼저 내보내세요.';
  }

  @override
  String get exportFirst => '먼저 내보내기';

  @override
  String get proceedToDelete => '삭제 계속';

  @override
  String get deleteAllFinalTitle => '최종 확인';

  @override
  String get deleteAllAcknowledge => '삭제한 데이터는 복구할 수 없다는 것을 이해했습니다';

  @override
  String get deleteAllButton => '모두 삭제';

  @override
  String get deleteAllDone => '모든 데이터를 삭제했습니다.';

  @override
  String get settingsAbout => '앱 정보';

  @override
  String settingsVersion(String version) {
    return '버전 $version';
  }

  @override
  String get settingsDataSources => '책 정보 출처';

  @override
  String get settingsDataSourcesDesc =>
      'ISBN 조회에는 일본 국립국회도서관 서치, Open Library, 미국 의회도서관, 프랑스 국립도서관, 독일 국립도서관을 사용합니다.';

  @override
  String get settingsLicenses => '오픈소스 라이선스';

  @override
  String get settingsSync => '동기화';

  @override
  String get syncGoogleDrive => 'Google 드라이브로 동기화';

  @override
  String get syncDesc =>
      '같은 Google 계정으로 로그인한 컴퓨터끼리 책과 노트를 똑같이 맞춥니다. 데이터는 Google 드라이브 안의 이 앱 전용 비공개 영역에 저장됩니다.';

  @override
  String get syncUnavailable =>
      '이 빌드에서는 동기화를 사용할 수 없습니다(Google 로그인 설정 없이 빌드되었습니다).';

  @override
  String get syncSignIn => '로그인';

  @override
  String get syncSignOut => '로그아웃';

  @override
  String syncSignedInAs(String email) {
    return '로그인됨: $email';
  }

  @override
  String get syncSignedIn => '로그인됨';

  @override
  String get syncSignInTitle => '브라우저에서 로그인';

  @override
  String get syncSignInBody =>
      '브라우저에서 Google 계정을 선택하고 Colophon의 액세스를 허용하세요. 브라우저가 열리지 않거나 다른 브라우저를 사용하려면 링크를 복사해 붙여 넣으세요.';

  @override
  String get syncCopyLink => '링크 복사';

  @override
  String get syncLinkCopied => '링크를 복사했습니다';

  @override
  String get syncSignInDone => '로그인했습니다.';

  @override
  String get syncSignInDenied => '로그인이 취소되었습니다.';

  @override
  String get syncSignInFailed => '로그인할 수 없습니다. 네트워크 연결을 확인하고 다시 시도하세요.';

  @override
  String get syncSignOutTitle => '로그아웃할까요?';

  @override
  String get syncSignOutBody =>
      '이 컴퓨터에서 동기화를 중지합니다. 이 컴퓨터와 Google 드라이브의 데이터는 삭제되지 않습니다.';

  @override
  String get syncBrowserPage => 'Colophon에 로그인했습니다. 이 탭을 닫고 앱으로 돌아가세요.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get syncing => '동기화 중…';

  @override
  String syncLastAt(String time) {
    return '마지막 동기화: $time';
  }

  @override
  String get syncNever => '아직 동기화하지 않았습니다';

  @override
  String get syncDone => '동기화했습니다.';

  @override
  String get syncFirstTitle => '첫 동기화';

  @override
  String syncFirstBody(int local, int remote) {
    return '이 컴퓨터에 $local권, Google 드라이브에 $remote권의 책이 있습니다. 어떻게 합칠지 선택하세요. 동기화 전에 이 컴퓨터 데이터의 백업을 자동으로 저장합니다.';
  }

  @override
  String get syncFirstMerge => '통합하기(권장)';

  @override
  String get syncFirstMergeDesc => '양쪽의 책을 모두 남깁니다. ISBN이 같은 책은 한 권으로 합칩니다.';

  @override
  String get syncFirstUseRemote => 'Google 드라이브 내용으로 바꾸기';

  @override
  String get syncFirstUseRemoteDesc => '이 컴퓨터에만 있는 책과 노트는 삭제됩니다.';

  @override
  String get syncFirstUseLocal => '이 컴퓨터 내용으로 바꾸기';

  @override
  String get syncFirstUseLocalDesc =>
      'Google 드라이브에만 있는 책과 노트는 동기화된 모든 컴퓨터에서 삭제됩니다.';

  @override
  String get syncFirstStart => '동기화';

  @override
  String get syncErrorNetwork => '연결할 수 없습니다. 네트워크 연결을 확인하고 잠시 후 다시 시도하세요.';

  @override
  String get syncErrorAuth =>
      'Colophon이 더 이상 Google 드라이브를 사용할 수 없습니다. 로그아웃한 뒤 다시 로그인하세요.';

  @override
  String get syncErrorNewerFormat =>
      '더 새로운 버전의 Colophon으로 동기화된 데이터입니다. 앱을 업데이트하세요.';

  @override
  String get syncErrorRemoteCorrupt =>
      'Google 드라이브의 동기화 데이터가 손상되어 동기화를 중지했습니다.';

  @override
  String get syncErrorBusy => '다른 컴퓨터가 동시에 동기화하고 있었습니다. 잠시 후 다시 시도하세요.';

  @override
  String get syncErrorMissingCover =>
      '일부 표지 이미지가 아직 도착하지 않았습니다. 잠시 후 다시 시도하세요.';

  @override
  String get syncErrorQuota => 'Google 드라이브 저장 공간이 가득 찼습니다.';

  @override
  String get syncErrorLocalStorage => '이 컴퓨터에 저장하지 못했습니다. 디스크 여유 공간을 확인하세요.';

  @override
  String get syncErrorOther => '동기화할 수 없습니다.';

  @override
  String get syncWarningUnreadable =>
      'Google 드라이브의 동기화 데이터 일부를 읽을 수 없어, 이 컴퓨터의 변경 내용 전송을 보류했습니다.';

  @override
  String get deleteScopeTitle => '삭제할 범위';

  @override
  String get deleteScopeThisPc => '이 컴퓨터만';

  @override
  String get deleteScopeThisPcDesc =>
      '동기화를 끕니다(로그아웃). Google 드라이브와 다른 컴퓨터의 데이터는 남습니다.';

  @override
  String get deleteScopeEverywhere => 'Google 드라이브와 모든 컴퓨터';

  @override
  String get deleteScopeEverywhereDesc => '다른 컴퓨터에서도 다음 동기화 때 책과 노트가 삭제됩니다.';

  @override
  String get deleteEverywhereSyncFailed =>
      'Google 드라이브에 연결할 수 없어 아무것도 삭제하지 않았습니다. 네트워크 연결을 확인하고 다시 시도하세요.';

  @override
  String get deleteEverywherePartial =>
      '이 컴퓨터의 책은 삭제했지만 Google 드라이브에 반영하지 못했습니다. 다음 동기화 때 반영됩니다.';

  @override
  String get deleteEverywhereProgress => 'Google 드라이브에서 삭제하는 중…';

  @override
  String get bookDeletedElsewhere => '이 책은 다른 컴퓨터에서 삭제되었습니다.';

  @override
  String get syncNeedsChoice => '첫 동기화 방법을 선택해야 합니다. \"지금 동기화\"를 누르세요.';

  @override
  String get syncOnExitTitle => 'Google 드라이브와 동기화하는 중…';

  @override
  String get syncOnExitBody => '동기화가 끝나면 종료합니다.';

  @override
  String get syncOnExitSkip => '동기화하지 않고 종료';
}
