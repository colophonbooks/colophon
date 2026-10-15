// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fermer';

  @override
  String get add => 'Ajouter';

  @override
  String get rename => 'Renommer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get discard => 'Abandonner';

  @override
  String get keepEditing => 'Continuer la modification';

  @override
  String get genericError => 'Une erreur s’est produite.';

  @override
  String get processing => 'Traitement en cours…';

  @override
  String get chooseLanguageTitle => 'Choisissez votre langue';

  @override
  String get chooseLanguageNote =>
      'Vous pourrez la modifier plus tard dans les Paramètres.';

  @override
  String get searchTooltip => 'Rechercher';

  @override
  String get showAsGridTooltip => 'Afficher les couvertures';

  @override
  String get showAsListTooltip => 'Afficher les titres';

  @override
  String get sortTooltip => 'Trier';

  @override
  String get sortRecent => 'Ajoutés récemment';

  @override
  String get sortTitle => 'Titre';

  @override
  String get menuTags => 'Gérer les étiquettes';

  @override
  String get menuExport => 'Exporter';

  @override
  String get menuImport => 'Importer';

  @override
  String get menuSettings => 'Paramètres';

  @override
  String get addBook => 'Ajouter un livre';

  @override
  String get emptyLibrary =>
      'Aucun livre pour le moment.\nAppuyez sur + pour ajouter votre premier livre.';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lu ×$count',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String get statusUnset => 'Non défini';

  @override
  String get statusUnread => 'Non lu';

  @override
  String get statusReading => 'En cours';

  @override
  String get statusFinished => 'Lu';

  @override
  String get categoryUnselected => 'Sans catégorie';

  @override
  String get categoryImpression => 'Impressions';

  @override
  String get categoryLearning => 'Enseignements';

  @override
  String get categoryMemo => 'Mémo';

  @override
  String get categoryExcerpt => 'Extrait';

  @override
  String get categoryOther => 'Autre';

  @override
  String get viewMode => 'Consulter';

  @override
  String get editMode => 'Modifier';

  @override
  String get viewBookTitle => 'Détails du livre';

  @override
  String get saveAndView => 'Enregistrer et consulter';

  @override
  String get discardAndView => 'Abandonner et consulter';

  @override
  String get newBookTitle => 'Nouveau livre';

  @override
  String get editBookTitle => 'Modifier le livre';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get fieldAuthor => 'Auteur';

  @override
  String get fieldTranslator => 'Traducteur';

  @override
  String get fieldSupervisor => 'Supervision';

  @override
  String get fieldPublisher => 'Éditeur';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => 'Édition';

  @override
  String get fieldStatus => 'Statut';

  @override
  String get fieldProgress => 'Progression (%)';

  @override
  String get progressHint => '0–100 (facultatif)';

  @override
  String get titleRequired => 'Veuillez saisir un titre.';

  @override
  String get progressInvalid => 'Saisissez un nombre entier de 0 à 100.';

  @override
  String get pageInvalid => 'Saisissez un nombre entier supérieur ou égal à 1.';

  @override
  String get isbnInvalidWarning =>
      'Cet ISBN est peut-être incorrect. Vous pouvez tout de même l’enregistrer.';

  @override
  String get isbnLookup => 'Récupérer les infos à partir de l’ISBN';

  @override
  String get isbnLookupInvalid =>
      'Saisissez un ISBN valide pour récupérer les infos du livre.';

  @override
  String get coverSection => 'Couverture';

  @override
  String get coverSelect => 'Choisir une image';

  @override
  String get coverRemove => 'Retirer l’image';

  @override
  String coverResized(int width, int height) {
    return 'L’image a été réduite à $width × $height px.';
  }

  @override
  String get coverLoadFailed => 'Impossible de lire cette image.';

  @override
  String get readDatesSection => 'Lu le';

  @override
  String get addReadDate => 'Ajouter une date';

  @override
  String get noReadDates => 'Aucune date enregistrée.';

  @override
  String get askAddReadDateTitle => 'Enregistrer la date de fin de lecture ?';

  @override
  String askAddReadDateBody(String date) {
    return 'Ajouter aujourd’hui ($date) comme date de fin de lecture de ce livre ?';
  }

  @override
  String get tagsSection => 'Étiquettes';

  @override
  String get tagInputHint => 'Saisissez une étiquette et appuyez sur Entrée';

  @override
  String get notesSection => 'Notes';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get noteCategory => 'Catégorie';

  @override
  String get notePage => 'Page';

  @override
  String get noteBody => 'Texte';

  @override
  String get noteBodyHint => 'Impressions, enseignements, mémos, extraits…';

  @override
  String get noNotes => 'Aucune note pour le moment.';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get deleteNote => 'Supprimer la note';

  @override
  String get deleteNoteConfirm => 'Supprimer cette note ?';

  @override
  String get deleteBook => 'Supprimer le livre';

  @override
  String deleteBookConfirm(String title) {
    return 'Supprimer « $title » ? Cette action est irréversible.';
  }

  @override
  String get unsavedTitle => 'Abandonner les modifications ?';

  @override
  String get unsavedBody =>
      'Certaines modifications n’ont pas été enregistrées.';

  @override
  String get saved => 'Enregistré.';

  @override
  String get fieldCreatedAt => 'Ajouté le';

  @override
  String get fieldUpdatedAt => 'Modifié le';

  @override
  String get lookupTitle => 'Infos trouvées pour cet ISBN';

  @override
  String lookupSource(String source) {
    return 'Source : $source';
  }

  @override
  String get lookupNotFound => 'Aucun livre trouvé pour cet ISBN.';

  @override
  String get lookupFailed =>
      'Impossible de récupérer les infos. Vérifiez votre connexion Internet.';

  @override
  String get lookupApply => 'Appliquer la sélection';

  @override
  String lookupCurrent(String value) {
    return 'Actuel : $value';
  }

  @override
  String get lookupRoleNote =>
      'Les traducteurs et superviseurs peuvent ne pas être détectés correctement. Vérifiez le résultat.';

  @override
  String get sourceNdl => 'NDL Search (Bibliothèque nationale de la Diète)';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => 'Bibliothèque du Congrès';

  @override
  String get sourceBnf => 'Bibliothèque nationale de France';

  @override
  String get sourceDnb => 'Bibliothèque nationale allemande';

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get searchHint => 'Rechercher des livres et des notes';

  @override
  String get searchConditions => 'Options de recherche';

  @override
  String get searchTargets => 'Rechercher dans';

  @override
  String get targetNotes => 'Texte des notes';

  @override
  String get filterStatus => 'Statut';

  @override
  String get filterCategory => 'Catégorie de note';

  @override
  String get filterFavorite => 'Favoris';

  @override
  String get favoriteNotesOnly => 'Notes favorites uniquement';

  @override
  String get filterTags =>
      'Étiquettes (livres ayant toutes les étiquettes sélectionnées)';

  @override
  String get filterReadDate => 'Lu entre le';

  @override
  String get dateFrom => 'Du';

  @override
  String get dateTo => 'Au';

  @override
  String get clearFilters => 'Effacer les options';

  @override
  String get noResults => 'Aucun livre ni aucune note ne correspond.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Étiquettes';

  @override
  String get noTags =>
      'Aucune étiquette pour le moment. Ajoutez-en depuis l’écran de modification d’un livre.';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => 'Renommer l’étiquette';

  @override
  String get tagName => 'Nom de l’étiquette';

  @override
  String get tagNameRequired => 'Veuillez saisir un nom d’étiquette.';

  @override
  String get tagExists => 'Une étiquette portant ce nom existe déjà.';

  @override
  String deleteTagConfirm(String name) {
    return 'Supprimer l’étiquette « $name » ? Elle sera retirée de tous les livres.';
  }

  @override
  String get exportTitle => 'Exporter';

  @override
  String get exportText => 'Texte';

  @override
  String get exportTextDesc => 'Facile à lire. Ne peut pas être réimporté.';

  @override
  String get exportTextIncludeCovers =>
      'Inclure les couvertures (enregistré en ZIP)';

  @override
  String get exportZip => 'JSON + images (ZIP)';

  @override
  String get exportZipDesc => 'Un format simple et ouvert. Peut être importé.';

  @override
  String get exportSqlite => 'Base de données SQLite';

  @override
  String get exportSqliteDesc =>
      'Une copie de toute la base de données. Peut être importée.';

  @override
  String get exportDone => 'Exportation terminée.';

  @override
  String get exportFailed => 'Échec de l’exportation.';

  @override
  String get exportEmpty => 'Aucun livre à exporter.';

  @override
  String get importTitle => 'Importer';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres trouvés dans le fichier.',
      one: '1 livre trouvé dans le fichier.',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => 'Tout remplacer';

  @override
  String get importModeReplaceDesc =>
      'Supprime tous les livres actuels, puis restaure le contenu du fichier.';

  @override
  String get importModeMerge => 'Ajouter';

  @override
  String get importModeMergeDesc =>
      'Conserve les livres actuels et ajoute les nouveaux. Les livres déjà présents (même ID ou ISBN) sont ignorés.';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les $count livres actuellement enregistrés seront tous supprimés. Continuer ?',
      one: 'Le livre actuellement enregistré sera supprimé. Continuer ?',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return 'Importation terminée. Ajoutés : $added / Ignorés : $skipped';
  }

  @override
  String get importFailed => 'Impossible d’importer ce fichier.';

  @override
  String get importInvalidFile =>
      'Ce fichier ne contient pas de données Colophon.';

  @override
  String get importNewerVersion =>
      'Ce fichier a été créé par une version plus récente de Colophon. Veuillez mettre à jour l’application.';

  @override
  String textExportHeader(String date) {
    return 'Export Colophon ($date)';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsCover => 'Images de couverture';

  @override
  String get settingsAutoResize => 'Réduire les grandes images de couverture';

  @override
  String get settingsAutoResizeDesc =>
      'Lors de l’ajout, les images de plus de 2000 px ou 2 MB sont réduites à 2000 px sur le côté le plus long.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsColorTheme => 'Thème de couleurs';

  @override
  String get settingsBrightness => 'Luminosité';

  @override
  String get brightnessSystem => 'Selon le système';

  @override
  String get brightnessLight => 'Clair';

  @override
  String get brightnessDark => 'Sombre';

  @override
  String get themeLeather => 'Cuir';

  @override
  String get themeForest => 'Forêt';

  @override
  String get themeOcean => 'Océan';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeMonochrome => 'Monochrome';

  @override
  String get themeUniversal => 'Universel';

  @override
  String get themeUniversalDesc =>
      'Des couleurs faciles à distinguer, quelle que soit la vision des couleurs.';

  @override
  String get settingsData => 'Données';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get deleteAllDataDesc =>
      'Supprime tous les livres, notes, étiquettes, dates de lecture et réglages comme la langue d’affichage, pour repartir de zéro.';

  @override
  String get deleteAllConfirmTitle => 'Supprimer toutes les données ?';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vos $count livres, avec leurs notes, étiquettes et dates de lecture, ainsi que tous les réglages seront supprimés.',
      one: 'Votre livre, avec ses notes, étiquettes et dates de lecture, ainsi que tous les réglages seront supprimés.',
    );
    return '$_temp0 Cette action est irréversible. Exportez d’abord ce que vous souhaitez conserver.';
  }

  @override
  String get exportFirst => 'Exporter d’abord';

  @override
  String get proceedToDelete => 'Continuer la suppression';

  @override
  String get deleteAllFinalTitle => 'Confirmation finale';

  @override
  String get deleteAllAcknowledge =>
      'Je comprends que les données supprimées ne peuvent pas être restaurées';

  @override
  String get deleteAllButton => 'Tout supprimer';

  @override
  String get deleteAllDone => 'Toutes les données ont été supprimées.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsDataSources => 'Sources des infos sur les livres';

  @override
  String get settingsDataSourcesDesc =>
      'La recherche par ISBN utilise NDL Search (Japon), Open Library, la Bibliothèque du Congrès, la Bibliothèque nationale de France et la Bibliothèque nationale allemande.';

  @override
  String get settingsLicenses => 'Licences open source';
}
