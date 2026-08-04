import '../models/movimiento.dart';
import 'db_helper.dart';

/// Operaciones de persistencia sobre la tabla de movimientos.
class MovimientoRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<int> registrar(Movimiento movimiento) async {
    final db = await _helper.database;
    return db.insert('movimientos', movimiento.toMap());
  }

  /// Suma de ahorros (recibido) y de gastos del mes de [referencia].
  Future<ResumenMes> resumenDelMes(DateTime referencia) async {
    final db = await _helper.database;
    final inicio = DateTime(referencia.year, referencia.month, 1);
    final fin = DateTime(referencia.year, referencia.month + 1, 1);

    final filas = await db.rawQuery(
      'SELECT tipo, SUM(monto) AS total '
      'FROM movimientos WHERE fecha >= ? AND fecha < ? GROUP BY tipo',
      [inicio.toIso8601String(), fin.toIso8601String()],
    );

    double recibido = 0;
    double gastado = 0;
    for (final fila in filas) {
      final total = (fila['total'] as num?)?.toDouble() ?? 0;
      if (fila['tipo'] == TipoMovimiento.ahorro.dbValue) {
        recibido = total;
      } else {
        gastado = total;
      }
    }
    return ResumenMes(recibido: recibido, gastado: gastado);
  }

  Future<List<Movimiento>> listar({TipoMovimiento? tipo}) async {
    final db = await _helper.database;
    final filas = tipo == null
        ? await db.query('movimientos', orderBy: 'fecha DESC, id DESC')
        : await db.query(
            'movimientos',
            where: 'tipo = ?',
            whereArgs: [tipo.dbValue],
            orderBy: 'fecha DESC, id DESC',
          );
    return filas.map(Movimiento.fromMap).toList();
  }

  Future<int> eliminar(int id) async {
    final db = await _helper.database;
    return db.delete('movimientos', where: 'id = ?', whereArgs: [id]);
  }
}
