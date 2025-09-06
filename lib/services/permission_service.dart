import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Solicita permissão para câmera
  Future<bool> requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await Permission.camera.request();
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          'Permissão de Câmera Necessária',
          'Para usar a funcionalidade de OCR, é necessário permitir o acesso à câmera. Vá para as configurações do aplicativo e ative a permissão de câmera.',
        );
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Erro ao solicitar permissão de câmera: $e');
      return false;
    }
  }

  /// Solicita permissão para galeria
  Future<bool> requestStoragePermission() async {
    try {
      var status = await Permission.storage.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await Permission.storage.request();
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          'Permissão de Armazenamento Necessária',
          'Para acessar fotos da galeria, é necessário permitir o acesso ao armazenamento. Vá para as configurações do aplicativo e ative a permissão de armazenamento.',
        );
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Erro ao solicitar permissão de armazenamento: $e');
      return false;
    }
  }

  /// Verifica se as permissões estão concedidas
  Future<bool> hasCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Erro ao verificar permissão de câmera: $e');
      return false;
    }
  }

  Future<bool> hasStoragePermission() async {
    try {
      var status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Erro ao verificar permissão de armazenamento: $e');
      return false;
    }
  }

  /// Abre as configurações do aplicativo
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Erro ao abrir configurações: $e');
    }
  }

  /// Mostra diálogo de permissão
  void _showPermissionDialog(String title, String message) {
    // Este método será implementado quando necessário
    debugPrint('$title: $message');
  }
}
