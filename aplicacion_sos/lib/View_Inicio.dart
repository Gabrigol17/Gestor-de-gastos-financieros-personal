// El nombre del archivo sigue la convención existente del proyecto.
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/categorias_bloc.dart';
import 'bloc/movimientos_bloc.dart';
import 'models/categoria.dart';
import 'models/movimiento.dart';
import 'utils/formato_moneda.dart';
import 'widgets/tarjeta_balance.dart';
import 'widgets/teclado_numerico.dart';

/// Vista inicial: balance del mes y registro rápido de gastos o ahorros.
class ViewInicio extends StatefulWidget {
  const ViewInicio({super.key});

  @override
  State<ViewInicio> createState() => _ViewInicioState();
}

class _ViewInicioState extends State<ViewInicio> {
  static const _montosRapidos = [1000, 5000, 10000, 20000];

  String _monto = '';
  TipoMovimiento _tipo = TipoMovimiento.gasto;
  int? _categoriaId;
  final _controladorComentario = TextEditingController();

  double? get _montoParseado => double.tryParse(_monto);

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
  }

  void _digito(String d) {
    setState(() {
      if (_monto.replaceAll('.', '').length >= 9) return;
      _monto = _monto == '0' ? d : '$_monto$d';
    });
  }

  void _punto() {
    setState(() {
      if (_monto.contains('.')) return;
      _monto = _monto.isEmpty ? '0.' : '$_monto.';
    });
  }

  void _borrar() {
    setState(() {
      if (_monto.isEmpty) return;
      _monto = _monto.substring(0, _monto.length - 1);
    });
  }

  void _montoRapido(int adicional) {
    setState(() {
      final nuevo = (_montoParseado ?? 0) + adicional;
      _monto = nuevo % 1 == 0 ? nuevo.toStringAsFixed(0) : nuevo.toString();
    });
  }

  void _registrar() {
    final monto = _montoParseado;
    if (monto == null || monto <= 0) {
      _mostrarAviso('Ingresa un monto primero');
      return;
    }
    final comentario = _controladorComentario.text.trim();
    context.read<MovimientosBloc>().add(
          RegistrarMovimiento(
            Movimiento(
              tipo: _tipo,
              monto: monto,
              categoriaId: _categoriaId,
              comentario: comentario.isEmpty ? null : comentario,
              fecha: DateTime.now(),
            ),
          ),
        );
    setState(() {
      _monto = '';
      _categoriaId = null;
      _controladorComentario.clear();
    });
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.select<CategoriasBloc, List<Categoria>>(
      (b) => b.state.categorias,
    );
    final resumen = context.select<MovimientosBloc, ResumenMes>(
      (b) => b.state.resumen,
    );

    final categoriasDelTipo = categorias.where((c) => c.tipo == _tipo).toList();
    final categoriaValida = categoriasDelTipo.any((c) => c.id == _categoriaId);
    final categoriaSeleccionada = categoriaValida
        ? _categoriaId
        : (categoriasDelTipo.isEmpty ? null : categoriasDelTipo.first.id);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _encabezado(),
          const SizedBox(height: 16),
          TarjetaBalance(resumen: resumen),
          const SizedBox(height: 20),
          _selectorTipo(),
          const SizedBox(height: 20),
          _visorMonto(),
          const SizedBox(height: 12),
          TecladoNumerico(
            onDigito: _digito,
            onPunto: _punto,
            onBorrar: _borrar,
            puntoHabilitado: !_monto.contains('.'),
          ),
          const SizedBox(height: 12),
          _montosRapidosWidget(),
          const SizedBox(height: 20),
          _selectorCategorias(categoriasDelTipo, categoriaSeleccionada),
          const SizedBox(height: 12),
          _campoComentario(),
          const SizedBox(height: 20),
          _botonRegistrar(),
        ],
      ),
    );
  }

  Widget _encabezado() {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola 👋',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: esquema.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tu resumen de ${formatoMes(DateTime.now())}',
          style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _selectorTipo() {
    return Row(
      children: [
        Expanded(
          child: _botonTipo(TipoMovimiento.gasto, Icons.arrow_upward_rounded, 'Gasto'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _botonTipo(TipoMovimiento.ahorro, Icons.savings_rounded, 'Ahorro'),
        ),
      ],
    );
  }

  Widget _botonTipo(TipoMovimiento tipo, IconData icono, String etiqueta) {
    final esquema = Theme.of(context).colorScheme;
    final seleccionado = _tipo == tipo;
    final color = tipo == TipoMovimiento.gasto
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() {
        _tipo = tipo;
        _categoriaId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado ? color : esquema.outlineVariant,
            width: seleccionado ? 2 : 1,
          ),
          color: seleccionado
              ? color.withValues(alpha: 0.12)
              : esquema.surfaceContainerLow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: seleccionado ? color : esquema.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              etiqueta,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: seleccionado ? color : esquema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visorMonto() {
    final esquema = Theme.of(context).colorScheme;
    final mostrar = _monto.isEmpty ? '0' : formatoMontoEscrito(_monto);
    return Column(
      children: [
        Text(
          'Monto · COP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          mostrar,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: esquema.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _montosRapidosWidget() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _montosRapidos
          .map(
            (m) => ActionChip(
              label: Text('+ ${formatoMoneda(m)}'),
              onPressed: () => _montoRapido(m),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }

  Widget _selectorCategorias(List<Categoria> categorias, int? seleccionada) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (categorias.isEmpty)
          Text(
            'No hay categorías de ${_tipo.nombre.toLowerCase()}. Crea una en Ajustes.',
            style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categorias.map((c) {
              final esSeleccionada = c.id == seleccionada;
              return ChoiceChip(
                selected: esSeleccionada,
                onSelected: (_) => setState(() => _categoriaId = c.id),
                showCheckmark: false,
                avatar: Icon(
                  c.icono,
                  size: 18,
                  color: esSeleccionada ? Colors.white : c.color,
                ),
                label: Text(c.nombre),
                selectedColor: c.color,
                labelStyle: TextStyle(
                  color: esSeleccionada ? Colors.white : null,
                  fontWeight: esSeleccionada ? FontWeight.w600 : null,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _campoComentario() {
    return TextField(
      controller: _controladorComentario,
      maxLength: 120,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        hintText: 'Comentario (opcional)',
        prefixIcon: Icon(Icons.edit_note_rounded),
        filled: true,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _botonRegistrar() {
    final esAhorro = _tipo == TipoMovimiento.ahorro;
    final color = esAhorro ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      onPressed: _registrar,
      child: Text(esAhorro ? 'Registrar ahorro' : 'Registrar gasto'),
    );
  }
}
