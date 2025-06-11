import { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';

type Alarme = {
  id: string;
  remedio: string;
  hora: string;
  observacao?: string;
  data_inicio: string;
};

export default function TabPrincipal() {
  const [proximosAlarmes, setProximosAlarmes] = useState<Alarme[]>([]);
  const db = useSQLiteContext();

  async function buscarProximosAlarmes() {
    try {
      const resultado = await db.getAllAsync('SELECT * FROM alarmes');
      const agora = new Date();
      

      const filtrados = resultado
        .map((alarme: any) => {
          const [horaStr, minutoStr] = alarme.hora.split(':');
          const data = new Date(alarme.data_inicio);
          data.setHours(Number(horaStr), Number(minutoStr), 0, 0);

          return { ...alarme, proximaData: data };
        })
        .filter((alarme: any) => alarme.proximaData <= agora)
        .sort((a: any, b: any) => a.proximaData.getTime() - b.proximaData.getTime())
        .slice(0, 5);

      const formatados = filtrados.map((a: any) => ({
        id: String(a.id),
        remedio: a.remedio,
        hora: a.hora,
        observacao: a.observacao,
        data_inicio: a.data_inicio,
      }));
      console.log(formatados)
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
            <Text style={styles.remedio}>{item.remedio}</Text>
            <Text style={styles.hora}>{item.hora}</Text>
            {item.observacao && <Text style={styles.obs}>{item.observacao}</Text>}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#000' },
  titulo: { fontSize: 24, fontWeight: 'bold', marginBottom: 16, color: '#fff' },
  alarmeItem: {
    marginBottom: 12,
    padding: 12,
    backgroundColor: '#1e1e1e',
    borderRadius: 8,
  },
  remedio: { fontSize: 18, color: '#fff' },
  hora: { fontSize: 16, color: '#ccc' },
  obs: { fontSize: 14, fontStyle: 'italic', color: '#aaa' },
});
