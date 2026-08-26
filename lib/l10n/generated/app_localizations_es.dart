// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CBH → PGN';

  @override
  String get resetTooltip => 'Reiniciar';

  @override
  String get issueNotMarkedAsGame => 'no es una partida';

  @override
  String get issueMarkedAsDeleted => 'marcada como eliminada';

  @override
  String get issueNotEncoded => 'formato no compatible (sin codificar)';

  @override
  String get issueChess960 => 'Chess960, no compatible';

  @override
  String get issueSpecialEncoding => 'codificación especial no compatible';

  @override
  String get issueDecodeError => 'error de decodificación';

  @override
  String issueLine(int index, String labelWithDetail) {
    return 'Partida #$index: $labelWithDetail';
  }

  @override
  String get filePickerDialogTitle =>
      'Seleccione el archivo .cbh de la base de datos (los archivos .cbg/.cbp/.cbt/.cba con el mismo nombre se cargarán automáticamente), o un archivo .cbv';

  @override
  String missingFilesError(int count, String files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan los archivos: $files',
      one: 'Falta el archivo: $files',
    );
    return '$_temp0';
  }

  @override
  String fileSelectionError(String error) {
    return 'Error al seleccionar los archivos: $error';
  }

  @override
  String get invalidBatchSize => 'Tamaño de lote no válido.';

  @override
  String conversionError(String error) {
    return 'Error durante la conversión: $error';
  }

  @override
  String saveError(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get sectionFilesTitle => '1. Archivos de la base de datos';

  @override
  String get filesDescription =>
      'Seleccione el archivo .cbh de la base de datos: los archivos .cbg, .cbp, .cbt (y .cba para comentarios/anotaciones) con el mismo nombre se cargan automáticamente si están en la misma carpeta. También puede seleccionar varios archivos manualmente, o directamente un archivo .cbv (creado mediante \"Guardar base de datos\" en ChessBase).';

  @override
  String get selectFilesButton =>
      'Seleccionar los archivos de la base de datos';

  @override
  String detectedGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidas detectadas en el índice.',
      one: '$count partida detectada en el índice.',
    );
    return '$_temp0';
  }

  @override
  String get sectionOptionsTitle => '2. Opciones de exportación';

  @override
  String get perGameOption => 'Un archivo PGN por partida';

  @override
  String get batchSizePrefix => 'Agrupar en lotes de ';

  @override
  String get batchSizeSuffix => ' partidas';

  @override
  String get includeVariations => 'Incluir variantes';

  @override
  String get includeAnnotations =>
      'Incluir comentarios y anotaciones (experimental)';

  @override
  String get includeAnnotationsSubtitle =>
      'Basado en una ingeniería inversa no verificada del formato .cba: conviene comprobarlo con su base de datos, puede estar incompleto o ausente.';

  @override
  String get sectionConversionTitle => '3. Conversión';

  @override
  String get convertButton => 'Convertir';

  @override
  String get convertingInProgress => 'Convirtiendo...';

  @override
  String conversionSummary(
    int convertedCount,
    int totalCount,
    int ignoredCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      convertedCount,
      locale: localeName,
      other: '# partidas convertidas',
      one: '# partida convertida',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ignoredCount,
      locale: localeName,
      other: '# ignoradas o con error',
      one: '# ignorada o con error',
    );
    return '$_temp0 de $totalCount, $_temp1.';
  }

  @override
  String detailsExpansionTitle(int count) {
    return 'Detalles ($count)';
  }

  @override
  String get saveZipButton => 'Guardar ZIP';
}
