import 'package:flutter/material.dart';

/// Iconos disponibles al crear una categoría: código de punto → [IconData].
///
/// Se usa un mapa (en vez de construir `IconData(...)` en tiempo de
/// ejecución) para que el compilador AOT en release pueda eliminar del
/// binario los glifos que la app no usa (tree-shake-icons): los valores son
/// instancias constantes de `Icons.*`, no construcciones dinámicas. La base
/// de datos guarda los códigos; la app los resuelve contra este mapa.
final Map<int, IconData> iconosCategoria = {
  Icons.restaurant.codePoint: Icons.restaurant,
  Icons.directions_bus.codePoint: Icons.directions_bus,
  Icons.movie.codePoint: Icons.movie,
  Icons.shopping_bag.codePoint: Icons.shopping_bag,
  Icons.home.codePoint: Icons.home,
  Icons.local_hospital.codePoint: Icons.local_hospital,
  Icons.savings.codePoint: Icons.savings,
  Icons.health_and_safety.codePoint: Icons.health_and_safety,
  Icons.flag.codePoint: Icons.flag,
  Icons.school.codePoint: Icons.school,
  Icons.work.codePoint: Icons.work,
  Icons.sports_soccer.codePoint: Icons.sports_soccer,
  Icons.pets.codePoint: Icons.pets,
  Icons.flight.codePoint: Icons.flight,
  Icons.phone_android.codePoint: Icons.phone_android,
  Icons.coffee.codePoint: Icons.coffee,
  Icons.music_note.codePoint: Icons.music_note,
  Icons.fitness_center.codePoint: Icons.fitness_center,
  Icons.card_giftcard.codePoint: Icons.card_giftcard,
  Icons.category.codePoint: Icons.category,
};

/// Códigos de los iconos disponibles al crear una categoría, en orden de uso.
final List<int> codigosIconosCategoria = iconosCategoria.keys.toList();

/// Colores disponibles al crear una categoría.
const List<Color> paletaColoresCategoria = [
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF14B8A6),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF6B7280),
  Color(0xFF1F2937),
];
