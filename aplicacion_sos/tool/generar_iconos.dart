// Genera los PNG base para flutter_launcher_icons a partir del JPEG del usuario.
// El JPEG original tiene una banda blanca en la parte superior y el contenido
// (objeto oscuro) en el resto; se recorta esa banda para centrar el contenido.
//  - asset/icono.png            : contenido centrado al ~93% (iOS + Android clásico)
//  - asset/icono_adaptativo.png : contenido al 66% centrado sobre blanco
//                                 (zona segura del icono adaptativo de Android 8+)
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const fuente = 'asset/finanzas.jpeg';
  const lado = 1024;
  // Banda blanca superior detectada (contenido real desde y=75).
  const bandaSup = 75;

  final original = img.decodeImage(File(fuente).readAsBytesSync())!;
  final contenido = img.copyCrop(
    original,
    x: 0,
    y: bandaSup,
    width: original.width,
    height: original.height - bandaSup,
  );

  // 1. Versión equilibrada: contenido centrado con relleno blanco (cuadrado).
  final lienzo = img.Image(width: lado, height: lado);
  img.fill(lienzo, color: img.ColorRgb8(255, 255, 255));
  final escalaCompleto = 0.93;
  final grande = img.copyResize(
    contenido,
    width: (lado * escalaCompleto).round(),
    height: (contenido.height * escalaCompleto).round(),
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    lienzo,
    grande,
    dstX: (lado - grande.width) ~/ 2,
    dstY: (lado - grande.height) ~/ 2,
  );
  File('asset/icono.png').writeAsBytesSync(img.encodePng(lienzo));
  print('Generado asset/icono.png (contenido al ${(escalaCompleto * 100).round()}%)');

  // 2. Versión adaptativa: contenido al 66% (zona segura del círculo).
  const escalaAdaptativo = 0.66;
  final lienzoAdapt = img.Image(width: lado, height: lado);
  img.fill(lienzoAdapt, color: img.ColorRgb8(255, 255, 255));
  final badge = img.copyResize(
    contenido,
    width: (lado * escalaAdaptativo).round(),
    height: (contenido.height * escalaAdaptativo).round(),
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    lienzoAdapt,
    badge,
    dstX: (lado - badge.width) ~/ 2,
    dstY: (lado - badge.height) ~/ 2,
  );
  File('asset/icono_adaptativo.png').writeAsBytesSync(img.encodePng(lienzoAdapt));
  print('Generado asset/icono_adaptativo.png (contenido al ${(escalaAdaptativo * 100).round()}%)');
}
