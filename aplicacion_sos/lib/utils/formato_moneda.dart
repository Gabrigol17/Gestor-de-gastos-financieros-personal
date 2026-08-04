import 'package:intl/intl.dart';

/// Agrupa los dígitos de la parte entera con puntos, estilo COP: 1234567 -> 1.234.567.
String _agrupar(String parte) {
  final buf = StringBuffer();
  for (var i = 0; i < parte.length; i++) {
    buf.write(parte[i]);
    final restantes = parte.length - 1 - i;
    if (restantes > 0 && restantes % 3 == 0) buf.write('.');
  }
  return buf.toString();
}

String _formatear(String parteEntera, [String? decimales]) {
  final entera = parteEntera.isEmpty ? '0' : parteEntera;
  return '\$${_agrupar(entera)}${decimales == null ? '' : ',$decimales'}';
}

/// Formatea un monto numérico en formato COP: $1.234.567 o $1.234.567,89.
/// Los montos enteros se muestran sin decimales; los fraccionarios con 2.
String formatoMoneda(num monto) {
  final negativo = monto < 0;
  final absoluto = monto.abs();
  final esEntero = absoluto == absoluto.roundToDouble();
  final fijo = absoluto.toStringAsFixed(2);
  final partes = fijo.split('.');
  final resultado = esEntero
      ? _formatear(partes[0])
      : _formatear(partes[0], partes[1]);
  return negativo ? '-$resultado' : resultado;
}

/// Formatea el texto crudo que el usuario escribe con el teclado numérico.
/// Ejemplo: "12500.5" -> "$12.500,5" y "0." -> "$0,"
String formatoMontoEscrito(String crudo) {
  final partes = crudo.split('.');
  final entera = _formatear(partes[0]);
  if (partes.length == 1) return entera;
  return '$entera,${partes[1]}';
}

/// Nombre del mes en español, capitalizado. Ejemplo: agosto -> Agosto.
String formatoMes(DateTime fecha) =>
    toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(fecha)) ?? '';
