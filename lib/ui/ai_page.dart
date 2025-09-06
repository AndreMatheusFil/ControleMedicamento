import 'package:flutter/material.dart';
import 'package:controlemedicamento/services/ocr_service.dart';
import 'package:controlemedicamento/helpers/horarios_universal.dart';
import 'package:controlemedicamento/helpers/horarios_web.dart' as web;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IA - OCR de Receitas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com instruções
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue[600], size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Scanner de Receitas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Capture ou selecione uma foto da receita médica para extrair automaticamente os medicamentos e horários.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
                    label: Text('Câmera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Preview da imagem
            if (_selectedImage != null || _imageBytes != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagem Selecionada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              );
                            },
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
                              label: Text(_isProcessing ? 'Processando...' : 'Extrair Texto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _clearImage,
                            icon: Icon(Icons.clear),
                            label: Text('Limpar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
            ],
            
            // Texto extraído
            if (_extractedText.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Texto Extraído',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
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
              
              SizedBox(height: 20),
            ],
            
            // Medicamentos identificados
            if (_medicamentosExtraidos.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Medicamentos Identificados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveAllMedicamentos,
                            icon: Icon(Icons.save),
                            label: Text('Salvar Todos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ...(_medicamentosExtraidos.asMap().entries.map((entry) {
                        int index = entry.key;
                        MedicamentoExtraido medicamento = entry.value;
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.medication, color: Colors.blue[600]),
                            ),
                            title: Text(
                              medicamento.nome,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (medicamento.dosagem.isNotEmpty)
                                  Text('Dosagem: ${medicamento.dosagem}'),
                                if (medicamento.frequencia.isNotEmpty)
                                  Text('Frequência: ${medicamento.frequencia}'),
                                if (medicamento.duracao.isNotEmpty)
                                  Text('Duração: ${medicamento.duracao}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _saveMedicamento(medicamento),
                                  icon: Icon(Icons.save, color: Colors.green[600]),
                                  tooltip: 'Salvar',
                                ),
                                IconButton(
                                  onPressed: () => _removeMedicamento(index),
                                  icon: Icon(Icons.delete, color: Colors.red[600]),
                                  tooltip: 'Remover',
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
            ],
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
        // Sempre converter para bytes para compatibilidade
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
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
        // Sempre converter para bytes para compatibilidade
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
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
    if (_imageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Sempre usar bytes para compatibilidade
      String extractedText = await _ocrService.extractTextFromImageBytes(_imageBytes!);
      
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
      _imageBytes = null;
      _extractedText = '';
      _medicamentosExtraidos = [];
    });
  }

  // Salvar todos os medicamentos
  Future<void> _saveAllMedicamentos() async {
    try {
      int savedCount = 0;
      
      for (MedicamentoExtraido medicamento in _medicamentosExtraidos) {
        await _saveMedicamento(medicamento);
        savedCount++;
      }
      
      _showSuccessDialog(
        'Medicamentos Salvos',
        '$savedCount medicamento(s) foram salvos com sucesso!'
      );
      
      // Remover medicamentos salvos da lista
      setState(() {
        _medicamentosExtraidos.clear();
      });
    } catch (e) {
      _showErrorDialog('Erro ao salvar medicamentos: $e');
    }
  }

  // Salvar medicamento individual
  Future<void> _saveMedicamento(MedicamentoExtraido medicamento) async {
    try {
      // Criar horário baseado no medicamento extraído
      web.Horarios horario = web.Horarios();
      horario.nome = '${medicamento.nome} - ${medicamento.dosagem}';
      horario.observacoes = 'Frequência: ${medicamento.frequencia}\nDuração: ${medicamento.duracao}';
      horario.dataInicio = DateTime.now().toIso8601String().split('T')[0];
      horario.diasFim = 30; // Padrão de 30 dias
      horario.horaInicio = 8; // Horário padrão
      horario.minutoInicio = 0;
      horario.frequencia = 8; // A cada 8 horas
      horario.segunda = 1;
      horario.terca = 1;
      horario.quarta = 1;
      horario.quinta = 1;
      horario.sexta = 1;
      horario.sabado = 1;
      horario.domingo = 1;
      
      await _helper.saveHorario(horario);
      
      _showSuccessDialog(
        'Medicamento Salvo',
        '${medicamento.nome} foi salvo com sucesso!'
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

  // Diálogos
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
