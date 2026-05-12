import 'package:controlemedicamento/helpers/horarios.dart';

class ProximaDose {
  final Horarios horario;
  final DateTime dataHora;

  ProximaDose({
    required this.horario,
    required this.dataHora,
  });
}

class ProximasDosesHelper {
  static List<ProximaDose> calcular(List<Horarios> horarios) {
    final agora = DateTime.now();
    final proximas = <ProximaDose>[];

    for (final h in horarios) {
      if (h.dataInicio == null ||
          h.horaInicio == null ||
          h.minutoInicio == null ||
          h.frequencia == null ||
          h.frequencia == 0) {
        continue;
      }

      final partes = h.dataInicio!.split("-");

      if (partes.length != 3) continue;

      final inicio = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
        h.horaInicio!,
        h.minutoInicio!,
      );

      final fim = (h.diasFim ?? 0) > 0
          ? inicio.add(Duration(days: h.diasFim!))
          : inicio.add(const Duration(days: 365));

      DateTime dose = inicio;

      while (dose.isBefore(agora)) {
        dose = dose.add(Duration(hours: h.frequencia!));
      }

      for (int i = 0; i < 10; i++) {
        if (dose.isAfter(fim)) break;

        if (_diaPermitido(h, dose.weekday)) {
          proximas.add(ProximaDose(horario: h, dataHora: dose));
        }

        dose = dose.add(Duration(hours: h.frequencia!));
      }
    }

    proximas.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return proximas;
  }

  static bool _diaPermitido(Horarios h, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return h.segunda == 1;
      case DateTime.tuesday:
        return h.terca == 1;
      case DateTime.wednesday:
        return h.quarta == 1;
      case DateTime.thursday:
        return h.quinta == 1;
      case DateTime.friday:
        return h.sexta == 1;
      case DateTime.saturday:
        return h.sabado == 1;
      case DateTime.sunday:
        return h.domingo == 1;
      default:
        return false;
    }
  }
}