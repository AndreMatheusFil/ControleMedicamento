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


class HorariosHelper {
  static final HorariosHelper _instance = HorariosHelper.internal();

  factory HorariosHelper() => _instance;
  
  HorariosHelper.internal();

  Database? _db;

  Future<Database?> get db async {
    if(_db != null){
      return _db;
    } else {
      _db = await initDb();
      return _db;
    }
  }
  Future<Database> initDb() async {
    // WidgetsFlutterBinding.ensureInitialized();
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath,"horariosnew.db");
    
    return await openDatabase(path, version: 1,
        onCreate: (Database db, int newerVersion) async {
      await db.execute(
          "CREATE TABLE $tableHorarios($colIdHorario INTEGER PRIMARY KEY, $colNomeHorario TEXT, $colDataInicio TEXT, $colDiasFim INTEGER, $colHoraInicio INTEGER, $colMinutoInicio INTEGER, $colFrequencia INTEGER, $colSegunda INTEGER, $colTerca INTEGER, $colQuarta INTEGER, $colQuinta INTEGER, $colSexta INTEGER, $colSabado INTEGER, $colDomingo INTEGER, $colObservacoes TEXT)");
    });
  }
  Future<Horarios> saveHorario(Horarios horario) async {
    Database? dbHorarios = await db;
    horario.id = await dbHorarios!.insert(tableHorarios, horario.toMap());
    return horario;
  }
  Future<Horarios?> getHorario(int id) async {
    Database? dbHorarios = await db;
    List<Map> maps = await dbHorarios!.query(tableHorarios,
        columns: [
          colIdHorario,
          colNomeHorario,
          colDataInicio,
          colHoraInicio,
          colMinutoInicio,
          colFrequencia,
          colSegunda,
          colTerca,
          colQuarta,
          colQuinta,
          colSexta,
          colSabado,
          colDomingo,
          colObservacoes
        ],
        where: "$colIdHorario = ?",
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Horarios.fromMap(maps.first);
    } else {	
      return null;
    }
  }
  Future<int> deleteHorario(int id) async {
    Database? dbHorarios = await db;
    return await dbHorarios!.delete(
      tableHorarios, 
      where: "$colIdHorario = ?", 
      whereArgs: [id]
    );
  }
  Future<int> updateHorario(Horarios horario) async {
    Database? dbHorarios = await db;
    return await dbHorarios!.update(
      tableHorarios, 
      horario.toMap(), 
      where: "$colIdHorario = ?", 
      whereArgs: [horario.id]
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
  Future<int?> getNumber() async {
    Database? dbHorarios = await db;
    return Sqflite.firstIntValue(await dbHorarios!.rawQuery("SELECT COUNT(*) FROM $tableHorarios"));
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
      colObservacoes: observacoes
    };

    map[colIdHorario] = id;
    return map;
  }
  @override
  String toString() {
    return "Horarios($colIdHorario: $id, $colNomeHorario: $nome, $colDataInicio: $dataInicio, $colDiasFim: $diasFim, $colHoraInicio: $horaInicio, $colMinutoInicio: $minutoInicio, $colFrequencia: $frequencia, $colSegunda: $segunda, $colTerca: $terca, $colQuarta: $quarta, $colQuinta: $quinta, $colSexta: $sexta, $colSabado: $sabado, $colDomingo: $domingo, $colObservacoes: $observacoes)";
  }
}
