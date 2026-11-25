import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configura `databaseFactory` para escritorio; en móvil usa el plugin nativo.
void configureDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// Fábrica usada por las bases de datos en memoria (tests).
DatabaseFactory get inMemoryDatabaseFactory => databaseFactoryFfi;
