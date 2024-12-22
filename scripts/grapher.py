import live_graph
import sys
import bash_to_csv
import os
import platform
from database_connection import database_connection

class Grapher():
    def __init__(self, metric):
        self.metric = metric
    
    def call_function(self):
        os_type = platform.system()
        print(os_type)
        with database_connection() as connection:
            data = connection.retrieve_metrics(os_type, limit=5)
            if self.metric == "cpu":
                live_graph.plot_cpu_utilization(data, os_type)
            elif self.metric == "ram":
                live_graph.plot_ram_utilization(data, os_type)
            elif self.metric =="network":
                live_graph.plot_network_utilization(data, os_type)
                

        
        
    
    def graph(self):
        self.call_function()
    
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 grapher.py <Metric>")
        sys.exit(1)
    
    metric = sys.argv[1]
    try:
        grapher = Grapher(metric)
        grapher.graph()
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)