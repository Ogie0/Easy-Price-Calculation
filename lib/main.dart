import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/appearance_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/quantity_provider.dart';
import 'screens/home_screen.dart';
import 'services/app_storage.dart';
import 'services/article_image_store.dart';
import 'theme.dart';
import 'widgets/article_art.dart';
import 'widgets/orientation_lock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStorage? storage;
  try {
    storage = await AppStorage.open();
  } on Object catch (e) {
    // Ohne Speicher läuft die Kasse mit den Standardpreisen weiter.
    debugPrint('Speicher nicht verfügbar: $e');
  }
  runApp(KassenRoot(storage: storage));
}

/// Stellt alle Provider bereit und startet die App.
class KassenRoot extends StatelessWidget {
  final AppStorage? storage;

  /// Für Tests austauschbar (Galerie/Kamera gibt es dort nicht).
  final ArticleImageStore? imageStore;

  const KassenRoot({super.key, this.storage, this.imageStore});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider(storage: storage)),
        ChangeNotifierProvider(create: (_) => AppearanceProvider(storage: storage)),
        ChangeNotifierProvider(
          create: (context) => CartProvider(context.read<CatalogProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CheckoutProvider(cart: context.read<CartProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => QuantityProvider()),
        Provider<ArticleImageStore>(create: (_) => imageStore ?? ArticleImageStore()),
      ],
      child: const KassenApp(),
    );
  }
}

class KassenApp extends StatelessWidget {
  const KassenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppearanceProvider, ThemeMode>((a) => a.themeMode);
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      // Deutsche System-Texte (z. B. „Zurück“, „Einfügen“).
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: clubTheme,
      darkTheme: clubDarkTheme,
      themeMode: themeMode,
      builder: (context, child) => OrientationLock(child: child!),
      home: const ArticleArtPrecache(child: HomeScreen()),
    );
  }
}
