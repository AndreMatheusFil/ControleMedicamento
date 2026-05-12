import 'package:controlemedicamento/helpers/historico_doses.dart';
import 'package:controlemedicamento/helpers/horarios.dart';
import 'package:controlemedicamento/helpers/proximas_doses.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final HorariosHelper helper = HorariosHelper();
  final HistoricoDosesHelper historicoHelper = HistoricoDosesHelper();

  List<Horarios> horarios = [];
  List<ProximaDose> proximasDoses = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final list = await helper.getAllHorarios();

    final horariosConvertidos = List<Horarios>.from(list);
    final proximas = ProximasDosesHelper.calcular(horariosConvertidos);

    if (!mounted) return;

    setState(() {
      horarios = horariosConvertidos;
      proximasDoses = proximas;
    });
  }

  Future<void> _marcarComoTomado(ProximaDose dose) async {
    if (dose.horario.id == null) return;

    await historicoHelper.salvarTomado(
      idHorario: dose.horario.id!,
      nomeMedicamento: dose.horario.nome ?? "Medicamento",
      dataHoraPrevista: dose.dataHora,
    );

    await helper.baixarEstoque(dose.horario);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${dose.horario.nome ?? "Medicamento"} marcado como tomado!"),
        backgroundColor: Colors.green,
      ),
    );

    await _carregarDados();
  }

  String _formatarDataHora(DateTime data) {
    return DateFormat("dd/MM/yyyy 'às' HH:mm", "pt_BR").format(data);
  }

  String _formatarHora(DateTime data) {
    return DateFormat("HH:mm", "pt_BR").format(data);
  }

  String _textoEstoque(Horarios h) {
    final total = h.quantidadeTotal ?? 0;
    final porDose = h.quantidadePorDose ?? 1;
    final forma = h.forma ?? "un.";

    if (total <= 0) {
      return "Estoque não informado";
    }

    return "Restam $total $forma • Usa $porDose por dose";
  }

  @override
  Widget build(BuildContext context) {
    final ProximaDose? proxima =
        proximasDoses.isNotEmpty ? proximasDoses.first : null;

    final medicamentosAcabando = horarios.where((h) {
      final total = h.quantidadeTotal ?? 0;
      return total > 0 && total <= 5;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Medicamentos"),
        backgroundColor: const Color(0xFF6C4AB6),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (proxima != null)
              Card(
                color: Colors.blue.shade50,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Próxima dose",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        proxima.horario.nome ?? "Medicamento",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((proxima.horario.dosagem ?? "").isNotEmpty)
                        Text(
                          proxima.horario.dosagem!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _formatarDataHora(proxima.dataHora),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _textoEstoque(proxima.horario),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        proxima.horario.observacoes ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _marcarComoTomado(proxima),
                        icon: const Icon(Icons.check),
                        label: const Text("Já tomei"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medication_liquid,
                          size: 56,
                          color: Color(0xFF6C4AB6),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Nenhum medicamento agendado",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Cadastre um remédio ou use a IA para ler uma receita.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (medicamentosAcabando.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Medicamentos acabando",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...medicamentosAcabando.map((h) {
                return Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(h.nome ?? "Medicamento"),
                    subtitle: Text(_textoEstoque(h)),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            const Text(
              "Próximos horários",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (proximasDoses.isEmpty)
              const Text("Cadastre um medicamento para aparecer aqui."),

            ...proximasDoses.take(8).map((dose) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C4AB6),
                    child: Text(
                      _formatarHora(dose.dataHora),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    dose.horario.nome ?? "Medicamento",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${_formatarDataHora(dose.dataHora)}\n${_textoEstoque(dose.horario)}",
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _marcarComoTomado(dose),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}