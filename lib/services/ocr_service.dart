import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'permission_service.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();

  /// Captura uma imagem da câmera
  Future<File?> captureImageFromCamera() async {
    try {
      // Verifica permissão da câmera
      bool hasPermission = await _permissionService.requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Permissão de câmera negada');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao capturar imagem: $e');
      return null;
    }
  }

  /// Seleciona uma imagem da galeria
  Future<File?> pickImageFromGallery() async {
    try {
      // Verifica permissão de armazenamento
      bool hasPermission = await _permissionService.requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Permissão de armazenamento negada');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Processa uma imagem e extrai o texto
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('Erro ao processar OCR: $e');
      return '';
    }
  }

  /// Processa o texto extraído e identifica medicamentos
  List<MedicamentoExtraido> processarReceita(String texto) {
    List<MedicamentoExtraido> medicamentos = [];
    
    // Divide o texto em linhas
    List<String> linhas = texto.split('\n');
    
    for (String linha in linhas) {
      linha = linha.trim();
      if (linha.isEmpty) continue;
      
      // Padrões comuns em receitas médicas
      MedicamentoExtraido? medicamento = _extrairMedicamento(linha);
      if (medicamento != null) {
        medicamentos.add(medicamento);
      }
    }
    
    return medicamentos;
  }

  /// Extrai informações de um medicamento de uma linha de texto
  MedicamentoExtraido? _extrairMedicamento(String linha) {
    // Remove caracteres especiais e normaliza
    String linhaLimpa = linha.replaceAll(RegExp(r'[^\w\s\d\-\.]'), ' ').trim();
    
    // Padrões para identificar medicamentos
    List<String> palavras = linhaLimpa.split(RegExp(r'\s+'));
    
    if (palavras.length < 2) return null;
    
    // Procura por padrões de dosagem
    String? dosagem = _extrairDosagem(linha);
    String? frequencia = _extrairFrequencia(linha);
    String? duracao = _extrairDuracao(linha);
    
    // Se encontrou pelo menos dosagem ou frequência, considera um medicamento
    if (dosagem != null || frequencia != null) {
      String nome = _extrairNomeMedicamento(palavras);
      
      if (nome.isNotEmpty) {
        return MedicamentoExtraido(
          nome: nome,
          dosagem: dosagem ?? 'Não especificada',
          frequencia: frequencia ?? 'Conforme orientação médica',
          duracao: duracao ?? '30 dias',
          observacoes: linha,
          confianca: _calcularConfianca(linha, dosagem, frequencia),
        );
      }
    }
    
    return null;
  }

  /// Extrai a dosagem do medicamento
  String? _extrairDosagem(String linha) {
    // Padrões comuns de dosagem
    RegExp dosagemRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|UI|cp|comprimido|comprimidos)', caseSensitive: false);
    Match? match = dosagemRegex.firstMatch(linha);
    
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}';
    }
    
    return null;
  }

  /// Extrai a frequência de uso
  String? _extrairFrequencia(String linha) {
    // Padrões de frequência
    if (linha.toLowerCase().contains('1x ao dia') || linha.toLowerCase().contains('1 vez ao dia')) {
      return '1x ao dia';
    } else if (linha.toLowerCase().contains('2x ao dia') || linha.toLowerCase().contains('2 vezes ao dia')) {
      return '2x ao dia';
    } else if (linha.toLowerCase().contains('3x ao dia') || linha.toLowerCase().contains('3 vezes ao dia')) {
      return '3x ao dia';
    } else if (linha.toLowerCase().contains('de 8/8 horas') || linha.toLowerCase().contains('a cada 8 horas')) {
      return 'A cada 8 horas';
    } else if (linha.toLowerCase().contains('de 12/12 horas') || linha.toLowerCase().contains('a cada 12 horas')) {
      return 'A cada 12 horas';
    } else if (linha.toLowerCase().contains('de 6/6 horas') || linha.toLowerCase().contains('a cada 6 horas')) {
      return 'A cada 6 horas';
    }
    
    return null;
  }

  /// Extrai a duração do tratamento
  String? _extrairDuracao(String linha) {
    // Padrões de duração
    RegExp duracaoRegex = RegExp(r'por\s+(\d+)\s*(dias?|semanas?|meses?)', caseSensitive: false);
    Match? match = duracaoRegex.firstMatch(linha);
    
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}';
    }
    
    return null;
  }

  /// Extrai o nome do medicamento
  String _extrairNomeMedicamento(List<String> palavras) {
    // Remove palavras comuns que não são nomes de medicamentos
    List<String> palavrasIgnorar = [
      'tomar', 'usar', 'aplicar', 'ingerir', 'administrar',
      'com', 'sem', 'alimento', 'agua', 'leite',
      'antes', 'depois', 'durante', 'apos', 'pos'
    ];
    
    List<String> nomePalavras = [];
    
    for (String palavra in palavras) {
      if (palavra.length > 2 && 
          !palavrasIgnorar.contains(palavra.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(palavra)) {
        nomePalavras.add(palavra);
      }
    }
    
    return nomePalavras.take(3).join(' '); // Pega até 3 palavras para o nome
  }

  /// Calcula a confiança da extração
  double _calcularConfianca(String linha, String? dosagem, String? frequencia) {
    double confianca = 0.0;
    
    // Base confiança
    confianca += 0.3;
    
    // Bonus por ter dosagem
    if (dosagem != null) confianca += 0.3;
    
    // Bonus por ter frequência
    if (frequencia != null) confianca += 0.3;
    
    // Bonus por ter palavras médicas
    if (linha.toLowerCase().contains('mg') || 
        linha.toLowerCase().contains('ml') ||
        linha.toLowerCase().contains('cp')) {
      confianca += 0.1;
    }
    
    return confianca.clamp(0.0, 1.0);
  }

  /// Limpa recursos
  void dispose() {
    _textRecognizer.close();
  }
}

