/// Versionsangabe für die Einstellungen. Der GitHub-Build setzt sie per
/// `--dart-define=APP_VERSION=...` (Version aus pubspec.yaml + Build-Nummer).
const String kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'Entwicklungsversion');
