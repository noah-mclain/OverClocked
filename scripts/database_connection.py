import sqlite3
import pandas as pd

class database_connection:
    def __init__(self):
        self.conn = None
        self.cursor = None
        
    def __enter__(self):
        self.conn = sqlite3.connect("system_metrics.db")
        self.cursor = self.conn.cursor()
        return self
    
    def __exit__(self, exc_type, exc_value, traceback):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()

    def create_linux_table(self):
        self.cursor.execute('''CREATE TABLE IF NOT EXISTS system_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        cpu_utilization FLOAT,
        cpu_temperature TEXT,
        total_ram TEXT,
        free_ram TEXT,
        utilized_ram TEXT,
        total_disk_space TEXT,
        used_disk_space TEXT,
        available_disk_space TEXT,
        ipv4_address TEXT,
        ipv6_address TEXT,
        sent TEXT,
        received TEXT,
        startup_time TEXT,
        average_process_waiting_time TEXT
        );''')
        self.conn.commit()
    
    def create_mac_table(self):
        self.cursor.execute('''CREATE TABLE IF NOT EXISTS mac_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        total_ram INTEGER,
        used_ram INTEGER,
        free_ram INTEGER,
        average_cpu_utilization FLOAT,
        gpu_active_frequency INTEGER,
        gpu_active_residency FLOAT,
        gpu_power_consumption INTEGER,
        disk_usage INTEGER,
        temperature INTEGER,
        percentage_used INTEGER,
        ping FLOAT,
        download FLOAT,
        upload FLOAT,
        load_avg FLOAT
        );''')
        self.conn.commit()
    
    def store_mac_metrics(self, metrics):
        try:     
            columns = ', '.join(metrics.keys())
            placeholders = ', '.join('?' * len(metrics))
            query = f"INSERT INTO mac_metrics ({columns}) VALUES ({placeholders})"
            values = tuple(metrics.values())
            self.cursor.execute(query, values)
            self.conn.commit()
        except sqlite3.Error as e:
            print(f"An error occurred: {e}")
    
    def store_linux_metrics(self, metrics):
        try:
            columns = ', '.join(metrics.keys())
            placeholders = ', '.join('?' * len(metrics))
            query = f"INSERT INTO system_metrics ({columns}) VALUES ({placeholders})"
            values = tuple(metrics.values())
            self.cursor.execute(query, values)
            self.conn.commit()
        except sqlite3.Error as e:
            print(f"An error has occurred: {e}")

    def retrieve_metrics(self, os_type, limit=None):
        table_name = "system_metrics" if os_type == "Linux" else "mac_metrics"
        
        query = f"SELECT * FROM {table_name}"
        
        if limit is not None:
            query += " ORDER BY timestamp DESC LIMIT ?"
            self.cursor.execute(query, (limit,))
        else:
            self.cursor.execute(query)
        
        rows = self.cursor.fetchall()
        columns = [column[0] for column in self.cursor.description]
        return [dict(zip(columns, row)) for row in rows]

    # def retrieve_linux_metrics(self, limit=None):
    #     query = "SELECT * FROM system_metrics"
    #     if limit:
    #         query += " ORDER BY timestamp DESC ?"
    #         self.cursor.execute(query, (limit,))
    #     else:
    #         self.cursor.execute(query)
            
    #     rows = self.cursor.fetchall()
    #     columns = [column[0] for column in self.cursor.description]
    #     return [dict(zip(columns, row)) for row in rows]
            
            
        # self.cursor.execute(query)
        # rows = self.cursor.fetchall()
        
        # results = []
        # for row in rows:
        #     results.append({
        #         'id': row[0],
        #         'timestamp': pd.to_datetime(row[1]),
        #         'cpu_utilization': row[2],
        #         'cpu_temperature': row[3],
        #         'total_ram': row[4],
        #         'free_ram': row[5],
        #         'utilized_ram': row[6],
        #         'total_disk_space': row[7],
        #         'used_disk_space': row[8],
        #         'available_disk_space': row[9],
        #         'ipv4_address': row[10],
        #         'ipv6_address': row[11],
        #         'sent': row[12],
        #         'received': row[13],
        #         'startup_time': row[14],
        #         'average_process_waiting_time': row[15]
        #     })
        # return results
    
    # def retrieve_mac_metrics(self, limit=None):
    #     query = "SELECT * FROM system_metrics"
    #     if limit:
    #         query += " ORDER BY timestamp DESC ?"
    #         self.cursor.execute(query, (limit,))
    #     else:
    #         self.cursor.execute(query)
            
    #     rows = self.cursor.fetchall()
    #     columns = [column[0] for column in self.cursor.description]
    #     return [dict(zip(columns, row)) for row in rows]

        # results = []
        # for row in rows:
        #     results.append({
        #         'id': row[0],
        #         'timestamp': pd.to_datetime(row[1]),
        #         'total_ram': row[2],
        #         'used_ram': row[3],
        #         'free_ram': row[4],
        #         'avg_cpu_utilization': row[5],
        #         'gpu_active_frequency': row[6],
        #         'gpu_active_residency': row[7],
        #         'gpu_power_consumption': row[8],
        #         'disk_usage': row[9],
        #         'temperature': row[10],
        #         'percentage_used': row[11],
        #         'ping': row[12],
        #         'download': row[13],
        #         'upload': row[14],
        #         'load_avg_1': row[15],
        #         'load_avg_5': row[16],
        #         'load_avg_15': row[17]
        #     })
        # return results

    

    # def close_connection(self):
    #     self.conn.close()

    # def connect(self):
    #     self.conn = sqlite3.connect("system_metrics.db")
    #     self.cursor = self.conn.cursor()

