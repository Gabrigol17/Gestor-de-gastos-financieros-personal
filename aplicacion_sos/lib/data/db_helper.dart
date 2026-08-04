import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'categorias_iniciales.dart';
import 'db_factory_stub.dart' if (dart.library.io) 'db_factory_io.dart';

/// Punto único de acceso a la base de datos SQLite de la app.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nombreDb = 'gestor_financiero.db';
  static const _version = 1;

  Database? _db;
  bool _sembrado = false;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _abrir();
    if (!_sembrado) {
      await _sembrarCategoriasIniciales(_db!);
      _sembrado = true;
    }
    return _db!;
  }

  Future<Database> _abrir() async {
    // En escritorio (Windows/Linux/macOS) sqflite necesita el adaptador FFI.
    final esEscritorio = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (esEscritorio) {
      configurarFactoryEscritorio();
    }

    final ruta = p.join(await getDatabasesPath(), _nombreDb);
    return openDatabase(
      ruta,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crearEsquema,
    );
  }

  Future<void> _crearEsquema(Database db, int version) async {
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
  }

  Future<void> _sembrarCategoriasIniciales(Database db) async {
    final conteo = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categorias'),
        ) ??
        0;
    if (conteo > 0) return;

    final batch = db.batch();
    for (final categoria in categoriasIniciales) {
      batch.insert('categorias', categoria.toMap());
    }
    await batch.commit(noResult: true);
  }
}
