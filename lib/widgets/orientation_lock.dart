import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/layout.dart';

/// Sperrt die Ausrichtung: Hochformat auf Smartphones, Querformat auf Tablets.
class OrientationLock extends StatefulWidget {
  final Widget child;

  const OrientationLock({super.key, required this.child});

  @override
  State<OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<OrientationLock> {
  bool? _appliedTablet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    if (size.isEmpty) return;
    final tablet = isTablet(context);
    if (_appliedTablet == tablet) return;
    _appliedTablet = tablet;
    unawaited(SystemChrome.setPreferredOrientations(
      tablet
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [DeviceOrientation.portraitUp],
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
