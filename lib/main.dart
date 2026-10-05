import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/checkout_provider.dart';
import 'screens/home_screen.dart';
import 'services/catalog_storage.dart';
import 'theme.dart';
import 'widgets/orientation_lock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CatalogStorage? storage;
  try {
    storage = await CatalogStorage.open();
  } on Object catch (e) {
    // Ohne Speicher läuft die Kasse mit den Standardpreisen weiter.
    debugPrint('Speicher nicht verfügbar: $e');
  }
  runApp(KassenRoot(storage: storage));
}

/// Stellt alle Provider bereit und startet die App.
class KassenRoot extends StatelessWidget {
  final CatalogStorage? storage;

  const KassenRoot({super.key, this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider(storage: storage)),
        ChangeNotifierProvider(
          create: (context) => CartProvider(context.read<CatalogProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CheckoutProvider(cart: context.read<CartProvider>()),
        ),
      ],
      child: const KassenApp(),
    );
  }
}

class KassenApp extends StatelessWidget {
  const KassenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      // Deutsche System-Texte (z. B. „Zurück“, „Einfügen“).
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: clubTheme,
      builder: (context, child) => OrientationLock(child: child!),
      home: const HomeScreen(),
    );
  }
}
