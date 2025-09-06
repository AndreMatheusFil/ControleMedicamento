import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WebOCRService {
  /// Extrai texto de uma imagem usando uma API gratuita para web
  static Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    try {
      // Converter bytes para base64
      String base64Image = base64Encode(imageBytes);
      
      debugPrint('Enviando requisição para API OCR web...');
      
      // Usar uma API gratuita que funciona
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'por',
          'isOverlayRequired': 'false',
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2',
          'apikey': 'helloworld', // API key gratuita
        },
      );

      debugPrint('Status da resposta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        
        debugPrint('Resposta da API: ${responseData.toString().substring(0, 200)}...');
        
        if (responseData['IsErroredOnProcessing'] == false && 
            responseData['ParsedResults'] != null && 
            responseData['ParsedResults'] is List &&
            (responseData['ParsedResults'] as List).isNotEmpty) {
          
          List parsedResults = responseData['ParsedResults'] as List;
          if (parsedResults.length > 0 && parsedResults[0] != null) {
            String extractedText = parsedResults[0]['ParsedText'] ?? '';
            debugPrint('✅ Texto extraído com sucesso: ${extractedText.length > 100 ? extractedText.substring(0, 100) + "..." : extractedText}');
            return extractedText;
          }
        }
        
        debugPrint('❌ Nenhum texto encontrado na imagem');
        return '';
      } else {
        debugPrint('❌ Erro na API: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar OCR web: $e');
      return '';
    }
  }
}
