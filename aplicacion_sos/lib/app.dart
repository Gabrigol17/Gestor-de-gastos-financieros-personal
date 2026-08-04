import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/categorias_bloc.dart';
import 'bloc/movimientos_bloc.dart';
import 'bloc/tema_cubit.dart';
import 'data/categoria_repository.dart';
import 'data/movimiento_repository.dart';
import 'views/shell_principal.dart';

const _colorSemilla = Color(0xFF00A884);

/// Raíz de la aplicación: proveedores BLoC, tema y navegación.
class GestorApp extends StatelessWidget {
  const GestorApp({super.key, required this.temaInicial, required this.prefs});

  final ThemeMode temaInicial;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TemaCubit(prefs, temaInicial)),
        BlocProvider(create: (_) => CategoriasBloc(CategoriaRepository())),
        BlocProvider(create: (_) => MovimientosBloc(MovimientoRepository())),
      ],
      child: BlocBuilder<TemaCubit, ThemeMode>(
        builder: (contexto, modo) {
          return MaterialApp(
            title: 'Gestor Financiero',
            debugShowCheckedModeBanner: false,
            theme: _temaClaro(),
            darkTheme: _temaOscuro(),
            themeMode: modo,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ShellPrincipal(),
          );
        },
      ),
    );
  }

  ThemeData _temaClaro() {
    final esquema = ColorScheme.fromSeed(seedColor: _colorSemilla);
    return ThemeData(
      colorScheme: esquema,
      scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: esquema.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  ThemeData _temaOscuro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: _colorSemilla,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: esquema,
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: esquema.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
