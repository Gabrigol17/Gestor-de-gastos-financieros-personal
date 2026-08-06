import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../utils/formato_moneda.dart';

/// Tarjeta de balance del mes estilo app bancaria.
class TarjetaBalance extends StatelessWidget {
  const TarjetaBalance({super.key, required this.resumen});

  final ResumenMes resumen;

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colores = esOscuro
        ? const [Color(0xFF064E3B), Color(0xFF0F766E)]
        : const [Color(0xFF0BA36B), Color(0xFF00B8A9)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colores,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colores.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Balance de ${formatoMes(DateTime.now())}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatoMoneda(resumen.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _itemResumen(
                icono: Icons.arrow_downward_rounded,
                etiqueta: 'Recibido',
                monto: resumen.recibido,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _itemResumen(
                icono: Icons.arrow_upward_rounded,
                etiqueta: 'Gastado',
                monto: resumen.gastado,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemResumen({
    required IconData icono,
    required String etiqueta,
    required double monto,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text(
                etiqueta,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Escala el monto si es muy largo para que nunca se desborde.
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatoMoneda(monto),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
