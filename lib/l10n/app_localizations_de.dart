// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Schließen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get discard => 'Verwerfen';

  @override
  String get keepEditing => 'Weiter bearbeiten';

  @override
  String get genericError => 'Etwas ist schiefgelaufen.';

  @override
  String get processing => 'Wird verarbeitet…';

  @override
  String get chooseLanguageTitle => 'Sprache auswählen';

  @override
  String get chooseLanguageNote =>
      'Kann später in den Einstellungen geändert werden.';

  @override
  String get searchTooltip => 'Suchen';

  @override
  String get showAsGridTooltip => 'Cover anzeigen';

  @override
  String get showAsListTooltip => 'Titel anzeigen';

  @override
  String get sortTooltip => 'Sortieren';

  @override
  String get sortRecent => 'Zuletzt hinzugefügt';

  @override
  String get sortTitle => 'Titel';

  @override
  String get menuTags => 'Tags verwalten';

  @override
  String get menuExport => 'Exportieren';

  @override
  String get menuImport => 'Importieren';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get addBook => 'Buch hinzufügen';

  @override
  String get emptyLibrary =>
      'Noch keine Bücher.\nMit + das erste Buch hinzufügen.';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gelesen ×$count',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String get statusUnset => 'Nicht festgelegt';

  @override
  String get statusUnread => 'Ungelesen';

  @override
  String get statusReading => 'Wird gelesen';

  @override
  String get statusFinished => 'Gelesen';

  @override
  String get categoryUnselected => 'Keine Kategorie';

  @override
  String get categoryImpression => 'Eindrücke';

  @override
  String get categoryLearning => 'Erkenntnisse';

  @override
  String get categoryMemo => 'Memo';

  @override
  String get categoryExcerpt => 'Auszug';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get viewMode => 'Ansehen';

  @override
  String get editMode => 'Bearbeiten';

  @override
  String get viewBookTitle => 'Buchdetails';

  @override
  String get saveAndView => 'Speichern und ansehen';

  @override
  String get discardAndView => 'Verwerfen und ansehen';

  @override
  String get newBookTitle => 'Neues Buch';

  @override
  String get editBookTitle => 'Buch bearbeiten';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldAuthor => 'Autor';

  @override
  String get fieldTranslator => 'Übersetzung';

  @override
  String get fieldSupervisor => 'Fachliche Beratung';

  @override
  String get fieldPublisher => 'Verlag';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => 'Auflage';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldProgress => 'Fortschritt (%)';

  @override
  String get progressHint => '0–100 (optional)';

  @override
  String get titleRequired => 'Bitte einen Titel eingeben.';

  @override
  String get progressInvalid => 'Eine ganze Zahl von 0 bis 100 eingeben.';

  @override
  String get pageInvalid => 'Eine ganze Zahl ab 1 eingeben.';

  @override
  String get isbnInvalidWarning =>
      'Diese ISBN ist möglicherweise falsch. Speichern ist trotzdem möglich.';

  @override
  String get isbnLookup => 'Daten per ISBN abrufen';

  @override
  String get isbnLookupInvalid =>
      'Eine gültige ISBN eingeben, um Buchdaten abzurufen.';

  @override
  String get coverSection => 'Cover';

  @override
  String get coverSelect => 'Bild auswählen';

  @override
  String get coverRemove => 'Bild entfernen';

  @override
  String coverResized(int width, int height) {
    return 'Das Bild wurde auf $width × $height px verkleinert.';
  }

  @override
  String get coverLoadFailed => 'Dieses Bild konnte nicht gelesen werden.';

  @override
  String get readDatesSection => 'Zu Ende gelesen am';

  @override
  String get addReadDate => 'Datum hinzufügen';

  @override
  String get noReadDates => 'Noch keine Einträge.';

  @override
  String get askAddReadDateTitle => 'Lesedatum erfassen?';

  @override
  String askAddReadDateBody(String date) {
    return 'Heute ($date) als Datum hinzufügen, an dem dieses Buch zu Ende gelesen wurde?';
  }

  @override
  String get tagsSection => 'Tags';

  @override
  String get tagInputHint => 'Tag eingeben und Enter drücken';

  @override
  String get notesSection => 'Notizen';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get noteCategory => 'Kategorie';

  @override
  String get notePage => 'Seite';

  @override
  String get noteBody => 'Text';

  @override
  String get noteBodyHint => 'Eindrücke, Erkenntnisse, Memos, Auszüge…';

  @override
  String get noNotes => 'Noch keine Notizen.';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get deleteNote => 'Notiz löschen';

  @override
  String get deleteNoteConfirm => 'Diese Notiz löschen?';

  @override
  String get deleteBook => 'Buch löschen';

  @override
  String deleteBookConfirm(String title) {
    return '„$title“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get unsavedTitle => 'Änderungen verwerfen?';

  @override
  String get unsavedBody => 'Es gibt ungespeicherte Änderungen.';

  @override
  String get saved => 'Gespeichert.';

  @override
  String get fieldCreatedAt => 'Hinzugefügt';

  @override
  String get fieldUpdatedAt => 'Aktualisiert';

  @override
  String get lookupTitle => 'Gefundene Daten zu dieser ISBN';

  @override
  String lookupSource(String source) {
    return 'Quelle: $source';
  }

  @override
  String get lookupNotFound => 'Zu dieser ISBN wurde kein Buch gefunden.';

  @override
  String get lookupFailed =>
      'Die Daten konnten nicht abgerufen werden. Bitte die Internetverbindung prüfen.';

  @override
  String get lookupApply => 'Auswahl übernehmen';

  @override
  String lookupCurrent(String value) {
    return 'Aktuell: $value';
  }

  @override
  String get lookupRoleNote =>
      'Übersetzung und fachliche Beratung werden eventuell nicht korrekt erkannt. Bitte das Ergebnis prüfen.';

  @override
  String get sourceNdl => 'NDL Search (Japanische Nationalbibliothek)';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => 'Library of Congress';

  @override
  String get sourceBnf => 'Französische Nationalbibliothek';

  @override
  String get sourceDnb => 'Deutsche Nationalbibliothek';

  @override
  String get searchTitle => 'Suche';

  @override
  String get searchHint => 'Bücher und Notizen durchsuchen';

  @override
  String get searchConditions => 'Suchoptionen';

  @override
  String get searchTargets => 'Suchen in';

  @override
  String get targetNotes => 'Notiztext';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterCategory => 'Notizkategorie';

  @override
  String get filterFavorite => 'Favoriten';

  @override
  String get favoriteNotesOnly => 'Nur Lieblingsnotizen';

  @override
  String get filterTags => 'Tags (Bücher mit allen ausgewählten Tags)';

  @override
  String get filterReadDate => 'Zu Ende gelesen im Zeitraum';

  @override
  String get dateFrom => 'Von';

  @override
  String get dateTo => 'Bis';

  @override
  String get clearFilters => 'Optionen zurücksetzen';

  @override
  String get noResults => 'Keine passenden Bücher oder Notizen.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get noTags =>
      'Noch keine Tags. Tags können im Bearbeitungsbildschirm eines Buches hinzugefügt werden.';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => 'Tag umbenennen';

  @override
  String get tagName => 'Tag-Name';

  @override
  String get tagNameRequired => 'Bitte einen Tag-Namen eingeben.';

  @override
  String get tagExists => 'Ein Tag mit diesem Namen ist bereits vorhanden.';

  @override
  String deleteTagConfirm(String name) {
    return 'Tag „$name“ löschen? Er wird von allen Büchern entfernt.';
  }

  @override
  String get exportTitle => 'Exportieren';

  @override
  String get exportText => 'Text';

  @override
  String get exportTextDesc =>
      'Gut lesbar. Kann nicht wieder importiert werden.';

  @override
  String get exportTextIncludeCovers =>
      'Cover einschließen (als ZIP speichern)';

  @override
  String get exportZip => 'JSON + Bilder (ZIP)';

  @override
  String get exportZipDesc =>
      'Ein einfaches, offenes Format. Kann importiert werden.';

  @override
  String get exportSqlite => 'SQLite-Datenbank';

  @override
  String get exportSqliteDesc =>
      'Eine Kopie der gesamten Datenbank. Kann importiert werden.';

  @override
  String get exportDone => 'Exportiert.';

  @override
  String get exportFailed => 'Export fehlgeschlagen.';

  @override
  String get exportEmpty => 'Keine Bücher zum Exportieren vorhanden.';

  @override
  String get importTitle => 'Importieren';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher in der Datei gefunden.',
      one: '1 Buch in der Datei gefunden.',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => 'Alles ersetzen';

  @override
  String get importModeReplaceDesc =>
      'Alle vorhandenen Bücher löschen und anschließend aus der Datei wiederherstellen.';

  @override
  String get importModeMerge => 'Hinzufügen';

  @override
  String get importModeMergeDesc =>
      'Vorhandene Bücher behalten und neue hinzufügen. Bereits vorhandene Bücher (gleiche ID oder ISBN) werden übersprungen.';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle $count derzeit gespeicherten Bücher werden gelöscht. Fortfahren?',
      one: 'Das derzeit gespeicherte Buch wird gelöscht. Fortfahren?',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return 'Import abgeschlossen. Hinzugefügt: $added / Übersprungen: $skipped';
  }

  @override
  String get importFailed => 'Diese Datei konnte nicht importiert werden.';

  @override
  String get importInvalidFile => 'Diese Datei enthält keine Colophon-Daten.';

  @override
  String get importNewerVersion =>
      'Diese Datei wurde mit einer neueren Version von Colophon erstellt. Bitte die App aktualisieren.';

  @override
  String textExportHeader(String date) {
    return 'Colophon-Export ($date)';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsCover => 'Coverbilder';

  @override
  String get settingsAutoResize => 'Große Coverbilder verkleinern';

  @override
  String get settingsAutoResizeDesc =>
      'Bilder über 2000 px oder 2 MB werden beim Hinzufügen auf 2000 px an der längeren Seite verkleinert.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsColorTheme => 'Farbschema';

  @override
  String get settingsBrightness => 'Helligkeit';

  @override
  String get brightnessSystem => 'Wie System';

  @override
  String get brightnessLight => 'Hell';

  @override
  String get brightnessDark => 'Dunkel';

  @override
  String get themeLeather => 'Leder';

  @override
  String get themeForest => 'Wald';

  @override
  String get themeOcean => 'Ozean';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeMonochrome => 'Monochrom';

  @override
  String get themeUniversal => 'Universell';

  @override
  String get themeUniversalDesc =>
      'Farben, die bei jeder Art des Farbsehens gut zu unterscheiden sind.';

  @override
  String get settingsData => 'Daten';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataDesc =>
      'Löscht alle Bücher, Notizen, Tags, Lesedaten und Einstellungen wie die Anzeigesprache und setzt die App zurück.';

  @override
  String get deleteAllConfirmTitle => 'Alle Daten löschen?';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle $count Bücher mit Notizen, Tags und Lesedaten sowie alle Einstellungen werden gelöscht.',
      one: 'Das Buch mit Notizen, Tags und Lesedaten sowie alle Einstellungen werden gelöscht.',
    );
    return '$_temp0 Dies kann nicht rückgängig gemacht werden. Bitte vorher exportieren, was erhalten bleiben soll.';
  }

  @override
  String get exportFirst => 'Zuerst exportieren';

  @override
  String get proceedToDelete => 'Weiter zum Löschen';

  @override
  String get deleteAllFinalTitle => 'Letzte Bestätigung';

  @override
  String get deleteAllAcknowledge =>
      'Mir ist klar, dass gelöschte Daten nicht wiederhergestellt werden können';

  @override
  String get deleteAllButton => 'Alles löschen';

  @override
  String get deleteAllDone => 'Alle Daten wurden gelöscht.';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsDataSources => 'Quellen für Buchdaten';

  @override
  String get settingsDataSourcesDesc =>
      'Die ISBN-Suche nutzt NDL Search (Japan), Open Library, die Library of Congress, die Französische Nationalbibliothek und die Deutsche Nationalbibliothek.';

  @override
  String get settingsLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsSync => 'Synchronisierung';

  @override
  String get syncGoogleDrive => 'Mit Google Drive synchronisieren';

  @override
  String get syncDesc =>
      'Halten Sie Bücher und Notizen auf allen Computern gleich, die mit demselben Google-Konto angemeldet sind. Die Daten werden in einem privaten, nur für die App bestimmten Bereich Ihres Google Drive gespeichert.';

  @override
  String get syncUnavailable =>
      'Die Synchronisierung ist in diesem Build nicht verfügbar (er wurde ohne Google-Anmeldeeinstellungen erstellt).';

  @override
  String get syncSignIn => 'Anmelden';

  @override
  String get syncSignOut => 'Abmelden';

  @override
  String syncSignedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get syncSignedIn => 'Angemeldet';

  @override
  String get syncSignInTitle => 'Im Browser anmelden';

  @override
  String get syncSignInBody =>
      'Wählen Sie im Browser Ihr Google-Konto aus und erlauben Sie Colophon den Zugriff. Wenn sich der Browser nicht öffnet oder Sie einen anderen Browser verwenden möchten, kopieren Sie den Link und fügen Sie ihn dort ein.';

  @override
  String get syncCopyLink => 'Link kopieren';

  @override
  String get syncLinkCopied => 'Link kopiert';

  @override
  String get syncSignInDone => 'Angemeldet.';

  @override
  String get syncSignInDenied => 'Die Anmeldung wurde abgebrochen.';

  @override
  String get syncSignInFailed =>
      'Anmeldung nicht möglich. Prüfen Sie die Netzwerkverbindung und versuchen Sie es erneut.';

  @override
  String get syncSignOutTitle => 'Abmelden?';

  @override
  String get syncSignOutBody =>
      'Die Synchronisierung wird auf diesem Computer beendet. Weder auf diesem Computer noch in Google Drive wird etwas gelöscht.';

  @override
  String get syncBrowserPage =>
      'Sie sind bei Colophon angemeldet. Schließen Sie diesen Tab und kehren Sie zur App zurück.';
}
