import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.WakeLockSentinel? _lock;
bool _requesting = false;

/// Fordert die Bildschirmsperre an (Safari ab iOS 16.4, Chrome, Edge …).
/// Der Browser gibt sie frei, sobald die Seite verborgen wird; beim
/// Zurückkehren und beim nächsten Tippen wird sie neu angefordert.
void keepScreenOnInBrowser() {
  unawaited(_request());
  void onEvent(web.Event _) => unawaited(_request());
  web.document.addEventListener('visibilitychange', onEvent.toJS);
  web.document.addEventListener('pointerdown', onEvent.toJS);
}

Future<void> _request() async {
  if (_requesting || web.document.visibilityState != 'visible') return;
  if (_lock != null && !_lock!.released) return;
  _requesting = true;
  try {
    _lock = await web.window.navigator.wakeLock.request('screen').toDart;
  } on Object {
    // Nicht unterstützt oder abgelehnt (z. B. Energiesparmodus): dann eben nicht.
  } finally {
    _requesting = false;
  }
}
