// Teste da extração de medicamentos
const MEDICATION_EXTRACTION_CONFIG = {
  patterns: [
    {
      pattern: /#\s*([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?\s*(?:por\s+)?(\d+)\s*dias?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency', 'duration']
    },
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency']
    },
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+\/\d+h?)/gi,
      groups: ['name', 'frequency']
    }
  ],
  
  medicationMappings: {
    'predrudona': 'Prednisone',
    'prednesdona': 'Prednisone',
    'varelton': 'Xarelto',
    'xarelton': 'Xarelto',
    'ntmoxilia': 'Amoxicilina',
    'amoxilia': 'Amoxicilina'
  },
  
  excludeWords: [
    'identificação', 'emitente', 'médica', 'crm', 'paciente', 'via', 'retenção', 
    'farmácia', 'droga', 'orientação', 'comprimido', 'cápsula', 'gota', 'ampola',
    'mg', 'ml', 'g', 'mcg', 'ui', 'µg', 'dias', 'semanas', 'meses', 'horas',
    'vezes', 'tomar', 'usar', 'aplicar', 'administrar', 'por', 'em', 'caso', 'dor',
    'go', 'tal', 'ccvt', 'oa', 'ret', 'ori', 'ali', 'ne', 'maria', 'jurura',
    'receita', 'prescrição', 'médico', 'doutor', 'dr', 'data', 'assinatura'
  ]
};

function isExcludedWord(word) {
  const lowerWord = word.toLowerCase();
  
  if (lowerWord.length < 3) {
    return true;
  }
  
  return MEDICATION_EXTRACTION_CONFIG.excludeWords.some(exclude => 
    lowerWord === exclude || lowerWord.includes(exclude) || exclude.includes(lowerWord)
  );
}

function normalizeMedicationName(name) {
  const lowerName = name.toLowerCase();
  
  for (const [variation, correctName] of Object.entries(MEDICATION_EXTRACTION_CONFIG.medicationMappings)) {
    if (lowerName.includes(variation)) {
      return correctName;
    }
  }
  
  return name.charAt(0).toUpperCase() + name.slice(1).toLowerCase();
}

function extractMedicationsFromText(text) {
  console.log('🔍 Extraindo medicamentos do texto:', text);
  
  if (!text || text.trim().length === 0) {
    console.log('❌ Texto vazio ou inválido');
    return [];
  }
  
  const lines = text.split('\n').filter(line => line.trim().length > 0);
  const medications = [];
  
  console.log(`📋 Processando ${lines.length} linhas de texto`);
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    console.log(`📝 Processando linha ${i + 1}: "${line}"`);
    
    let lineProcessed = false;
    
    // Tentar padrões específicos
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
          console.log(`✅ Match válido encontrado: ${name}`);
          
          const normalizedName = normalizeMedicationName(name);
          const fullDosage = dosage && unit ? `${dosage}${unit}` : dosage;
          
          const medication = {
            name: normalizedName,
            dosage: fullDosage,
            frequency: frequency,
            duration: duration,
            originalText: line
          };
          
          console.log(`💊 Medicamento extraído:`, medication);
          medications.push(medication);
          lineProcessed = true;
        }
      }
    }
    
    // Se não foi processada, tentar extrair por nomes conhecidos
    if (!lineProcessed) {
      for (const [variation, correctName] of Object.entries(MEDICATION_EXTRACTION_CONFIG.medicationMappings)) {
        if (line.toLowerCase().includes(variation)) {
          console.log(`🔍 Variação encontrada: ${variation} -> ${correctName}`);
          
          const medication = {
            name: correctName,
            dosage: undefined,
            frequency: undefined,
            duration: undefined,
            originalText: line
          };
          
          console.log(`💊 Medicamento com variação extraído:`, medication);
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
}

// Testes
console.log('🧪 TESTANDO EXTRAÇÃO DE MEDICAMENTOS\n');

const testTexts = [
  `#Prednesdona 40 mg (12/12h) 5 dias
#Xarelton 20 mg (12/12h) por 30 dias
ntmoxilia 12/12h por 5 dias
camude dor`,
  
  `Prednisone 40mg 12/12h 7 dias
Xarelto 20mg por 30 dias
Amoxicilina 500mg 8/8h 10 dias`,
  
  `Receita médica
Dr. João Silva
CRM 12345

#Paracetamol 500mg 6/6h por 3 dias
#Ibuprofeno 400mg 8/8h por 5 dias
Em caso de dor`
];

testTexts.forEach((text, index) => {
  console.log(`\n📋 TESTE ${index + 1}:`);
  console.log('='.repeat(50));
  const result = extractMedicationsFromText(text);
  console.log(`✅ Resultado: ${result.length} medicamentos encontrados`);
});
