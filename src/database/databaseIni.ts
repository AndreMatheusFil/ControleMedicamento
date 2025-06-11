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
                hora TEXT,
                data_inicio TEXT,
                data_fim TEXT,
                dias_semana TEXT,
                regra_especial INTEGER,
                observacao TEXT
            );
        `) 
        await seed(database)
    }
}