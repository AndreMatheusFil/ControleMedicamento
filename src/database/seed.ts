import { type SQLiteDatabase } from "expo-sqlite";

export async function seed(database: SQLiteDatabase){
    await database.withTransactionAsync(async () => {
        await database.runAsync(`
            INSERT INTO alarmes (remedio, hora, data_inicio, data_fim, dias_semana, regra_especial, observacao) VALUES
                ('Paracetamol', '08:00', '2025-06-01', '2025-06-15', '1,2,3,4,5', 0, 'Tomar em jejum'),
                ('Ibuprofeno', '12:00', '2025-06-01', '2025-06-10', '1,3,5', 2, 'Tomar após o almoço'),
                ('Amoxicilina', '18:00', '2025-06-05', '2025-06-20', '0,1,2,3,4,5,6', 0, 'Completar o ciclo de 10 dias'),
                ('Vitamina D', '07:30', '2025-06-01', '2025-07-01', '6', 0, 'Tomar só aos domingos'),
                ('Dipirona', '22:00', '2025-06-01', '2025-06-30', '0,2,4,6', 1, 'Tomar se houver dor'),
                ('Losartana', '09:00', '2025-06-01', '2025-12-31', '1,2,3,4,5,6,0', 0, 'Uso contínuo diário');    
        `)
    })
}