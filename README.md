# Knülle Kalkulieren - JGC

Offline-Kassen-App des Junggesellenclubs Ellierode v. 1960 für Vereinsfeste (Flutter, Android). Speisen und Getränke
per Kachel buchen, automatische Pfandposten, Pfandrückgabe, Rückgeldrechner
mit Ziffernblock. Preise und Pfandwert lassen sich in den Einstellungen
ändern und bleiben auf dem Gerät gespeichert. Es werden keine Umsätze
protokolliert, die App braucht kein Internet.

## APK installieren

Jeder Push baut über GitHub Actions eine neue APK. Die neueste liegt unter
**Releases → „Knülle Kalkulieren - JGC …“** (`Knuelle-Kalkulieren-JGC.apk`) und kann direkt
auf dem Smartphone heruntergeladen und installiert werden.

## Entwicklung

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Die Flutter-Version ist im Workflow festgelegt
(`.github/workflows/build-apk.yml`); lokal am besten dieselbe verwenden.

## Einstellungen

Preise, Pfandwert und Sortiment sind durch ein Master-Passwort geschützt
(`lib/widgets/password_dialog.dart`). Es verhindert versehentliche Änderungen
an der Kasse, ist aber keine echte Sicherung, da der Quellcode einsehbar ist.

## Signatur

Release-APKs werden mit einem festen Schlüssel signiert, damit sich neue
Versionen als Update installieren lassen. Der Workflow erwartet die
Repository-Secrets `ANDROID_KEYSTORE_BASE64` (PKCS12-Keystore, Base64) und
`ANDROID_KEYSTORE_PASSWORD` (Alias `upload`). Ohne Secrets wird mit einem
Wegwerf-Schlüssel signiert. Lokal: `android/key.properties` anlegen (siehe
`android/app/build.gradle.kts`), die Datei wird nicht eingecheckt.

## Projektstruktur

- `lib/models` – Artikel, Warenkorbpositionen, Standardsortiment
- `lib/providers` – Zustand (Katalog, Warenkorb, Bargeldeingabe)
- `lib/services` – lokales Speichern der Preise
- `lib/screens`, `lib/widgets` – Oberfläche (Smartphone hoch, Tablet quer)
- `assets/icon` – App-Icon; nach Änderungen `dart run flutter_launcher_icons`
