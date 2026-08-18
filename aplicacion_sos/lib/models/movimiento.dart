/// Tipos de movimiento que puede registrar el usuario.
enum TipoMovimiento {
  gasto,
  ahorro;

  String get nombre => switch (this) {
        TipoMovimiento.gasto => 'Gasto',
        TipoMovimiento.ahorro => 'Ingresos',
      };

  /// Valor que se guarda en la base de datos.
  String get dbValue => name;

  static TipoMovimiento fromDb(String valor) =>
      TipoMovimiento.values.firstWhere((t) => t.name == valor);
}

/// Resumen de movimientos del mes actual.
///
/// Como la app solo registra gastos e ingresos, el monto "recibido" del mes
/// corresponde a la suma de los ingresos y el "gastado" a la suma de gastos.
class ResumenMes {
  final double recibido;
  final double gastado;

  const ResumenMes({required this.recibido, required this.gastado});

  double get balance => recibido - gastado;
}

/// Un movimiento de gasto o ingreso registrado por el usuario.
class Movimiento {
  final int? id;
  final TipoMovimiento tipo;
  final double monto;
  final int? categoriaId;
  final String? comentario;
  final DateTime fecha;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    this.categoriaId,
    this.comentario,
    required this.fecha,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'tipo': tipo.dbValue,
        'monto': monto,
        'categoria_id': categoriaId,
        'comentario': comentario,
        'fecha': fecha.toIso8601String(),
      };

  factory Movimiento.fromMap(Map<String, Object?> map) => Movimiento(
        id: map['id'] as int?,
        tipo: TipoMovimiento.fromDb(map['tipo'] as String),
        monto: (map['monto'] as num).toDouble(),
        categoriaId: map['categoria_id'] as int?,
        comentario: map['comentario'] as String?,
        fecha: DateTime.parse(map['fecha'] as String),
      );
}
