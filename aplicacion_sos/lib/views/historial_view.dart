import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/categorias_bloc.dart';
import '../bloc/movimientos_bloc.dart';
import '../models/categoria.dart';
import '../models/movimiento.dart';
import '../utils/formato_moneda.dart';

enum _FiltroHistorial { todos, gasto, ahorro }

/// Vista de historial: movimientos agrupados por día, con filtros, fecha de
/// registro y borrado por deslizamiento o menú contextual.
class HistorialView extends StatefulWidget {
  const HistorialView({super.key});

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  _FiltroHistorial _filtro = _FiltroHistorial.todos;

  /// Movimientos que ya se deslizaron y esperan a que el BLoC recargue la
  /// lista; evita que un elemento eliminado reaparezca antes de la recarga.
  final Set<int> _pendientesEliminar = {};

  void _cambiarFiltro(_FiltroHistorial nuevo) {
    if (nuevo == _filtro) return;
    setState(() => _filtro = nuevo);
    final tipo = switch (nuevo) {
      _FiltroHistorial.todos => null,
      _FiltroHistorial.gasto => TipoMovimiento.gasto,
      _FiltroHistorial.ahorro => TipoMovimiento.ahorro,
    };
    context.read<MovimientosBloc>().add(FiltrarPorTipo(tipo));
  }

  void _eliminarMovimiento(Movimiento mov) {
    final id = mov.id;
    if (id == null) return;
    setState(() => _pendientesEliminar.add(id));
    context.read<MovimientosBloc>().add(EliminarMovimiento(id));
  }

  /// Muestra el diálogo de confirmación y devuelve si el usuario confirmó.
  Future<bool> _confirmarEliminar(BuildContext contexto, Movimiento mov) async {
    final confirmado = await showDialog<bool>(
      context: contexto,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
          '¿Eliminar ${formatoMoneda(mov.monto)} de ${mov.tipo.nombre.toLowerCase()}? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  void _mostrarOpciones(BuildContext contexto, Movimiento mov) {
    showModalBottomSheet<void>(
      context: contexto,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(hoja).colorScheme.error,
              ),
              title: const Text('Eliminar movimiento'),
              subtitle: Text('Se quitará del historial y del balance'),
              onTap: () async {
                Navigator.pop(hoja);
                final confirmado = await _confirmarEliminar(contexto, mov);
                if (confirmado && contexto.mounted) {
                  _eliminarMovimiento(mov);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _etiquetaDia(DateTime f) {
    final hoy = DateTime.now();
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    bool mismaFecha(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (mismaFecha(f, hoy)) return 'Hoy';
    if (mismaFecha(f, ayer)) return 'Ayer';
    final texto = DateFormat("EEEE, d 'de' MMMM", 'es').format(f);
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _itemMovimiento(
    BuildContext contexto,
    Movimiento m,
    Categoria? categoria,
  ) {
    final esAhorro = m.tipo == TipoMovimiento.ahorro;
    final color = categoria?.color ??
        (esAhorro ? const Color(0xFF10B981) : const Color(0xFFEF4444));
    final icono = categoria?.icono ??
        (esAhorro ? Icons.savings_rounded : Icons.wallet_rounded);
    final colorMonto =
        esAhorro ? const Color(0xFF10B981) : Theme.of(contexto).colorScheme.error;
    final tieneComentario = m.comentario != null && m.comentario!.isNotEmpty;
    final fechaTexto = DateFormat('d MMM, HH:mm', 'es').format(m.fecha);

    final tile = ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icono, color: color),
        ),
        title: Text(
          categoria?.nombre ?? 'Sin categoría',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fechaTexto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(contexto).colorScheme.onSurfaceVariant,
              ),
            ),
            if (tieneComentario)
              Text(
                m.comentario!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(contexto).colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${esAhorro ? '+' : '−'}${formatoMoneda(m.monto)}',
          style: TextStyle(
            color: colorMonto,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        onLongPress: () => _mostrarOpciones(contexto, m),
      );
    // Un movimiento sin id no se puede borrar ni eliminar de forma segura;
    // se muestra sin acciones de deslizamiento.
    if (m.id == null) return tile;
    return Dismissible(
      key: ValueKey('movimiento-${m.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(contexto).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmarEliminar(contexto, m),
      onDismissed: (_) => _eliminarMovimiento(m),
      child: tile,
    );
  }

  Widget _lista(
    BuildContext contexto,
    List<Movimiento> movimientos,
    Map<int, Categoria> categorias,
  ) {
    final porDia = <DateTime, List<Movimiento>>{};
    for (final m in movimientos) {
      if (m.id != null && _pendientesEliminar.contains(m.id)) continue;
      final clave = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      porDia.putIfAbsent(clave, () => []).add(m);
    }

    final entradas = porDia.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: entradas.length,
      itemBuilder: (contexto, i) {
        final entrada = entradas[i];
        final fecha = entrada.key;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text(
                _etiquetaDia(fecha),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(contexto).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Card(
              elevation: 0,
              child: Column(
                children: [
                  for (var j = 0; j < entrada.value.length; j++) ...[
                    if (j > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    _itemMovimiento(
                      contexto,
                      entrada.value[j],
                      categorias[entrada.value[j].categoriaId],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _vacio(BuildContext contexto) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Theme.of(contexto).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no hay movimientos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(contexto).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra tu primer gasto o ingreso',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(contexto).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Desliza un movimiento a la izquierda para eliminarlo',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(contexto).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasPorId = context.select<CategoriasBloc, Map<int, Categoria>>(
      (b) => {for (final c in b.state.categorias) if (c.id != null) c.id!: c},
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Historial',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SegmentedButton<_FiltroHistorial>(
              segments: const [
                ButtonSegment(
                  value: _FiltroHistorial.todos,
                  label: Text('Todos'),
                  icon: Icon(Icons.list_rounded),
                ),
                ButtonSegment(value: _FiltroHistorial.gasto, label: Text('Gastos')),
                ButtonSegment(value: _FiltroHistorial.ahorro, label: Text('Ingresos')),
              ],
              selected: {_filtro},
              onSelectionChanged: (s) => _cambiarFiltro(s.first),
              showSelectedIcon: false,
            ),
          ),
          Expanded(
            child: BlocBuilder<MovimientosBloc, MovimientosState>(
              builder: (contexto, estado) {
                // Descarta de la lista de pendientes los movimientos que el
                // BLoC ya dejó de incluir tras recargar.
                if (_pendientesEliminar.isNotEmpty) {
                  final vivos = estado.movimientos.map((m) => m.id).toSet();
                  _pendientesEliminar.removeWhere((id) => !vivos.contains(id));
                }
                if (estado.cargando && estado.movimientos.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.movimientos.isEmpty) {
                  return _vacio(contexto);
                }
                return _lista(contexto, estado.movimientos, categoriasPorId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
