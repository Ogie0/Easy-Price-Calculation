import 'package:flutter/widgets.dart';

/// Ab dieser kürzesten Bildschirmseite (in logischen Pixeln) gilt ein Gerät
/// als Tablet.
const double kTabletBreakpoint = 600;

bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= kTabletBreakpoint;
