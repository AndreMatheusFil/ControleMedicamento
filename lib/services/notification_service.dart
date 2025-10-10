import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'dart:html' as html show Notification, NotificationPermission, window, document;

import 'package:intl/intl.dart';

import 'package:controlemedicamento/helpers/horarios_web.dart' as web;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final Map<int, Timer> _timersByHorarioId = <int, Timer>{};

  Future<void> initialize() async {
    if (!kIsWeb) return;
    await _ensurePermissionWeb();
  }

  Future<void> _ensurePermissionWeb() async {
    if (!kIsWeb) return;
    try {
      final permission = html.Notification.permission;
      if (permission != 'granted') {
        await html.Notification.requestPermission();
      }
    } catch (_) {
    }
  }

  Future<void> rescheduleAll(List<web.Horarios> horarios) async {
    for (final timer in _timersByHorarioId.values) {
      timer.cancel();
    }
    _timersByHorarioId.clear();

    if (!kIsWeb) return;

    await _ensurePermissionWeb();
    for (final h in horarios) {
      _scheduleNextWeb(h);
    }
  }

  void _scheduleNextWeb(web.Horarios h) {
    if (!kIsWeb) return;

    if ((h.horaInicio == null) || (h.minutoInicio == null)) return;

    final now = DateTime.now();

    DateTime startDate = now;
    if ((h.dataInicio != null) && h.dataInicio!.isNotEmpty) {
      try {
        final parts = h.dataInicio!.split('-');
        if (parts.length == 3) {
          startDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      h.horaInicio ?? 0,
      h.minutoInicio ?? 0,
    );

    if (candidate.isBefore(startDate)) {
      candidate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        h.horaInicio ?? 0,
        h.minutoInicio ?? 0,
      );
    }

    final int frequenciaHoras = (h.frequencia ?? 0) <= 0 ? 24 : (h.frequencia ?? 24);
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(hours: frequenciaHoras));
    }

    candidate = _applyWeekdayConstraints(candidate, h);

    if ((h.diasFim ?? 0) > 0) {
      final DateTime fim = startDate.add(Duration(days: h.diasFim ?? 0));
      if (candidate.isAfter(fim)) return;
    }

    final delay = candidate.difference(DateTime.now());
    if (delay.isNegative) return;

    final id = h.id ?? candidate.millisecondsSinceEpoch;
    _timersByHorarioId[id]?.cancel();
    _timersByHorarioId[id] = Timer(delay, () {
      _showWebNotification(h);

      final next = candidate.add(Duration(hours: frequenciaHoras));
      final nextAdjusted = _applyWeekdayConstraints(next, h);
      final nextId = h.id ?? nextAdjusted.millisecondsSinceEpoch;
      _timersByHorarioId[nextId]?.cancel();
      final nextDelay = nextAdjusted.difference(DateTime.now());
      if (!nextDelay.isNegative) {
        _timersByHorarioId[nextId] = Timer(nextDelay, () {
          _showWebNotification(h);
        });
      }
    });
  }

  DateTime _applyWeekdayConstraints(DateTime candidate, web.Horarios h) {
    final diasFlags = <int, int?>{
      DateTime.monday: h.segunda,
      DateTime.tuesday: h.terca,
      DateTime.wednesday: h.quarta,
      DateTime.thursday: h.quinta,
      DateTime.friday: h.sexta,
      DateTime.saturday: h.sabado,
      DateTime.sunday: h.domingo,
    };

    final bool algumMarcado = diasFlags.values.any((v) => (v ?? 0) > 0);
    if (!algumMarcado) return candidate;

    DateTime adjusted = candidate;
    while ((diasFlags[adjusted.weekday] ?? 0) <= 0) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }

  void _showWebNotification(web.Horarios h) {
    if (!kIsWeb) return;
    try {
      final permission = html.Notification.permission;
      if (permission != 'granted') return;

      final titulo = h.nome ?? 'Lembrete de medicamento';
      final horarioFmt = DateFormat('HH:mm').format(DateTime.now());
      final corpo = StringBuffer()
        ..write('Está na hora de tomar o medicamento.')
        ..write(' ')
        ..write('Horário: ')
        ..write(horarioFmt);

      html.Notification(
        titulo,
        body: corpo.toString(),
      );
    } catch (_) {
    }
  }
}



