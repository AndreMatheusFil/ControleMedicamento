import 'package:flutter/material.dart';
import 'package:controlemedicamento/helpers/horarios_universal.dart';
import 'package:controlemedicamento/helpers/horarios_web.dart' as web;

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  HorariosUniversalHelper helper = HorariosUniversalHelper();
  List<web.Horarios> horarios = [];
  List<web.Horarios> medicamentosHoje = [];

  @override
  void initState() {
    super.initState();
    _getAllHorarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
        toolbarHeight: 75.0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de resumo
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resumo do Dia",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard("Total", horarios.length.toString(), Icons.medication),
                          _buildStatCard("Hoje", medicamentosHoje.length.toString(), Icons.today),
                          _buildStatCard("Ativos", _getMedicamentosAtivos().toString(), Icons.check_circle),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Próximos medicamentos
              Text(
                "Próximos Medicamentos",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              if (medicamentosHoje.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.medication, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "Nenhum medicamento para hoje",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...medicamentosHoje.map((medicamento) => _buildMedicamentoCard(medicamento)).toList(),
              
              SizedBox(height: 20),
              
              // Todos os medicamentos
              Text(
                "Todos os Medicamentos",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              if (horarios.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.add_circle_outline, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "Nenhum medicamento cadastrado",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navegar para a tela de cadastro
                              // Isso será implementado quando tivermos acesso ao TabController
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Use a aba 'Medicamentos' para cadastrar"),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            icon: Icon(Icons.add),
                            label: Text("Cadastrar Medicamento"),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...horarios.map((medicamento) => _buildMedicamentoCard(medicamento)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicamentoCard(web.Horarios medicamento) {
    String horario = "${medicamento.horaInicio.toString().padLeft(2, '0')}:${medicamento.minutoInicio.toString().padLeft(2, '0')}";
    
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.medication, color: Colors.white),
        ),
        title: Text(
          medicamento.nome ?? "Sem nome",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Horário: $horario"),
            Text("Frequência: A cada ${medicamento.frequencia} horas"),
            if (medicamento.observacoes != null && medicamento.observacoes!.isNotEmpty)
              Text(
                medicamento.observacoes!,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar para detalhes ou edição
        },
      ),
    );
  }

  int _getMedicamentosAtivos() {
    DateTime hoje = DateTime.now();
    return horarios.where((medicamento) {
      if (medicamento.dataInicio == null) return false;
      
      try {
        if (medicamento.dataInicio != null) {
          List<String> parts = medicamento.dataInicio!.split("-");
          if (parts.length == 3) {
            DateTime dataInicio = DateTime.parse("${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}");
            DateTime? dataFim;
            
            if (medicamento.diasFim != null) {
              dataFim = dataInicio.add(Duration(days: medicamento.diasFim!));
            }
            
            return hoje.isAfter(dataInicio) && (dataFim == null || hoje.isBefore(dataFim));
          }
        }
      } catch (e) {
        return false;
      }
      return false;
    }).length;
  }

  Future<void> _refreshData() async {
    _getAllHorarios();
  }

  void _getAllHorarios() {
    helper.getAllHorarios().then((list) {
      setState(() {
        horarios = List<web.Horarios>.from(list);
        medicamentosHoje = _getMedicamentosParaHoje();
      });
    });
  }

  List<web.Horarios> _getMedicamentosParaHoje() {
    DateTime hoje = DateTime.now();
    int diaSemana = hoje.weekday; // 1 = segunda, 7 = domingo
    
    return horarios.where((medicamento) {
      // Verifica se o medicamento está ativo hoje
      if (medicamento.dataInicio == null) return false;
      
      try {
        if (medicamento.dataInicio != null) {
          List<String> parts = medicamento.dataInicio!.split("-");
          if (parts.length == 3) {
            DateTime dataInicio = DateTime.parse("${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}");
            DateTime? dataFim;
            
            if (medicamento.diasFim != null) {
              dataFim = dataInicio.add(Duration(days: medicamento.diasFim!));
            }
            
            // Verifica se está no período ativo
            if (!hoje.isAfter(dataInicio) || (dataFim != null && hoje.isAfter(dataFim))) {
              return false;
            }
            
            // Verifica se o dia da semana está marcado
            switch (diaSemana) {
              case 1: return medicamento.segunda == 1;
              case 2: return medicamento.terca == 1;
              case 3: return medicamento.quarta == 1;
              case 4: return medicamento.quinta == 1;
              case 5: return medicamento.sexta == 1;
              case 6: return medicamento.sabado == 1;
              case 7: return medicamento.domingo == 1;
              default: return false;
            }
          }
        }
      } catch (e) {
        return false;
      }
      return false;
    }).toList();
  }
}
