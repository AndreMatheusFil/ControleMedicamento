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
    
    // Primeiro, tenta identificar medicamentos por blocos maiores (múltiplas linhas)
    List<MedicamentoInfo> medicamentosPorBloco = _extrairMedicamentosPorBloco(context);
    medicamentos.addAll(medicamentosPorBloco);
    
    // Se não encontrou medicamentos por bloco, tenta por linha individual
    if (medicamentos.isEmpty) {
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
    }
    
    return medicamentos;
  }

  // Extrai medicamentos analisando blocos maiores de texto
  List<MedicamentoInfo> _extrairMedicamentosPorBloco(ReceitaContext context) {
    List<MedicamentoInfo> medicamentos = [];
    
    // Primeiro, procura por medicamentos combinados (ex: LEVONORGESTREL + ETINILESTRADIOL)
    List<MedicamentoInfo> medicamentosCombinados = _extrairMedicamentosCombinados(context);
    medicamentos.addAll(medicamentosCombinados);
    
    // Se já encontrou medicamentos combinados, não precisa procurar mais
    if (medicamentos.isNotEmpty) {
      return medicamentos;
    }
    
    // Procura por padrões genéricos de medicamentos em todo o texto
    List<MedicamentoInfo> medicamentosGenericos = _extrairMedicamentosGenericos(context);
    medicamentos.addAll(medicamentosGenericos);
    
    // Remove duplicatas
    medicamentos = medicamentos.fold<List<MedicamentoInfo>>([], (lista, med) {
      if (!lista.any((m) => m.nome == med.nome)) {
        lista.add(med);
      }
      return lista;
    });
    
    return medicamentos;
  }
  
  // Extrai medicamentos de forma genérica baseado em padrões
  List<MedicamentoInfo> _extrairMedicamentosGenericos(ReceitaContext context) {
    List<MedicamentoInfo> medicamentos = [];
    
    // Procura por padrões de medicamento + dosagem em todo o texto
    RegExp regexMedicamentoDosagem = RegExp(
      r'([A-Z][A-Za-z]{3,})\s+(\d+(?:,\d+)?)\s*(mg|g|ml|mcg|UI)',
      caseSensitive: false
    );
    
    Iterable<Match> matches = regexMedicamentoDosagem.allMatches(context.textoOriginal);
    
    for (Match match in matches) {
      String nomeMedicamento = match.group(1)?.toUpperCase() ?? '';
      String dosagem = match.group(2)?.replaceAll(',', '.') ?? '';
      String unidade = match.group(3)?.toLowerCase() ?? 'mg';
      
      // Verifica se não é uma palavra comum que não é medicamento
      if (_ehMedicamentoValido(nomeMedicamento)) {
        // Extrai contexto ao redor do medicamento
        int indice = match.start;
        String contexto = _extrairContextoMedicamento(context.textoOriginal, indice, nomeMedicamento);
        
        // Extrai frequência e duração do contexto
        String? frequencia = _extrairFrequenciaInteligente(contexto);
        String? duracao = _extrairDuracaoInteligente(contexto);
        
        medicamentos.add(MedicamentoInfo(
          nome: nomeMedicamento,
          dosagem: '$dosagem $unidade',
          frequencia: frequencia ?? 'Conforme orientação médica',
          duracao: duracao ?? '30 dias',
          instrucoes: contexto,
          confianca: 0.8, // Alta confiança para medicamentos com dosagem
        ));
      }
    }
    
    return medicamentos;
  }
  
  // Verifica se uma palavra é um medicamento válido
  bool _ehMedicamentoValido(String palavra) {
    // Lista de palavras que definitivamente NÃO são medicamentos
    List<String> palavrasNaoMedicamentos = [
      'TOMAR', 'USAR', 'APLICAR', 'INGERIR', 'ADMINISTRAR',
      'COM', 'SEM', 'ALIMENTO', 'AGUA', 'LEITE',
      'ANTES', 'DEPOIS', 'DURANTE', 'APOS', 'POS',
      'NOME', 'UPA', 'ATENDIMENTO', 'RECEITUARIO', 'SANTOS',
      'UNIDADE', 'PRONTO', 'ATENDIMENTO', 'ZONA', 'LESTE',
      'RECEITUARIO', 'CONTROLE', 'ESPECIAL', 'VIA', 'RETENCAO',
      'FARMACIA', 'DROGA', 'ORIENTACAO', 'PACIENTE', 'IDENTIFICACAO',
      'EMITENTE', 'MEDICA', 'CRM', 'COMPRADOR', 'FORNECEDOR',
      'DIAS', 'HORAS', 'SEMANA', 'MES', 'POR', 'CASO', 'DOR',
      'MANHA', 'TARDE', 'NOITE', 'CONTINUO', 'CONTINUA',
      'NECESSARIO', 'NECESSARIO', 'SOS', 'PRN', 'CX', 'CXS',
      'CARTELA', 'BLISTER', 'COMPRIMIDO', 'CAPSULA', 'CAPS',
      'QUANTIDADE', 'QUANTIDADE', 'QUANTIDADE', 'QUANTIDADE',
      'PREFETURA', 'MUNICIPAL', 'CURITIBA', 'SECRETARIA', 'SAUDE',
      'SUS', 'USUARIO', 'MAE', 'ENDERECO', 'BAIRRO', 'RESPONSAVEL',
      'NASCIMENTO', 'IDADE', 'CARTAO', 'NACIONAL', 'MUNICIPIO',
      'RESIDENCIA', 'TELEFONE', 'INTERNO', 'MEDICAMENTO', 'INSTRUCOES',
      'PORTE', 'SEGURO', 'CLINICA', 'ATENDIMENTO', 'EMAIL', 'WWW',
      'BRIGADEIRO', 'FRANCO', 'PARANA', 'CEP', 'PAGINA', 'DATA',
      'HORA', 'ASSINATURA', 'CARIMBO', 'FARMACEUTICO', 'IDENTIFICACAO',
      'EMISSOR', 'UF', 'CIDADE', 'FORNECEDOR', 'COMPRADOR'
    ];
    
    return !palavrasNaoMedicamentos.contains(palavra.toUpperCase()) &&
           palavra.length >= 4 &&
           !RegExp(r'^\d+$').hasMatch(palavra);
  }
  
  // Extrai medicamentos combinados (ex: LEVONORGESTREL 0,15 MG + ETINILESTRADIOL 0,03 MG)
  List<MedicamentoInfo> _extrairMedicamentosCombinados(ReceitaContext context) {
    List<MedicamentoInfo> medicamentos = [];
    
    // Padrão para medicamentos combinados
    RegExp regexCombinado = RegExp(
      r'(\w+)\s+(\d+(?:,\d+)?)\s*mg\s*\+\s*(\w+)\s+(\d+(?:,\d+)?)\s*mg',
      caseSensitive: false
    );
    
    Match? match = regexCombinado.firstMatch(context.textoOriginal);
    if (match != null) {
      String medicamento1 = match.group(1)?.toUpperCase() ?? '';
      String dosagem1 = match.group(2)?.replaceAll(',', '.') ?? '';
      String medicamento2 = match.group(3)?.toUpperCase() ?? '';
      String dosagem2 = match.group(4)?.replaceAll(',', '.') ?? '';
      
      // Extrai frequência e duração do contexto
      String? frequencia = _extrairFrequenciaInteligente(context.textoOriginal);
      String? duracao = _extrairDuracaoInteligente(context.textoOriginal);
      
      // Cria medicamento combinado
      medicamentos.add(MedicamentoInfo(
        nome: '$medicamento1 + $medicamento2',
        dosagem: '$dosagem1 mg + $dosagem2 mg',
        frequencia: frequencia ?? 'Conforme orientação médica',
        duracao: duracao ?? '30 dias',
        instrucoes: context.textoOriginal,
        confianca: 0.9, // Alta confiança para medicamentos combinados
      ));
    }
    
    return medicamentos;
  }
  
  // Extrai contexto ao redor de um medicamento encontrado
  String _extrairContextoMedicamento(String texto, int indice, String medicamento) {
    int inicio = (indice - 50).clamp(0, texto.length);
    int fim = (indice + medicamento.length + 100).clamp(0, texto.length);
    
    String contexto = texto.substring(inicio, fim);
    
    // Tenta encontrar o final da linha ou próximo medicamento
    List<String> linhas = contexto.split('\n');
    if (linhas.length > 1) {
      // Pega a linha que contém o medicamento e a próxima
      String linhaComMedicamento = linhas.firstWhere(
        (linha) => linha.toUpperCase().contains(medicamento),
        orElse: () => linhas.first
      );
      
      int indiceLinha = linhas.indexOf(linhaComMedicamento);
      if (indiceLinha >= 0 && indiceLinha + 1 < linhas.length) {
        return '$linhaComMedicamento ${linhas[indiceLinha + 1]}';
      }
      return linhaComMedicamento;
    }
    
    return contexto;
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
      'dias', 'horas', 'semana', 'mes', 'por', 'caso', 'dor',
      'manha', 'tarde', 'noite', 'continuo', 'continua',
      'necessario', 'necessario', 'sos', 'prn', 'cx', 'cxs',
      'cartela', 'blister', 'comprimido', 'capsula', 'caps'
    ];
    
    // Procura por padrões de medicamento (palavra + dosagem)
    for (int i = 0; i < palavras.length - 1; i++) {
      String palavra = palavras[i].trim();
      String proximaPalavra = palavras[i + 1].trim();
      
      // Verifica se é um padrão de medicamento + dosagem
      if (palavra.length >= 4 && 
          !palavrasIgnorar.contains(palavra.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(palavra) &&
          RegExp(r'^\d+(?:,\d+)?$').hasMatch(proximaPalavra)) {
        return palavra.toUpperCase();
      }
    }
    
    // Se não encontrou padrão medicamento + dosagem, procura por palavras válidas
    for (String palavra in palavras) {
      String palavraLimpa = palavra.trim();
      
      if (palavraLimpa.length >= 4 && 
          !palavrasIgnorar.contains(palavraLimpa.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(palavraLimpa) &&
          !RegExp(r'^\d+[a-z]*$').hasMatch(palavraLimpa.toLowerCase()) &&
          !RegExp(r'^[a-z]{1,2}$').hasMatch(palavraLimpa.toLowerCase())) {
        
        // Ignora palavras que são claramente dosagens
        if (RegExp(r'\d+').hasMatch(palavraLimpa) && palavraLimpa.length < 8) {
          continue;
        }
        
        // Ignora palavras que são claramente unidades
        if (RegExp(r'^(mg|g|ml|mcg|ui|cp|cápsula|comprimido)$', caseSensitive: false).hasMatch(palavraLimpa)) {
          continue;
        }
        
        return palavraLimpa.toUpperCase();
      }
    }
    
    // Fallback: procura por palavras mais longas
    for (String palavra in palavras) {
      String palavraLimpa = palavra.trim();
      if (palavraLimpa.length >= 6 && 
          !RegExp(r'^\d+$').hasMatch(palavraLimpa) &&
          !palavrasIgnorar.contains(palavraLimpa.toLowerCase())) {
        return palavraLimpa.toUpperCase();
      }
    }
    
    return '';
  }


  String? _extrairDosagemInteligente(String linha) {
    List<RegExp> padroesDosagem = [
      // Padrões com vírgula (ex: 0,15 MG)
      RegExp(r'(\d+(?:,\d+)?)\s*(mg|g|ml|mcg|UI|cp|cápsula|comprimido)', caseSensitive: false),      RegExp(r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|UI|cp|cápsula|comprimido)', caseSensitive: false),
      RegExp(r'(\d+)\s*m\b', caseSensitive: false),
      RegExp(r'(\d+)\s*mig\b', caseSensitive: false),
      RegExp(r'(\d+)\s*mg\b', caseSensitive: false),
      RegExp(r'(\d+(?:,\d+)?)\s*mg\s*\+\s*(\w+)\s*(\d+(?:,\d+)?)\s*mg', caseSensitive: false),
    ];
    
    for (RegExp regex in padroesDosagem) {
      Match? match = regex.firstMatch(linha);
      if (match != null) {
        String numero = match.group(1) ?? '';
        String unidade = match.group(2) ?? 'mg';
        
        // Trata vírgula como ponto decimal
        if (numero.contains(',')) {
          numero = numero.replaceAll(',', '.');
        }
        
        if (unidade == 'm' || unidade == 'mig') {
          unidade = 'mg';
        }
        
        // Se é uma combinação de medicamentos, retorna a primeira dosagem
        if (match.groupCount >= 3 && match.group(3) != null) {
          return '$numero $unidade';
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
    } else if (linhaLower.contains('4/4h') || linhaLower.contains('4/4')) {
      return 'A cada 4 horas';
    } 
    // Padrões de "tomar X comp"
    else if (linhaLower.contains('tomar 1 comp') || linhaLower.contains('tomar 1 caps')) {
      if (linhaLower.contains('manha') || linhaLower.contains('dia')) {
        return '1x ao dia';
      } else if (linhaLower.contains('12h') || linhaLower.contains('12 horas')) {
        return 'A cada 12 horas';
      } else if (linhaLower.contains('8h') || linhaLower.contains('8 horas')) {
        return 'A cada 8 horas';
      } else if (linhaLower.contains('6h') || linhaLower.contains('6 horas')) {
        return 'A cada 6 horas';
      } else {
        return '1x ao dia'; // Padrão quando não especificado
      }
    }
    // Padrões de "tomar X caps"
    else if (linhaLower.contains('tomar 2 comp') || linhaLower.contains('tomar 2 caps')) {
      return '2x ao dia';
    } else if (linhaLower.contains('tomar 3 comp') || linhaLower.contains('tomar 3 caps')) {
      return '3x ao dia';
    }
    // Padrões de "se necessário"
    else if (linhaLower.contains('se necessario') || linhaLower.contains('se necessário') || 
             linhaLower.contains('sos') || linhaLower.contains('prn')) {
      return 'Conforme necessário';
    }
    // Padrões de "ao dia"
    else if (linhaLower.contains('1 cap') && linhaLower.contains('dia')) {
      return '1x ao dia';
    } else if (linhaLower.contains('2x ao dia') || linhaLower.contains('2 vezes ao dia')) {
      return '2x ao dia';
    } else if (linhaLower.contains('3x ao dia') || linhaLower.contains('3 vezes ao dia')) {
      return '3x ao dia';
    }
    // Padrões de "de forma continua"
    else if (linhaLower.contains('de forma continua') || linhaLower.contains('continuamente')) {
      return 'Continuamente';
    }
    
    List<RegExp> padroesFrequencia = [
      RegExp(r'(\d+)/(\d+)h?', caseSensitive: false),
      RegExp(r'(\d+)/(\d+)', caseSensitive: false),
      RegExp(r'(\d+)x\s*ao\s*dia', caseSensitive: false),
      RegExp(r'(\d+)\s*vezes\s*ao\s*dia', caseSensitive: false),
    ];
    
    for (RegExp regex in padroesFrequencia) {
      Match? match = regex.firstMatch(linha);
      if (match != null) {
        String grupo1 = match.group(1) ?? '';
        String grupo2 = match.group(2) ?? '';
        
        if (grupo2.isNotEmpty) {
          int horas = int.tryParse(grupo2) ?? 0;
          if (horas > 0) {
            return 'A cada $horas horas';
          }
        } else {
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
    String linhaLower = linha.toLowerCase();
    
    // Padrões específicos para cartelas/blisters
    if (linhaLower.contains('cartela') || linhaLower.contains('blister')) {
      RegExp regexCartela = RegExp(r'(\d+)\s*(cartela|blister)', caseSensitive: false);
      Match? match = regexCartela.firstMatch(linha);
      if (match != null) {
        String numero = match.group(1) ?? '';
        int numCartelas = int.tryParse(numero) ?? 1;
        // Assumindo que cada cartela tem 28 comprimidos (comum em anticoncepcionais)
        int dias = numCartelas * 28;
        return '$dias dias';
      }
    }
    
    // Padrões específicos para comprimidos
    if (linhaLower.contains('comprimido') || linhaLower.contains('comp')) {
      RegExp regexComp = RegExp(r'(\d+)\s*(comprimido|comp)', caseSensitive: false);
      Match? match = regexComp.firstMatch(linha);
      if (match != null) {
        String numero = match.group(1) ?? '';
        int numComps = int.tryParse(numero) ?? 1;
        // Assumindo 1 comprimido por dia
        return '$numComps dias';
      }
    }
    
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

