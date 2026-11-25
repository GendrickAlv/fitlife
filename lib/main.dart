import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'data/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initFactoryForPlatform();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';
  runApp(const FitLifeApp());
}
