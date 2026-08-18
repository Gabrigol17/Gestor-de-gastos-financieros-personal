import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/categorias_bloc.dart';
import '../bloc/tema_cubit.dart';
import '../models/categoria.dart';
import '../models/movimiento.dart';
import '../utils/constantes.dart';

/// Vista de ajustes: tema de la app y gestión de categorías.
class ConfiguracionView extends StatelessWidget {
  const ConfiguracionView({super.key});

  Future<void> _crearCategoria(BuildContext contexto) async {
    final nueva = await showDialog<Categoria>(
      context: contexto,
      builder: (_) => const DialogoCategoria(),
    );
    if (nueva != null && contexto.mounted) {
      contexto.read<CategoriasBloc>().add(AgregarCategoria(nueva));
    }
  }

  Future<void> _confirmarEliminarCategoria(
    BuildContext contexto,
    Categoria categoria,
  ) async {
    final confirmado = await showDialog<bool>(
      context: contexto,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar la categoría "${categoria.nombre}"? '
          'Los movimientos asociados quedarán sin categoría.',
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
    if (confirmado == true && contexto.mounted && categoria.id != null) {
      contexto.read<CategoriasBloc>().add(EliminarCategoria(categoria.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoriasBloc, CategoriasState>(
      listener: (contexto, estado) {
        if (estado.mensaje != null) {
          ScaffoldMessenger.of(contexto)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(estado.mensaje!)));
        }
      },
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Ajustes',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _seccionApariencia(context),
            const SizedBox(height: 24),
            _seccionCategorias(context),
            const SizedBox(height: 24),
            _seccionAcercaDe(context),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(BuildContext contexto, String texto) => Text(
        texto,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(contexto).colorScheme.onSurface,
        ),
      );

  Widget _seccionApariencia(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion(contexto, 'Apariencia'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema de la app',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige entre modo claro u oscuro',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(contexto).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<TemaCubit, ThemeMode>(
                  builder: (contexto, modo) => SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {modo},
                    onSelectionChanged: (s) =>
                        contexto.read<TemaCubit>().cambiarTema(s.first),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seccionCategorias(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _tituloSeccion(contexto, 'Categorías'),
            FilledButton.tonalIcon(
              onPressed: () => _crearCategoria(contexto),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<CategoriasBloc, CategoriasState>(
          builder: (contexto, estado) {
            if (estado.cargando) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final categorias = estado.categorias;
            if (categorias.isEmpty) {
              return Text(
                'Aún no hay categorías. Crea la primera.',
                style: TextStyle(
                  color: Theme.of(contexto).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [
                _bloqueCategorias(contexto, TipoMovimiento.gasto, 'Gastos', categorias),
                const SizedBox(height: 8),
                _bloqueCategorias(contexto, TipoMovimiento.ahorro, 'Ingresos', categorias),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _bloqueCategorias(
    BuildContext contexto,
    TipoMovimiento tipo,
    String titulo,
    List<Categoria> todas,
  ) {
    final lista = todas.where((c) => c.tipo == tipo).toList();
    if (lista.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tipo == TipoMovimiento.gasto
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: Column(
            children: [
              for (var i = 0; i < lista.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _itemCategoria(contexto, lista[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemCategoria(BuildContext contexto, Categoria c) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: c.color.withValues(alpha: 0.15),
        child: Icon(c.icono, color: c.color),
      ),
      title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: c.porDefecto ? const Text('Por defecto') : null,
      trailing: c.porDefecto
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Theme.of(contexto).colorScheme.error,
              tooltip: 'Eliminar',
              onPressed: () => _confirmarEliminarCategoria(contexto, c),
            ),
    );
  }

  Widget _seccionAcercaDe(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion(contexto, 'Acerca de'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money_rounded),
                title: const Text('Moneda'),
                subtitle: const Text('Peso colombiano (COP)'),
                trailing: const Icon(Icons.check_circle_outline_rounded),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Versión'),
                subtitle: Text('2.0.1'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Diálogo para crear una categoría: nombre, tipo, icono y color.
class DialogoCategoria extends StatefulWidget {
  const DialogoCategoria({super.key});

  @override
  State<DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<DialogoCategoria> {
  final _nombre = TextEditingController();
  TipoMovimiento _tipo = TipoMovimiento.gasto;
  int _iconoCodePoint = codigosIconosCategoria.first;
  Color _color = paletaColoresCategoria.first;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return;
    Navigator.of(context).pop(
      Categoria(
        nombre: nombre,
        colorValue: _color.toARGB32(),
        iconoCodePoint: _iconoCodePoint,
        tipo: _tipo,
      ),
    );
  }

  Widget _itemIcono(BuildContext contexto, int codigo, Color color, ColorScheme esquema) {
    final seleccionado = _iconoCodePoint == codigo;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _iconoCodePoint = codigo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withValues(alpha: 0.15)
              : esquema.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          iconosCategoria[codigo] ?? Icons.category,
          color: seleccionado ? color : esquema.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<TipoMovimiento>(
              segments: const [
                ButtonSegment(value: TipoMovimiento.gasto, label: Text('Gasto')),
                ButtonSegment(value: TipoMovimiento.ahorro, label: Text('Ingreso')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Transporte',
              ),
              onSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: 16),
            Text(
              'Icono',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Un ListView horizontal no soporta dimensiones intrínsecas dentro
            // del diálogo y provoca un error de layout; se usa un scroll simple.
            SizedBox(
              height: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < codigosIconosCategoria.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _itemIcono(context, codigosIconosCategoria[i], _color, esquema),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: paletaColoresCategoria.map((c) {
                final seleccionado = _color == c;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: seleccionado
                          ? Border.all(color: esquema.onSurface, width: 3)
                          : null,
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _nombre.text.trim().isEmpty ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
