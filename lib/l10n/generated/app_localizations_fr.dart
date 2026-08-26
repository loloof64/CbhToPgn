// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'CBH → PGN';

  @override
  String get resetTooltip => 'Réinitialiser';

  @override
  String get issueNotMarkedAsGame => 'n\'est pas une partie';

  @override
  String get issueMarkedAsDeleted => 'marquée supprimée';

  @override
  String get issueNotEncoded => 'format non pris en charge (non encodé)';

  @override
  String get issueChess960 => 'Chess960, non pris en charge';

  @override
  String get issueSpecialEncoding => 'encodage spécial non pris en charge';

  @override
  String get issueDecodeError => 'erreur de décodage';

  @override
  String issueLine(int index, String labelWithDetail) {
    return 'Partie #$index : $labelWithDetail';
  }

  @override
  String get filePickerDialogTitle =>
      'Sélectionnez le fichier .cbh de la base (les .cbg/.cbp/.cbt/.cba portant le même nom seront chargés automatiquement), ou une archive .cbv';

  @override
  String missingFilesError(int count, String files) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fichiers manquants : $files',
      one: 'Fichier manquant : $files',
    );
    return '$_temp0';
  }

  @override
  String fileSelectionError(String error) {
    return 'Erreur pendant la sélection des fichiers : $error';
  }

  @override
  String get invalidBatchSize => 'Taille de lot invalide.';

  @override
  String conversionError(String error) {
    return 'Erreur pendant la conversion : $error';
  }

  @override
  String saveError(String error) {
    return 'Erreur pendant l\'enregistrement : $error';
  }

  @override
  String get sectionFilesTitle => '1. Fichiers de la base';

  @override
  String get filesDescription =>
      'Sélectionnez le fichier .cbh de la base : les fichiers .cbg, .cbp, .cbt (et .cba pour les commentaires/annotations) portant le même nom sont chargés automatiquement s\'ils se trouvent dans le même dossier. Vous pouvez aussi sélectionner plusieurs fichiers manuellement, ou directement une archive .cbv (créée via \"Sauvegarder la base de données\" dans ChessBase).';

  @override
  String get selectFilesButton => 'Sélectionner les fichiers de la base';

  @override
  String detectedGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties détectées dans l\'index.',
      one: '$count partie détectée dans l\'index.',
    );
    return '$_temp0';
  }

  @override
  String get sectionOptionsTitle => '2. Options d\'export';

  @override
  String get perGameOption => 'Un fichier PGN par partie';

  @override
  String get batchSizePrefix => 'Regrouper par lots de ';

  @override
  String get batchSizeSuffix => ' parties';

  @override
  String get includeVariations => 'Inclure les variations';

  @override
  String get includeAnnotations =>
      'Inclure commentaires et annotations (expérimental)';

  @override
  String get includeAnnotationsSubtitle =>
      'Basé sur une rétro-ingénierie non vérifiée du format .cba : à valider sur votre base, peut être incomplet ou absent.';

  @override
  String get sectionConversionTitle => '3. Conversion';

  @override
  String get convertButton => 'Convertir';

  @override
  String get convertingInProgress => 'Conversion en cours...';

  @override
  String conversionSummary(
    int convertedCount,
    int totalCount,
    int ignoredCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      convertedCount,
      locale: localeName,
      other: '# parties converties',
      one: '# partie convertie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ignoredCount,
      locale: localeName,
      other: '# ignorées ou en erreur',
      one: '# ignorée ou en erreur',
    );
    return '$_temp0 sur $totalCount, $_temp1.';
  }

  @override
  String detailsExpansionTitle(int count) {
    return 'Détail ($count)';
  }

  @override
  String get saveZipButton => 'Enregistrer le ZIP';
}
