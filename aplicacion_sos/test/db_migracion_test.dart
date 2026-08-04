import 'dart:io';

import 'package:aplicacion_sos/data/db_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('la migración v1→v2 elimina duplicados y conserva los movimientos', () async {
    // 1. Crear una base con el esquema de la v1 (sin índice único) y
    //    categorías duplicadas que ya tienen movimientos asociados.
    final dir = await getDatabasesPath();
    final ruta = p.join(dir, 'gestor_financiero.db');
    final archivo = File(ruta);
    if (archivo.existsSync()) archivo.deleteSync();

    final dbV1 = await openDatabase(ruta, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE categorias(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          color INTEGER NOT NULL,
          icono INTEGER NOT NULL,
          tipo TEXT NOT NULL,
          por_defecto INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE movimientos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          monto REAL NOT NULL,
          categoria_id INTEGER,
          comentario TEXT,
          fecha TEXT NOT NULL,
          FOREIGN KEY(categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
        )
      ''');
    });
    await dbV1.insert('categorias', {
      'nombre': 'Comida',
      'color': 1,
      'icono': 1,
      'tipo': 'gasto',
      'por_defecto': 1,
    });
    await dbV1.insert('categorias', {
      'nombre': 'comida',
      'color': 2,
      'icono': 2,
      'tipo': 'gasto',
      'por_defecto': 1,
    });
    await dbV1.insert('categorias', {
      'nombre': 'Meta',
      'color': 3,
      'icono': 3,
      'tipo': 'ahorro',
      'por_defecto': 1,
    });
    final idMetaDuplicada = await dbV1.insert('categorias', {
      'nombre': 'meta',
      'color': 4,
      'icono': 4,
      'tipo': 'ahorro',
      'por_defecto': 1,
    });
    await dbV1.insert('movimientos', {
      'tipo': 'gasto',
      'monto': 10000,
      'categoria_id': 2, // apunta a la 'comida' duplicada
      'fecha': '2026-08-01T10:00:00.000',
    });
    await dbV1.insert('movimientos', {
      'tipo': 'ahorro',
      'monto': 5000,
      'categoria_id': idMetaDuplicada,
      'fecha': '2026-08-02T10:00:00.000',
    });
    await dbV1.close();

    // 2. Abrir con DatabaseHelper (v2): debe migrar y deduplicar.
    final db = await DatabaseHelper.instance.database;

    final categorias = await db.query('categorias', orderBy: 'id ASC');
    expect(categorias, hasLength(2), reason: 'debe quedar una por (nombre, tipo)');
    expect(categorias.map((c) => c['id']), containsAll([1, 3]));

    // Los movimientos deben apuntar a la categoría conservada (menor id).
    final movimientos = await db.query('movimientos', orderBy: 'id ASC');
    expect(movimientos, hasLength(2));
    expect(movimientos[0]['categoria_id'], 1); // Comida
    expect(movimientos[1]['categoria_id'], 3); // Meta

    // El índice único impide volver a insertar duplicados.
    await expectLater(
      db.insert('categorias', {
        'nombre': 'Comida',
        'color': 5,
        'icono': 5,
        'tipo': 'gasto',
        'por_defecto': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
