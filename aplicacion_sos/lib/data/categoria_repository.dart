import '../models/categoria.dart';
import 'db_helper.dart';

/// Operaciones de persistencia sobre la tabla de categorías.
class CategoriaRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Categoria>> listar() async {
    final db = await _helper.database;
    final filas = await db.query('categorias', orderBy: 'tipo ASC, id ASC');
    return filas.map(Categoria.fromMap).toList();
  }

  Future<int> insertar(Categoria categoria) async {
    final db = await _helper.database;
    return db.insert('categorias', categoria.toMap());
  }

  Future<int> eliminar(int id) async {
    final db = await _helper.database;
    return db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}
