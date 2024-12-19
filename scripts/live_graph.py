import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sqlalchemy

from database_connection import engine

def load_metrics():
    try:
        query = "SELECT * FROM metrics ORDER BY timestamp DESC LIMIT 10"
        data = pd.read_sql(query, engine, params={"limit": 10})
        return data
        print(data)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return None
    
def animate(i):
    data = load_metrics()
    if data is not None and not data.empty:
        plt.clf()
        plt.bar(data['metric_name'], data['metric_value'], color='skyblue')
        plt.xlabel("Metrics")
        plt.ylabel("Values")
        plt.title("Live System Performance Metrics")
        plt.xticks(rotation=45)
        plt.tight_layout()
        
fig = plt.figure(figsize=(10, 6))
ani = animation.FuncAnimation(fig, animate, interval=1000)

plt.show()

