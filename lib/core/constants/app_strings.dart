/// All user-facing strings in one place for easy i18n migration.
class AppStrings {
  const AppStrings._();

  // App
  static const String appName = 'Spinly Wheel Decision';
  static const String appTagline = 'Spin Your Choice';

  // Splash
  static const String loading = 'Loading...';

  // Home
  static const String spinNow = 'SPIN NOW';
  static const String editWheel = 'EDIT WHEEL';
  static const String addOption = '+ Add Option';

  // Edit
  static const String addOptionHint = 'Enter an option...';
  static const String add = 'Add';
  static const String editWheelTitle = 'Edit Options';

  // Result
  static const String resultTitle = '🎉 RESULT';
  static const String spinAgain = 'SPIN AGAIN';
  static const String backHome = 'BACK HOME';

  // Templates
  static const String templates = 'Templates';
  static const String templateWhatToEat = 'What to Eat';
  static const String templateWhereToGo = 'Where to Go';
  static const String templatePartyGame = 'Party Game';
  static const String templateYesNo = 'Yes / No';

  // Settings
  static const String settings = 'Settings';
  static const String sound = 'Sound';
  static const String vibration = 'Vibration';
  static const String theme = 'Theme';

  // Validation
  static const String errorMinOptions =
      'Add at least 2 options to spin the wheel';
  static const String errorMaxOptions = 'Maximum 20 options reached';
  static const String errorEmptyOption = 'Option cannot be empty';
  static const String errorDuplicateOption = 'Option already exists';
}
