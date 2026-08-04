import 'package:flutter/material.dart';

import '../models/categoria.dart';
import '../models/movimiento.dart';

/// Categorías por defecto que se crean la primera vez que se abre la app.
final categoriasIniciales = <Categoria>[
  // Gastos
  Categoria(
    nombre: 'Comida',
    colorValue: 0xFFF59E0B,
    iconoCodePoint: Icons.restaurant.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Transporte',
    colorValue: 0xFF3B82F6,
    iconoCodePoint: Icons.directions_bus.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Entretenimiento',
    colorValue: 0xFF8B5CF6,
    iconoCodePoint: Icons.movie.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Compras',
    colorValue: 0xFFEC4899,
    iconoCodePoint: Icons.shopping_bag.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Hogar',
    colorValue: 0xFF14B8A6,
    iconoCodePoint: Icons.home.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Salud',
    colorValue: 0xFFEF4444,
    iconoCodePoint: Icons.local_hospital.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Otros',
    colorValue: 0xFF6B7280,
    iconoCodePoint: Icons.category.codePoint,
    tipo: TipoMovimiento.gasto,
    porDefecto: true,
  ),
  // Ahorros
  Categoria(
    nombre: 'Ahorro general',
    colorValue: 0xFF10B981,
    iconoCodePoint: Icons.savings.codePoint,
    tipo: TipoMovimiento.ahorro,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Emergencias',
    colorValue: 0xFFF97316,
    iconoCodePoint: Icons.health_and_safety.codePoint,
    tipo: TipoMovimiento.ahorro,
    porDefecto: true,
  ),
  Categoria(
    nombre: 'Meta',
    colorValue: 0xFF3B82F6,
    iconoCodePoint: Icons.flag.codePoint,
    tipo: TipoMovimiento.ahorro,
    porDefecto: true,
  ),
];
