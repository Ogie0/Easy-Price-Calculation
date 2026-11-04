# Knülle Kalkulieren - JGC

Offline-Kassen-App („Knülle Kasse“ auf dem Startbildschirm) des Junggesellenclubs Ellierode v. 1960 für Vereinsfeste (Flutter, Android und als Web-App fürs iPhone). Speisen und Getränke
per Kachel buchen, automatische Pfandposten, Pfandrückgabe, Rückgeldrechner
mit Ziffernblock. Preise und Pfandwert lassen sich in den Einstellungen
ändern und bleiben auf dem Gerät gespeichert. Es werden keine Umsätze
protokolliert, die App braucht kein Internet.

## APK installieren

Jeder Push baut über GitHub Actions eine neue APK. Die neueste liegt unter
**Releases → „Knülle Kalkulieren - JGC …“** (`Knuelle-Kalkulieren-JGC.apk`) und kann direkt
auf dem Smartphone heruntergeladen und installiert werden.

## iPhone (Web-App)

Derselbe Lauf baut auch eine Web-App und legt sie in den Zweig `gh-pages`.
Einmalig in GitHub unter **Settings → Pages** „Deploy from a branch“ mit
`gh-pages` / `(root)` wählen. Danach ist die Kasse unter
<https://ogie0.github.io/Easy-Price-Calculation/> erreichbar: in Safari öffnen,
„Teilen“ → „Zum Home-Bildschirm“. Nach dem ersten Öffnen läuft sie ohne
Internet (eigener Service Worker `web/sw.js`; Schriften, CanvasKit und der
QR-Scanner `web/zxing` werden mitgeliefert). Lokal bauen:

```sh
flutter build web --release --no-web-resources-cdn --base-href /Easy-Price-Calculation/
python3 tool/web/finalize_web.py build/web lokal
```

Sortiment und Preise lassen sich zwischen den Geräten per QR-Code
übertragen, auch aus einem gespeicherten Screenshot des QR-Codes
(Einstellungen → „Sortiment teilen“ / „Sortiment übernehmen“).

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

Nur „Preise & Sortiment“ (Preise, Pfandwert, Artikel, Reihenfolge, Fotos)
ist durch ein Master-Passwort geschützt (`lib/widgets/password_dialog.dart`).
Darstellung, „Sortiment teilen“, „Sortiment übernehmen“ und die Version sind
ohne Passwort erreichbar. Es verhindert versehentliche Änderungen
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
- `lib/services` – lokales Speichern, QR-Übertragung, eigene Fotos
- `lib/screens`, `lib/widgets` – Oberfläche (Smartphone hoch, Tablet quer)
- `assets/icon` – App-Icon; nach Änderungen `dart run flutter_launcher_icons`
- `web`, `tool/web` – Web-App (iPhone): Startseite, Manifest, Offline-Speicher
