// Configuração do sistema de OCR - OpenAI
export const OCR_CONFIG = {
  // OpenAI GPT-4 Vision (Mais preciso e confiável)
  OPENAI: {
    apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY || 'your-api-key-here',
    endpoint: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o-mini',
    maxTokens: 1000,
    name: 'OpenAI GPT-4V',
    confidence: 95,
    local: false,
    free: false,
    instructions: 'Extraia todo o texto desta receita médica. Retorne apenas o texto extraído, sem comentários ou explicações. Se houver medicamentos, mantenha o formato original com #, dosagens, frequências e durações.'
  }
};

// Configuração de fallback
export const FALLBACK_CONFIG = {
  // Tentar múltiplas vezes
  maxRetries: 3,
  // Timeout para cada tentativa
  timeout: 60000, // OpenAI pode ser mais lento
  // Usar apenas OpenAI
  useMultipleConfigs: false
};

// Lista de métodos OCR em ordem de preferência
export const OCR_PROVIDERS = [
  {
    name: 'OpenAI GPT-4V',
    function: 'processWithOpenAI',
    priority: 1,
    free: false,
    accuracy: 95,
    local: false,
    description: 'Modelo de visão computacional mais avançado disponível'
  }
];

// Configurações específicas para extração de medicamentos
export const MEDICATION_EXTRACTION_CONFIG = {
  // Padrões para identificar medicamentos
  patterns: [
    // #Predrudona 40 mg (12/12h) 5 dias
    {
      pattern: /#\s*([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?\s*(?:por\s+)?(\d+)\s*dias?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency', 'duration']
    },
    // #Varelton 20mg (12/12h) por 30 dias
    {
      pattern: /#\s*([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?\s*por\s+(\d+)\s*dias?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency', 'duration']
    },
    // Predrudona 40 mg (12/12h) 5 dias
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?\s*(?:por\s+)?(\d+)\s*dias?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency', 'duration']
    },
    // Nome + frequência + duração (sem dosagem)
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+\/\d+h?)\s*por\s+(\d+)\s*dias?/gi,
      groups: ['name', 'frequency', 'duration']
    },
    // Nome + dosagem + frequência (sem duração)
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)?\s*\(?(\d+\/\d+h?)\s*\)?/gi,
      groups: ['name', 'dosage', 'unit', 'frequency']
    },
    // Nome + dosagem (sem frequência nem duração)
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+(?:[.,]\d+)?)\s*(mg|ml|g|mcg|ui|µg)/gi,
      groups: ['name', 'dosage', 'unit']
    },
    // Nome + frequência (sem dosagem nem duração)
    {
      pattern: /([A-Za-zÀ-ÿ]+)\s+(\d+\/\d+h?)/gi,
      groups: ['name', 'frequency']
    }
  ],
  
  // Mapeamento de variações para nomes corretos
  medicationMappings: {
    'predrudona': 'Prednisone',
    'prednesdona': 'Prednisone',
    'prednisona': 'Prednisone',
    'prednisolona': 'Prednisone',
    'varelton': 'Xarelto',
    'xarelton': 'Xarelto',
    'xarelto': 'Xarelto',
    'ntmoxilia': 'Amoxicilina',
    'amoxilia': 'Amoxicilina',
    'amoxicilina': 'Amoxicilina',
    'coragesia': 'Em caso de dor',
    'nibacetim': 'Nimesulida',
    'nimesulida': 'Nimesulida',
    'paracetamol': 'Paracetamol',
    'acetaminofeno': 'Paracetamol',
    'ibuprofeno': 'Ibuprofeno',
    'dipirona': 'Dipirona',
    'metamizol': 'Dipirona',
    'omeprazol': 'Omeprazol',
    'pantoprazol': 'Pantoprazol',
    'lansoprazol': 'Lansoprazol'
  },
  
  // Palavras que NÃO são medicamentos
  excludeWords: [
    'identificação', 'emitente', 'médica', 'crm', 'paciente', 'via', 'retenção', 
    'farmácia', 'droga', 'orientação', 'comprimido', 'cápsula', 'gota', 'ampola',
    'mg', 'ml', 'g', 'mcg', 'ui', 'µg', 'dias', 'semanas', 'meses', 'horas',
    'vezes', 'tomar', 'usar', 'aplicar', 'administrar', 'por', 'em', 'caso', 'dor',
    'go', 'tal', 'ccvt', 'oa', 'ret', 'ori', 'ali', 'ne', 'maria', 'jurura',
    'receita', 'prescrição', 'médico', 'doutor', 'dr', 'data', 'assinatura'
  ]
};
