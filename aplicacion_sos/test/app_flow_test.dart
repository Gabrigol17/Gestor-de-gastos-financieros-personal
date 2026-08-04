import 'package:aplicacion_sos/bloc/categorias_bloc.dart';
import 'package:aplicacion_sos/bloc/movimientos_bloc.dart';
import 'package:aplicacion_sos/bloc/tema_cubit.dart';
import 'package:aplicacion_sos/data/categoria_repository.dart';
import 'package:aplicacion_sos/data/movimiento_repository.dart';
import 'package:aplicacion_sos/models/categoria.dart';
import 'package:aplicacion_sos/models/movimiento.dart';
import 'package:aplicacion_sos/views/shell_principal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorios falsos: la base de datos FFI no avanza dentro del FakeAsync
/// de los widget tests, así que aquí se simula en memoria.
class _CategoriasFake extends CategoriaRepository {
  _CategoriasFake(this.datos);

  final List<Categoria> datos;

  @override
  Future<List<Categoria>> listar() async => List.of(datos);

  @override
  Future<int> insertar(Categoria categoria) async {
    datos.add(categoria);
    return 1;
  }

  @override
  Future<int> eliminar(int id) async {
    datos.removeWhere((c) => c.id == id);
    return 1;
  }
}

class _MovimientosFake extends MovimientoRepository {
  _MovimientosFake(this.datos);

  final List<Movimiento> datos;
  int _proximoId = 1;

  @override
  Future<int> registrar(Movimiento movimiento) async {
    final id = _proximoId++;
    datos.add(Movimiento(
      id: id,
      tipo: movimiento.tipo,
      monto: movimiento.monto,
      categoriaId: movimiento.categoriaId,
      comentario: movimiento.comentario,
      fecha: movimiento.fecha,
    ));
    return id;
  }

  @override
  Future<ResumenMes> resumenDelMes(DateTime referencia) async {
    var recibido = 0.0;
    var gastado = 0.0;
    for (final m in datos) {
      if (m.fecha.year == referencia.year && m.fecha.month == referencia.month) {
        if (m.tipo == TipoMovimiento.ahorro) {
          recibido += m.monto;
        } else {
          gastado += m.monto;
        }
      }
    }
    return ResumenMes(recibido: recibido, gastado: gastado);
  }

  @override
  Future<List<Movimiento>> listar({TipoMovimiento? tipo}) async {
    final lista =
        tipo == null ? datos : datos.where((m) => m.tipo == tipo).toList();
    return List.of(lista.reversed);
  }

  @override
  Future<int> eliminar(int id) async {
    datos.removeWhere((m) => m.id == id);
    return 1;
  }
}

Future<SharedPreferences> _prefsMock() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _appConFakes(
  List<Categoria> categorias,
  List<Movimiento> movimientos,
  SharedPreferences prefs,
) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => TemaCubit(prefs, ThemeMode.light)),
      BlocProvider(create: (_) => CategoriasBloc(_CategoriasFake(categorias))),
      BlocProvider(create: (_) => MovimientosBloc(_MovimientosFake(movimientos))),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ShellPrincipal(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('navegar a Ajustes y crear una categoría', (tester) async {
    final prefs = await _prefsMock();
    final categorias = [
      const Categoria(
        id: 1,
        nombre: 'Comida',
        colorValue: 0xFFF59E0B,
        iconoCodePoint: 0xe56c,
        tipo: TipoMovimiento.gasto,
        porDefecto: true,
      ),
    ];

    await tester.pumpWidget(_appConFakes(categorias, [], prefs));
    await tester.pumpAndSettle();

    // Ir a la pestaña Ajustes.
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    // La vista de configuración debe renderizar sus secciones (antes se
    // quedaba detenida por la inicialización concurrente de la BD).
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Apariencia'), findsOneWidget);

    // Abrir el diálogo de nueva categoría.
    await tester.tap(find.text('Nueva'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsOneWidget);

    // Escribir un nombre y guardar.
    await tester.enterText(find.byType(TextField), 'Gimnasio');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // La categoría creada debe aparecer en la lista.
    expect(find.text('Gimnasio'), findsOneWidget);
  });

  testWidgets('registrar un gasto, ver su fecha en el historial y eliminarlo',
      (tester) async {
    final prefs = await _prefsMock();
    final categorias = [
      const Categoria(
        id: 1,
        nombre: 'Comida',
        colorValue: 0xFFF59E0B,
        iconoCodePoint: 0xe56c,
        tipo: TipoMovimiento.gasto,
        porDefecto: true,
      ),
    ];

    await tester.pumpWidget(_appConFakes(categorias, [], prefs));
    await tester.pumpAndSettle();

    // Registrar un gasto de $1.000 con el teclado numérico. El teclado y el
    // botón pueden quedar fuera del viewport del test, así que se desplaza
    // la lista antes de tocar.
    await tester.ensureVisible(find.text('1'));
    await tester.pumpAndSettle();
    for (final digito in ['1', '0', '0', '0']) {
      await tester.tap(find.text(digito), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(find.text('Registrar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gasto'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Ir al historial: el movimiento debe aparecer con su fecha de registro.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.textContaining(r'$1.000'), findsOneWidget);
    final mes = DateFormat('MMM', 'es').format(DateTime.now());
    expect(
      find.textContaining(mes),
      findsWidgets,
      reason: 'cada movimiento debe mostrar la fecha en que se registró',
    );

    // Eliminar deslizando el movimiento hacia la izquierda.
    await tester.drag(
      find.textContaining(r'$1.000'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    // Confirmar en el diálogo.
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay movimientos'), findsOneWidget);
  });
}