/// Classe para representar um medicamento extraído do OCR
class MedicamentoExtraido {
  final String nome;
  final String dosagem;
  final String frequencia;
  final String duracao;
  final String observacoes;
  final double confianca;

  MedicamentoExtraido({
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    required this.duracao,
    required this.observacoes,
    required this.confianca,
  });

  /// Converte para Horarios (modelo do banco)
  Map<String, dynamic> toHorariosMap() {
    // Converte frequência para horas
    int frequenciaHoras = _converterFrequenciaParaHoras(frequencia);
    
    // Converte duração para dias
    int duracaoDias = _converterDuracaoParaDias(duracao);
    
    return {
      'nome_horario': '$nome - $dosagem',
      'data_inicio': DateTime.now().toIso8601String().split('T')[0],
      'dias_fim': duracaoDias,
      'hora_inicio': 8, // Hora padrão
      'minuto_inicio': 0,
      'frequencia': frequenciaHoras,
      'segunda': 1,
      'terca': 1,
      'quarta': 1,
      'quinta': 1,
      'sexta': 1,
      'sabado': 1,
      'domingo': 1,
      'observacoes': observacoes,
    };
  }

  int _converterFrequenciaParaHoras(String freq) {
    if (freq.contains('1x ao dia')) return 24;
    if (freq.contains('2x ao dia')) return 12;
    if (freq.contains('3x ao dia')) return 8;
    if (freq.contains('8 horas')) return 8;
    if (freq.contains('12 horas')) return 12;
    if (freq.contains('6 horas')) return 6;
    return 8; // Padrão
  }

  int _converterDuracaoParaDias(String dur) {
    if (dur.contains('dias')) {
      RegExp regex = RegExp(r'(\d+)');
      Match? match = regex.firstMatch(dur);
      if (match != null) return int.parse(match.group(1)!);
    } else if (dur.contains('semanas')) {
      RegExp regex = RegExp(r'(\d+)');
      Match? match = regex.firstMatch(dur);
      if (match != null) return int.parse(match.group(1)!) * 7;
    } else if (dur.contains('meses')) {
      RegExp regex = RegExp(r'(\d+)');
      Match? match = regex.firstMatch(dur);
      if (match != null) return int.parse(match.group(1)!) * 30;
    }
    return 30; // Padrão
  }
}
