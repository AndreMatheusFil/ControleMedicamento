import { type SQLiteDatabase } from 'expo-sqlite'
import { seed } from './seed'


export async function databaseIni(database:SQLiteDatabase) {
    const result = await database.getFirstAsync<alarmes>(`
        SELECT name FROM sqlite_master WHERE type='table' AND name='alarmes'  
    `)
    if(!result){
        await database.execAsync(`
            CREATE TABLE IF NOT EXISTS alarmes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                remedio TEXT,
                duas_vezes BOOLEAN,
                uma_vez BOOLEAN,
                periodico BOOLEAN,
                periodo TEXT, 
                data_inicio TEXT,
                hora_inicio TEXT,
                data_fim TEXT,
                segunda BOOLEAN,
                terca BOOLEAN,
                quarta BOOLEAN,
                quinta BOOLEAN,
                sexta BOOLEAN,
                sabado BOOLEAN,
                domingo BOOLEAN,
                regra_especial INTEGER,
                observacao TEXT
            );
        `)
        await seed(database)
    }
}