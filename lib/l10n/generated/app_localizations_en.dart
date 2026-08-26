// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CBH → PGN';

  @override
  String get resetTooltip => 'Reset';

  @override
  String get issueNotMarkedAsGame => 'not marked as a game';

  @override
  String get issueMarkedAsDeleted => 'marked as deleted';

  @override
  String get issueNotEncoded => 'unsupported format (not encoded)';

  @override
  String get issueChess960 => 'Chess960, not supported';

  @override
  String get issueSpecialEncoding => 'unsupported special encoding';

  @override
  String get issueDecodeError => 'decoding error';

  @override
  String issueLine(int index, String labelWithDetail) {
    return 'Game #$index: $labelWithDetail';
  }

  @override
  String get filePickerDialogTitle =>
      'Select the database\'s .cbh file (matching .cbg/.cbp/.cbt/.cba files will be loaded automatically), or a .cbv archive';

  @override
  String missingFilesError(int count, String files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Missing files: $files',
      one: 'Missing file: $files',
    );
    return '$_temp0';
  }

  @override
  String fileSelectionError(String error) {
    return 'Error while selecting files: $error';
  }

  @override
  String get invalidBatchSize => 'Invalid batch size.';

  @override
  String conversionError(String error) {
    return 'Error during conversion: $error';
  }

  @override
  String saveError(String error) {
    return 'Error while saving: $error';
  }

  @override
  String get sectionFilesTitle => '1. Database files';

  @override
  String get filesDescription =>
      'Select the database\'s .cbh file: the .cbg, .cbp, .cbt files (and .cba for comments/annotations) sharing the same name are loaded automatically if they are in the same folder. You can also select several files manually, or directly a .cbv archive (created via \"Save database\" in ChessBase).';

  @override
  String get selectFilesButton => 'Select database files';

  @override
  String detectedGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games detected in the index.',
      one: '$count game detected in the index.',
    );
    return '$_temp0';
  }

  @override
  String get sectionOptionsTitle => '2. Export options';

  @override
  String get perGameOption => 'One PGN file per game';

  @override
  String get batchSizePrefix => 'Group in batches of ';

  @override
  String get batchSizeSuffix => ' games';

  @override
  String get includeVariations => 'Include variations';

  @override
  String get includeAnnotations =>
      'Include comments and annotations (experimental)';

  @override
  String get includeAnnotationsSubtitle =>
      'Based on unverified reverse engineering of the .cba format: please verify against your database, it may be incomplete or missing.';

  @override
  String get sectionConversionTitle => '3. Conversion';

  @override
  String get convertButton => 'Convert';

  @override
  String get convertingInProgress => 'Converting...';

  @override
  String conversionSummary(
    int convertedCount,
    int totalCount,
    int ignoredCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      convertedCount,
      locale: localeName,
      other: '# games',
      one: '# game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ignoredCount,
      locale: localeName,
      other: '# ignored or failed',
      one: '# ignored or failed',
    );
    return '$_temp0 converted out of $totalCount, $_temp1.';
  }

  @override
  String detailsExpansionTitle(int count) {
    return 'Details ($count)';
  }

  @override
  String get saveZipButton => 'Save ZIP';
}
