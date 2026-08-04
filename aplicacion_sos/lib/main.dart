import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilita el formato de fechas en español (meses, días de la semana).
  await initializeDateFormatting('es');

  final prefs = await SharedPreferences.getInstance();
  final temaGuardado = prefs.getString('tema');
  final temaInicial =
      temaGuardado == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;

  runApp(GestorApp(temaInicial: temaInicial, prefs: prefs));
}
