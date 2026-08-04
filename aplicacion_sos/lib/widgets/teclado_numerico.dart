import 'package:flutter/material.dart';

/// Teclado numérico estilo app bancaria para ingresar montos rápidamente.
class TecladoNumerico extends StatelessWidget {
  const TecladoNumerico({
    super.key,
    required this.onDigito,
    required this.onPunto,
    required this.onBorrar,
    required this.puntoHabilitado,
  });

  final ValueChanged<String> onDigito;
  final VoidCallback onPunto;
  final VoidCallback onBorrar;
  final bool puntoHabilitado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colorTexto = esquema.onSurface;
    final colorFondo = esquema.surfaceContainerHighest;

    Widget tecla(String etiqueta, {VoidCallback? onTap, Widget? icono}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: colorFondo,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: icono ??
                      Text(
                        etiqueta,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorTexto,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget fila(List<Widget> teclas) => Row(children: teclas);

    return Column(
      children: [
        fila([
          tecla('7', onTap: () => onDigito('7')),
          tecla('8', onTap: () => onDigito('8')),
          tecla('9', onTap: () => onDigito('9')),
        ]),
        fila([
          tecla('4', onTap: () => onDigito('4')),
          tecla('5', onTap: () => onDigito('5')),
          tecla('6', onTap: () => onDigito('6')),
        ]),
        fila([
          tecla('1', onTap: () => onDigito('1')),
          tecla('2', onTap: () => onDigito('2')),
          tecla('3', onTap: () => onDigito('3')),
        ]),
        fila([
          tecla('.', onTap: puntoHabilitado ? onPunto : null),
          tecla('0', onTap: () => onDigito('0')),
          tecla(
            '',
            onTap: onBorrar,
            icono: Icon(Icons.backspace_outlined, color: colorTexto),
          ),
        ]),
      ],
    );
  }
}
