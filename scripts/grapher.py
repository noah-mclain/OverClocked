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
            if self.metric == "cpu":
                data = connection.retrieve_metrics(os_type)
                live_graph.plot_cpu_utilization(data, os_type)
            elif self.metric == "ram":
                ...

        
        
    
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