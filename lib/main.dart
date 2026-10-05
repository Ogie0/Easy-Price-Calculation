import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/orientation_lock.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProxyProvider<CatalogProvider, CartProvider>(
          create: (context) => CartProvider(context.read<CatalogProvider>()),
          update: (_, catalog, cart) => cart!..updateCatalog(catalog),
        ),
      ],
      child: const KassenApp(),
    ),
  );
}

class KassenApp extends StatelessWidget {
  const KassenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vereinskasse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      builder: (context, child) => OrientationLock(child: child!),
      home: const HomeScreen(),
    );
  }
}
