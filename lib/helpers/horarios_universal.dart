import 'package:flutter/foundation.dart';
import 'horarios.dart' as sqlite;
import 'horarios_web.dart' as web;

// Helper universal que detecta a plataforma e usa o helper apropriado
class HorariosUniversalHelper {
  static final HorariosUniversalHelper _instance = HorariosUniversalHelper.internal();
  factory HorariosUniversalHelper() => _instance;
  HorariosUniversalHelper.internal();

  late dynamic _helper;

  void _initializeHelper() {
    if (kIsWeb) {
      _helper = web.HorariosWebHelper();
    } else {
      _helper = sqlite.HorariosHelper();
    }
  }

  Future<List<dynamic>> getAllHorarios() async {
    _initializeHelper();
    return await _helper.getAllHorarios();
  }

  Future<int> saveHorario(dynamic horario) async {
    _initializeHelper();
    return await _helper.saveHorario(horario);
  }

  Future<int> updateHorario(dynamic horario) async {
    _initializeHelper();
    return await _helper.updateHorario(horario);
  }

  Future<int> deleteHorario(int? id) async {
    _initializeHelper();
    return await _helper.deleteHorario(id);
  }
}
