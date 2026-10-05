import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';

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
    return const MaterialApp(
      title: 'Vereinskasse',
      home: Scaffold(body: Center(child: Text('Vereinskasse'))),
    );
  }
}
