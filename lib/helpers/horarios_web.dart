import 'dart:async';

// Versão web-compatible do helper de horários
class HorariosWebHelper {
  static final HorariosWebHelper _instance = HorariosWebHelper.internal();
  factory HorariosWebHelper() => _instance;
  HorariosWebHelper.internal();

  // Lista mock de horários para demonstração
  List<Horarios> _horarios = [
    Horarios(
      id: 1,
      nome: "Paracetamol",
      dataInicio: "2024-01-15",
      diasFim: 30,
      horaInicio: 8,
      minutoInicio: 0,
      frequencia: 8,
      segunda: 1,
      terca: 1,
      quarta: 1,
      quinta: 1,
      sexta: 1,
      sabado: 1,
      domingo: 1,
      observacoes: "Tomar com água",
    ),
    Horarios(
      id: 2,
      nome: "Vitamina D",
      dataInicio: "2024-01-10",
      diasFim: 60,
      horaInicio: 9,
      minutoInicio: 30,
      frequencia: 24,
      segunda: 1,
      terca: 1,
      quarta: 1,
      quinta: 1,
      sexta: 1,
      sabado: 0,
      domingo: 0,
      observacoes: "Tomar após o café da manhã",
    ),
    Horarios(
      id: 3,
      nome: "Ibuprofeno",
      dataInicio: "2024-01-20",
      diasFim: 7,
      horaInicio: 14,
      minutoInicio: 0,
      frequencia: 12,
      segunda: 1,
      terca: 1,
      quarta: 1,
      quinta: 1,
      sexta: 1,
      sabado: 1,
      domingo: 1,
      observacoes: "Apenas se houver dor",
    ),
  ];

  int _nextId = 4;

  Future<List<Horarios>> getAllHorarios() async {
    // Simula delay de rede
    await Future.delayed(Duration(milliseconds: 500));
    return List.from(_horarios);
  }

  Future<int> saveHorario(Horarios horario) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    if (horario.id == null) {
      horario.id = _nextId++;
      _horarios.add(horario);
    } else {
      int index = _horarios.indexWhere((h) => h.id == horario.id);
      if (index != -1) {
        _horarios[index] = horario;
      }
    }
    return horario.id!;
  }

  Future<int> updateHorario(Horarios horario) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    int index = _horarios.indexWhere((h) => h.id == horario.id);
    if (index != -1) {
      _horarios[index] = horario;
      return 1;
    }
    return 0;
  }

  Future<int> deleteHorario(int? id) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    int index = _horarios.indexWhere((h) => h.id == id);
    if (index != -1) {
      _horarios.removeAt(index);
      return 1;
    }
    return 0;
  }
}

// Classe Horarios (mesma estrutura do arquivo original)
class Horarios {
  int? id;
  String? nome;
  String? dataInicio;
  int? diasFim;
  int? horaInicio;
  int? minutoInicio;
  int? frequencia;
  int? segunda;
  int? terca;
  int? quarta;
  int? quinta;
  int? sexta;
  int? sabado;
  int? domingo;
  String? observacoes;

  Horarios({
    this.id,
    this.nome,
    this.dataInicio,
    this.diasFim,
    this.horaInicio,
    this.minutoInicio,
    this.frequencia,
    this.segunda,
    this.terca,
    this.quarta,
    this.quinta,
    this.sexta,
    this.sabado,
    this.domingo,
    this.observacoes,
  });

  Horarios.fromMap(Map<String, dynamic> map) {
    id = map['id_horario'];
    nome = map['nome_horario'];
    dataInicio = map['data_inicio'];
    diasFim = map['dias_fim'];
    horaInicio = map['hora_inicio'];
    minutoInicio = map['minuto_inicio'];
    frequencia = map['frequencia'];
    segunda = map['segunda'];
    terca = map['terca'];
    quarta = map['quarta'];
    quinta = map['quinta'];
    sexta = map['sexta'];
    sabado = map['sabado'];
    domingo = map['domingo'];
    observacoes = map['observacoes'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id_horario': id,
      'nome_horario': nome,
      'data_inicio': dataInicio,
      'dias_fim': diasFim,
      'hora_inicio': horaInicio,
      'minuto_inicio': minutoInicio,
      'frequencia': frequencia,
      'segunda': segunda,
      'terca': terca,
      'quarta': quarta,
      'quinta': quinta,
      'sexta': sexta,
      'sabado': sabado,
      'domingo': domingo,
      'observacoes': observacoes,
    };
  }
}
