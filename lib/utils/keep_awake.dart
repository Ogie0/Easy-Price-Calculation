// Bildschirm anlassen, solange die Kasse offen ist. In der Android-App
// erledigt das MainActivity; im Browser (iPhone) die Screen-Wake-Lock-API.
export 'keep_awake_stub.dart' if (dart.library.js_interop) 'keep_awake_web.dart';
