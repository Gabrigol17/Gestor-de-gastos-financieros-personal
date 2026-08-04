import 'package:flutter/material.dart';

import 'movimiento.dart';

/// Categoría creada por el usuario para clasificar sus gastos o ahorros.
class Categoria {
  final int? id;
  final String nombre;
  final int colorValue;
  final int iconoCodePoint;
  final TipoMovimiento tipo;

  /// Las categorías por defecto no pueden eliminarse desde la UI.
  final bool porDefecto;

  const Categoria({
    this.id,
    required this.nombre,
    required this.colorValue,
    required this.iconoCodePoint,
    required this.tipo,
    this.porDefecto = false,
  });

  Color get color => Color(colorValue);

  IconData get icono => IconData(iconoCodePoint, fontFamily: 'MaterialIcons');

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'color': colorValue,
        'icono': iconoCodePoint,
        'tipo': tipo.dbValue,
        'por_defecto': porDefecto ? 1 : 0,
      };

  factory Categoria.fromMap(Map<String, Object?> map) => Categoria(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        colorValue: map['color'] as int,
        iconoCodePoint: map['icono'] as int,
        tipo: TipoMovimiento.fromDb(map['tipo'] as String),
        porDefecto: (map['por_defecto'] as int) == 1,
      );
}
