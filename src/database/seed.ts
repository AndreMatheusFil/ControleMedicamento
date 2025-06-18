import { type SQLiteDatabase } from "expo-sqlite";

export async function seed(database: SQLiteDatabase){
    console.log("Dentro do seed");
    await database.withTransactionAsync(async () => {
        await database.runAsync(`
            INSERT INTO alarmes (remedio,duas_vezes ,uma_vez ,periodico, periodo, data_inicio, hora_inicio, data_fim, segunda ,terca ,quarta ,quinta ,sexta ,sabado ,domingo , regra_especial, observacao) VALUES
                ('Paracetamol',false,true,false, '08:00', '2025-06-01', '08:00', '2025-06-15', true,true,true,true,true,true,true, 0, 'Tomar em jejum'),
                ('Ibuprofeno',false,true,false,'12:00', '2025-06-01', '08:00', '2025-06-10',  true,true,true,true,true,true,true,3, 'Tomar após o almoço'),
                ('Amoxicilina',false,true,false, '18:00', '2025-06-05', '08:00', '2025-06-20', true,true,true,true,true,true,true, 0, 'Completar o ciclo de 10 dias'),
                ('Vitamina D',false,true,false, '07:30', '2025-06-01', '08:00', '2025-07-01',  true,true,true,true,true,true,true, 0, 'Tomar só aos domingos'),
                ('Dipirona',false,true,false,'22:00', '2025-06-01', '08:00', '2025-06-30',    true,true,true,true,true,true,true, 1, 'Tomar se houver dor'),
                ('Losartana',false,true,false, '09:00', '2025-06-01', '08:00', '2025-12-31',    true,true,true,true,true,true,true, 0, 'Uso contínuo diário');    
        `)
    })
}