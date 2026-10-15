// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Colophon';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get ok => 'Aceptar';

  @override
  String get close => 'Cerrar';

  @override
  String get add => 'Añadir';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get discard => 'Descartar';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get genericError => 'Se ha producido un error.';

  @override
  String get processing => 'Procesando…';

  @override
  String get chooseLanguageTitle => 'Elige tu idioma';

  @override
  String get chooseLanguageNote => 'Puedes cambiarlo más tarde en Ajustes.';

  @override
  String get searchTooltip => 'Buscar';

  @override
  String get showAsGridTooltip => 'Ver portadas';

  @override
  String get showAsListTooltip => 'Ver títulos';

  @override
  String get sortTooltip => 'Ordenar';

  @override
  String get sortRecent => 'Añadidos recientemente';

  @override
  String get sortTitle => 'Título';

  @override
  String get menuTags => 'Gestionar etiquetas';

  @override
  String get menuExport => 'Exportar';

  @override
  String get menuImport => 'Importar';

  @override
  String get menuSettings => 'Ajustes';

  @override
  String get addBook => 'Añadir libro';

  @override
  String get emptyLibrary =>
      'Aún no hay libros.\nToca + para añadir tu primer libro.';

  @override
  String readCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Leído ×$count',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String get statusUnset => 'Sin definir';

  @override
  String get statusUnread => 'Sin leer';

  @override
  String get statusReading => 'Leyendo';

  @override
  String get statusFinished => 'Leído';

  @override
  String get categoryUnselected => 'Sin categoría';

  @override
  String get categoryImpression => 'Impresiones';

  @override
  String get categoryLearning => 'Aprendizajes';

  @override
  String get categoryMemo => 'Apunte';

  @override
  String get categoryExcerpt => 'Extracto';

  @override
  String get categoryOther => 'Otro';

  @override
  String get viewMode => 'Ver';

  @override
  String get editMode => 'Editar';

  @override
  String get viewBookTitle => 'Detalles del libro';

  @override
  String get saveAndView => 'Guardar y ver';

  @override
  String get discardAndView => 'Descartar y ver';

  @override
  String get newBookTitle => 'Nuevo libro';

  @override
  String get editBookTitle => 'Editar libro';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldAuthor => 'Autor';

  @override
  String get fieldTranslator => 'Traductor';

  @override
  String get fieldSupervisor => 'Supervisión';

  @override
  String get fieldPublisher => 'Editorial';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldEdition => 'Edición';

  @override
  String get fieldStatus => 'Estado';

  @override
  String get fieldProgress => 'Progreso (%)';

  @override
  String get progressHint => '0–100 (opcional)';

  @override
  String get titleRequired => 'Introduce un título.';

  @override
  String get progressInvalid => 'Introduce un número entero del 0 al 100.';

  @override
  String get pageInvalid => 'Introduce un número entero igual o mayor que 1.';

  @override
  String get isbnInvalidWarning =>
      'Puede que este ISBN no sea correcto. Aun así, puedes guardarlo.';

  @override
  String get isbnLookup => 'Obtener datos a partir del ISBN';

  @override
  String get isbnLookupInvalid =>
      'Introduce un ISBN válido para obtener los datos del libro.';

  @override
  String get coverSection => 'Portada';

  @override
  String get coverSelect => 'Elegir imagen';

  @override
  String get coverRemove => 'Quitar imagen';

  @override
  String coverResized(int width, int height) {
    return 'La imagen se ha reducido a $width × $height px.';
  }

  @override
  String get coverLoadFailed => 'No se ha podido leer esta imagen.';

  @override
  String get readDatesSection => 'Fechas de finalización';

  @override
  String get addReadDate => 'Añadir fecha';

  @override
  String get noReadDates => 'Aún no hay registros.';

  @override
  String get askAddReadDateTitle => '¿Registrar la fecha de finalización?';

  @override
  String askAddReadDateBody(String date) {
    return '¿Añadir hoy ($date) como fecha en que terminaste este libro?';
  }

  @override
  String get tagsSection => 'Etiquetas';

  @override
  String get tagInputHint => 'Escribe una etiqueta y pulsa Intro';

  @override
  String get notesSection => 'Notas';

  @override
  String get addNote => 'Añadir nota';

  @override
  String get noteCategory => 'Categoría';

  @override
  String get notePage => 'Página';

  @override
  String get noteBody => 'Texto';

  @override
  String get noteBodyHint => 'Impresiones, aprendizajes, apuntes, extractos…';

  @override
  String get noNotes => 'Aún no hay notas.';

  @override
  String get addFavorite => 'Añadir a favoritos';

  @override
  String get removeFavorite => 'Quitar de favoritos';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get deleteNote => 'Eliminar nota';

  @override
  String get deleteNoteConfirm => '¿Eliminar esta nota?';

  @override
  String get deleteBook => 'Eliminar libro';

  @override
  String deleteBookConfirm(String title) {
    return '¿Eliminar «$title»? Esta acción no se puede deshacer.';
  }

  @override
  String get unsavedTitle => '¿Descartar los cambios?';

  @override
  String get unsavedBody => 'Hay cambios sin guardar.';

  @override
  String get saved => 'Guardado.';

  @override
  String get fieldCreatedAt => 'Añadido';

  @override
  String get fieldUpdatedAt => 'Actualizado';

  @override
  String get lookupTitle => 'Datos encontrados para este ISBN';

  @override
  String lookupSource(String source) {
    return 'Fuente: $source';
  }

  @override
  String get lookupNotFound =>
      'No se ha encontrado ningún libro con este ISBN.';

  @override
  String get lookupFailed =>
      'No se han podido obtener los datos. Comprueba tu conexión a Internet.';

  @override
  String get lookupApply => 'Aplicar selección';

  @override
  String lookupCurrent(String value) {
    return 'Actual: $value';
  }

  @override
  String get lookupRoleNote =>
      'Es posible que los traductores y supervisores no se detecten correctamente. Revisa el resultado.';

  @override
  String get sourceNdl => 'NDL Search (Biblioteca Nacional de la Dieta)';

  @override
  String get sourceOpenLibrary => 'Open Library';

  @override
  String get sourceLoc => 'Biblioteca del Congreso';

  @override
  String get sourceBnf => 'Biblioteca Nacional de Francia';

  @override
  String get sourceDnb => 'Biblioteca Nacional Alemana';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar libros y notas';

  @override
  String get searchConditions => 'Opciones de búsqueda';

  @override
  String get searchTargets => 'Buscar en';

  @override
  String get targetNotes => 'Texto de las notas';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterCategory => 'Categoría de nota';

  @override
  String get filterFavorite => 'Favoritos';

  @override
  String get favoriteNotesOnly => 'Solo notas favoritas';

  @override
  String get filterTags =>
      'Etiquetas (libros con todas las etiquetas seleccionadas)';

  @override
  String get filterReadDate => 'Terminados entre';

  @override
  String get dateFrom => 'Desde';

  @override
  String get dateTo => 'Hasta';

  @override
  String get clearFilters => 'Borrar opciones';

  @override
  String get noResults => 'No hay libros ni notas que coincidan.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Etiquetas';

  @override
  String get noTags =>
      'Aún no hay etiquetas. Añádelas desde la pantalla de edición de un libro.';

  @override
  String tagBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get renameTag => 'Cambiar nombre de etiqueta';

  @override
  String get tagName => 'Nombre de la etiqueta';

  @override
  String get tagNameRequired => 'Introduce un nombre de etiqueta.';

  @override
  String get tagExists => 'Ya existe una etiqueta con este nombre.';

  @override
  String deleteTagConfirm(String name) {
    return '¿Eliminar la etiqueta «$name»? Se quitará de todos los libros.';
  }

  @override
  String get exportTitle => 'Exportar';

  @override
  String get exportText => 'Texto';

  @override
  String get exportTextDesc => 'Fácil de leer. No se puede volver a importar.';

  @override
  String get exportTextIncludeCovers => 'Incluir portadas (se guarda como ZIP)';

  @override
  String get exportZip => 'JSON + imágenes (ZIP)';

  @override
  String get exportZipDesc =>
      'Un formato sencillo y abierto. Se puede importar.';

  @override
  String get exportSqlite => 'Base de datos SQLite';

  @override
  String get exportSqliteDesc =>
      'Una copia de toda la base de datos. Se puede importar.';

  @override
  String get exportDone => 'Exportación completada.';

  @override
  String get exportFailed => 'No se ha podido exportar.';

  @override
  String get exportEmpty => 'No hay libros para exportar.';

  @override
  String get importTitle => 'Importar';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se han encontrado $count libros en el archivo.',
      one: 'Se ha encontrado 1 libro en el archivo.',
    );
    return '$_temp0';
  }

  @override
  String get importModeReplace => 'Reemplazar todo';

  @override
  String get importModeReplaceDesc =>
      'Elimina todos los libros actuales y restaura el contenido del archivo.';

  @override
  String get importModeMerge => 'Añadir';

  @override
  String get importModeMergeDesc =>
      'Conserva los libros actuales y añade los nuevos. Los libros que ya existen (mismo ID o ISBN) se omiten.';

  @override
  String importReplaceConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán los $count libros registrados actualmente. ¿Continuar?',
      one: 'Se eliminará el libro registrado actualmente. ¿Continuar?',
    );
    return '$_temp0';
  }

  @override
  String importDone(int added, int skipped) {
    return 'Importación completada. Añadidos: $added / Omitidos: $skipped';
  }

  @override
  String get importFailed => 'No se ha podido importar este archivo.';

  @override
  String get importInvalidFile => 'Este archivo no contiene datos de Colophon.';

  @override
  String get importNewerVersion =>
      'Este archivo se creó con una versión más reciente de Colophon. Actualiza la aplicación.';

  @override
  String textExportHeader(String date) {
    return 'Exportación de Colophon ($date)';
  }

  @override
  String textBookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsCover => 'Imágenes de portada';

  @override
  String get settingsAutoResize => 'Reducir portadas grandes';

  @override
  String get settingsAutoResizeDesc =>
      'Al añadirlas, las imágenes de más de 2000 px o 2 MB se reducen a 2000 px en el lado más largo.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsColorTheme => 'Tema de color';

  @override
  String get settingsBrightness => 'Brillo';

  @override
  String get brightnessSystem => 'Según el sistema';

  @override
  String get brightnessLight => 'Claro';

  @override
  String get brightnessDark => 'Oscuro';

  @override
  String get themeLeather => 'Cuero';

  @override
  String get themeForest => 'Bosque';

  @override
  String get themeOcean => 'Océano';

  @override
  String get themeRose => 'Rosa';

  @override
  String get themeMonochrome => 'Monocromo';

  @override
  String get themeUniversal => 'Universal';

  @override
  String get themeUniversalDesc =>
      'Colores fáciles de distinguir con cualquier tipo de visión del color.';

  @override
  String get settingsData => 'Datos';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataDesc =>
      'Elimina todos los libros, notas, etiquetas, fechas de lectura y ajustes como el idioma, y vuelve al estado inicial.';

  @override
  String get deleteAllConfirmTitle => '¿Eliminar todos los datos?';

  @override
  String deleteAllConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán tus $count libros, con sus notas, etiquetas y fechas de lectura, y todos los ajustes.',
      one: 'Se eliminarán tu libro, con sus notas, etiquetas y fechas de lectura, y todos los ajustes.',
    );
    return '$_temp0 Esta acción no se puede deshacer. Si quieres conservar algo, expórtalo primero.';
  }

  @override
  String get exportFirst => 'Exportar primero';

  @override
  String get proceedToDelete => 'Continuar con la eliminación';

  @override
  String get deleteAllFinalTitle => 'Confirmación final';

  @override
  String get deleteAllAcknowledge =>
      'Entiendo que los datos eliminados no se pueden recuperar';

  @override
  String get deleteAllButton => 'Eliminar todo';

  @override
  String get deleteAllDone => 'Se han eliminado todos los datos.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsDataSources => 'Fuentes de datos de libros';

  @override
  String get settingsDataSourcesDesc =>
      'La búsqueda por ISBN utiliza NDL Search (Japón), Open Library, la Biblioteca del Congreso, la Biblioteca Nacional de Francia y la Biblioteca Nacional Alemana.';

  @override
  String get settingsLicenses => 'Licencias de código abierto';

  @override
  String get settingsSync => 'Sincronización';

  @override
  String get syncGoogleDrive => 'Sincronizar con Google Drive';

  @override
  String get syncDesc =>
      'Mantén tus libros y notas iguales en todos los ordenadores con la misma cuenta de Google. Los datos se guardan en un área privada de tu Google Drive reservada para la aplicación.';

  @override
  String get syncUnavailable =>
      'La sincronización no está disponible en esta compilación (se creó sin la configuración de inicio de sesión de Google).';

  @override
  String get syncSignIn => 'Iniciar sesión';

  @override
  String get syncSignOut => 'Cerrar sesión';

  @override
  String syncSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get syncSignedIn => 'Sesión iniciada';

  @override
  String get syncSignInTitle => 'Inicia sesión en el navegador';

  @override
  String get syncSignInBody =>
      'En el navegador, elige tu cuenta de Google y permite el acceso a Colophon. Si el navegador no se abre o quieres usar otro, copia el enlace y pégalo allí.';

  @override
  String get syncCopyLink => 'Copiar enlace';

  @override
  String get syncLinkCopied => 'Enlace copiado';

  @override
  String get syncSignInDone => 'Sesión iniciada.';

  @override
  String get syncSignInDenied => 'Se canceló el inicio de sesión.';

  @override
  String get syncSignInFailed =>
      'No se pudo iniciar sesión. Comprueba la conexión de red e inténtalo de nuevo.';

  @override
  String get syncSignOutTitle => '¿Cerrar sesión?';

  @override
  String get syncSignOutBody =>
      'La sincronización se detiene en este ordenador. No se elimina nada de este ordenador ni de Google Drive.';

  @override
  String get syncBrowserPage =>
      'Has iniciado sesión en Colophon. Cierra esta pestaña y vuelve a la aplicación.';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String syncLastAt(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get syncNever => 'Aún no se ha sincronizado';

  @override
  String get syncDone => 'Sincronizado.';

  @override
  String get syncFirstTitle => 'Primera sincronización';

  @override
  String syncFirstBody(int local, int remote) {
    return 'Este ordenador tiene $local libros y Google Drive tiene $remote. Elige cómo combinarlos. Antes de sincronizar, se guarda automáticamente una copia de seguridad de los datos de este ordenador.';
  }

  @override
  String get syncFirstMerge => 'Combinar (recomendado)';

  @override
  String get syncFirstMergeDesc =>
      'Conserva los libros de ambos. Los libros con el mismo ISBN se unen en uno.';

  @override
  String get syncFirstUseRemote => 'Reemplazar con Google Drive';

  @override
  String get syncFirstUseRemoteDesc =>
      'Se eliminan los libros y notas que solo existen en este ordenador.';

  @override
  String get syncFirstUseLocal => 'Reemplazar con este ordenador';

  @override
  String get syncFirstUseLocalDesc =>
      'Los libros y notas que solo existen en Google Drive se eliminan de todos los ordenadores sincronizados.';

  @override
  String get syncFirstStart => 'Sincronizar';

  @override
  String get syncErrorNetwork =>
      'No se pudo conectar. Comprueba la conexión de red e inténtalo más tarde.';

  @override
  String get syncErrorAuth =>
      'Colophon ya no tiene permiso para usar tu Google Drive. Cierra sesión y vuelve a iniciarla.';

  @override
  String get syncErrorNewerFormat =>
      'Estos datos se sincronizaron con una versión más reciente de Colophon. Actualiza la aplicación.';

  @override
  String get syncErrorRemoteCorrupt =>
      'Los datos de sincronización de Google Drive están dañados, así que se detuvo la sincronización.';

  @override
  String get syncErrorBusy =>
      'Otro ordenador estaba sincronizando al mismo tiempo. Inténtalo de nuevo en un momento.';

  @override
  String get syncErrorMissingCover =>
      'Algunas portadas aún no han llegado. Inténtalo de nuevo en un momento.';

  @override
  String get syncErrorQuota => 'El almacenamiento de Google Drive está lleno.';

  @override
  String get syncErrorLocalStorage =>
      'No se pudo guardar en este ordenador. Comprueba el espacio libre en disco.';

  @override
  String get syncErrorOther => 'No se pudo sincronizar.';

  @override
  String get syncWarningUnreadable =>
      'No se pudo leer parte de los datos de sincronización de Google Drive, así que este ordenador no envió sus cambios.';

  @override
  String get deleteScopeTitle => 'Qué eliminar';

  @override
  String get deleteScopeThisPc => 'Solo este ordenador';

  @override
  String get deleteScopeThisPcDesc =>
      'Se desactiva la sincronización (se cierra la sesión). Se conservan los datos de Google Drive y de otros ordenadores.';

  @override
  String get deleteScopeEverywhere => 'Google Drive y todos los ordenadores';

  @override
  String get deleteScopeEverywhereDesc =>
      'Los demás ordenadores también eliminarán sus libros y notas en la próxima sincronización.';

  @override
  String get deleteEverywhereSyncFailed =>
      'No se pudo conectar con Google Drive, así que no se eliminó nada. Comprueba la conexión de red e inténtalo de nuevo.';

  @override
  String get deleteEverywherePartial =>
      'Los libros se eliminaron en este ordenador, pero no se pudo enviar la eliminación a Google Drive. Se enviará en la próxima sincronización.';

  @override
  String get deleteEverywhereProgress => 'Eliminando de Google Drive…';

  @override
  String get bookDeletedElsewhere => 'Este libro se eliminó en otro ordenador.';

  @override
  String get syncNeedsChoice =>
      'Elige cómo combinar este ordenador con Google Drive: pulsa «Sincronizar ahora».';

  @override
  String get syncOnExitTitle => 'Sincronizando con Google Drive…';

  @override
  String get syncOnExitBody =>
      'Colophon se cerrará cuando termine la sincronización.';

  @override
  String get syncOnExitSkip => 'Cerrar sin sincronizar';
}
