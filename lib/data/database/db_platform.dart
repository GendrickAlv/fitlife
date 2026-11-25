/// Selección de la fábrica de SQLite según la plataforma.
///
/// - Android / iOS: plugin nativo `sqflite` (no requiere configuración).
/// - Windows / Linux / macOS: `sqflite_common_ffi`.
/// - Web: `sqflite_common_ffi_web` (SQLite compilado a WebAssembly).
library;

export 'db_platform_io.dart'
    if (dart.library.js_interop) 'db_platform_web.dart';
