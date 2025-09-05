import 'package:controlemedicamento/helpers/horarios.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cadastro_horarios_page.dart';

class HomePageCadastroState extends StatefulWidget{
  const HomePageCadastroState({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageCadastroState createState() => _HomePageCadastroState();
}

class _HomePageCadastroState extends State<HomePageCadastroState>{

  HorariosHelper helper = HorariosHelper();

  List<Horarios> horarios = [];
  Map<String, dynamic> _lastRemoved = {};
  int _lastRemovedPos = 0;

  @override
  void initState(){
    super.initState();
    // print("Iniciando...");
    // Teste de banco de dados
    // Horarios h = Horarios();
    // h.nome = "Teste 2";
    // h.dataInicio = "2024-06-01";
    // h.horaInicio = 9;
    // h.minutoInicio = 30;
    // h.frequencia = 8;
    // h.segunda = 1;
    // h.terca = 1;
    // h.quarta = 1;
    // h.quinta = 1;
    // h.sexta = 1;
    // h.sabado = 0;
    // h.domingo = 0;
    // h.observacoes = "Tomar com água";
    // helper.saveHorario(h);    
    _getAllHorarios();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold( 
      bottomNavigationBar: SizedBox(height: 10.0),
      
      appBar: AppBar(
        title: Text("Cadastro de Horários"),
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 255, 255, 255)
        ),
        centerTitle: true,
        toolbarHeight: 75.0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCadastroHorarioPage,
        // ignore: sort_child_properties_last
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: horarios.length,
        itemBuilder: (context, index){
          return _horarioCard(context, index);
        }
      ),
    );
  }


  //Card de cada horário
  Widget _horarioCard(BuildContext context, int index){
  DateTime? inicio;
    // Converte a string do banco para DateTime
  if (horarios[index].dataInicio != null && horarios[index].dataInicio != "") {
    String rawDate = horarios[index].dataInicio ?? "";
    List<String> parts = rawDate.split("-");

    if (parts.length == 3) {
      String year = parts[0];
      String month = parts[1].padLeft(2, '0');
      String day = parts[2].padLeft(2, '0');
      
      inicio = DateTime.parse("$year-$month-$day");
    }
  }
  String dataFormatada = "";
  DateTime? fim;
  String? dataFimFormatada;
  if (inicio != null) {
    // Formata em pt-BR
    dataFormatada =
        DateFormat("dd 'de' MMMM 'de' yyyy", "pt_BR").format(inicio);

    
    fim = inicio.add(Duration(days: horarios[index].diasFim ?? 0));
    // Formata em pt-BR
    dataFimFormatada =
      DateFormat("dd 'de' MMMM 'de' yyyy", "pt_BR").format(fim);
  }

  

  // Monta o texto completo
  String textoDataInicio =
      "Início: $dataFormatada";
  String textoDataFim =
      "Fim: $dataFimFormatada";
  
  String textoHorario =
    "${horarios[index].horaInicio.toString().padLeft(2, '0')}:${horarios[index].minutoInicio.toString().padLeft(2, '0')}";
  String textoFrquencia =
    "A cada ${horarios[index].frequencia} horas";

    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = {
            'item': horarios[index],
            'index': index,
          };
          _lastRemovedPos = index;
          horarios.removeAt(index);
          helper.deleteHorario(_lastRemoved['item'].id);
          
          final snack = SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            content: Text("Horário \"${_lastRemoved['item'].nome}\" removido!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  horarios.insert(_lastRemovedPos, Horarios.fromMap(_lastRemoved['item'].toMap()));
                  helper.saveHorario(horarios[_lastRemovedPos]);
                });
              },
            ),
            duration: Duration(seconds: 5),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        }
        );
      },
      direction: DismissDirection.startToEnd,
      child:GestureDetector(
        child: Card(
          child: Padding(
            padding:  EdgeInsets.all(10.0),
            child: Row(
                children: <Widget>[Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        horarios[index].nome ?? "",
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        textoDataInicio,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        textoDataFim,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        textoHorario,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        textoFrquencia,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        horarios[index].observacoes ?? "",
                        overflow: TextOverflow.visible, // deixa quebrar
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontStyle: FontStyle.italic
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        onTap: (){
          _showCadastroHorarioPage(horario: horarios[index]);
        },
      )
    );
  }
  void _showCadastroHorarioPage({Horarios? horario}) async {
    final recHorario = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroHorarioPage(horarios: horario),
      )
    );
    if (recHorario != null) {
      if (horario != null) {
        await helper.updateHorario(recHorario);
      } else {
        await helper.saveHorario(recHorario);
      }
      _getAllHorarios();
    }
  }
  void _getAllHorarios() {
    helper.getAllHorarios().then((list) {
      setState(() {
        horarios = List<Horarios>.from(list);
      }); 
    });
  }
}