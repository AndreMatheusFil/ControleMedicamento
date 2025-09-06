import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OCRSpaceService {
  // Usando uma API simples que funciona sem API key
  static const String _apiUrl = 'https://api.ocr.space/parse/image';

  /// Extrai texto de uma imagem usando API gratuita
  static Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    try {
      // Converter bytes para base64
      String base64Image = base64Encode(imageBytes);
      
      debugPrint('Enviando requisição para OCR API...');
      
      // Fazer requisição HTTP
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'por', // Português
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2', // Engine 2 para melhor precisão
          'apikey': 'helloworld', // API key gratuita para teste
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['IsErroredOnProcessing'] == false && 
            responseData['ParsedResults'] != null && 
            responseData['ParsedResults'].isNotEmpty) {
          
          String extractedText = responseData['ParsedResults'][0]['ParsedText'];
          debugPrint('✅ Texto extraído com sucesso: ${extractedText.length > 100 ? extractedText.substring(0, 100) + "..." : extractedText}');
          return extractedText;
        } else {
          debugPrint('❌ Nenhum texto encontrado na imagem');
          return '';
        }
      } else {
        debugPrint('❌ Erro na API: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar OCR: $e');
      return '';
    }
  }

}
