import { useState } from 'react';
import {
  StyleSheet,
  TouchableOpacity,
  Alert,
  Image,
  ScrollView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { createWorker } from 'tesseract.js';

import { Text, View } from '@/components/Themed';
import { useSQLiteContextSafe } from '@/hooks/useSQLiteContextSafe';

type ExtractedMedication = {
  name: string;
  dosage?: string;
  frequency?: string;
  duration?: string;
};

export default function IAScreen() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [extractedText, setExtractedText] = useState<string>('');
  const [medications, setMedications] = useState<ExtractedMedication[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
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
      }
    } catch (error) {
      Alert.alert('Erro', 'Erro ao tirar foto');
      console.error('Error taking photo:', error);
    }
  };

  const processImage = async () => {
    if (!selectedImage) {
      Alert.alert('Erro', 'Selecione uma imagem primeiro');
      return;
    }

    setIsProcessing(true);
    
    try {
      const worker = await createWorker('por', 1, {
        logger: m => console.log(m)
      });
      
      const { data: { text } } = await worker.recognize(selectedImage);
      await worker.terminate();
      
      setExtractedText(text);
      const extractedMeds = extractMedicationsFromText(text);
      setMedications(extractedMeds);
      
    } catch (error) {
      Alert.alert('Erro', 'Erro ao processar imagem');
      console.error('OCR Error:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const extractMedicationsFromText = (text: string): ExtractedMedication[] => {
    const lines = text.split('\n').filter(line => line.trim().length > 0);
    const medications: ExtractedMedication[] = [];
    
    const medicationKeywords = [
      'mg', 'ml', 'comprimido', 'cápsula', 'gotas', 'ampola',
      'vezes', 'dia', 'manhã', 'tarde', 'noite', 'horas',
      'tomar', 'usar', 'aplicar'
    ];
    
    for (const line of lines) {
      const lowerLine = line.toLowerCase();
      
      if (medicationKeywords.some(keyword => lowerLine.includes(keyword))) {
        const words = line.trim().split(' ');
        let medicationName = '';
        
        for (const word of words) {
          if (!/\d/.test(word) && word.length > 2) {
            medicationName += word + ' ';
          } else {
            break;
          }
        }
        
        if (medicationName.trim()) {
          const dosageMatch = line.match(/(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg)/i);
          const dosage = dosageMatch ? `${dosageMatch[1]}${dosageMatch[2]}` : undefined;
          
          const frequencyMatch = line.match(/(\d+)\s*(?:vezes?|x)\s*(?:ao\s*)?dia|de\s*(\d+)\s*em\s*(\d+)\s*horas?/i);
          let frequency = undefined;
          if (frequencyMatch) {
            if (frequencyMatch[1]) {
              frequency = `${frequencyMatch[1]} vezes ao dia`;
            } else if (frequencyMatch[2] && frequencyMatch[3]) {
              frequency = `De ${frequencyMatch[2]} em ${frequencyMatch[3]} horas`;
            }
          }
          
          medications.push({
            name: medicationName.trim(),
            dosage,
            frequency,
            duration: undefined
          });
        }
      }
    }
    
    return medications;
  };

  const registerMedication = async (medication: ExtractedMedication) => {
    try {
      const hoje = new Date();
      const fimTratamento = new Date();
      fimTratamento.setDate(hoje.getDate() + 30);
      
      let umaVez = false;
      let duasVezes = false;
      let periodico = false;
      let periodo = '08:00';
      
      if (medication.frequency) {
        const freq = medication.frequency.toLowerCase();
        if (freq.includes('1') || freq.includes('uma')) {
          umaVez = true;
        } else if (freq.includes('2') || freq.includes('duas')) {
          duasVezes = true;
        } else {
          periodico = true;
          const horasMatch = freq.match(/(\d+)\s*horas?/);
          if (horasMatch) {
            const horas = parseInt(horasMatch[1]);
            periodo = `${horas.toString().padStart(2, '0')}:00`;
          }
        }
      } else {
        umaVez = true;
      }
      
      const valores = [
        `${medication.name}${medication.dosage ? ` ${medication.dosage}` : ''}`,
        duasVezes ? 1 : 0,
        umaVez ? 1 : 0,
        periodico ? 1 : 0,
        periodo,
        hoje.toISOString().split('T')[0],
        '08:00',
        fimTratamento.toISOString().split('T')[0],
        1, 1, 1, 1, 1, 1, 1,
        0,
        medication.frequency || 'Extraído da receita'
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
          
          <TouchableOpacity 
            style={[styles.processButton, isProcessing && styles.disabledButton]} 
            onPress={processImage}
            disabled={isProcessing}
          >
            {isProcessing ? (
              <ActivityIndicator color="white" />
            ) : (
              <Text style={styles.buttonText}>🔍 Processar Receita</Text>
            )}
          </TouchableOpacity>
        </View>
      )}
      
      {extractedText && (
        <View style={styles.textContainer}>
          <Text style={styles.sectionTitle}>Texto Extraído:</Text>
          <Text style={styles.extractedText}>{extractedText}</Text>
        </View>
      )}
      
      {medications.length > 0 && (
        <View style={styles.medicationsContainer}>
          <Text style={styles.sectionTitle}>Medicamentos Encontrados:</Text>
          {medications.map((med, index) => (
            <View key={index} style={styles.medicationCard}>
              <Text style={styles.medicationName}>{med.name}</Text>
              {med.dosage && <Text style={styles.medicationDetail}>Dosagem: {med.dosage}</Text>}
              {med.frequency && <Text style={styles.medicationDetail}>Frequência: {med.frequency}</Text>}
              
              <TouchableOpacity 
                style={styles.registerButton}
                onPress={() => registerMedication(med)}
              >
                <Text style={styles.registerButtonText}>✅ Cadastrar</Text>
              </TouchableOpacity>
            </View>
          ))}
        </View>
      )}
      
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
  processButton: {
    backgroundColor: '#34C759',
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 10,
    minWidth: 150,
    alignItems: 'center',
  },
  disabledButton: {
    backgroundColor: '#999',
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
