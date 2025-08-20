import React, { useState } from 'react';
import {
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
  ActivityIndicator,
  Modal,
  TextInput,
  View as RNView,
} from 'react-native';
import * as FileSystem from 'expo-file-system';

import { Text, View } from '@/components/Themed';
import { OCR_CONFIG, MEDICATION_EXTRACTION_CONFIG } from '@/config/ocrConfig';

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

type AdvancedOCRProps = {
  imageUri: string;
  onResults: (results: OCRResult[], medications: ExtractedMedication[]) => void;
  onError: (error: string) => void;
  onRegisterMedication?: (medication: ExtractedMedication) => void;
};

export default function AdvancedOCR({ imageUri, onResults, onError, onRegisterMedication }: AdvancedOCRProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [showTextEditor, setShowTextEditor] = useState(false);
  const [editedText, setEditedText] = useState<string>('');
  const [ocrResult, setOcrResult] = useState<OCRResult | null>(null);
  const [extractedMedications, setExtractedMedications] = useState<ExtractedMedication[]>([]);
  const [showMedications, setShowMedications] = useState(false);
  const [showAddMedication, setShowAddMedication] = useState(false);
  const [newMedication, setNewMedication] = useState<ExtractedMedication>({
    name: '',
    dosage: '',
    frequency: '',
    duration: '',
    originalText: ''
  });

  // Função principal para processar com OpenAI
  const processWithOpenAI = async (uri: string): Promise<OCRResult | null> => {
    try {
      console.log('🚀 Iniciando processamento com OpenAI...');
      
      // Converter imagem para base64
      const base64Image = await FileSystem.readAsStringAsync(uri, {
        encoding: FileSystem.EncodingType.Base64,
      });
      
      const startTime = Date.now();
      
      // Chamar API da OpenAI
      const response = await fetch(OCR_CONFIG.OPENAI.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${OCR_CONFIG.OPENAI.apiKey}`
        },
        body: JSON.stringify({
          model: OCR_CONFIG.OPENAI.model,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: OCR_CONFIG.OPENAI.instructions
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:image/png;base64,${base64Image}`
                  }
                }
              ]
            }
          ],
          max_tokens: OCR_CONFIG.OPENAI.maxTokens
        })
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        console.error('❌ Erro na API OpenAI:', errorData);
        throw new Error(`Erro na API: ${errorData.error?.message || 'Erro desconhecido'}`);
      }
      
      const result = await response.json();
      const extractedText = result.choices?.[0]?.message?.content || '';
      const processingTime = Date.now() - startTime;
      
      if (!extractedText.trim()) {
        throw new Error('Nenhum texto foi extraído da imagem');
      }
      
      console.log('✅ OpenAI resultado:', extractedText);
      
      return {
        text: extractedText.trim(),
        confidence: OCR_CONFIG.OPENAI.confidence,
        provider: OCR_CONFIG.OPENAI.name,
        processingTime,
      };
      
    } catch (error) {
      console.error('❌ Erro no processamento OpenAI:', error);
      throw error;
    }
  };

  const processImage = async () => {
    if (!imageUri) {
      onError('Nenhuma imagem selecionada');
      return;
    }

    setIsProcessing(true);
    setOcrResult(null);
    setExtractedMedications([]);
    setShowMedications(false);

    try {
      console.log('🤖 Processando imagem com OpenAI...');
      
      const result = await processWithOpenAI(imageUri);
      
      if (result) {
        setOcrResult(result);
        setEditedText(result.text);
        const medications = extractMedicationsFromText(result.text);
        setExtractedMedications(medications);
        setShowMedications(true);
        
        onResults([result], medications);
        
        console.log('✅ Processamento concluído com sucesso:', result);
        console.log('💊 Medicamentos extraídos:', medications);
        
        Alert.alert(
          'OCR Concluído',
          `Processado com ${result.provider}\nConfiança: ${result.confidence}%\nTempo: ${result.processingTime}ms\nMedicamentos encontrados: ${medications.length}`,
          [
            { text: 'OK' },
            { text: 'Editar Texto', onPress: () => setShowTextEditor(true) }
          ]
        );
      } else {
        throw new Error('Falha ao processar imagem');
      }
      
    } catch (error) {
      console.error('❌ Erro no processamento:', error);
      const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
      onError(`Erro ao processar imagem: ${errorMessage}`);
      
      Alert.alert(
        'Erro no Processamento',
        `Falha ao processar imagem:\n${errorMessage}\n\nVerifique:\n• Sua API key da OpenAI\n• Se a imagem está clara\n• Sua conexão com a internet`,
        [{ text: 'OK' }]
      );
    } finally {
      setIsProcessing(false);
    }
  };

  const extractMedicationsFromText = (text: string): ExtractedMedication[] => {
    console.log('🔍 Extraindo medicamentos do texto:', text);
    
    if (!text || text.trim().length === 0) {
      console.log('❌ Texto vazio ou inválido');
      return [];
    }
    
    const lines = text.split('\n').filter(line => line.trim().length > 0);
    const medications: ExtractedMedication[] = [];
    
    console.log(`📋 Processando ${lines.length} linhas de texto`);
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      console.log(`📝 Processando linha ${i + 1}: "${line}"`);
      
      if (isExcludedLine(line)) {
        console.log(`⏭️ Pulando linha não-medicamento: ${line}`);
        continue;
      }
      
      let lineProcessed = false;
      
      for (const patternInfo of MEDICATION_EXTRACTION_CONFIG.patterns) {
        patternInfo.pattern.lastIndex = 0;
        let match;
        
        while ((match = patternInfo.pattern.exec(line)) !== null) {
          const groups = patternInfo.groups;
          const name = match[1]?.trim();
          const dosage = match[2] ? match[2].replace(',', '.') : undefined;
          const unit = match[3] ? match[3].toLowerCase() : undefined;
          const frequency = match[4] || undefined;
          const duration = match[5] ? `${match[5]} dias` : undefined;
          
          console.log(`🔍 Match encontrado:`, { name, dosage, unit, frequency, duration });
          
          if (name && name.length >= 3 && !isExcludedWord(name)) {
            console.log(`✅ Match válido encontrado: ${name} - Dosagem: ${dosage}${unit || ''} - Frequência: ${frequency} - Duração: ${duration}`);
            
            const normalizedName = normalizeMedicationName(name);
            
            const fullDosage = dosage && unit ? `${dosage}${unit}` : 
                              dosage ? `${dosage}` : undefined;
            
            const medication: ExtractedMedication = {
              name: normalizedName,
              dosage: fullDosage,
              frequency: frequency,
              duration: duration,
              originalText: line
            };
            
            console.log(`💊 Medicamento extraído:`, medication);
            medications.push(medication);
            lineProcessed = true;
          } else {
            console.log(`❌ Match inválido ignorado: ${name} (palavra excluída ou muito curta)`);
          }
        }
      }
      
      if (!lineProcessed && !line.includes('*') && !line.includes('#')) {
        console.log(`🔍 Tentando extrair por nomes conhecidos da linha: "${line}"`);
        
        for (const [variation, correctName] of Object.entries(MEDICATION_EXTRACTION_CONFIG.medicationMappings)) {
          if (line.toLowerCase().includes(variation)) {
            console.log(`🔍 Variação encontrada: ${variation} -> ${correctName}`);
            
            // Tentar extrair informações adicionais da linha
            const dosageMatch = line.match(/(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)/i);
            const dosage = dosageMatch ? `${dosageMatch[1].replace(',', '.')}${dosageMatch[2]}` : undefined;
            
            const frequency = extractFrequencyFromLine(line);
            const duration = extractDurationFromLine(line);
            
            const medication: ExtractedMedication = {
              name: correctName,
              dosage,
              frequency,
              duration,
              originalText: line
            };
            
            console.log(`💊 Medicamento com variação extraído:`, medication);
            medications.push(medication);
            break;
          }
        }
      }
      
      if (!lineProcessed && line.length > 3) {
        console.log(`🔍 Tentando extrair medicamento simples da linha: "${line}"`);
        
        const words = line.split(/\s+/).filter(word => word.length >= 3);
        
        for (const word of words) {
          const cleanWord = word.replace(/[^\wÀ-ÿ]/g, '').toLowerCase();
          
          if (cleanWord.length >= 3 && !isExcludedWord(cleanWord)) {
            console.log(`🔍 Palavra candidata encontrada: ${cleanWord}`);
            
            const normalizedName = normalizeMedicationName(cleanWord);
            
            const dosageMatch = line.match(/(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)/i);
            const dosage = dosageMatch ? `${dosageMatch[1].replace(',', '.')}${dosageMatch[2]}` : undefined;
            
            const frequency = extractFrequencyFromLine(line);
            const duration = extractDurationFromLine(line);
            
            const medication: ExtractedMedication = {
              name: normalizedName,
              dosage,
              frequency,
              duration,
              originalText: line
            };
            
            console.log(`💊 Medicamento simples extraído:`, medication);
            medications.push(medication);
            break;
          }
        }
      }
    }
    
    const uniqueMedications = medications.filter((med, index, self) => 
      index === self.findIndex(m => m.name.toLowerCase() === med.name.toLowerCase())
    ).sort((a, b) => a.name.localeCompare(b.name));
    
    console.log(`🎯 Total de medicamentos extraídos: ${uniqueMedications.length}`, uniqueMedications);
    
    return uniqueMedications;
  };

  const isExcludedLine = (line: string): boolean => {
    const lowerLine = line.toLowerCase();
    
    const words = lowerLine.split(/\s+/).filter(word => word.length > 0);
    const excludedWords = words.filter(word => 
      MEDICATION_EXTRACTION_CONFIG.excludeWords.some(exclude => 
        word.includes(exclude) || exclude.includes(word)
      )
    );
    
    const shouldExclude = words.length > 0 && excludedWords.length === words.length;
    
    if (shouldExclude) {
      console.log(`⏭️ Linha excluída (todas as palavras são excluídas): "${line}"`);
    }
    
    return shouldExclude;
  };

  const isExcludedWord = (word: string): boolean => {
    const lowerWord = word.toLowerCase();
    
    if (lowerWord.length < 3) {
      return true;
    }
    
    const isExcluded = MEDICATION_EXTRACTION_CONFIG.excludeWords.some(exclude => 
      lowerWord === exclude || lowerWord.includes(exclude) || exclude.includes(lowerWord)
    );
    
    if (isExcluded) {
      console.log(`🚫 Palavra excluída: "${word}"`);
    }
    
    return isExcluded;
  };

  const normalizeMedicationName = (name: string): string => {
    const lowerName = name.toLowerCase();
    for (const [variation, correctName] of Object.entries(MEDICATION_EXTRACTION_CONFIG.medicationMappings)) {
      if (lowerName.includes(variation)) {
        return correctName;
      }
    }
    return name.charAt(0).toUpperCase() + name.slice(1).toLowerCase();
  };

  const extractFrequencyFromLine = (line: string): string | undefined => {
    const frequencyPatterns = [
      /(\d+)\/(\d+)h/gi,
      /(\d+)\/(\d+)\s*h/gi,
      /(\d+)\/(\d+)\s*horas/gi,
    ];
    
    for (const pattern of frequencyPatterns) {
      pattern.lastIndex = 0;
      const match = pattern.exec(line);
      if (match) {
        return `${match[1]}/${match[2]}h`;
      }
    }
    return undefined;
  };

  const extractDurationFromLine = (line: string): string | undefined => {
    const durationPatterns = [
      /(?:por\s*)?(\d+)\s*dias?/gi,
      /(?:durante\s*)?(\d+)\s*semanas?/gi,
      /(?:por\s*)?(\d+)\s*meses?/gi,
    ];
    
    for (const pattern of durationPatterns) {
      pattern.lastIndex = 0;
      const match = pattern.exec(line.toLowerCase());
      if (match) {
        if (pattern.source.includes('dias')) {
          return `${match[1]} dias`;
        } else if (pattern.source.includes('semanas')) {
          return `${match[1]} semanas`;
        } else if (pattern.source.includes('meses')) {
          return `${match[1]} meses`;
        }
      }
    }
    return undefined;
  };

  const applyTextCorrections = () => {
    const extractedMeds = extractMedicationsFromText(editedText);
    setExtractedMedications(extractedMeds);
    setShowMedications(true);
    if (ocrResult) {
      onResults([ocrResult], extractedMeds);
    }
    setShowTextEditor(false);
  };

  const cadastrarMedicamento = (medication: ExtractedMedication) => {
    if (onRegisterMedication) {
      onRegisterMedication(medication);
    } else if (onResults && ocrResult) {
      onResults([ocrResult], [medication]);
    }
    
    Alert.alert(
      'Medicamento Cadastrado',
      `${medication.name} ${medication.dosage || ''} foi cadastrado com sucesso!`,
      [{ text: 'OK' }]
    );
  };

  const adicionarMedicamentoManual = () => {
    if (!newMedication.name.trim()) {
      Alert.alert('Erro', 'Nome do medicamento é obrigatório');
      return;
    }

    const medicationToAdd: ExtractedMedication = {
      ...newMedication,
      name: newMedication.name.trim()
    };

    setExtractedMedications(prev => [...prev, medicationToAdd]);
    setNewMedication({
      name: '',
      dosage: '',
      frequency: '',
      duration: '',
      originalText: ''
    });
    setShowAddMedication(false);
    
    Alert.alert(
      'Medicamento Adicionado',
      `${medicationToAdd.name} foi adicionado à lista!`,
      [{ text: 'OK' }]
    );
  };

  const removerMedicamento = (index: number) => {
    Alert.alert(
      'Remover Medicamento',
      `Deseja remover ${extractedMedications[index].name}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Remover', 
          style: 'destructive',
          onPress: () => {
            setExtractedMedications(prev => prev.filter((_, i) => i !== index));
          }
        }
      ]
    );
  };

  const cadastrarTodosMedicamentos = () => {
    if (extractedMedications.length === 0) {
      Alert.alert('Nenhum medicamento para cadastrar');
      return;
    }

    Alert.alert(
      'Cadastrar Todos',
      `Deseja cadastrar ${extractedMedications.length} medicamento(s)?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Cadastrar', 
          onPress: () => {
            extractedMedications.forEach(med => cadastrarMedicamento(med));
            Alert.alert('Sucesso', 'Todos os medicamentos foram cadastrados!');
          }
        }
      ]
    );
  };

  return (
    <RNView style={styles.container}>
      <TouchableOpacity 
        style={[styles.processButton, isProcessing && styles.disabledButton]} 
        onPress={processImage}
        disabled={isProcessing}
      >
        {isProcessing ? (
          <ActivityIndicator color="white" />
        ) : (
          <Text style={styles.buttonText}> Extrair Medicamentos</Text>
        )}
      </TouchableOpacity>
      
      <TouchableOpacity 
        style={[styles.processButton, { backgroundColor: '#6B73FF', marginBottom: 10 }]} 
        onPress={() => {
          setShowTextEditor(true)
        }}
      >
        <Text style={styles.buttonText}>✏️ Inserir Texto Manual</Text>
      </TouchableOpacity>
      
      <TouchableOpacity 
        style={[styles.processButton, { backgroundColor: '#FF9500', marginBottom: 10 }]} 
        onPress={() => {}}
      >
        <Text style={styles.buttonText}>🧪 Testar Extração</Text>
      </TouchableOpacity>
      
      {ocrResult && (
        <RNView style={styles.ocrResultContainer}>
          <Text style={styles.sectionTitle}>Resultado:</Text>
          <RNView style={styles.ocrResultItem}>
            <Text style={styles.ocrProviderName}>{ocrResult.provider}</Text>
            <Text style={styles.ocrConfidence}>
              {ocrResult.confidence.toFixed(1)}% confiança
            </Text>
            <Text style={styles.ocrTime}>
              {ocrResult.processingTime}ms
            </Text>
            <TouchableOpacity
              style={styles.editButton}
              onPress={() => setShowTextEditor(true)}
            >
              <Text style={styles.editButtonText}>✏️ Editar Texto</Text>
            </TouchableOpacity>
          </RNView>
        </RNView>
      )}
      
      {showMedications && (
        <RNView style={styles.medicationsContainer}>
          <RNView style={styles.medicationsHeader}>
            <Text style={styles.sectionTitle}>💊 Medicamentos Extraídos:</Text>
            <TouchableOpacity
              style={styles.addButton}
              onPress={() => setShowAddMedication(true)}
            >
              <Text style={styles.addButtonText}>➕ Adicionar</Text>
            </TouchableOpacity>
          </RNView>
          
          {extractedMedications.length === 0 ? (
            <RNView style={styles.noMedicationsContainer}>
              <Text style={styles.noMedicationsText}>
                Nenhum medicamento foi extraído automaticamente.
              </Text>
              <Text style={styles.noMedicationsSubtext}>
                Tente editar o texto ou adicionar manualmente.
              </Text>
              <TouchableOpacity
                style={styles.addManualButton}
                onPress={() => setShowAddMedication(true)}
              >
                <Text style={styles.addManualButtonText}>➕ Adicionar Primeiro Medicamento</Text>
              </TouchableOpacity>
            </RNView>
          ) : (
            extractedMedications.map((medication, index) => (
              <RNView key={index} style={styles.medicationItem}>
                <RNView style={styles.medicationHeader}>
                  <Text style={styles.medicationName}>{medication.name}</Text>
                  <RNView style={styles.medicationActions}>
                    <TouchableOpacity
                      style={styles.editButton}
                      onPress={() => {
                        setNewMedication(medication);
                        setShowAddMedication(true);
                      }}
                    >
                      <Text style={styles.editButtonText}>✏️</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.removeButton}
                      onPress={() => removerMedicamento(index)}
                    >
                      <Text style={styles.removeButtonText}>🗑️</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.cadastrarButton}
                      onPress={() => cadastrarMedicamento(medication)}
                    >
                      <Text style={styles.cadastrarButtonText}>Cadastrar</Text>
                    </TouchableOpacity>
                  </RNView>
                </RNView>
                
                <RNView style={styles.medicationDetails}>
                  {medication.dosage && (
                    <Text style={styles.medicationDetail}>💊 {medication.dosage}</Text>
                  )}
                  {medication.frequency && (
                    <Text style={styles.medicationDetail}>⏰ {medication.frequency}</Text>
                  )}
                  {medication.duration && (
                    <Text style={styles.medicationDetail}>📅 {medication.duration}</Text>
                  )}
                </RNView>
                
                {medication.originalText && (
                  <Text style={styles.originalText}>📝 "{medication.originalText}"</Text>
                )}
              </RNView>
            ))
          )}
          
          {extractedMedications.length > 0 && (
            <TouchableOpacity
              style={styles.cadastrarTodosButton}
              onPress={cadastrarTodosMedicamentos}
            >
              <Text style={styles.cadastrarTodosButtonText}>
                📋 Cadastrar Todos os Medicamentos
              </Text>
            </TouchableOpacity>
          )}
        </RNView>
      )}
      
      <Modal
        visible={showAddMedication}
        animationType="slide"
        transparent={true}
      >
        <RNView style={styles.modalOverlay}>
          <RNView style={styles.modalContent}>
            <Text style={styles.modalTitle}>
              {newMedication.name ? 'Editar Medicamento' : 'Adicionar Medicamento'}
            </Text>
            
            <RNView style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Nome do Medicamento *</Text>
              <TextInput
                style={styles.smallTextInput}
                value={newMedication.name}
                onChangeText={(text) => setNewMedication(prev => ({ ...prev, name: text }))}
                placeholder="Ex: Paracetamol"
              />
            </RNView>
            
            <RNView style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Dosagem</Text>
              <TextInput
                style={styles.smallTextInput}
                value={newMedication.dosage}
                onChangeText={(text) => setNewMedication(prev => ({ ...prev, dosage: text }))}
                placeholder="Ex: 500mg"
              />
            </RNView>
            
            <RNView style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Frequência</Text>
              <TextInput
                style={styles.smallTextInput}
                value={newMedication.frequency}
                onChangeText={(text) => setNewMedication(prev => ({ ...prev, frequency: text }))}
                placeholder="Ex: 3 vezes ao dia"
              />
            </RNView>
            
            <RNView style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Duração</Text>
              <TextInput
                style={styles.smallTextInput}
                value={newMedication.duration}
                onChangeText={(text) => setNewMedication(prev => ({ ...prev, duration: text }))}
                placeholder="Ex: 7 dias"
              />
            </RNView>
            
            <RNView style={styles.modalButtons}>
              <TouchableOpacity 
                style={styles.modalButton}
                onPress={() => {
                  setShowAddMedication(false);
                  setNewMedication({
                    name: '',
                    dosage: '',
                    frequency: '',
                    duration: '',
                    originalText: ''
                  });
                }}
              >
                <Text style={styles.modalButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.modalButton, styles.applyButton]}
                onPress={adicionarMedicamentoManual}
              >
                <Text style={styles.modalButtonText}>
                  {newMedication.name ? 'Atualizar' : 'Adicionar'}
                </Text>
              </TouchableOpacity>
            </RNView>
          </RNView>
        </RNView>
      </Modal>
      
      <Modal
        visible={showTextEditor}
        animationType="slide"
        transparent={true}
      >
        <RNView style={styles.modalOverlay}>
          <RNView style={styles.modalContent}>
            <Text style={styles.modalTitle}>Editar Texto Extraído</Text>
            <TextInput
              style={styles.textInput}
              multiline
              value={editedText}
              onChangeText={setEditedText}
              placeholder="Edite o texto extraído..."
            />
            <RNView style={styles.modalButtons}>
              <TouchableOpacity 
                style={styles.modalButton}
                onPress={() => setShowTextEditor(false)}
              >
                <Text style={styles.modalButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.modalButton, styles.applyButton]}
                onPress={applyTextCorrections}
              >
                <Text style={styles.modalButtonText}>Aplicar</Text>
              </TouchableOpacity>
            </RNView>
          </RNView>
        </RNView>
      </Modal>
    </RNView>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  processButton: {
    backgroundColor: '#10A37F',
    paddingHorizontal: 20,
    paddingVertical: 15,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 15,
  },
  disabledButton: {
    backgroundColor: '#999',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  ocrResultContainer: {
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  ocrResultItem: {
    backgroundColor: '#f0f9ff',
    padding: 15,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#10A37F',
    alignItems: 'center',
  },
  ocrProviderName: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
    color: '#10A37F',
  },
  ocrConfidence: {
    fontSize: 14,
    color: '#666',
    marginBottom: 5,
  },
  ocrTime: {
    fontSize: 12,
    color: '#999',
    marginBottom: 10,
  },
  editButton: {
    backgroundColor: '#10A37F',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 8,
  },
  editButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  medicationsContainer: {
    marginTop: 20,
    marginBottom: 15,
  },
  medicationsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  addButton: {
    backgroundColor: '#007bff',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 8,
  },
  addButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  noMedicationsContainer: {
    alignItems: 'center',
    paddingVertical: 20,
    backgroundColor: '#f0f0f0',
    borderRadius: 10,
    marginTop: 10,
  },
  noMedicationsText: {
    fontSize: 16,
    color: '#555',
    marginBottom: 5,
  },
  noMedicationsSubtext: {
    fontSize: 14,
    color: '#888',
  },
  medicationItem: {
    backgroundColor: '#f8f9fa',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#e9ecef',
  },
  medicationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  medicationName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#2c3e50',
    flex: 1,
  },
  medicationActions: {
    flexDirection: 'row',
    gap: 10,
  },
  removeButton: {
    backgroundColor: '#dc3545',
    padding: 8,
    borderRadius: 6,
  },
  removeButtonText: {
    color: 'white',
    fontSize: 16,
  },
  cadastrarButton: {
    backgroundColor: '#28a745',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  cadastrarButtonText: {
    color: 'white',
    fontSize: 12,
    fontWeight: 'bold',
  },
  medicationDetails: {
    marginBottom: 8,
  },
  medicationDetail: {
    fontSize: 14,
    color: '#495057',
    marginBottom: 2,
  },
  originalText: {
    fontSize: 12,
    color: '#6c757d',
    fontStyle: 'italic',
    backgroundColor: '#e9ecef',
    padding: 8,
    borderRadius: 6,
  },
  cadastrarTodosButton: {
    backgroundColor: '#28a745',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  cadastrarTodosButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 20,
    width: '90%',
    maxHeight: '80%',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    textAlign: 'center',
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 10,
    fontSize: 16,
    minHeight: 200,
    textAlignVertical: 'top',
    marginBottom: 15,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
  },
  modalButton: {
    flex: 1,
    backgroundColor: '#999',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  applyButton: {
    backgroundColor: '#10A37F',
  },
  modalButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },
  inputContainer: {
    marginBottom: 15,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    marginBottom: 5,
    color: '#333',
  },
  smallTextInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 10,
    fontSize: 16,
    minHeight: 50,
    textAlignVertical: 'top',
  },
  addManualButton: {
    backgroundColor: '#007bff',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 15,
  },
  addManualButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
});
