import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configura sqflite para funcionar en escritorio (Windows/Linux/macOS)
/// usando el adaptador FFI en lugar del canal nativo de móvil.
void configurarFactoryEscritorio() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
