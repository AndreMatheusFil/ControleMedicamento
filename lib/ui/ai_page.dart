import 'package:flutter/material.dart';
import 'package:controlemedicamento/services/ocr_service.dart';
import 'package:controlemedicamento/helpers/horarios_universal.dart';
import 'package:controlemedicamento/helpers/horarios_web.dart' as web;
import 'dart:io';

class AIPage extends StatefulWidget {
  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final OCRService _ocrService = OCRService();
  final HorariosUniversalHelper _helper = HorariosUniversalHelper();
  
  bool _isProcessing = false;
  String _extractedText = '';
  List<MedicamentoExtraido> _medicamentosExtraidos = [];
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IA - Assistente"),
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
        toolbarHeight: 75.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 60,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Assistente IA - OCR de Receitas",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Tire uma foto da sua receita médica e cadastre os medicamentos automaticamente",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Botões de captura
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureFromCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text("Câmera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text("Galeria"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Imagem selecionada
            if (_selectedImage != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Imagem Selecionada:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _processImage,
                              icon: _isProcessing 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.auto_awesome),
                              label: Text(_isProcessing ? "Processando..." : "Processar OCR"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _clearImage,
                            icon: Icon(Icons.clear),
                            label: Text("Limpar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Texto extraído
            if (_extractedText.isNotEmpty) ...[
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Texto Extraído:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _extractedText,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Medicamentos extraídos
            if (_medicamentosExtraidos.isNotEmpty) ...[
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Medicamentos Identificados:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveAllMedicamentos,
                            icon: Icon(Icons.save),
                            label: Text("Salvar Todos"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ..._medicamentosExtraidos.asMap().entries.map((entry) {
                        int index = entry.key;
                        MedicamentoExtraido medicamento = entry.value;
                        return _buildMedicamentoCard(medicamento, index);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
            
            // Instruções
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Como usar:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildInstructionItem(
                      "1. Tire uma foto clara da receita médica",
                      Icons.camera_alt,
                    ),
                    _buildInstructionItem(
                      "2. Aguarde o processamento do OCR",
                      Icons.auto_awesome,
                    ),
                    _buildInstructionItem(
                      "3. Revise os medicamentos identificados",
                      Icons.medication,
                    ),
                    _buildInstructionItem(
                      "4. Salve os medicamentos no seu controle",
                      Icons.save,
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

  // Métodos para captura de imagem
  Future<void> _captureFromCamera() async {
    try {
      final image = await _ocrService.captureImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedText = '';
          _medicamentosExtraidos = [];
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao capturar imagem: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _ocrService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedText = '';
          _medicamentosExtraidos = [];
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar imagem: $e');
    }
  }

  // Processar imagem com OCR
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Extrair texto da imagem
      String extractedText = await _ocrService.extractTextFromImage(_selectedImage!);
      
      // Processar receita e extrair medicamentos
      List<MedicamentoExtraido> medicamentos = _ocrService.processarReceita(extractedText);
      
      setState(() {
        _extractedText = extractedText;
        _medicamentosExtraidos = medicamentos;
        _isProcessing = false;
      });

      if (medicamentos.isEmpty) {
        _showInfoDialog(
          'Nenhum medicamento identificado',
          'Não foi possível identificar medicamentos na receita. Verifique se a imagem está clara e tente novamente.'
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Erro ao processar imagem: $e');
    }
  }

  // Limpar imagem selecionada
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _medicamentosExtraidos = [];
    });
  }

  // Salvar todos os medicamentos
  Future<void> _saveAllMedicamentos() async {
    if (_medicamentosExtraidos.isEmpty) return;

    try {
      int savedCount = 0;
      
      for (MedicamentoExtraido medicamento in _medicamentosExtraidos) {
        Map<String, dynamic> horarioMap = medicamento.toHorariosMap();
        web.Horarios horario = web.Horarios.fromMap(horarioMap);
        await _helper.saveHorario(horario);
        savedCount++;
      }

      _showSuccessDialog(
        'Medicamentos salvos!',
        '$savedCount medicamento(s) foram cadastrados com sucesso.'
      );

      // Limpar após salvar
      _clearImage();
    } catch (e) {
      _showErrorDialog('Erro ao salvar medicamentos: $e');
    }
  }

  // Salvar medicamento individual
  Future<void> _saveMedicamento(MedicamentoExtraido medicamento) async {
    try {
      Map<String, dynamic> horarioMap = medicamento.toHorariosMap();
      web.Horarios horario = web.Horarios.fromMap(horarioMap);
      await _helper.saveHorario(horario);
      
      _showSuccessDialog(
        'Medicamento salvo!',
        '${medicamento.nome} foi cadastrado com sucesso.'
      );
    } catch (e) {
      _showErrorDialog('Erro ao salvar medicamento: $e');
    }
  }

  // Remover medicamento da lista
  void _removeMedicamento(int index) {
    setState(() {
      _medicamentosExtraidos.removeAt(index);
    });
  }

  // Widget para card de medicamento
  Widget _buildMedicamentoCard(MedicamentoExtraido medicamento, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dosagem: ${medicamento.dosagem}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Frequência: ${medicamento.frequencia}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Duração: ${medicamento.duracao}',
                        style: TextStyle(fontSize: 14),
                      ),
                      if (medicamento.observacoes.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          'Observações: ${medicamento.observacoes}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Indicador de confiança
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: medicamento.confianca > 0.7 
                          ? Colors.green 
                          : medicamento.confianca > 0.4 
                            ? Colors.orange 
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(medicamento.confianca * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Botões de ação
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _saveMedicamento(medicamento),
                          icon: Icon(Icons.save, color: Colors.green),
                          tooltip: 'Salvar medicamento',
                        ),
                        IconButton(
                          onPressed: () => _removeMedicamento(index),
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Remover da lista',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para item de instrução
  Widget _buildInstructionItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogos
  void _showErrorDialog(String title, [String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message ?? 'Ocorreu um erro inesperado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}


