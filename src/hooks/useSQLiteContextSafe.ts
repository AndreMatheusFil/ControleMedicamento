import { Platform } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';

class WebSQLiteStorage {
  private getStorageKey(table: string): string {
    return `sqlite_${table}`;
  }

  private getTableData(table: string): any[] {
    if (typeof window === 'undefined') return [];
    
    const data = localStorage.getItem(this.getStorageKey(table));
    return data ? JSON.parse(data) : [];
  }

  private saveTableData(table: string, data: any[]): void {
    if (typeof window === 'undefined') return;
    
    localStorage.setItem(this.getStorageKey(table), JSON.stringify(data));
  }

  private parseQuery(query: string): { type: string; table: string } {
    const normalizedQuery = query.trim().toLowerCase();
    
    if (normalizedQuery.startsWith('select')) {
      const match = normalizedQuery.match(/from\s+(\w+)/);
      return { type: 'select', table: match ? match[1] : 'alarmes' };
    } else if (normalizedQuery.startsWith('insert')) {
      const match = normalizedQuery.match(/into\s+(\w+)/);
      return { type: 'insert', table: match ? match[1] : 'alarmes' };
    } else if (normalizedQuery.startsWith('update')) {
      const match = normalizedQuery.match(/update\s+(\w+)/);
      return { type: 'update', table: match ? match[1] : 'alarmes' };
    } else if (normalizedQuery.startsWith('delete')) {
      const match = normalizedQuery.match(/from\s+(\w+)/);
      return { type: 'delete', table: match ? match[1] : 'alarmes' };
    }
    
    return { type: 'unknown', table: 'alarmes' };
  }

  async getAllAsync(query: string): Promise<any[]> {
    console.log('Web SQLite - getAllAsync:', query);
    
    const { table } = this.parseQuery(query);
    return this.getTableData(table);
  }

  async runAsync(query: string, params: any[] = []): Promise<{ changes: number; insertId: number; lastInsertRowId: number }> {
    console.log('Web SQLite - runAsync:', query, params);
    
    const { type, table } = this.parseQuery(query);
    const data = this.getTableData(table);
    
    switch (type) {
      case 'insert':
        const newId = Date.now();
        const newRecord = {
          id: newId,
          remedio: params[0] || '',
          duas_vezes: params[1] || 0,
          uma_vez: params[2] || 0,
          periodico: params[3] || 0,
          periodo: params[4] || '',
          data_inicio: params[5] || '',
          hora_inicio: params[6] || '',
          data_fim: params[7] || '',
          segunda: params[8] || 0,
          terca: params[9] || 0,
          quarta: params[10] || 0,
          quinta: params[11] || 0,
          sexta: params[12] || 0,
          sabado: params[13] || 0,
          domingo: params[14] || 0,
          regra_especial: params[15] || 0,
          observacao: params[16] || '',
        };
        
        data.push(newRecord);
        this.saveTableData(table, data);
        
        return { changes: 1, insertId: newId, lastInsertRowId: newId };
        
      case 'update':
        const updateId = params[params.length - 1]; // ID é o último parâmetro
        const recordIndex = data.findIndex(item => item.id == updateId);
        
        if (recordIndex !== -1) {
          data[recordIndex] = {
            ...data[recordIndex],
            remedio: params[0] || data[recordIndex].remedio,
            duas_vezes: params[1] !== undefined ? params[1] : data[recordIndex].duas_vezes,
            uma_vez: params[2] !== undefined ? params[2] : data[recordIndex].uma_vez,
            periodico: params[3] !== undefined ? params[3] : data[recordIndex].periodico,
            periodo: params[4] || data[recordIndex].periodo,
            data_inicio: params[5] || data[recordIndex].data_inicio,
            hora_inicio: params[6] || data[recordIndex].hora_inicio,
            data_fim: params[7] || data[recordIndex].data_fim,
            segunda: params[8] !== undefined ? params[8] : data[recordIndex].segunda,
            terca: params[9] !== undefined ? params[9] : data[recordIndex].terca,
            quarta: params[10] !== undefined ? params[10] : data[recordIndex].quarta,
            quinta: params[11] !== undefined ? params[11] : data[recordIndex].quinta,
            sexta: params[12] !== undefined ? params[12] : data[recordIndex].sexta,
            sabado: params[13] !== undefined ? params[13] : data[recordIndex].sabado,
            domingo: params[14] !== undefined ? params[14] : data[recordIndex].domingo,
            regra_especial: params[15] !== undefined ? params[15] : data[recordIndex].regra_especial,
            observacao: params[16] !== undefined ? params[16] : data[recordIndex].observacao,
          };
          
          this.saveTableData(table, data);
          return { changes: 1, insertId: 0, lastInsertRowId: 0 };
        }
        
        return { changes: 0, insertId: 0, lastInsertRowId: 0 };
        
      case 'delete':
        const deleteId = params[0];
        const initialLength = data.length;
        const filteredData = data.filter(item => item.id != deleteId);
        
        this.saveTableData(table, filteredData);
        
        return { changes: initialLength - filteredData.length, insertId: 0, lastInsertRowId: 0 };
        
      default:
        return { changes: 0, insertId: 0, lastInsertRowId: 0 };
    }
  }
}

const webStorage = new WebSQLiteStorage();

export function useSQLiteContextSafe() {
  if (Platform.OS === 'web') {
    return webStorage;
  }
  
  return useSQLiteContext();
}
