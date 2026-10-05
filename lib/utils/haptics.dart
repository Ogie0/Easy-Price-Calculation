import 'dart:async';

import 'package:flutter/services.dart';

/// Kurze Vibration als Bestätigung, dass ein Tipp angekommen ist (z. B. im
/// Festlärm). Richtet sich nach der Systemeinstellung „Vibration bei
/// Berührung“.
void tapFeedback() => unawaited(HapticFeedback.lightImpact());

/// Deutlichere Vibration beim Abschließen eines Kaufs.
void completeFeedback() => unawaited(HapticFeedback.mediumImpact());
