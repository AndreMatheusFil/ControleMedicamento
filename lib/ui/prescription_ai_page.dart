import 'dart:io';

import 'package:controlemedicamento/helpers/horarios.dart';
import 'package:controlemedicamento/services/ocr_service.dart';
import 'package:controlemedicamento/ui/cadastro_horarios_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:controlemedicamento/helpers/medicamentos_helper.dart';

class PrescriptionAiPage extends StatefulWidget {
  const PrescriptionAiPage({super.key});

  @override
  State<PrescriptionAiPage> createState() => _PrescriptionAiPageState();
}

class _PrescriptionAiPageState extends State<PrescriptionAiPage> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  File? _image;
  String _textoExtraido = "";
  bool _loading = false;

  Future<void> _tirarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      maxWidth: 2000,
    );

    if (foto == null) return;

    setState(() {
      _image = File(foto.path);
      _textoExtraido = "";
      _loading = true;
    });

    try {
      final texto = await _ocrService.readTextFromImage(foto.path);

      setState(() {
        _textoExtraido = texto;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao ler receita: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _escolherGaleria() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
      maxWidth: 2000,
    );

    if (foto == null) return;

    setState(() {
      _image = File(foto.path);
      _textoExtraido = "";
      _loading = true;
    });

    try {
      final texto = await _ocrService.readTextFromImage(foto.path);

      setState(() {
        _textoExtraido = texto;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao ler receita: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Horarios _gerarHorarioPeloTexto(String texto) {
    final agora = DateTime.now();

    final horario = Horarios();

    horario.nome = _extrairNomeMedicamento(texto);
    horario.dataInicio = "${agora.year}-${agora.month}-${agora.day}";
    horario.horaInicio = agora.hour;
    horario.minutoInicio = agora.minute + 2 >= 60 ? 0 : agora.minute + 2;
    horario.frequencia = _extrairFrequencia(texto);
    horario.diasFim = _extrairDiasTratamento(texto);

    horario.segunda = 1;
    horario.terca = 1;
    horario.quarta = 1;
    horario.quinta = 1;
    horario.sexta = 1;
    horario.sabado = 1;
    horario.domingo = 1;

    horario.observacoes = texto;

    return horario;
  }

  String _extrairNomeMedicamento(String texto) {
    final nomeCorrigido = MedicamentosHelper.corrigirNomeMedicamento(texto);

    if (nomeCorrigido != "Medicamento") {
      return nomeCorrigido;
    }

    final linhas = texto
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final linha in linhas) {
      final lower = linha.toLowerCase();

      if (lower.contains("paciente")) continue;
      if (lower.contains("médico")) continue;
      if (lower.contains("medico")) continue;
      if (lower.contains("crm")) continue;
      if (lower.contains("receita")) continue;
      if (lower.contains("tomar")) continue;
      if (lower.contains("uso")) continue;
      if (lower.contains("data")) continue;

      if (lower.contains("mg") ||
          lower.contains("ml") ||
          lower.contains("comprimido") ||
          lower.contains("capsula") ||
          lower.contains("cápsula") ||
          lower.contains("gotas")) {
        return linha;
      }
    }

    return "Medicamento";
  }

  int _extrairFrequencia(String texto) {
    final lower = texto.toLowerCase();

    final regexBarra = RegExp(r'(\d{1,2})\s*/\s*(\d{1,2})');
    final matchBarra = regexBarra.firstMatch(lower);
    if (matchBarra != null) {
      return int.tryParse(matchBarra.group(1) ?? "") ?? 8;
    }

    final regexEmHoras = RegExp(r'(\d{1,2})\s*em\s*(\d{1,2})\s*horas');
    final matchEmHoras = regexEmHoras.firstMatch(lower);
    if (matchEmHoras != null) {
      return int.tryParse(matchEmHoras.group(1) ?? "") ?? 8;
    }

    final regexCada = RegExp(r'a cada\s*(\d{1,2})\s*horas');
    final matchCada = regexCada.firstMatch(lower);
    if (matchCada != null) {
      return int.tryParse(matchCada.group(1) ?? "") ?? 8;
    }

    if (lower.contains("uma vez ao dia") || lower.contains("1 vez ao dia")) {
      return 24;
    }

    if (lower.contains("duas vezes ao dia") || lower.contains("2 vezes ao dia")) {
      return 12;
    }

    if (lower.contains("três vezes ao dia") || lower.contains("3 vezes ao dia")) {
      return 8;
    }

    return 8;
  }

  int _extrairDiasTratamento(String texto) {
    final lower = texto.toLowerCase();

    final regex = RegExp(r'(por|durante)\s*(\d{1,3})\s*dias');
    final match = regex.firstMatch(lower);

    if (match != null) {
      return int.tryParse(match.group(2) ?? "") ?? 0;
    }

    return 0;
  }

  Future<void> _abrirCadastroComTexto() async {
    if (_textoExtraido.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum texto foi lido da receita.")),
      );
      return;
    }

    final horario = _gerarHorarioPeloTexto(_textoExtraido);

    final recHorario = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroHorarioPage(horarios: horario),
      ),
    );

    if (!mounted) return;

    if (recHorario != null) {
      final helper = HorariosHelper();
      await helper.saveHorario(recHorario);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicamento salvo com sucesso!")),
      );
    }
  }

  @override
  void dispose() {
    _ocrService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IA da Receita"),
        backgroundColor: const Color(0xFF6C4AB6),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(
                      Icons.document_scanner,
                      size: 64,
                      color: Color(0xFF6C4AB6),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Leia sua receita com IA",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tire uma foto da receita médica e o app tenta preencher os dados do medicamento automaticamente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _tirarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Tirar foto da receita"),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _escolherGaleria,
                      icon: const Icon(Icons.image),
                      label: const Text("Escolher da galeria"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C4AB6),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}