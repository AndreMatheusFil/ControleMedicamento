import { SQLiteDatabase } from 'expo-sqlite';
import * as Notifications from 'expo-notifications';
import { gerarHorariosParaAlarme } from './gerarHorariosParaAlarme';

export async function verificarEAgendarNotificacoesHoje(database: SQLiteDatabase) {
    try {
        const now = new Date();
        const today = now.toISOString().split('T')[0]; // Formato YYYY-MM-DD

        // 1. Buscar horários não notificados para hoje
        const horariosPendentes = await database.getAllAsync(
            `
            SELECT * FROM horarios
            WHERE data = ? AND notificado = 0
            `,
            [today]
        );

        // 2. Agendar notificações para os horários pendentes
        for (const horario of horariosPendentes) {
            const { id, id_alarme, data, hora } = horario;

            const alarme = await database.getAllAsync(
                `
                SELECT remedio FROM alarmes
                WHERE id = ?
                `,
                [id_alarme]
            );

            const remedio = alarme[0]?.remedio;

            if (remedio) {
                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: 'Hora de tomar o remédio',
                        body: `Remédio: ${remedio}`,
                        sound: 'default',
                    },
                    trigger: {
                        date: new Date(`${data}T${hora}`), // Ajuste aqui
                    },
                });
            }
        }

        // 3. Atualizar os horários como notificados
        await database.getAllAsync(
            `
            UPDATE horarios
            SET notificado = 1
            WHERE data = ? AND notificado = 0
            `,
            [today]
        );

        // 4. Gerar os próximos 30 horários
        await gerarHorariosParaAlarme(database);

        console.log('Horários pendentes verificados e próximos horários gerados.');
    } catch (error) {
        console.error('Erro ao verificar e agendar notificações:', error);
    }
}