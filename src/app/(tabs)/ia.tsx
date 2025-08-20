import { useState } from 'react';
import {
  StyleSheet,
  TouchableOpacity,
  Alert,
  Image,
  ScrollView,
  Platform,
  ActivityIndicator,
  Modal,
  TextInput,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';

import { Text, View } from '@/components/Themed';
import { useSQLiteContextSafe } from '@/hooks/useSQLiteContextSafe';
import AdvancedOCR from '@/components/AdvancedOCR';

type ExtractedMedication = {
  name: string;
  dosage?: string;
  frequency?: string;
  duration?: string;
  originalText?: string;
};

type OCRResult = {
  text: string;
  confidence: number;
  provider: string;
  processingTime: number;
};

export default function IAScreen() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [extractedText, setExtractedText] = useState<string>('');
  const [medications, setMedications] = useState<ExtractedMedication[]>([]);
  const [ocrResults, setOcrResults] = useState<OCRResult[]>([]);
  const db = useSQLiteContextSafe();

  const pickImage = async () => {
    try {
      const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();
      
      if (permissionResult.granted === false) {
        Alert.alert('Permissão necessária', 'É necessário permitir acesso à galeria de fotos.');
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [4, 3],
        quality: 1,
      });

      if (!result.canceled) {
        setSelectedImage(result.assets[0].uri);
        setExtractedText('');
        setMedications([]);
        setOcrResults([]);
      }
    } catch (error) {
      Alert.alert('Erro', 'Erro ao selecionar imagem');
      console.error('Error picking image:', error);
    }
  };

  const takePhoto = async () => {
    try {
      const permissionResult = await ImagePicker.requestCameraPermissionsAsync();
      
      if (permissionResult.granted === false) {
        Alert.alert('Permissão necessária', 'É necessário permitir acesso à câmera.');
        return;
      }

      const result = await ImagePicker.launchCameraAsync({
        allowsEditing: true,
        aspect: [4, 3],
        quality: 1,
      });

      if (!result.canceled) {
        setSelectedImage(result.assets[0].uri);
        setExtractedText('');
        setMedications([]);
        setOcrResults([]);
      }
    } catch (error) {
      Alert.alert('Erro', 'Erro ao tirar foto');
      console.error('Error taking photo:', error);
    }
  };

  // Handlers para o componente AdvancedOCR
  const handleOcrResults = (results: OCRResult[], extractedMeds: ExtractedMedication[]) => {
    console.log('📱 Tela principal recebeu resultados:', results);
    console.log('💊 Medicamentos extraídos:', extractedMeds);
    
    setOcrResults(results);
    setMedications(extractedMeds);
    
    if (results.length > 0) {
      const bestResult = results.reduce((best, current) => 
        current.confidence > best.confidence ? current : best
      );
      setExtractedText(bestResult.text);
    }
    
    // Se não há medicamentos extraídos automaticamente, mostrar mensagem
    if (extractedMeds.length === 0) {
      Alert.alert(
        'Nenhum Medicamento Encontrado',
        'Não foi possível extrair medicamentos automaticamente. Tente editar o texto ou adicionar manualmente.',
        [{ text: 'OK' }]
      );
    }
  };

  const handleOcrError = (error: string) => {
    Alert.alert('Erro OCR', error);
  };

  const registerMedication = async (medication: ExtractedMedication) => {
    try {
      const hoje = new Date();
      const fimTratamento = new Date();
      
      if (medication.duration) {
        const durationLower = medication.duration.toLowerCase();
        if (durationLower.includes('dias')) {
          const days = parseInt(durationLower.match(/(\d+)/)?.[1] || '30');
          fimTratamento.setDate(hoje.getDate() + days);
        } else if (durationLower.includes('semanas')) {
          const weeks = parseInt(durationLower.match(/(\d+)/)?.[1] || '4');
          fimTratamento.setDate(hoje.getDate() + (weeks * 7));
        } else if (durationLower.includes('meses')) {
          const months = parseInt(durationLower.match(/(\d+)/)?.[1] || '1');
          fimTratamento.setMonth(hoje.getMonth() + months);
        } else if (durationLower.includes('contínuo')) {
          fimTratamento.setFullYear(hoje.getFullYear() + 1);
        }
      } else {
        fimTratamento.setDate(hoje.getDate() + 30);
      }
      
      let umaVez = false;
      let duasVezes = false;
      let periodico = false;
      let periodo = '08:00';
      let horaInicio = '08:00';
      
      if (medication.frequency) {
        const freq = medication.frequency.toLowerCase();
        
        if (freq.includes('1 vez') || freq.includes('uma vez')) {
          umaVez = true;
        } else if (freq.includes('2 vezes') || freq.includes('duas vezes')) {
          duasVezes = true;
        } else if (freq.includes('3 vezes') || freq.includes('três vezes')) {
          periodico = true;
          periodo = '08:00';
        } else if (freq.includes('4 vezes') || freq.includes('quatro vezes')) {
          periodico = true;
          periodo = '06:00';
        } else if (freq.includes('cada') || freq.includes('de') && freq.includes('em')) {
          periodico = true;
          const horasMatch = freq.match(/(\d+)\s*horas?/);
          if (horasMatch) {
            const horas = parseInt(horasMatch[1]);
            periodo = `${horas.toString().padStart(2, '0')}:00`;
          }
        } else if (freq.includes('manhã')) {
          umaVez = true;
          horaInicio = '08:00';
        } else if (freq.includes('tarde')) {
          umaVez = true;
          horaInicio = '14:00';
        } else if (freq.includes('noite')) {
          umaVez = true;
          horaInicio = '20:00';
        } else if (freq.includes('jejum') || freq.includes('antes')) {
          umaVez = true;
          horaInicio = '07:00';
        } else {
          umaVez = true;
        }
      } else {
        umaVez = true;
      }
      
      let nomeCompleto = medication.name;
      if (medication.dosage) {
        nomeCompleto += ` ${medication.dosage}`;
      }
      
      let observacao = 'Extraído da receita';
      if (medication.frequency) {
        observacao += ` - Frequência: ${medication.frequency}`;
      }
      if (medication.duration) {
        observacao += ` - Duração: ${medication.duration}`;
      }
      if (medication.originalText) {
        observacao += ` - Original: ${medication.originalText}`;
      }
      
      const valores = [
        nomeCompleto,
        duasVezes ? 1 : 0,
        umaVez ? 1 : 0,
        periodico ? 1 : 0,
        periodo,
        hoje.toISOString().split('T')[0],
        horaInicio,
        fimTratamento.toISOString().split('T')[0],
        1, 1, 1, 1, 1, 1, 1,
        0,
        observacao
      ];
      
      await db.runAsync(
        `INSERT INTO alarmes (
          remedio, duas_vezes, uma_vez, periodico, periodo, data_inicio, hora_inicio, 
          data_fim, segunda, terca, quarta, quinta, sexta, sabado, domingo,
          regra_especial, observacao
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        valores
      );
      
      Alert.alert('Sucesso', `Medicamento "${medication.name}" cadastrado com sucesso!`);
      
    } catch (error) {
      Alert.alert('Erro', 'Erro ao cadastrar medicamento');
      console.error('Error registering medication:', error);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>OCR - Receita Médica</Text>
      <Text style={styles.subtitle}>
        Tire uma foto ou selecione uma imagem da receita médica
      </Text>
      
      <View style={styles.buttonContainer}>
        <TouchableOpacity style={styles.button} onPress={takePhoto}>
          <Text style={styles.buttonText}>📷 Tirar Foto</Text>
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.button} onPress={pickImage}>
          <Text style={styles.buttonText}>🖼️ Selecionar Imagem</Text>
        </TouchableOpacity>
      </View>
      
      {selectedImage && (
        <View style={styles.imageContainer}>
          <Image source={{ uri: selectedImage }} style={styles.image} />
          
          <AdvancedOCR
            imageUri={selectedImage}
            onResults={handleOcrResults}
            onError={handleOcrError}
            onRegisterMedication={registerMedication}
          />
        </View>
      )}
      
      {extractedText && (
        <View style={styles.textContainer}>
          <Text style={styles.sectionTitle}>Texto Extraído:</Text>
          <Text style={styles.extractedText}>{extractedText}</Text>
        </View>
      )}
      
      {/* Os medicamentos agora são exibidos pelo componente AdvancedOCR */}
      {/* Esta seção foi removida para evitar duplicação */}
      

      
      <View style={styles.bottomPadding} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
    opacity: 0.7,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
    gap: 10,
  },
  button: {
    flex: 1,
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  imageContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  image: {
    width: '100%',
    height: 300,
    borderRadius: 10,
    marginBottom: 15,
    resizeMode: 'contain',
  },

  textContainer: {
    backgroundColor: '#f5f5f5',
    padding: 15,
    borderRadius: 10,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  extractedText: {
    fontSize: 14,
    lineHeight: 20,
    color: '#333',
  },
  medicationsContainer: {
    marginBottom: 20,
  },
  medicationCard: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 3,
  },
  medicationName: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
    color: '#007AFF',
  },
  medicationDetail: {
    fontSize: 14,
    marginBottom: 3,
    color: '#666',
  },
  registerButton: {
    backgroundColor: '#34C759',
    padding: 10,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  registerButtonText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },

  bottomPadding: {
    height: 50,
  },
});
