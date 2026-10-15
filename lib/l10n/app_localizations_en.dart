// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get add => 'Add';

  @override
  String get rename => 'Rename';

  @override
  String get continueLabel => 'Continue';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get genericError => 'Something went wrong.';

  @override
  String get processing => 'Processing…';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageNote => 'You can change this later in Settings.';

  @override
  String get searchTooltip => 'Search';

  @override
  String get showAsGridTooltip => 'Show covers';

  @override
  String get showAsListTooltip => 'Show titles';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get sortRecent => 'Recently added';

  @override
  String get sortTitle => 'Title';

  @override
  String get menuTags => 'Manage tags';

  @override
  String get menuExport => 'Export';

  @override
  String get menuImport => 'Import';

  @override
  String get menuSettings => 'Settings';

  @override
  String get addBook => 'Add book';

  @override
  String get emptyLibrary => 'No books yet.\nTap + to add your first book.';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finished ×$count',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get statusUnset => 'Not set';

  @override
  String get statusUnread => 'Unread';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusFinished => 'Finished';

  @override
  String get categoryUnselected => 'No category';

  @override
  String get categoryImpression => 'Impressions';

  @override
  String get categoryLearning => 'Learnings';

  @override
  String get categoryMemo => 'Memo';

  @override
  String get categoryExcerpt => 'Excerpt';

  @override
  String get categoryOther => 'Other';

  @override
  String get viewMode => 'View';

  @override
  String get editMode => 'Edit';

  @override
  String get viewBookTitle => 'Book details';

  @override
  String get saveAndView => 'Save and view';

  @override
  String get discardAndView => 'Discard and view';

  @override
  String get newBookTitle => 'New book';

  @override
  String get editBookTitle => 'Edit book';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldAuthor => 'Author';

  @override
  String get fieldTranslator => 'Translator';

  @override
  String get fieldSupervisor => 'Supervisor';

  @override
  String get fieldPublisher => 'Publisher';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => 'Edition';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldProgress => 'Progress (%)';

  @override
  String get progressHint => '0–100 (optional)';

  @override
  String get titleRequired => 'Please enter a title.';

  @override
  String get progressInvalid => 'Enter a whole number from 0 to 100.';

  @override
  String get pageInvalid => 'Enter a whole number of 1 or more.';

  @override
  String get isbnInvalidWarning =>
      'This ISBN may be incorrect. You can still save it.';

  @override
  String get isbnLookup => 'Fetch details from ISBN';

  @override
  String get isbnLookupInvalid => 'Enter a valid ISBN to fetch book details.';

  @override
  String get coverSection => 'Cover';

  @override
  String get coverSelect => 'Choose image';

  @override
  String get coverRemove => 'Remove image';

  @override
  String coverResized(int width, int height) {
    return 'The image was reduced to $width × $height px.';
  }

  @override
  String get coverLoadFailed => 'This image could not be read.';

  @override
  String get readDatesSection => 'Finished reading on';

  @override
  String get addReadDate => 'Add date';

  @override
  String get noReadDates => 'No records yet.';

  @override
  String get askAddReadDateTitle => 'Record the finish date?';

  @override
  String askAddReadDateBody(String date) {
    return 'Add today ($date) as a date you finished this book?';
  }

  @override
  String get tagsSection => 'Tags';

  @override
  String get tagInputHint => 'Type a tag and press Enter';

  @override
  String get notesSection => 'Notes';

  @override
  String get addNote => 'Add note';

  @override
  String get noteCategory => 'Category';

  @override
  String get notePage => 'Page';

  @override
  String get noteBody => 'Text';

  @override
  String get noteBodyHint => 'Thoughts, lessons, memos, quotes…';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get deleteNoteConfirm => 'Delete this note?';

  @override
  String get deleteBook => 'Delete book';

  @override
  String deleteBookConfirm(String title) {
    return 'Delete “$title”? This cannot be undone.';
  }

  @override
  String get unsavedTitle => 'Discard changes?';

  @override
  String get unsavedBody => 'You have changes that have not been saved.';

  @override
  String get saved => 'Saved.';

  @override
  String get fieldCreatedAt => 'Added';

  @override
  String get fieldUpdatedAt => 'Updated';

  @override
  String get lookupTitle => 'Details found for this ISBN';

  @override
  String lookupSource(String source) {
    return 'Source: $source';
  }

  @override
  String get lookupNotFound => 'No book was found for this ISBN.';

  @override
  String get lookupFailed =>
      'Could not fetch the details. Please check your internet connection.';

  @override
  String get lookupApply => 'Apply selected';

  @override
  String lookupCurrent(String value) {
    return 'Current: $value';
  }

  @override
  String get lookupRoleNote =>
      'Translators and supervisors may not be detected correctly. Please check the result.';

  @override
  String get sourceNdl => 'National Diet Library Search';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => 'Library of Congress';

  @override
  String get sourceBnf => 'Bibliothèque nationale de France';

  @override
  String get sourceDnb => 'German National Library';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search books and notes';

  @override
  String get searchConditions => 'Search options';

  @override
  String get searchTargets => 'Search in';

  @override
  String get targetNotes => 'Note text';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterCategory => 'Note category';

  @override
  String get filterFavorite => 'Favorites';

  @override
  String get favoriteNotesOnly => 'Favorite notes only';

  @override
  String get filterTags => 'Tags (books with all selected tags)';

  @override
  String get filterReadDate => 'Finished reading between';

  @override
  String get dateFrom => 'From';

  @override
  String get dateTo => 'To';

  @override
  String get clearFilters => 'Clear options';

  @override
  String get noResults => 'No matching books or notes.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get noTags => 'No tags yet. Add tags on a book\'s edit screen.';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => 'Rename tag';

  @override
  String get tagName => 'Tag name';

  @override
  String get tagNameRequired => 'Please enter a tag name.';

  @override
  String get tagExists => 'A tag with this name already exists.';

  @override
  String deleteTagConfirm(String name) {
    return 'Delete the tag “$name”? It will be removed from all books.';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportText => 'Text';

  @override
  String get exportTextDesc => 'Easy to read. Cannot be imported back.';

  @override
  String get exportTextIncludeCovers => 'Include covers (saved as a ZIP)';

  @override
  String get exportZip => 'JSON + images (ZIP)';

  @override
  String get exportZipDesc => 'A simple, open format. Can be imported.';

  @override
  String get exportSqlite => 'SQLite database';

  @override
  String get exportSqliteDesc =>
      'A copy of the whole database. Can be imported.';

  @override
  String get exportDone => 'Exported.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get exportEmpty => 'There are no books to export.';

  @override
  String get importTitle => 'Import';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books were found in the file.',
      one: '1 book was found in the file.',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => 'Replace all';

  @override
  String get importModeReplaceDesc =>
      'Delete all current books, then restore from the file.';

  @override
  String get importModeMerge => 'Add';

  @override
  String get importModeMergeDesc =>
      'Keep current books and add the new ones. Books that already exist (same ID or ISBN) are skipped.';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count books currently registered will be deleted. Continue?',
      one: 'The 1 book currently registered will be deleted. Continue?',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return 'Import finished. Added: $added / Skipped: $skipped';
  }

  @override
  String get importFailed => 'This file could not be imported.';

  @override
  String get importInvalidFile => 'This file does not contain Colophon data.';

  @override
  String get importNewerVersion =>
      'This file was created by a newer version of Colophon. Please update the app.';

  @override
  String textExportHeader(String date) {
    return 'Colophon export ($date)';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCover => 'Cover images';

  @override
  String get settingsAutoResize => 'Shrink large cover images';

  @override
  String get settingsAutoResizeDesc =>
      'Images over 2000 px or 2 MB are reduced to 2000 px on the long side when added.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsColorTheme => 'Color theme';

  @override
  String get settingsBrightness => 'Brightness';

  @override
  String get brightnessSystem => 'Match system';

  @override
  String get brightnessLight => 'Light';

  @override
  String get brightnessDark => 'Dark';

  @override
  String get themeLeather => 'Leather';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeMonochrome => 'Monochrome';

  @override
  String get themeUniversal => 'Universal';

  @override
  String get themeUniversalDesc =>
      'Colors chosen to be easy to tell apart for every type of color vision.';

  @override
  String get settingsData => 'Data';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataDesc =>
      'Delete all books, notes, tags, finish dates, and settings such as the display language, and start over.';

  @override
  String get deleteAllConfirmTitle => 'Delete all data?';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $count books, with their notes, tags, and finish dates, and all settings will be deleted.',
      one: 'Your 1 book, with its notes, tags, and finish dates, and all settings will be deleted.',
    );
    return '$_temp0 This cannot be undone. If you want to keep anything, export it first.';
  }

  @override
  String get exportFirst => 'Export first';

  @override
  String get proceedToDelete => 'Continue to delete';

  @override
  String get deleteAllFinalTitle => 'Final confirmation';

  @override
  String get deleteAllAcknowledge =>
      'I understand that deleted data cannot be restored';

  @override
  String get deleteAllButton => 'Delete everything';

  @override
  String get deleteAllDone => 'All data has been deleted.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsDataSources => 'Book data sources';

  @override
  String get settingsDataSourcesDesc =>
      'ISBN lookup uses National Diet Library Search (Japan), Open Library, the Library of Congress, the Bibliothèque nationale de France, and the German National Library.';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsSync => 'Sync';

  @override
  String get syncGoogleDrive => 'Sync with Google Drive';

  @override
  String get syncDesc =>
      'Keep your books and notes the same on every computer signed in to the same Google account. Data is stored in a private, app-only area of your Google Drive.';

  @override
  String get syncUnavailable =>
      'Sync is not available in this build (it was built without Google sign-in settings).';

  @override
  String get syncSignIn => 'Sign in';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String syncSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncSignedIn => 'Signed in';

  @override
  String get syncSignInTitle => 'Sign in with your browser';

  @override
  String get syncSignInBody =>
      'In your browser, choose your Google account and allow Colophon access. If the browser does not open, or you want to use a different browser, copy the link and paste it there.';

  @override
  String get syncCopyLink => 'Copy link';

  @override
  String get syncLinkCopied => 'Link copied';

  @override
  String get syncSignInDone => 'Signed in.';

  @override
  String get syncSignInDenied => 'Sign-in was cancelled.';

  @override
  String get syncSignInFailed =>
      'Could not sign in. Check your network connection and try again.';

  @override
  String get syncSignOutTitle => 'Sign out?';

  @override
  String get syncSignOutBody =>
      'Syncing stops on this computer. Nothing is deleted from this computer or from Google Drive.';

  @override
  String get syncBrowserPage =>
      'You are signed in to Colophon. Close this tab and return to the app.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String syncLastAt(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncDone => 'Synced.';

  @override
  String get syncFirstTitle => 'First sync';

  @override
  String syncFirstBody(int local, int remote) {
    return 'This computer has $local books and Google Drive has $remote. Choose how to combine them. Before syncing, a backup of this computer’s data is saved automatically.';
  }

  @override
  String get syncFirstMerge => 'Combine (recommended)';

  @override
  String get syncFirstMergeDesc =>
      'Keeps the books from both. Books with the same ISBN become one.';

  @override
  String get syncFirstUseRemote => 'Replace with Google Drive';

  @override
  String get syncFirstUseRemoteDesc =>
      'Books and notes that exist only on this computer are deleted.';

  @override
  String get syncFirstUseLocal => 'Replace with this computer';

  @override
  String get syncFirstUseLocalDesc =>
      'Books and notes that exist only on Google Drive are deleted from every synced computer.';

  @override
  String get syncFirstStart => 'Sync';

  @override
  String get syncErrorNetwork =>
      'Could not connect. Check your network connection and try again later.';

  @override
  String get syncErrorAuth =>
      'Colophon is no longer allowed to use your Google Drive. Sign out, then sign in again.';

  @override
  String get syncErrorNewerFormat =>
      'This data was synced by a newer version of Colophon. Please update the app.';

  @override
  String get syncErrorRemoteCorrupt =>
      'The sync data on Google Drive is damaged, so syncing stopped.';

  @override
  String get syncErrorBusy =>
      'Another computer was syncing at the same time. Try again in a moment.';

  @override
  String get syncErrorMissingCover =>
      'Some cover images have not arrived yet. Try again in a moment.';

  @override
  String get syncErrorQuota => 'Your Google Drive storage is full.';

  @override
  String get syncErrorLocalStorage =>
      'Could not save to this computer. Check the free disk space.';

  @override
  String get syncErrorOther => 'Could not sync.';

  @override
  String get syncWarningUnreadable =>
      'Part of the sync data on Google Drive could not be read, so this computer did not send its changes.';

  @override
  String get deleteScopeTitle => 'What to delete';

  @override
  String get deleteScopeThisPc => 'This computer only';

  @override
  String get deleteScopeThisPcDesc =>
      'Sync is turned off (you are signed out). Data on Google Drive and other computers is kept.';

  @override
  String get deleteScopeEverywhere => 'Google Drive and every computer';

  @override
  String get deleteScopeEverywhereDesc =>
      'Other computers also delete their books and notes when they next sync.';

  @override
  String get deleteEverywhereSyncFailed =>
      'Could not reach Google Drive, so nothing was deleted. Check your network connection and try again.';

  @override
  String get deleteEverywherePartial =>
      'Books were deleted on this computer, but the deletion could not be sent to Google Drive. It will be sent at the next sync.';

  @override
  String get deleteEverywhereProgress => 'Deleting from Google Drive…';
}
