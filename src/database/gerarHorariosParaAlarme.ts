import { SQLiteDatabase } from 'expo-sqlite';

export async function gerarHorariosParaAlarme(db: SQLiteDatabase, alarme: any) {
  const horarios = [];
  const dataInicio = new Date(alarme.data_inicio);
  const dataFim = new Date(alarme.data_fim);
  const agora = new Date();

  for (let d = new Date(dataInicio); d <= dataFim; d.setDate(d.getDate() + 1)) {
    const dia = d.getDay();
    const diaPermitido =
      (dia === 0 && alarme.domingo) ||
      (dia === 1 && alarme.segunda) ||
      (dia === 2 && alarme.terca) ||
      (dia === 3 && alarme.quarta) ||
      (dia === 4 && alarme.quinta) ||
      (dia === 5 && alarme.sexta) ||
      (dia === 6 && alarme.sabado);

    if (!diaPermitido) continue;

    if (alarme.uma_vez) {
      horarios.push({ data: new Date(d), hora: alarme.hora_inicio });
    }

    if (alarme.duas_vezes) {
      horarios.push({ data: new Date(d), hora: alarme.hora_inicio });
      const [h, m] = alarme.hora_inicio.split(':');
      const segundaHora = new Date(d);
      segundaHora.setHours(Number(h) + 12, Number(m));
      horarios.push({ data: segundaHora, hora: segundaHora.toTimeString().substring(0, 5) });
    }

    if (alarme.periodico) {
      const [h, m] = alarme.periodo.split(':');
      for (let t = new Date(d); t <= new Date(d.getTime() + 86400000); t.setHours(t.getHours() + Number(h))) {
        if (t > dataFim) break;
        horarios.push({ data: new Date(t), hora: t.toTimeString().substring(0, 5) });
      }
    }
  }

  for (const h of horarios) {
    await db.runAsync(
      `INSERT INTO horarios (id_alarme, data, hora, notificado) VALUES (?, ?, ?, 0)`,
      [alarme.id, h.data.toISOString().split('T')[0], h.hora]
    );
  }
}