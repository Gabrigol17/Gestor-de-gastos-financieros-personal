import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../View_Inicio.dart';
import '../bloc/movimientos_bloc.dart';
import 'configuracion_view.dart';
import 'historial_view.dart';

/// Contenedor principal con la barra de navegación inferior de 3 pestañas.
class ShellPrincipal extends StatefulWidget {
  const ShellPrincipal({super.key});

  @override
  State<ShellPrincipal> createState() => _ShellPrincipalState();
}

class _ShellPrincipalState extends State<ShellPrincipal> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MovimientosBloc, MovimientosState>(
        listener: (contexto, estado) {
          if (estado.mensaje != null) {
            ScaffoldMessenger.of(contexto)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(estado.mensaje!)));
          }
        },
        child: IndexedStack(
          index: _indice,
          children: const [
            ViewInicio(),
            HistorialView(),
            ConfiguracionView(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
