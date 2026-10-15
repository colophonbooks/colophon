import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Colophon'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get genericError;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get chooseLanguageNote;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @showAsGridTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show covers'**
  String get showAsGridTooltip;

  /// No description provided for @showAsListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show titles'**
  String get showAsListTooltip;

  /// No description provided for @sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTooltip;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortRecent;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @menuTags.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get menuTags;

  /// No description provided for @menuExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get menuExport;

  /// No description provided for @menuImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get menuImport;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @addBook.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get addBook;

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No books yet.\nTap + to add your first book.'**
  String get emptyLibrary;

  /// No description provided for @readCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Finished ×{count}}}'**
  String readCount(int count);

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String progressPercent(int percent);

  /// No description provided for @statusUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get statusUnset;

  /// No description provided for @statusUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get statusUnread;

  /// No description provided for @statusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get statusReading;

  /// No description provided for @statusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusFinished;

  /// No description provided for @categoryUnselected.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get categoryUnselected;

  /// No description provided for @categoryImpression.
  ///
  /// In en, this message translates to:
  /// **'Impressions'**
  String get categoryImpression;

  /// No description provided for @categoryLearning.
  ///
  /// In en, this message translates to:
  /// **'Learnings'**
  String get categoryLearning;

  /// No description provided for @categoryMemo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get categoryMemo;

  /// No description provided for @categoryExcerpt.
  ///
  /// In en, this message translates to:
  /// **'Excerpt'**
  String get categoryExcerpt;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewMode;

  /// No description provided for @editMode.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMode;

  /// No description provided for @viewBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book details'**
  String get viewBookTitle;

  /// No description provided for @saveAndView.
  ///
  /// In en, this message translates to:
  /// **'Save and view'**
  String get saveAndView;

  /// No description provided for @discardAndView.
  ///
  /// In en, this message translates to:
  /// **'Discard and view'**
  String get discardAndView;

  /// No description provided for @newBookTitle.
  ///
  /// In en, this message translates to:
  /// **'New book'**
  String get newBookTitle;

  /// No description provided for @editBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get editBookTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get fieldAuthor;

  /// No description provided for @fieldTranslator.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get fieldTranslator;

  /// No description provided for @fieldSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get fieldSupervisor;

  /// No description provided for @fieldPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get fieldPublisher;

  /// No description provided for @fieldIsbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get fieldIsbn;

  /// No description provided for @fieldEdition.
  ///
  /// In en, this message translates to:
  /// **'Edition'**
  String get fieldEdition;

  /// No description provided for @fieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @fieldProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress (%)'**
  String get fieldProgress;

  /// No description provided for @progressHint.
  ///
  /// In en, this message translates to:
  /// **'0–100 (optional)'**
  String get progressHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get titleRequired;

  /// No description provided for @progressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 0 to 100.'**
  String get progressInvalid;

  /// No description provided for @pageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of 1 or more.'**
  String get pageInvalid;

  /// No description provided for @isbnInvalidWarning.
  ///
  /// In en, this message translates to:
  /// **'This ISBN may be incorrect. You can still save it.'**
  String get isbnInvalidWarning;

  /// No description provided for @isbnLookup.
  ///
  /// In en, this message translates to:
  /// **'Fetch details from ISBN'**
  String get isbnLookup;

  /// No description provided for @isbnLookupInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid ISBN to fetch book details.'**
  String get isbnLookupInvalid;

  /// No description provided for @coverSection.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverSection;

  /// No description provided for @coverSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get coverSelect;

  /// No description provided for @coverRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get coverRemove;

  /// No description provided for @coverResized.
  ///
  /// In en, this message translates to:
  /// **'The image was reduced to {width} × {height} px.'**
  String coverResized(int width, int height);

  /// No description provided for @coverLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This image could not be read.'**
  String get coverLoadFailed;

  /// No description provided for @readDatesSection.
  ///
  /// In en, this message translates to:
  /// **'Finished reading on'**
  String get readDatesSection;

  /// No description provided for @addReadDate.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get addReadDate;

  /// No description provided for @noReadDates.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get noReadDates;

  /// No description provided for @askAddReadDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Record the finish date?'**
  String get askAddReadDateTitle;

  /// No description provided for @askAddReadDateBody.
  ///
  /// In en, this message translates to:
  /// **'Add today ({date}) as a date you finished this book?'**
  String askAddReadDateBody(String date);

  /// No description provided for @tagsSection.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsSection;

  /// No description provided for @tagInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag and press Enter'**
  String get tagInputHint;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @noteCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get noteCategory;

  /// No description provided for @notePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get notePage;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get noteBody;

  /// No description provided for @noteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Thoughts, lessons, memos, quotes…'**
  String get noteBodyHint;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @deleteBook.
  ///
  /// In en, this message translates to:
  /// **'Delete book'**
  String get deleteBook;

  /// No description provided for @deleteBookConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”? This cannot be undone.'**
  String deleteBookConfirm(String title);

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get unsavedTitle;

  /// No description provided for @unsavedBody.
  ///
  /// In en, this message translates to:
  /// **'You have changes that have not been saved.'**
  String get unsavedBody;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saved;

  /// No description provided for @fieldCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get fieldCreatedAt;

  /// No description provided for @fieldUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get fieldUpdatedAt;

  /// No description provided for @lookupTitle.
  ///
  /// In en, this message translates to:
  /// **'Details found for this ISBN'**
  String get lookupTitle;

  /// No description provided for @lookupSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String lookupSource(String source);

  /// No description provided for @lookupNotFound.
  ///
  /// In en, this message translates to:
  /// **'No book was found for this ISBN.'**
  String get lookupNotFound;

  /// No description provided for @lookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch the details. Please check your internet connection.'**
  String get lookupFailed;

  /// No description provided for @lookupApply.
  ///
  /// In en, this message translates to:
  /// **'Apply selected'**
  String get lookupApply;

  /// No description provided for @lookupCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String lookupCurrent(String value);

  /// No description provided for @lookupRoleNote.
  ///
  /// In en, this message translates to:
  /// **'Translators and supervisors may not be detected correctly. Please check the result.'**
  String get lookupRoleNote;

  /// No description provided for @sourceNdl.
  ///
  /// In en, this message translates to:
  /// **'National Diet Library Search'**
  String get sourceNdl;

  /// No description provided for @sourceOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get sourceOpenLibrary;

  /// No description provided for @sourceLoc.
  ///
  /// In en, this message translates to:
  /// **'Library of Congress'**
  String get sourceLoc;

  /// No description provided for @sourceBnf.
  ///
  /// In en, this message translates to:
  /// **'Bibliothèque nationale de France'**
  String get sourceBnf;

  /// No description provided for @sourceDnb.
  ///
  /// In en, this message translates to:
  /// **'German National Library'**
  String get sourceDnb;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search books and notes'**
  String get searchHint;

  /// No description provided for @searchConditions.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get searchConditions;

  /// No description provided for @searchTargets.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get searchTargets;

  /// No description provided for @targetNotes.
  ///
  /// In en, this message translates to:
  /// **'Note text'**
  String get targetNotes;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Note category'**
  String get filterCategory;

  /// No description provided for @filterFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filterFavorite;

  /// No description provided for @favoriteNotesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorite notes only'**
  String get favoriteNotesOnly;

  /// No description provided for @filterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (books with all selected tags)'**
  String get filterTags;

  /// No description provided for @filterReadDate.
  ///
  /// In en, this message translates to:
  /// **'Finished reading between'**
  String get filterReadDate;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dateTo;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear options'**
  String get clearFilters;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching books or notes.'**
  String get noResults;

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String resultCount(int count);

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Add tags on a book\'s edit screen.'**
  String get noTags;

  /// No description provided for @tagBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String tagBookCount(int count);

  /// No description provided for @renameTag.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get renameTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @tagNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a tag name.'**
  String get tagNameRequired;

  /// No description provided for @tagExists.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists.'**
  String get tagExists;

  /// No description provided for @deleteTagConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the tag “{name}”? It will be removed from all books.'**
  String deleteTagConfirm(String name);

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @exportText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get exportText;

  /// No description provided for @exportTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy to read. Cannot be imported back.'**
  String get exportTextDesc;

  /// No description provided for @exportTextIncludeCovers.
  ///
  /// In en, this message translates to:
  /// **'Include covers (saved as a ZIP)'**
  String get exportTextIncludeCovers;

  /// No description provided for @exportZip.
  ///
  /// In en, this message translates to:
  /// **'JSON + images (ZIP)'**
  String get exportZip;

  /// No description provided for @exportZipDesc.
  ///
  /// In en, this message translates to:
  /// **'A simple, open format. Can be imported.'**
  String get exportZipDesc;

  /// No description provided for @exportSqlite.
  ///
  /// In en, this message translates to:
  /// **'SQLite database'**
  String get exportSqlite;

  /// No description provided for @exportSqliteDesc.
  ///
  /// In en, this message translates to:
  /// **'A copy of the whole database. Can be imported.'**
  String get exportSqliteDesc;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported.'**
  String get exportDone;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get exportFailed;

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no books to export.'**
  String get exportEmpty;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book was found in the file.} other{{count} books were found in the file.}}'**
  String importFound(int count);

  /// No description provided for @importModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get importModeReplace;

  /// No description provided for @importModeReplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete all current books, then restore from the file.'**
  String get importModeReplaceDesc;

  /// No description provided for @importModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get importModeMerge;

  /// No description provided for @importModeMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep current books and add the new ones. Books that already exist (same ID or ISBN) are skipped.'**
  String get importModeMergeDesc;

  /// No description provided for @importReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The 1 book currently registered will be deleted. Continue?} other{All {count} books currently registered will be deleted. Continue?}}'**
  String importReplaceConfirm(int count);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Import finished. Added: {added} / Skipped: {skipped}'**
  String importDone(int added, int skipped);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'This file could not be imported.'**
  String get importFailed;

  /// No description provided for @importInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This file does not contain Colophon data.'**
  String get importInvalidFile;

  /// No description provided for @importNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This file was created by a newer version of Colophon. Please update the app.'**
  String get importNewerVersion;

  /// No description provided for @textExportHeader.
  ///
  /// In en, this message translates to:
  /// **'Colophon export ({date})'**
  String textExportHeader(String date);

  /// No description provided for @textBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String textBookCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCover.
  ///
  /// In en, this message translates to:
  /// **'Cover images'**
  String get settingsCover;

  /// No description provided for @settingsAutoResize.
  ///
  /// In en, this message translates to:
  /// **'Shrink large cover images'**
  String get settingsAutoResize;

  /// No description provided for @settingsAutoResizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Images over 2000 px or 2 MB are reduced to 2000 px on the long side when added.'**
  String get settingsAutoResizeDesc;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsColorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get settingsColorTheme;

  /// No description provided for @settingsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get settingsBrightness;

  /// No description provided for @brightnessSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get brightnessSystem;

  /// No description provided for @brightnessLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get brightnessLight;

  /// No description provided for @brightnessDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get brightnessDark;

  /// No description provided for @themeLeather.
  ///
  /// In en, this message translates to:
  /// **'Leather'**
  String get themeLeather;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @themeRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get themeRose;

  /// No description provided for @themeMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get themeMonochrome;

  /// No description provided for @themeUniversal.
  ///
  /// In en, this message translates to:
  /// **'Universal'**
  String get themeUniversal;

  /// No description provided for @themeUniversalDesc.
  ///
  /// In en, this message translates to:
  /// **'Colors chosen to be easy to tell apart for every type of color vision.'**
  String get themeUniversalDesc;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete all books, notes, tags, finish dates, and settings such as the display language, and start over.'**
  String get deleteAllDataDesc;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your 1 book, with its notes, tags, and finish dates, and all settings will be deleted.} other{All {count} books, with their notes, tags, and finish dates, and all settings will be deleted.}} This cannot be undone. If you want to keep anything, export it first.'**
  String deleteAllConfirmBody(int count);

  /// No description provided for @exportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export first'**
  String get exportFirst;

  /// No description provided for @proceedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Continue to delete'**
  String get proceedToDelete;

  /// No description provided for @deleteAllFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Final confirmation'**
  String get deleteAllFinalTitle;

  /// No description provided for @deleteAllAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand that deleted data cannot be restored'**
  String get deleteAllAcknowledge;

  /// No description provided for @deleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllButton;

  /// No description provided for @deleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get deleteAllDone;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsDataSources.
  ///
  /// In en, this message translates to:
  /// **'Book data sources'**
  String get settingsDataSources;

  /// No description provided for @settingsDataSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'ISBN lookup uses National Diet Library Search (Japan), Open Library, the Library of Congress, the Bibliothèque nationale de France, and the German National Library.'**
  String get settingsDataSourcesDesc;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSync;

  /// No description provided for @syncGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get syncGoogleDrive;

  /// No description provided for @syncDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your books and notes the same on every computer signed in to the same Google account. Data is stored in a private, app-only area of your Google Drive.'**
  String get syncDesc;

  /// No description provided for @syncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync is not available in this build (it was built without Google sign-in settings).'**
  String get syncUnavailable;

  /// No description provided for @syncSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get syncSignIn;

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get syncSignOut;

  /// No description provided for @syncSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String syncSignedInAs(String email);

  /// No description provided for @syncSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get syncSignedIn;

  /// No description provided for @syncSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your browser'**
  String get syncSignInTitle;

  /// No description provided for @syncSignInBody.
  ///
  /// In en, this message translates to:
  /// **'In your browser, choose your Google account and allow Colophon access. If the browser does not open, or you want to use a different browser, copy the link and paste it there.'**
  String get syncSignInBody;

  /// No description provided for @syncCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get syncCopyLink;

  /// No description provided for @syncLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get syncLinkCopied;

  /// No description provided for @syncSignInDone.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get syncSignInDone;

  /// No description provided for @syncSignInDenied.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get syncSignInDenied;

  /// No description provided for @syncSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your network connection and try again.'**
  String get syncSignInFailed;

  /// No description provided for @syncSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get syncSignOutTitle;

  /// No description provided for @syncSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Syncing stops on this computer. Nothing is deleted from this computer or from Google Drive.'**
  String get syncSignOutBody;

  /// No description provided for @syncBrowserPage.
  ///
  /// In en, this message translates to:
  /// **'You are signed in to Colophon. Close this tab and return to the app.'**
  String get syncBrowserPage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
