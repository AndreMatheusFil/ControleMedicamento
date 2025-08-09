// cadastro.tsx
import { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Modal,
  TouchableOpacity,
  Button,
  ScrollView,
  Platform,
  Alert,
} from 'react-native';


import { TextInput, Checkbox } from '@/components/Themed';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useSQLiteContextSafe } from '@/hooks/useSQLiteContextSafe';

type Alarme = {
  id: string;
  duas_vezes: boolean;
  uma_vez: boolean;
  remedio: string;
  periodico: boolean;
  periodo: string;
  data_inicio: string;
  hora_inicio: string;
  data_fim: string;
  segunda: boolean;
  terca: boolean;
  quarta: boolean;
  quinta: boolean;
  sexta: boolean;
  sabado: boolean;
  domingo: boolean;
  regra_especial: number;
  observacao: string;
};

export default function CadastroScreen() {
  const [mostrarModal, setMostrarModal] = useState(false);
  
  const [Alarmes, setAlarmes] = useState<Alarme[]>([]);
  const db = useSQLiteContextSafe();

  const [id, setId] = useState<string | null>();
  const [remedio, setRemedio] = useState<string>('');
  const [duasVezes, setDuasVezes] = useState<boolean>(false);
  const [umaVez, setUmaVez] = useState<boolean>(false);
  const [periodico, setPeriodico] = useState<boolean>(false);
  const [periodo, setPeriodo] = useState<Date>(new Date());
  const [mostrarPeriodo, setMostrarPeriodo] = useState(false);
  const [dataInicio, setDataInicio] = useState<Date>(new Date());
  const [mostrarInicio, setMostrarInicio] = useState(false);
  const [horaInicio, setHoraInicio] = useState<Date>(new Date());
  const [mostrarHoraInicio, setMostrarHoraInicio] = useState(false);
  const [dataFim, setDataFim] = useState<Date>(new Date());
  const [mostrarFim, setMostrarFim] = useState<boolean>(false);
  const [observacao, setObservacao] = useState<string>('');
  const [regraEspecial, setRegraEspecial] = useState<number>(0);

  const [segunda, setSegunda] = useState<boolean>(false);
  const [terca, setTerca] = useState<boolean>(false);
  const [quarta, setQuarta] = useState<boolean>(false);
  const [quinta, setQuinta] = useState<boolean>(false);
  const [sexta, setSexta] = useState<boolean>(false);
  const [sabado, setSabado] = useState<boolean>(false);
  const [domingo, setDomingo] = useState<boolean>(false);

  const formatDate = (date: Date) => date.toISOString().split('T')[0];
  const formatLabel = (date: Date) =>
    date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });

  async function cadastrarAlarme() {
    if (!remedio || !dataInicio || !horaInicio || !dataFim) {
      Alert.alert('Preencha todos os campos obrigatórios.');
      return;
    }

    const periodoTexto = periodo.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const horaInicioTexto = horaInicio.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    const valores = [
      remedio,
      duasVezes ? 1 : 0,
      umaVez ? 1 : 0,
      periodico ? 1 : 0,
      periodoTexto,
      formatDate(dataInicio),
      horaInicioTexto,
      formatDate(dataFim),
      segunda ? 1 : 0,
      terca ? 1 : 0,
      quarta ? 1 : 0,
      quinta ? 1 : 0,
      sexta ? 1 : 0,
      sabado ? 1 : 0,
      domingo ? 1 : 0,
      regraEspecial,
      observacao,
    ];

    try {
      if (id) {
        await db.runAsync(
          `UPDATE alarmes SET
            remedio = ?,
            duas_vezes = ?,
            uma_vez = ?,
            periodico = ?,
            periodo = ?, 
            data_inicio = ?, 
            hora_inicio = ?,
            data_fim = ?,
            segunda= ?, 
            terca = ?, 
            quarta = ?, 
            quinta = ?, 
            sexta = ?, 
            sabado = ?, 
            domingo = ?,
            regra_especial = ?, 
            observacao = ? 
            WHERE 
            id = ?`,
          [...valores, id]
        );
        Alert.alert('Alarme atualizado com sucesso!');
      } else {
        await db.runAsync(
          `INSERT INTO alarmes (
            remedio, duas_vezes, uma_vez, periodico, periodo, data_inicio, hora_inicio, 
            data_fim, segunda, terca, quarta, quinta, sexta, sabado, domingo,
            regra_especial, observacao
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          valores
        );
        Alert.alert('Alarme cadastrado com sucesso!');
      }

      setMostrarModal(false);
      buscarAlarmes();
    } catch (error) {
      Alert.alert('Erro ao salvar.');
    }
  }

  async function excluirAlarme(id: string) {
    try {
      await db.runAsync('DELETE FROM alarmes WHERE id = ?', [id]);
      Alert.alert('Alarme excluído');
      buscarAlarmes();
    } catch (error) {
      Alert.alert('Erro ao excluir alarme');
    }
  }

  async function buscarAlarmes() {
    try {
      const resultado = await db.getAllAsync('SELECT * FROM alarmes');

      const formatados = resultado.map((a: any) => ({
        id: String(a.id),
        remedio: a.remedio,
        duas_vezes:!!a.duas_vezes,
        uma_vez: !!a.uma_vez,
        periodico:a.periodico,
        periodo: a.periodo,
        data_inicio: a.data_inicio,
        hora_inicio:a.hora_inicio,
        data_fim: a.data_fim,
        segunda: !!a.segunda,
        terca: !!a.terca,
        quarta: !!a.quarta,
        quinta: !!a.quinta,
        sexta: !!a.sexta,
        sabado: !!a.sabado,
        domingo: !!a.domingo,
        regra_especial: a.regra_especial,
        observacao: a.observacao,
      }));

      setAlarmes(formatados);
    } catch (error) {
      console.error('Erro ao carregar alarmes:', error);
    }
  }

  useEffect(() => {
    buscarAlarmes();
  }, []);

  return (
    <View style={{ flex: 1 }}>
      
        <FlatList
          data={Alarmes}
          keyExtractor={(item) => item.id.toString()}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.itemFlatList}
              onPress={() => {
                const [h1, m1] = item.periodo.split(':');
                const [h2, m2] = item.hora_inicio.split(':');
                const p = new Date();
                const h = new Date();
                p.setHours(Number(h1), Number(m1));
                h.setHours(Number(h2), Number(m2));

                setId(item.id);
                setRemedio(item.remedio);
                setDuasVezes(item.duas_vezes);
                setUmaVez(item.uma_vez);
                setPeriodico(item.periodico);
                setPeriodo(p);
                setHoraInicio(h);
                setDataInicio(new Date(item.data_inicio));
                setDataFim(new Date(item.data_fim));
                setObservacao(item.observacao);
                setRegraEspecial(item.regra_especial);
                setSegunda(item.segunda);
                setTerca(item.terca);
                setQuarta(item.quarta);
                setQuinta(item.quinta);
                setSexta(item.sexta);
                setSabado(item.sabado);
                setDomingo(item.domingo);
                setMostrarModal(true);
              }}
            >
              <View style={styles.botoesExcluir}>
                <Text style={styles.item}>{item.remedio} - a cada {item.periodo} horas</Text>
                <TouchableOpacity
                  style={{
                    backgroundColor: '#FF3B30',
                    justifyContent: 'center',
                    alignItems: 'center',
                    height: 80,
                    borderRadius: 8,
                    // marginVertical: 6,
                  }}
                  onPress={() => excluirAlarme(item.id)}
                >
                  <Text style={{ color: 'white', fontWeight: 'bold' }}>Excluir</Text>
                </TouchableOpacity>
              </View>
            </TouchableOpacity>
          )}
        />

      <TouchableOpacity
        style={styles.fab}
        onPress={() => {
          setId(null);
          setRemedio('');
          setDuasVezes(false);
          setUmaVez(true);
          setPeriodico(false);
          setPeriodo(new Date());
          setDataInicio(new Date());
          setDataFim(new Date());
          setObservacao('');
          setRegraEspecial(0);

          setSegunda(true);
          setTerca(true);
          setQuarta(true);
          setQuinta(true);
          setSexta(true);
          setSabado(true);
          setDomingo(true);

          setMostrarModal(true);
        }}
      >
        <Text style={styles.fabText}>+</Text>
      </TouchableOpacity>

      <Modal visible={mostrarModal} animationType="slide">
        <ScrollView contentContainerStyle={styles.modalContent}>
          <Text style={styles.titulo}>Novo Alarme</Text>

          <Text>Remédio*</Text>
          <TextInput value={remedio} onChangeText={setRemedio} placeholder="Ex: Paracetamol" />

          <Text>Dias da Semana</Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' }}>
            <View style={{ width: '48%' }}>
              <Checkbox label="Uma Vez ao dia" status={umaVez} onPress={() => {
                setUmaVez(!umaVez);
                setDuasVezes(false);
                setPeriodico(false);
                }} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Duas Vezes ao dia" status={duasVezes} onPress={() => {
                setDuasVezes(!duasVezes);
                setPeriodico(false);
                setUmaVez(false);
                }} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Periodico" status={periodico} onPress={() => {
                setPeriodico(!periodico);
                setUmaVez(false);
                setDuasVezes(false);
                }} />
            </View>
          </View>

          <View style={{ display: periodico ? 'flex' : 'none', marginBottom: 10 }}>
            <Text>Período (Colocar quando for, por exemplo, 8 em 8 horas: 08:00)</Text>
            <Button
              title={periodo.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              onPress={() => setMostrarPeriodo(true)}
            />
            {mostrarPeriodo && (
              <DateTimePicker
                value={periodo}
                mode="time"
                is24Hour={true}
                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                onChange={(_, selectedTime) => {
                  setMostrarPeriodo(false);
                  if (selectedTime) setPeriodo(selectedTime);
                }}
              />
            )}
          </View>
        

          <Text>Data Início*</Text>
          <Button title={formatLabel(dataInicio)} onPress={() => setMostrarInicio(true)} />
          {mostrarInicio && (
            <DateTimePicker
              value={dataInicio}
              mode="date"
              display={Platform.OS === 'ios' ? 'inline' : 'default'}
              onChange={(_, date) => {
                setMostrarInicio(false);
                if (date) setDataInicio(date);
              }}
            />
          )}
          <Text>Hora Inicial</Text>
          <Button
            title={periodo.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            onPress={() => setMostrarHoraInicio(true)}
          />
          {mostrarHoraInicio && (
            <DateTimePicker
              value={horaInicio}
              mode="time"
              is24Hour={true}
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              onChange={(_, selectedTime) => {
                setMostrarPeriodo(false);
                if (selectedTime) setHoraInicio(selectedTime);
              }}
            />
          )}

          <Text>Data Fim*</Text>
          <Button title={formatLabel(dataFim)} onPress={() => setMostrarFim(true)} />
          {mostrarFim && (
            <DateTimePicker
              value={dataFim}
              mode="date"
              display={Platform.OS === 'ios' ? 'inline' : 'default'}
              onChange={(_, date) => {
                setMostrarFim(false);
                if (date) setDataFim(date);
              }}
            />
          )}

          <Text>Dias da Semana</Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' }}>
            <View style={{ width: '48%' }}>
              <Checkbox label="Segunda" status={segunda} onPress={() => setSegunda(!segunda)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Terça" status={terca} onPress={() => setTerca(!terca)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Quarta" status={quarta} onPress={() => setQuarta(!quarta)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Quinta" status={quinta} onPress={() => setQuinta(!quinta)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Sexta" status={sexta} onPress={() => setSexta(!sexta)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Sábado" status={sabado} onPress={() => setSabado(!sabado)} />
            </View>
            <View style={{ width: '48%' }}>
              <Checkbox label="Domingo" status={domingo} onPress={() => setDomingo(!domingo)} />
            </View>
          </View>

          <Text>Observação</Text>
          <TextInput
            value={observacao}
            onChangeText={setObservacao}
            placeholder="Ex: Tomar em jejum"
          />

          <View style={{ marginTop: 20 }}>
            <Text>Dias sem tomar o remedio (Isso ocorre quando for tome um dia e pule 2 daí nesse campo é para colocar 2)</Text>
            <TextInput
              value={String(regraEspecial)}
              onChangeText={(text) => {
                const number = parseInt(text, 10);
                setRegraEspecial(!isNaN(number) ? number : 0);
              }}
              keyboardType="numeric"
            />
          </View>

          <View style={styles.botoesLinha}>
            <TouchableOpacity style={styles.botaoSalvar} onPress={cadastrarAlarme}>
              <Text style={styles.textoBotao}>SALVAR ALARME</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.botaoFechar} onPress={() => setMostrarModal(false)}>
              <Text style={styles.textoBotao}>FECHAR</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  item: {
    backgroundColor: '#eee',
    // justifyContent: 'center',
    // alignItems: 'center',
    padding: 16,
    borderRadius: 8,
    marginBottom: 6,
    marginTop: 6,
    marginLeft:5,
    marginRight:5
  },
  itemFlatList: {
    backgroundColor: '#eee',
    justifyContent: 'center',
    // alignItems: 'center',
    // padding: 16,
    borderRadius: 8,
    marginBottom: 6,
    marginTop: 6,
    marginLeft:5,
    marginRight:5
  },
  itemText: {
    fontSize: 16,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    backgroundColor: '#007AFF',
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 4,
  },
  fabText: {
    color: 'white',
    fontSize: 28,
    fontWeight: 'bold',
  },
  modalContent: {
    padding: 20,
    paddingBottom: 40,
  },
  titulo: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  botoesLinha: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
    gap: 10,
  },
  botoesExcluir: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  botaoSalvar: {
    flex: 1,
    backgroundColor: '#007AFF',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  botaoFechar: {
    flex: 1,
    backgroundColor: '#FF3B30',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  textoBotao: {
    color: 'white',
    fontWeight: 'bold',
  },
});
