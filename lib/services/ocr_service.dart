import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'permission_service.dart';
import 'web_ocr_service.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();
  final PermissionService _permissionService = PermissionService();


  Future<XFile?> captureImageFromCamera() async {
    try {
      if (!kIsWeb) {
        bool hasPermission = await _permissionService.requestCameraPermission();
        if (!hasPermission) {
          throw Exception('Permissão de câmera negada');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image;
    } catch (e) {
      debugPrint('Erro ao capturar imagem: $e');
      return null;
    }
  }


  Future<XFile?> pickImageFromGallery() async {
    try {
    
      if (!kIsWeb) {
        bool hasPermission = await _permissionService.requestStoragePermission();
        if (!hasPermission) {
          throw Exception('Permissão de armazenamento negada');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image;
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }
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
  Future<String> extractTextFromXFile(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('Erro ao processar OCR com XFile: $e');
      return '';
    }
  }
  Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        debugPrint('Usando OCR web...');
        // Para web, usar API externa
        String result = await WebOCRService.extractTextFromImageBytes(imageBytes);
        debugPrint('Texto extraído pelo OCR web: ${result.length > 100 ? result.substring(0, 100) + "..." : result}');
        return result;
      } else {
        debugPrint('Usando ML Kit para mobile...');
        
        // Para mobile, usar ML Kit
        final inputImage = InputImage.fromBytes(
          bytes: imageBytes,
          metadata: InputImageMetadata(
            size: Size(1920, 1080),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 1920 * 4,
          ),
        );
        
        // Processar a imagem com ML Kit
        final recognizedText = await _textRecognizer.processImage(inputImage);
        
        debugPrint('Texto extraído pelo ML Kit: ${recognizedText.text.length > 100 ? recognizedText.text.substring(0, 100) + "..." : recognizedText.text}');
        return recognizedText.text;
      }
    } catch (e) {
      debugPrint('Erro ao processar OCR: $e');
      return '';
    }
  }



  List<MedicamentoExtraido> processarReceita(String texto) {
    try {
      debugPrint('Processando receita: $texto');
      
      if (texto.trim().isEmpty) {
        debugPrint('Texto vazio recebido');
        return [];
      }
      
      ReceitaContext context = _analisarContextoReceita(texto);
      
      List<MedicamentoExtraido> medicamentos = _extrairMedicamentosInteligente(context);
      
      debugPrint('Medicamentos encontrados: ${medicamentos.length}');
      return medicamentos;
    } catch (e) {
      debugPrint('Erro ao processar receita: $e');
      return [];
    }
  }

  // Análise contextual inteligente da receita
  ReceitaContext _analisarContextoReceita(String texto) {
    try {
      String textoLimpo = _limparTexto(texto);
      List<String> linhas = textoLimpo.split('\n').where((l) => l.trim().isNotEmpty).toList();
      List<String> palavras = textoLimpo.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      
      Map<String, dynamic> metadados = {
        'totalLinhas': linhas.length,
        'totalPalavras': palavras.length,
        'contemNumeros': RegExp(r'\d+').hasMatch(texto),
        'contemUnidades': RegExp(r'\d+\s*(mg|ml|g|cp|cápsula|comprimido)', caseSensitive: false).hasMatch(texto),
        'contemInstrucoes': RegExp(r'(tomar|usar|aplicar|ingerir)', caseSensitive: false).hasMatch(texto),
        'contemFrequencia': RegExp(r'(\d+/\d+h?|\d+x\s*ao\s*dia)', caseSensitive: false).hasMatch(texto),
      };
      
      return ReceitaContext(
        textoOriginal: texto,
        linhas: linhas,
        palavras: palavras,
        metadados: metadados,
      );
    } catch (e) {
      debugPrint('Erro na análise contextual: $e');
      return ReceitaContext(
        textoOriginal: texto,
        linhas: [],
        palavras: [],
        metadados: {},
      );
    }
  }

  // Extração inteligente de medicamentos baseada em contexto
  List<MedicamentoExtraido> _extrairMedicamentosInteligente(ReceitaContext context) {
    List<MedicamentoExtraido> medicamentos = [];
    
    // Identifica blocos de texto que podem conter medicamentos
    List<MedicamentoInfo> medicamentosInfo = _identificarBlocosMedicamentos(context);
    
    // Converte para MedicamentoExtraido
    for (MedicamentoInfo info in medicamentosInfo) {
      medicamentos.add(MedicamentoExtraido(
        nome: info.nome,
        dosagem: info.dosagem ?? 'Não especificada',
        frequencia: info.frequencia ?? 'Conforme orientação médica',
        duracao: info.duracao ?? '30 dias',
        observacoes: info.instrucoes ?? '',
        confianca: info.confianca,
      ));
    }
    
    return medicamentos;
  }

  // Identifica blocos de texto que contêm medicamentos
  List<MedicamentoInfo> _identificarBlocosMedicamentos(ReceitaContext context) {
    List<MedicamentoInfo> medicamentos = [];
    
    // Analisa o texto completo para identificar medicamentos
    
    // Procura por linhas que começam com # (comum em receitas)
    List<String> linhasComMedicamentos = context.linhas.where((linha) => 
      linha.trim().startsWith('#') || 
      _contemInformacoesMedicamento(linha)
    ).toList();
    
    // Se não encontrou linhas com #, procura por padrões de medicamento
    if (linhasComMedicamentos.isEmpty) {
      linhasComMedicamentos = context.linhas.where((linha) => 
        _contemInformacoesMedicamento(linha)
      ).toList();
    }
    
    // Processa cada linha identificada
    for (String linha in linhasComMedicamentos) {
      MedicamentoInfo? medicamento = _extrairMedicamentoInteligente(linha, context, 0);
      if (medicamento != null && medicamento.nome.isNotEmpty) {
        medicamentos.add(medicamento);
      }
    }
    
    return medicamentos;
  }

  // Verifica se uma linha contém informações de medicamento
  bool _contemInformacoesMedicamento(String linha) {
    
    // Remove caracteres especiais para análise
    String linhaLimpa = linha.replaceAll(RegExp(r'[^\w\s\d]'), ' ').trim();
    
    // Verifica se tem pelo menos uma palavra longa (possível nome de medicamento)
    List<String> palavras = linhaLimpa.split(RegExp(r'\s+'));
    bool temPalavraLonga = palavras.any((palavra) => palavra.length > 4 && !RegExp(r'^\d+$').hasMatch(palavra));
    
    // Verifica se tem números (dosagem, frequência, duração)
    bool temNumero = RegExp(r'\d+').hasMatch(linha);
    
    // Verifica se tem unidades médicas
    bool temUnidade = RegExp(r'\d+\s*(mg|ml|g|mcg|ui|cp|cápsula|comprimido)', caseSensitive: false).hasMatch(linha);
    
    // Verifica se tem padrões de frequência
    bool temFrequencia = RegExp(r'(\d+/\d+h?|\d+x\s*ao\s*dia|\d+\s*vezes|por\s+\d+)', caseSensitive: false).hasMatch(linha);
    
    // Verifica se tem palavras médicas comuns
    bool temPalavraMedica = RegExp(r'(tomar|usar|aplicar|ingerir|administrar|dias|horas|semana|mes)', caseSensitive: false).hasMatch(linha);
    
    // Conta indicadores
    int indicadores = 0;
    if (temPalavraLonga) indicadores++;
    if (temNumero) indicadores++;
    if (temUnidade) indicadores++;
    if (temFrequencia) indicadores++;
    if (temPalavraMedica) indicadores++;
    
    // Precisa de pelo menos 2 indicadores para ser considerado medicamento
    return indicadores >= 2;
  }

  MedicamentoInfo? _extrairMedicamentoInteligente(String linha, ReceitaContext context, int indiceLinha) {
    String nome = _extrairNomeMedicamentoInteligente(linha);
    if (nome.isEmpty) return null;
    
    String? dosagem = _extrairDosagemInteligente(linha);
    
    String? frequencia = _extrairFrequenciaInteligente(linha);
    
    String? duracao = _extrairDuracaoInteligente(linha);
    

    double confianca = _calcularConfiancaInteligente(linha, dosagem, frequencia, duracao);
    
    return MedicamentoInfo(
      nome: nome,
      dosagem: dosagem,
      frequencia: frequencia,
      duracao: duracao,
      instrucoes: linha,
      confianca: confianca,
    );
  }

  String _limparTexto(String texto) {
    String limpo = texto.replaceAll(RegExp(r'[^\w\s\d\-\.\/\(\)]'), ' ');
    
    limpo = limpo.replaceAll(RegExp(r'\s+'), ' ');
    
    List<String> linhas = limpo.split('\n');
    linhas = linhas.where((linha) => linha.trim().length > 3).toList();
    
    return linhas.join('\n');
  }

  String _extrairNomeMedicamentoInteligente(String linha) {
    // Remove caracteres especiais e normaliza
    String linhaLimpa = linha.replaceAll(RegExp(r'[^\w\s\d]'), ' ').trim();
    List<String> palavras = linhaLimpa.split(RegExp(r'\s+'));
    
    // Lista de palavras que não são nomes de medicamentos
    List<String> palavrasIgnorar = [
      'tomar', 'usar', 'aplicar', 'ingerir', 'administrar',
      'com', 'sem', 'alimento', 'agua', 'leite',
      'antes', 'depois', 'durante', 'apos', 'pos',
      'nome', 'upa', 'atendimento', 'receituario', 'santos',
      'unidade', 'pronto', 'atendimento', 'zona', 'leste',
      'receituario', 'controle', 'especial', 'via', 'retencao',
      'farmacia', 'droga', 'orientacao', 'paciente', 'identificacao',
      'emitente', 'medica', 'crm', 'comprador', 'fornecedor',
      'dias', 'horas', 'semana', 'mes', 'por', 'caso', 'dor'
    ];
    
    // Procura pela primeira palavra que parece ser um nome de medicamento
    for (String palavra in palavras) {
      String palavraLimpa = palavra.trim();
      
      // Deve ter pelo menos 4 caracteres, não ser número, não estar na lista de ignorar
      if (palavraLimpa.length >= 4 && 
          !palavrasIgnorar.contains(palavraLimpa.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(palavraLimpa) &&
          !RegExp(r'^\d+[a-z]*$').hasMatch(palavraLimpa.toLowerCase()) &&
          !RegExp(r'^[a-z]{1,2}$').hasMatch(palavraLimpa.toLowerCase())) { // Evita abreviações muito curtas
        
        // Se a palavra contém números misturados, pode ser uma dosagem, pula
        if (RegExp(r'\d+').hasMatch(palavraLimpa) && palavraLimpa.length < 8) {
          continue;
        }
        
        return palavraLimpa;
      }
    }
    
    // Se não encontrou uma palavra adequada, tenta pegar a primeira palavra longa
    for (String palavra in palavras) {
      String palavraLimpa = palavra.trim();
      if (palavraLimpa.length >= 6 && 
          !RegExp(r'^\d+$').hasMatch(palavraLimpa) &&
          !palavrasIgnorar.contains(palavraLimpa.toLowerCase())) {
        return palavraLimpa;
      }
    }
    
    return '';
  }


  String? _extrairDosagemInteligente(String linha) {
    // Padrões mais flexíveis para dosagem
    List<RegExp> padroesDosagem = [
      RegExp(r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|UI|cp|cápsula|comprimido)', caseSensitive: false),
      RegExp(r'(\d+)\s*m\b', caseSensitive: false), // Para "400m" quando OCR corta "mg"
      RegExp(r'(\d+)\s*mig\b', caseSensitive: false), // Para "400mig" quando OCR erra "mg"
      RegExp(r'(\d+)\s*mg\b', caseSensitive: false), // Padrão direto
    ];
    
    for (RegExp regex in padroesDosagem) {
      Match? match = regex.firstMatch(linha);
    if (match != null) {
        String numero = match.group(1) ?? '';
        String unidade = match.group(2) ?? 'mg';
        
        // Corrige unidades comuns de erro de OCR
        if (unidade == 'm' || unidade == 'mig') {
          unidade = 'mg';
        }
        
        return '$numero $unidade';
      }
    }
    
    return null;
  }

  String? _extrairFrequenciaInteligente(String linha) {
    String linhaLower = linha.toLowerCase();
    
    // Padrões específicos de frequência
    if (linhaLower.contains('12/12h') || linhaLower.contains('12/12') || linhaLower.contains('12112')) {
      return 'A cada 12 horas';
    } else if (linhaLower.contains('8/8h') || linhaLower.contains('8/8')) {
      return 'A cada 8 horas';
    } else if (linhaLower.contains('6/6h') || linhaLower.contains('6/6')) {
      return 'A cada 6 horas';
    } else if (linhaLower.contains('1 cap') && linhaLower.contains('dia')) {
      return '1x ao dia';
    } else if (linhaLower.contains('2x ao dia') || linhaLower.contains('2 vezes ao dia')) {
      return '2x ao dia';
    } else if (linhaLower.contains('3x ao dia') || linhaLower.contains('3 vezes ao dia')) {
      return '3x ao dia';
    }
    
    // Padrões mais flexíveis para frequência
    List<RegExp> padroesFrequencia = [
      RegExp(r'(\d+)/(\d+)h?', caseSensitive: false), // 12/12h
      RegExp(r'(\d+)/(\d+)', caseSensitive: false), // 12/12
      RegExp(r'(\d+)x\s*ao\s*dia', caseSensitive: false), // 2x ao dia
      RegExp(r'(\d+)\s*vezes\s*ao\s*dia', caseSensitive: false), // 2 vezes ao dia
    ];
    
    for (RegExp regex in padroesFrequencia) {
      Match? match = regex.firstMatch(linha);
    if (match != null) {
        String grupo1 = match.group(1) ?? '';
        String grupo2 = match.group(2) ?? '';
        
        // Se tem dois grupos (formato X/Y)
        if (grupo2.isNotEmpty) {
          int horas = int.tryParse(grupo2) ?? 0;
          if (horas > 0) {
            return 'A cada $horas horas';
          }
        } else {
          // Se tem apenas um grupo (formato Xx ao dia)
          int vezes = int.tryParse(grupo1) ?? 0;
          if (vezes > 0) {
            return '${vezes}x ao dia';
          }
        }
      }
    }
    
    return null;
  }

  String? _extrairDuracaoInteligente(String linha) {
    
    List<RegExp> padroesDuracao = [
      RegExp(r'por\s+(\d+)\s*(dias?|semanas?|meses?)', caseSensitive: false), 
      RegExp(r'durante\s+(\d+)\s*(dias?|semanas?|meses?)', caseSensitive: false), 
      RegExp(r'(\d+)\s*(dias?|semanas?|meses?)', caseSensitive: false),
      RegExp(r'(\d+)\s*d\b', caseSensitive: false), 
    ];
    
    for (RegExp regex in padroesDuracao) {
      Match? match = regex.firstMatch(linha);
      if (match != null) {
        String numero = match.group(1) ?? '';
        String unidade = match.group(2) ?? 'dias';
        
        // Corrige abreviações
        if (unidade == 'd') {
          unidade = 'dias';
        }
        
        return '$numero $unidade';
      }
    }
    
    return null;
  }

  double _calcularConfiancaInteligente(String linha, String? dosagem, String? frequencia, String? duracao) {
    double confianca = 0.0;
    
    confianca += 0.2;
    
    if (dosagem != null) confianca += 0.3;
    
    if (frequencia != null) confianca += 0.3;
    
    if (duracao != null) confianca += 0.2;
    
    return confianca.clamp(0.0, 1.0);
  }


  void dispose() {
    _textRecognizer.close();
  }
}

class ReceitaContext {
  final String textoOriginal;
  final List<String> linhas;
  final List<String> palavras;
  final Map<String, dynamic> metadados;
  
  ReceitaContext({
    required this.textoOriginal,
    required this.linhas,
    required this.palavras,
    required this.metadados,
  });
}

class MedicamentoInfo {
  final String nome;
  final String? dosagem;
  final String? frequencia;
  final String? duracao;
  final String? instrucoes;
  final double confianca;
  
  MedicamentoInfo({
    required this.nome,
    this.dosagem,
    this.frequencia,
    this.duracao,
    this.instrucoes,
    required this.confianca,
  });
}

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

  Map<String, dynamic> toHorariosMap() {
    int frequenciaHoras = _converterFrequenciaParaHoras(frequencia);
    
    int duracaoDias = _converterDuracaoParaDias(duracao);
    
    // Obter data atual de forma segura
    String dataInicio = DateTime.now().toIso8601String();
    List<String> partesData = dataInicio.split('T');
    String dataFormatada = partesData.isNotEmpty ? partesData[0] : DateTime.now().toString().split(' ')[0];
    
    return {
      'nome_horario': '$nome - $dosagem',
      'data_inicio': dataFormatada,
      'dias_fim': duracaoDias,
      'hora_inicio': 8,
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
    try {
      if (dur.contains('dias')) {
        RegExp regex = RegExp(r'(\d+)');
        Match? match = regex.firstMatch(dur);
        if (match != null && match.group(1) != null) {
          return int.parse(match.group(1)!);
        }
      } else if (dur.contains('semanas')) {
        RegExp regex = RegExp(r'(\d+)');
        Match? match = regex.firstMatch(dur);
        if (match != null && match.group(1) != null) {
          return int.parse(match.group(1)!) * 7;
        }
      } else if (dur.contains('meses')) {
        RegExp regex = RegExp(r'(\d+)');
        Match? match = regex.firstMatch(dur);
        if (match != null && match.group(1) != null) {
          return int.parse(match.group(1)!) * 30;
        }
      }
    } catch (e) {
      debugPrint('Erro ao converter duração: $e');
    }
    return 30; // Padrão
  }
}

