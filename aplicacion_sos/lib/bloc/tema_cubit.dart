import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el modo claro/oscuro de la app y lo persiste localmente.
class TemaCubit extends Cubit<ThemeMode> {
  TemaCubit(this._prefs, ThemeMode inicial) : super(inicial);

  static const _clave = 'tema';

  final SharedPreferences _prefs;

  void cambiarTema(ThemeMode modo) {
    if (modo == state) return;
    emit(modo);
    _prefs.setString(_clave, modo.name);
  }
}
