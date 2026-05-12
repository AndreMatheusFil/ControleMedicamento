import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final String tableHorarios = "horarios";
final String colIdHorario = "id_horario";
final String colNomeHorario = "nome_horario";
final String colDataInicio = "data_inicio";
final String colDiasFim = "dias_fim";
final String colHoraInicio = "hora_inicio";
final String colMinutoInicio = "minuto_inicio";
final String colFrequencia = "frequencia";
final String colSegunda = "segunda";
final String colTerca = "terca";
final String colQuarta = "quarta";
final String colQuinta = "quinta";
final String colSexta = "sexta";
final String colSabado = "sabado";
final String colDomingo = "domingo";
final String colObservacoes = "observacoes";

final String colQuantidadeTotal = "quantidade_total";
final String colQuantidadePorDose = "quantidade_por_dose";
final String colDosagem = "dosagem";
final String colForma = "forma";

class HorariosHelper {
  static final HorariosHelper _instance = HorariosHelper.internal();

  factory HorariosHelper() => _instance;

  HorariosHelper.internal();

  Database? _db;

  Future<Database?> get db async {
    _db ??= await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "horariosnew.db");

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int newerVersion) async {
        await db.execute("""
          CREATE TABLE $tableHorarios(
            $colIdHorario INTEGER PRIMARY KEY,
            $colNomeHorario TEXT,
            $colDataInicio TEXT,
            $colDiasFim INTEGER,
            $colHoraInicio INTEGER,
            $colMinutoInicio INTEGER,
            $colFrequencia INTEGER,
            $colSegunda INTEGER,
            $colTerca INTEGER,
            $colQuarta INTEGER,
            $colQuinta INTEGER,
            $colSexta INTEGER,
            $colSabado INTEGER,
            $colDomingo INTEGER,
            $colObservacoes TEXT,
            $colQuantidadeTotal INTEGER DEFAULT 0,
            $colQuantidadePorDose INTEGER DEFAULT 1,
            $colDosagem TEXT,
            $colForma TEXT
          )
        """);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfNotExists(db, tableHorarios, colQuantidadeTotal, "INTEGER DEFAULT 0");
          await _addColumnIfNotExists(db, tableHorarios, colQuantidadePorDose, "INTEGER DEFAULT 1");
          await _addColumnIfNotExists(db, tableHorarios, colDosagem, "TEXT");
          await _addColumnIfNotExists(db, tableHorarios, colForma, "TEXT");
        }
      },
    );
  }

  static Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery("PRAGMA table_info($table)");
    final exists = columns.any((c) => c["name"] == column);

    if (!exists) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $type");
    }
  }

  Future<Horarios> saveHorario(Horarios horario) async {
    Database? dbHorarios = await db;
    horario.id = await dbHorarios!.insert(tableHorarios, horario.toMap());
    return horario;
  }

  Future<Horarios?> getHorario(int id) async {
    Database? dbHorarios = await db;
    List<Map> maps = await dbHorarios!.query(
      tableHorarios,
      where: "$colIdHorario = ?",
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Horarios.fromMap(maps.first);
    }

    return null;
  }

  Future<int> deleteHorario(int id) async {
    Database? dbHorarios = await db;
    return await dbHorarios!.delete(
      tableHorarios,
      where: "$colIdHorario = ?",
      whereArgs: [id],
    );
  }

  Future<int> updateHorario(Horarios horario) async {
    Database? dbHorarios = await db;
    return await dbHorarios!.update(
      tableHorarios,
      horario.toMap(),
      where: "$colIdHorario = ?",
      whereArgs: [horario.id],
    );
  }

  Future<List> getAllHorarios() async {
    Database? dbHorarios = await db;
    List listMap = await dbHorarios!.rawQuery("SELECT * FROM $tableHorarios");
    List<Horarios> listHorario = [];

    for (Map m in listMap) {
      listHorario.add(Horarios.fromMap(m));
    }

    return listHorario;
  }

  Future<void> baixarEstoque(Horarios horario) async {
    if (horario.id == null) return;

    final quantidadeAtual = horario.quantidadeTotal ?? 0;
    final quantidadeDose = horario.quantidadePorDose ?? 1;

    int novaQuantidade = quantidadeAtual - quantidadeDose;

    if (novaQuantidade < 0) {
      novaQuantidade = 0;
    }

    horario.quantidadeTotal = novaQuantidade;

    await updateHorario(horario);
  }

  Future<int?> getNumber() async {
    Database? dbHorarios = await db;
    return Sqflite.firstIntValue(
      await dbHorarios!.rawQuery("SELECT COUNT(*) FROM $tableHorarios"),
    );
  }

  Future close() async {
    Database? dbHorarios = await db;
    dbHorarios!.close();
  }
}

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

  int? quantidadeTotal;
  int? quantidadePorDose;
  String? dosagem;
  String? forma;

  Horarios();

  Horarios.fromMap(Map map) {
    id = map[colIdHorario];
    nome = map[colNomeHorario];
    dataInicio = map[colDataInicio];
    diasFim = map[colDiasFim] ?? 0;
    horaInicio = map[colHoraInicio];
    minutoInicio = map[colMinutoInicio];
    frequencia = map[colFrequencia];
    segunda = map[colSegunda];
    terca = map[colTerca];
    quarta = map[colQuarta];
    quinta = map[colQuinta];
    sexta = map[colSexta];
    sabado = map[colSabado];
    domingo = map[colDomingo];
    observacoes = map[colObservacoes];

    quantidadeTotal = map[colQuantidadeTotal] ?? 0;
    quantidadePorDose = map[colQuantidadePorDose] ?? 1;
    dosagem = map[colDosagem];
    forma = map[colForma];
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      colNomeHorario: nome,
      colDataInicio: dataInicio,
      colDiasFim: diasFim,
      colHoraInicio: horaInicio,
      colMinutoInicio: minutoInicio,
      colFrequencia: frequencia,
      colSegunda: segunda,
      colTerca: terca,
      colQuarta: quarta,
      colQuinta: quinta,
      colSexta: sexta,
      colSabado: sabado,
      colDomingo: domingo,
      colObservacoes: observacoes,
      colQuantidadeTotal: quantidadeTotal,
      colQuantidadePorDose: quantidadePorDose,
      colDosagem: dosagem,
      colForma: forma,
    };

    map[colIdHorario] = id;
    return map;
  }
}