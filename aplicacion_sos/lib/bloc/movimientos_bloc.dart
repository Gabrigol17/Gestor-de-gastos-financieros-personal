import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/movimiento_repository.dart';
import '../models/movimiento.dart';

sealed class MovimientosEvent {
  const MovimientosEvent();
}

final class CargarDatos extends MovimientosEvent {
  const CargarDatos();
}

final class RegistrarMovimiento extends MovimientosEvent {
  final Movimiento movimiento;

  const RegistrarMovimiento(this.movimiento);
}

final class EliminarMovimiento extends MovimientosEvent {
  final int id;

  const EliminarMovimiento(this.id);
}

final class FiltrarPorTipo extends MovimientosEvent {
  final TipoMovimiento? tipo;

  const FiltrarPorTipo(this.tipo);
}

class MovimientosState {
  final bool cargando;
  final ResumenMes resumen;
  final List<Movimiento> movimientos;
  final TipoMovimiento? filtro;

  /// Mensaje informativo para mostrar en un SnackBar (registro, borrado, error).
  final String? mensaje;

  const MovimientosState({
    required this.cargando,
    required this.resumen,
    required this.movimientos,
    this.filtro,
    this.mensaje,
  });

  factory MovimientosState.inicial() => const MovimientosState(
        cargando: true,
        resumen: ResumenMes(recibido: 0, gastado: 0),
        movimientos: [],
      );

  static const _sinValor = Object();

  MovimientosState copyWith({
    bool? cargando,
    ResumenMes? resumen,
    List<Movimiento>? movimientos,
    Object? filtro = _sinValor,
    String? mensaje,
    bool limpiarMensaje = false,
  }) =>
      MovimientosState(
        cargando: cargando ?? this.cargando,
        resumen: resumen ?? this.resumen,
        movimientos: movimientos ?? this.movimientos,
        filtro: identical(filtro, _sinValor) ? this.filtro : filtro as TipoMovimiento?,
        mensaje: limpiarMensaje ? null : (mensaje ?? this.mensaje),
      );
}

/// Gestiona el resumen mensual y el historial de movimientos.
class MovimientosBloc extends Bloc<MovimientosEvent, MovimientosState> {
  MovimientosBloc(this._repo) : super(MovimientosState.inicial()) {
    on<CargarDatos>(_cargar);
    on<RegistrarMovimiento>(_registrar);
    on<EliminarMovimiento>(_eliminar);
    on<FiltrarPorTipo>(_filtrar);
    add(const CargarDatos());
  }

  final MovimientoRepository _repo;

  Future<void> _recargar(Emitter<MovimientosState> emit) async {
    // El resumen y el historial son independientes: se consultan en paralelo.
    final (resumen, movimientos) = await (
      _repo.resumenDelMes(DateTime.now()),
      _repo.listar(tipo: state.filtro),
    ).wait;
    emit(state.copyWith(
      cargando: false,
      resumen: resumen,
      movimientos: movimientos,
    ));
  }

  Future<void> _cargar(CargarDatos evento, Emitter<MovimientosState> emit) async {
    emit(state.copyWith(cargando: true, limpiarMensaje: true));
    try {
      await _recargar(emit);
    } catch (_) {
      emit(state.copyWith(
        cargando: false,
        mensaje: 'No se pudieron cargar los datos',
      ));
    }
  }

  Future<void> _registrar(
    RegistrarMovimiento evento,
    Emitter<MovimientosState> emit,
  ) async {
    try {
      final id = await _repo.registrar(evento.movimiento);
      // El movimiento recién guardado es el más reciente: se inserta al frente
      // de la lista en memoria y solo se recalcula el resumen, sin volver a
      // leer el historial completo de la base de datos.
      final resumen = await _repo.resumenDelMes(DateTime.now());
      final nuevo = Movimiento(
        id: id,
        tipo: evento.movimiento.tipo,
        monto: evento.movimiento.monto,
        categoriaId: evento.movimiento.categoriaId,
        comentario: evento.movimiento.comentario,
        fecha: evento.movimiento.fecha,
      );
      // Si el filtro activo excluye el nuevo movimiento, no se agrega a la
      // vista; la próxima consulta del filtro lo mostrará desde la BD.
      final coincide = state.filtro == null || state.filtro == nuevo.tipo;
      emit(state.copyWith(
        resumen: resumen,
        movimientos: coincide ? [nuevo, ...state.movimientos] : state.movimientos,
        mensaje: '${evento.movimiento.tipo.nombre} registrado ✓',
      ));
    } catch (_) {
      emit(state.copyWith(mensaje: 'No se pudo registrar el movimiento'));
    }
  }

  Future<void> _eliminar(
    EliminarMovimiento evento,
    Emitter<MovimientosState> emit,
  ) async {
    try {
      await _repo.eliminar(evento.id);
      // Se quita de la lista en memoria y solo se recalcula el resumen, sin
      // releer el historial completo.
      final resumen = await _repo.resumenDelMes(DateTime.now());
      emit(state.copyWith(
        resumen: resumen,
        movimientos:
            state.movimientos.where((m) => m.id != evento.id).toList(),
        mensaje: 'Movimiento eliminado',
      ));
    } catch (_) {
      emit(state.copyWith(mensaje: 'No se pudo eliminar el movimiento'));
    }
  }

  Future<void> _filtrar(
    FiltrarPorTipo evento,
    Emitter<MovimientosState> emit,
  ) async {
    emit(state.copyWith(cargando: true, filtro: evento.tipo, limpiarMensaje: true));
    try {
      final movimientos = await _repo.listar(tipo: evento.tipo);
      emit(state.copyWith(cargando: false, movimientos: movimientos));
    } catch (_) {
      emit(state.copyWith(
        cargando: false,
        mensaje: 'No se pudieron cargar los datos',
      ));
    }
  }
}
