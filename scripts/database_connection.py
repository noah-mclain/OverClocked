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
        five_min FLOAT
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

    def retrieve_latest_metrics(self, os_type):
        table_name = "system_metrics" if os_type == "Linux" else "mac_metrics"
        query = f"SELECT * FROM {table_name} ORDER BY timestamp DESC LIMIT 1"
        try:
            self.cursor.execute(query)
            row = self.cursor.fetchone()
        except Exception as e:
            print(f"Error retrieving metrics: {e}")
            return None

        def parse_percentage(value):
            if isinstance(value, str) and '%' in value:
                return float(value.strip('%'))
            return value if value is not None else 0

        def replace_none(value, default):
            return value if value is not None else default

        print("Retrieved row:", row)

        if os_type == "Linux":
            return {
                'timestamp': row[1],
                'cpu_utilization': parse_percentage(row[5]),
                'cpu_temperature': replace_none(row[6], 0),
                'used_disk_space': replace_none(row[7], 0),
                'available_disk_space': replace_none(row[8], 0),
                'ipv4_address': replace_none(row[9], "N/A"),  
                'ipv6_address': replace_none(row[10], "N/A"), 
                'sent': replace_none(row[11], 0),
                'received': replace_none(row[12], 0),
                'startup_time': replace_none(row[13], "N/A"),
                'average_process_waiting_time': replace_none(row[14], "N/A"),
            }

        elif os_type == "Darwin":
            return {
                'timestamp': row[1],  # Assuming timestamp is at index 1
                'total_ram': replace_none(row[2], 0),
                'used_ram': replace_none(row[3], 0),
                'free_ram': replace_none(row[4], 0),
                'average_cpu_utilization': parse_percentage(row[5]),
                'gpu_active_frequency': replace_none(row[6], 0),
                'gpu_active_residency': parse_percentage(row[7]),
                'gpu_power_consumption': replace_none(row[8], 0),
                'disk_usage': parse_percentage(row[9]),
                'temperature': replace_none(row[10], "N/A"),
                'percentage_used': parse_percentage(row[11]),
                'ping': replace_none(row[12], 0.0),
                'download': replace_none(row[13], 0.0),
                'upload': replace_none(row[14], 0.0),
                'five_min': replace_none(row[15], "N/A"),
            }

