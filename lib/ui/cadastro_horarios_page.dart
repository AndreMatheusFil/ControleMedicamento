import 'package:controlemedicamento/helpers/horarios_universal.dart';
import 'package:controlemedicamento/helpers/horarios_web.dart' as web;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CadastroHorarioPage extends StatefulWidget {
  final web.Horarios? horarios;

  const CadastroHorarioPage({super.key, this.horarios});

  @override
  // ignore: library_private_types_in_public_api
  _CadastroHorarioPageState createState() => _CadastroHorarioPageState();
}

class _CadastroHorarioPageState extends State<CadastroHorarioPage> {
  late web.Horarios _editedHorario; 
  final _nomeController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _diasFimController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _minutoInicioController = TextEditingController();
  final _frequenciaController = TextEditingController();
  final _observacoesController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.horarios == null) {
      _editedHorario = web.Horarios();
      _editedHorario.segunda = 1;
      _editedHorario.terca = 1;
      _editedHorario.quarta = 1;
      _editedHorario.quinta = 1;
      _editedHorario.sexta = 1;
      _editedHorario.sabado = 1;
      _editedHorario.domingo = 1;
    } else {
      _editedHorario = web.Horarios.fromMap(widget.horarios!.toMap());
      _nomeController.text = _editedHorario.nome ?? "";
      if (_editedHorario.dataInicio != null) {
        String rawDate = _editedHorario.dataInicio ?? "";
        List<String> parts = rawDate.split("-");

        if (parts.length == 3) {
          String year = parts[0];
          String month = parts[1].padLeft(2, '0');
          String day = parts[2].padLeft(2, '0');
          
          _dataInicioController.text = DateFormat('dd/MM/yyyy','pt_BR').format(DateTime.parse("$year-$month-$day"));
        }
        //_dataInicioController.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(DateTime.parse(_editedHorario.dataInicio.toString()));
      } else {
        _dataInicioController.text = "";
      }
      _diasFimController.text = _editedHorario.diasFim?.toString() ?? "";
      _horaInicioController.text = _editedHorario.horaInicio?.toString() ?? "";
      _minutoInicioController.text = _editedHorario.minutoInicio?.toString() ?? "";
      _frequenciaController.text = _editedHorario.frequencia?.toString() ?? "";
      _observacoesController.text = _editedHorario.observacoes ?? "";
      _editedHorario = web.Horarios.fromMap(widget.horarios!.toMap());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editedHorario.nome ?? "Novo Horário"),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.white, // Define a cor do ícone como branco
        ), 
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 255, 255, 255)
        ),
        centerTitle: true,
        toolbarHeight: 75.0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.pop(context, _editedHorario);
        },
        // ignore: sort_child_properties_last
        child: Icon(Icons.save, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: "Nome"),
              onChanged: (text) {
                setState(() {
                  _nomeController.text = text;
                  _editedHorario.nome = text;
                });
              },
              // controller: TextEditingController(text: _editedHorario.nome),
            ),
            TextField(
              controller: _dataInicioController,
              // readOnly: true, // impede digitação
              decoration: InputDecoration(
                labelText: "Data Início",
                // border: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(12),
                // ),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  String formatted = DateFormat('dd/MM/yyyy', 'pt_BR').format(pickedDate);
                  String saveData = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                  setState(() {
                    _dataInicioController.text = formatted;
                    _editedHorario.dataInicio = saveData; // salva no modelo
                  });
                }
              },
            ),
            Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _horaInicioController,
                      decoration: InputDecoration(labelText: "Hora Inicio"),
                      keyboardType: TextInputType.number,
                      onChanged: (text) {
                        setState(() {
                          _horaInicioController.text = text;
                          _editedHorario.horaInicio = text.isNotEmpty ? int.parse(text) : null;
                        });
                      },
                    ),
                ),
                Expanded(
                  child: TextField(
                    controller: _minutoInicioController,
                    decoration: InputDecoration(labelText: "Minuto Inicio"),
                    keyboardType: TextInputType.number,
                    onChanged: (text) {
                      setState(() {
                        _minutoInicioController.text = text;
                        _editedHorario.minutoInicio = text.isNotEmpty ? int.parse(text) : null;
                      });
                    },
                  ),
                )
              ]
            ),
            TextField(
              controller: _frequenciaController,
              decoration: InputDecoration(labelText: "Frequencia (em horas)"),
              keyboardType: TextInputType.number,
              onChanged: (text) {
                setState(() {
                  _frequenciaController.text = text;
                  _editedHorario.frequencia = text.isNotEmpty ? int.parse(text) : null;
                });
              },
              // controller: TextEditingController(text: _editedHorario.nome),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6, // espaço horizontal
              runSpacing: 20, // espaço vertical se quebrar linha
              // direction: Axis.vertical,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.segunda == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.segunda = 1;
                          } else {
                            _editedHorario.segunda = 0;
                          }
                        });
                      },
                    ),
                    Text("Seg")
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [ 
                    Checkbox(
                      value: _editedHorario.terca == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.terca = 1;
                          } else {
                            _editedHorario.terca = 0;
                          }
                        });
                      },
                    ),
                    Text("Ter")
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.quarta == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.quarta = 1;
                          } else {
                            _editedHorario.quarta = 0;
                          }
                        });
                      },
                    ),
                    Text("Qua")
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.quinta == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.quinta = 1;
                          } else {
                            _editedHorario.quinta = 0;
                          }
                        });
                      },
                    ),
                    Text("Qui")
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.sexta == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.sexta = 1;
                          } else {
                            _editedHorario.sexta = 0;
                          }
                        });
                      },
                    ),
                    Text("Sex")
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.sabado == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.sabado = 1;
                          } else {
                            _editedHorario.sabado = 0;
                          }
                        });
                      },
                    ),
                    Text("Sab"),
                  ]
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _editedHorario.domingo == 1 ? true : false,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _editedHorario.domingo = 1;
                          } else {
                            _editedHorario.domingo = 0;
                          }
                        });
                      },
                    ),
                    Text("Dom")
                  ]
                )
              ]
            ),
            TextField(
              controller: _observacoesController,
              decoration: InputDecoration(labelText: "Observações"),
              onChanged: (text) {
                setState(() {
                  _observacoesController.text = text;
                  _editedHorario.observacoes = text;
                });
              },
            ),
            // Adicione mais campos conforme necessário
          ],
        )
      ),
    );
    
  }
}