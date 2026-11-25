import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Configura `databaseFactory` para web (SQLite en WebAssembly + IndexedDB).
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}

/// Fábrica usada por las bases de datos en memoria.
DatabaseFactory get inMemoryDatabaseFactory => databaseFactoryFfiWeb;
