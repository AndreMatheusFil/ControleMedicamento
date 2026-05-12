import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final String tableHistoricoDoses = "historico_doses";
final String colIdHistorico = "id_historico";
final String colIdHorarioHistorico = "id_horario";
final String colNomeMedicamentoHistorico = "nome_medicamento";
final String colDataHoraPrevista = "data_hora_prevista";
final String colDataHoraTomada = "data_hora_tomada";
final String colStatusHistorico = "status";

class HistoricoDosesHelper {
  static final HistoricoDosesHelper _instance = HistoricoDosesHelper.internal();

  factory HistoricoDosesHelper() => _instance;

  HistoricoDosesHelper.internal();

  Database? _db;

  Future<Database?> get db async {
    _db ??= await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "historico_doses.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int newerVersion) async {
        await db.execute("""
          CREATE TABLE $tableHistoricoDoses(
            $colIdHistorico INTEGER PRIMARY KEY,
            $colIdHorarioHistorico INTEGER,
            $colNomeMedicamentoHistorico TEXT,
            $colDataHoraPrevista TEXT,
            $colDataHoraTomada TEXT,
            $colStatusHistorico TEXT
          )
        """);
      },
    );
  }

  Future<void> salvarTomado({
    required int idHorario,
    required String nomeMedicamento,
    required DateTime dataHoraPrevista,
  }) async {
    Database? dbHistorico = await db;

    await dbHistorico!.insert(tableHistoricoDoses, {
      colIdHorarioHistorico: idHorario,
      colNomeMedicamentoHistorico: nomeMedicamento,
      colDataHoraPrevista: dataHoraPrevista.toIso8601String(),
      colDataHoraTomada: DateTime.now().toIso8601String(),
      colStatusHistorico: "tomado",
    });
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    Database? dbHistorico = await db;

    return await dbHistorico!.query(
      tableHistoricoDoses,
      orderBy: "$colDataHoraTomada DESC",
    );
  }
}