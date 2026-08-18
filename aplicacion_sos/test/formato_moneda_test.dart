import 'package:aplicacion_sos/models/movimiento.dart';
import 'package:aplicacion_sos/utils/formato_moneda.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatoMoneda (COP)', () {
    test('agrupa montos enteros con puntos', () {
      expect(formatoMoneda(0), r'$0');
      expect(formatoMoneda(1000), r'$1.000');
      expect(formatoMoneda(1234567), r'$1.234.567');
    });

    test('usa coma decimal cuando hay centavos', () {
      expect(formatoMoneda(1234567.89), r'$1.234.567,89');
      expect(formatoMoneda(10.5), r'$10,50');
      expect(formatoMoneda(1234.05), r'$1.234,05');
    });

    test('maneja montos negativos', () {
      expect(formatoMoneda(-5000), r'-$5.000');
    });
  });

  group('formatoMontoEscrito', () {
    test('formatea el texto del teclado numérico', () {
      expect(formatoMontoEscrito('0.'), r'$0,');
      expect(formatoMontoEscrito('12500.5'), r'$12.500,5');
      expect(formatoMontoEscrito('9999999'), r'$9.999.999');
    });
  });

  group('ResumenMes', () {
    test('calcula el balance neto', () {
      const resumen = ResumenMes(recibido: 100000, gastado: 35000);
      expect(resumen.balance, 65000);
    });
  });

  group('Movimiento', () {
    test('hace round-trip a mapa y de vuelta', () {
      final original = Movimiento(
        id: 3,
        tipo: TipoMovimiento.gasto,
        monto: 12500.5,
        categoriaId: 2,
        comentario: 'Almuerzo',
        fecha: DateTime(2026, 8, 3, 13, 30),
      );
      final restaurado = Movimiento.fromMap(original.toMap());
      expect(restaurado.id, 3);
      expect(restaurado.tipo, TipoMovimiento.gasto);
      expect(restaurado.monto, 12500.5);
      expect(restaurado.categoriaId, 2);
      expect(restaurado.comentario, 'Almuerzo');
      expect(restaurado.fecha, DateTime(2026, 8, 3, 13, 30));
    });

    test(' TipoMovimiento.ahorro se muestra como Ingresos', () {
      expect(TipoMovimiento.ahorro.nombre, 'Ingresos');
    });
  });
}
