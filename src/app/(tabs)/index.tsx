import { useEffect, useState } from 'react';
import { View, Text }from '@/components/Themed';
import { FlatList, StyleSheet } from 'react-native'
import { useSQLiteContextSafe } from '@/hooks/useSQLiteContextSafe';

type Alarme = {
  id: string;
  remedio: string;
  periodo: string;
  observacao?: string;
  data_inicio: string;
};

export default function TabPrincipal() {
  const [proximosAlarmes, setProximosAlarmes] = useState<Alarme[]>([]);
  const db = useSQLiteContextSafe();

  async function buscarProximosAlarmes() {
    try {
      const resultado = await db.getAllAsync('SELECT * FROM alarmes');
      const agora = new Date();
      

      const filtrados = resultado
        .map((alarme: any) => {
          const [horaStr, minutoStr] = alarme.periodo.split(':');
          const data = new Date(alarme.data_inicio);
          data.setHours(Number(horaStr), Number(minutoStr), 0, 0);

          return { ...alarme, proximaData: data };
        })
        .filter((alarme: any) => alarme.proximaData <= agora)
        .sort((a: any, b: any) => a.proximaData.getTime() - b.proximaData.getTime())
        .slice(0, 40);

      const formatados = filtrados.map((a: any) => ({
        id: String(a.id),
        remedio: a.remedio,
        periodo: a.periodo,
        observacao: a.observacao,
        data_inicio: a.data_inicio,
      }));
      setProximosAlarmes(formatados);
    } catch (error) {
      console.error('Erro ao carregar alarmes:', error);
    }
  }

  useEffect(() => {
    buscarProximosAlarmes();
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.titulo}>Próximos Alarmes</Text>
      <FlatList
        data={proximosAlarmes}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.alarmeItem}>
            <Text >{item.remedio}</Text>
            <Text >{item.periodo}</Text>
            {item.observacao && <Text >{item.observacao}</Text>}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  titulo: { fontSize: 24, fontWeight: 'bold', marginBottom: 16 },
  alarmeItem: {
    marginBottom: 12,
    padding: 12,
    backgroundColor: '#1e1e1e',
    borderRadius: 8,
  },
  // remedio: { fontSize: 18, color: '#fff' },
  // hora: { fontSize: 16, color: '#ccc' },
  // obs: { fontSize: 14, fontStyle: 'italic', color: '#aaa' },
});
