import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/categoria_repository.dart';
import '../models/categoria.dart';

sealed class CategoriasEvent {
  const CategoriasEvent();
}

final class CargarCategorias extends CategoriasEvent {
  const CargarCategorias();
}

final class AgregarCategoria extends CategoriasEvent {
  final Categoria categoria;

  const AgregarCategoria(this.categoria);
}

final class EliminarCategoria extends CategoriasEvent {
  final int id;

  const EliminarCategoria(this.id);
}

class CategoriasState {
  final bool cargando;
  final List<Categoria> categorias;
  final String? mensaje;

  const CategoriasState({
    required this.cargando,
    required this.categorias,
    this.mensaje,
  });

  CategoriasState copyWith({
    bool? cargando,
    List<Categoria>? categorias,
    String? mensaje,
    bool limpiarMensaje = false,
  }) =>
      CategoriasState(
        cargando: cargando ?? this.cargando,
        categorias: categorias ?? this.categorias,
        mensaje: limpiarMensaje ? null : (mensaje ?? this.mensaje),
      );
}

/// Gestiona el catálogo de categorías del usuario.
class CategoriasBloc extends Bloc<CategoriasEvent, CategoriasState> {
  CategoriasBloc(this._repo)
      : super(const CategoriasState(cargando: true, categorias: [])) {
    on<CargarCategorias>(_cargar);
    on<AgregarCategoria>(_agregar);
    on<EliminarCategoria>(_eliminar);
    add(const CargarCategorias());
  }

  final CategoriaRepository _repo;

  Future<void> _cargar(
    CargarCategorias evento,
    Emitter<CategoriasState> emit,
  ) async {
    try {
      final categorias = await _repo.listar();
      emit(CategoriasState(cargando: false, categorias: categorias));
    } catch (_) {
      emit(const CategoriasState(
        cargando: false,
        categorias: [],
        mensaje: 'No se pudieron cargar las categorías',
      ));
    }
  }

  Future<void> _agregar(
    AgregarCategoria evento,
    Emitter<CategoriasState> emit,
  ) async {
    try {
      await _repo.insertar(evento.categoria);
      final categorias = await _repo.listar();
      emit(CategoriasState(
        cargando: false,
        categorias: categorias,
        mensaje: 'Categoría "${evento.categoria.nombre}" creada',
      ));
    } catch (_) {
      emit(state.copyWith(mensaje: 'No se pudo crear la categoría'));
    }
  }

  Future<void> _eliminar(
    EliminarCategoria evento,
    Emitter<CategoriasState> emit,
  ) async {
    try {
      await _repo.eliminar(evento.id);
      final categorias = await _repo.listar();
      emit(CategoriasState(
        cargando: false,
        categorias: categorias,
        mensaje: 'Categoría eliminada',
      ));
    } catch (_) {
      emit(state.copyWith(mensaje: 'No se pudo eliminar la categoría'));
    }
  }
}
