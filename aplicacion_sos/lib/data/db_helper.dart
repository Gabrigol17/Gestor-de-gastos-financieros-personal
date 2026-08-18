import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'categorias_iniciales.dart';

/// Punto único de acceso a la base de datos SQLite de la app.
///
/// La inicialización se guarda como una única [Future] compartida para que,
/// aunque varios BLoCs pidan la base al mismo tiempo (p. ej. al arrancar),
/// la apertura y el sembrado de categorías se ejecuten una sola vez.
/// Esto evita dos problemas reales: que la vista de Ajustes se quede
/// detenida esperando un candado por aperturas concurrentes, y que las
/// categorías iniciales se inserten por duplicado.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nombreDb = 'gestor_financiero.db';
  static const _version = 4;

  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _inicializarConReintento();

  /// Si la apertura falla, se descarta la [Future] memoizada para que el
  /// siguiente acceso pueda reintentar.
  Future<Database> _inicializarConReintento() async {
    try {
      return await _inicializar();
    } catch (_) {
      _dbFuture = null;
      rethrow;
    }
  }

  Future<Database> _inicializar() async {
    final db = await _abrir();
    await _sembrarCategoriasIniciales(db);
    return db;
  }

  Future<Database> _abrir() async {
    final ruta = p.join(await getDatabasesPath(), _nombreDb);
    return openDatabase(
      ruta,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crearEsquema,
      onUpgrade: _actualizarEsquema,
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
        medio_pago TEXT NOT NULL DEFAULT 'efectivo',
        banco TEXT,
        FOREIGN KEY(categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
      )
    ''');
    await _crearIndiceUnicoCategorias(db);
    await _crearIndicesMovimientos(db);
  }

  Future<void> _actualizarEsquema(
    Database db,
    int versionAnterior,
    int versionNueva,
  ) async {
    if (versionAnterior < 2) {
      // Limpia las categorías duplicadas que pudieron quedar por versiones
      // anteriores y evita que vuelvan a aparecer con un índice único.
      await _deduplicarCategorias(db);
      await _crearIndiceUnicoCategorias(db);
    }
    if (versionAnterior < 3) {
      // Acelera el resumen mensual y el historial a medida que crece la tabla
      // de movimientos. Solo crea índices; no altera ningún dato existente.
      await _crearIndicesMovimientos(db);
    }
    if (versionAnterior < 4) {
      // Agrega soporte para medio de pago (efectivo / transferencia) y banco.
      // Los registros existentes quedan como 'efectivo' por defecto.
      await db.execute(
        "ALTER TABLE movimientos ADD COLUMN medio_pago TEXT NOT NULL DEFAULT 'efectivo'",
      );
      await db.execute(
        'ALTER TABLE movimientos ADD COLUMN banco TEXT',
      );
    }
  }

  Future<void> _crearIndiceUnicoCategorias(Database db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_categorias_nombre_tipo '
      'ON categorias(nombre COLLATE NOCASE, tipo)',
    );
  }

  /// Índices para las consultas más frecuentes sobre movimientos: el resumen
  /// mensual filtra por rango de [fecha] y el historial ordena por ella;
  /// [categoria_id] acelera la unión con la tabla de categorías.
  Future<void> _crearIndicesMovimientos(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movimientos_fecha ON movimientos(fecha)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movimientos_categoria_id '
      'ON movimientos(categoria_id)',
    );
  }

  /// Conserva una sola categoría por (nombre, tipo) sin importar mayúsculas:
  /// reasigna sus movimientos a la categoría que se conserva (la de menor id)
  /// y elimina el resto de duplicados.
  Future<void> _deduplicarCategorias(Database db) async {
    final grupos = await db.rawQuery('''
      SELECT LOWER(nombre) AS nombre, tipo, MIN(id) AS conservada,
             GROUP_CONCAT(id) AS ids
      FROM categorias
      GROUP BY LOWER(nombre), tipo
      HAVING COUNT(*) > 1
    ''');

    for (final grupo in grupos) {
      final conservada = grupo['conservada'] as int;
      final ids = (grupo['ids'] as String).split(',').map(int.parse).toList();
      final descartadas = ids.where((i) => i != conservada).toList();
      final marcadores = List.filled(descartadas.length, '?').join(',');

      await db.update(
        'movimientos',
        {'categoria_id': conservada},
        where: 'categoria_id IN ($marcadores)',
        whereArgs: descartadas,
      );
      await db.delete(
        'categorias',
        where: 'id IN ($marcadores)',
        whereArgs: descartadas,
      );
    }
  }

  Future<void> _sembrarCategoriasIniciales(Database db) async {
    final conteo = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categorias'),
        ) ??
        0;
    if (conteo > 0) return;

    final batch = db.batch();
    for (final categoria in categoriasIniciales) {
      batch.insert(
        'categorias',
        categoria.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
