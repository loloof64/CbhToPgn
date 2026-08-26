import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Application title shown in the app bar and window title.
  ///
  /// In en, this message translates to:
  /// **'CBH → PGN'**
  String get appTitle;

  /// Tooltip for the button that clears the current selection/results.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTooltip;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'not marked as a game'**
  String get issueNotMarkedAsGame;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'marked as deleted'**
  String get issueMarkedAsDeleted;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'unsupported format (not encoded)'**
  String get issueNotEncoded;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'Chess960, not supported'**
  String get issueChess960;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'unsupported special encoding'**
  String get issueSpecialEncoding;

  /// Reason a database record was skipped during conversion.
  ///
  /// In en, this message translates to:
  /// **'decoding error'**
  String get issueDecodeError;

  /// One line in the list of skipped/errored games.
  ///
  /// In en, this message translates to:
  /// **'Game #{index}: {labelWithDetail}'**
  String issueLine(int index, String labelWithDetail);

  /// Title of the native file picker dialog.
  ///
  /// In en, this message translates to:
  /// **'Select the database\'s .cbh file (matching .cbg/.cbp/.cbt/.cba files will be loaded automatically), or a .cbv archive'**
  String get filePickerDialogTitle;

  /// Shown when some required database files were not selected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Missing file: {files}} other{Missing files: {files}}}'**
  String missingFilesError(int count, String files);

  /// Shown when an exception is thrown while picking files.
  ///
  /// In en, this message translates to:
  /// **'Error while selecting files: {error}'**
  String fileSelectionError(String error);

  /// Shown when the batch size field does not contain a valid positive integer.
  ///
  /// In en, this message translates to:
  /// **'Invalid batch size.'**
  String get invalidBatchSize;

  /// Shown when an exception is thrown while converting.
  ///
  /// In en, this message translates to:
  /// **'Error during conversion: {error}'**
  String conversionError(String error);

  /// Shown when an exception is thrown while saving the output ZIP.
  ///
  /// In en, this message translates to:
  /// **'Error while saving: {error}'**
  String saveError(String error);

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'1. Database files'**
  String get sectionFilesTitle;

  /// Explanation of how to select database files.
  ///
  /// In en, this message translates to:
  /// **'Select the database\'s .cbh file: the .cbg, .cbp, .cbt files (and .cba for comments/annotations) sharing the same name are loaded automatically if they are in the same folder. You can also select several files manually, or directly a .cbv archive (created via \"Save database\" in ChessBase).'**
  String get filesDescription;

  /// Button label to open the file picker.
  ///
  /// In en, this message translates to:
  /// **'Select database files'**
  String get selectFilesButton;

  /// Shown after loading files, reporting how many games were found.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} game detected in the index.} other{{count} games detected in the index.}}'**
  String detectedGameCount(int count);

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'2. Export options'**
  String get sectionOptionsTitle;

  /// Export mode radio option.
  ///
  /// In en, this message translates to:
  /// **'One PGN file per game'**
  String get perGameOption;

  /// Text before the batch size input field. Note the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Group in batches of '**
  String get batchSizePrefix;

  /// Text after the batch size input field. Note the leading space.
  ///
  /// In en, this message translates to:
  /// **' games'**
  String get batchSizeSuffix;

  /// Checkbox label.
  ///
  /// In en, this message translates to:
  /// **'Include variations'**
  String get includeVariations;

  /// Checkbox label.
  ///
  /// In en, this message translates to:
  /// **'Include comments and annotations (experimental)'**
  String get includeAnnotations;

  /// Disclaimer shown below the annotations checkbox.
  ///
  /// In en, this message translates to:
  /// **'Based on unverified reverse engineering of the .cba format: please verify against your database, it may be incomplete or missing.'**
  String get includeAnnotationsSubtitle;

  /// Section header.
  ///
  /// In en, this message translates to:
  /// **'3. Conversion'**
  String get sectionConversionTitle;

  /// Button label to start the conversion.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertButton;

  /// Shown while the conversion is running.
  ///
  /// In en, this message translates to:
  /// **'Converting...'**
  String get convertingInProgress;

  /// Summary shown after a conversion completes.
  ///
  /// In en, this message translates to:
  /// **'{convertedCount, plural, one{# game} other{# games}} converted out of {totalCount}, {ignoredCount, plural, one{# ignored or failed} other{# ignored or failed}}.'**
  String conversionSummary(
    int convertedCount,
    int totalCount,
    int ignoredCount,
  );

  /// Title of the expandable panel listing skipped/errored games.
  ///
  /// In en, this message translates to:
  /// **'Details ({count})'**
  String detailsExpansionTitle(int count);

  /// Button label to save the resulting ZIP file.
  ///
  /// In en, this message translates to:
  /// **'Save ZIP'**
  String get saveZipButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
