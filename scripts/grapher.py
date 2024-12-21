import live_graph
import sys
import bash_to_csv
import database_connection

class Grapher():
    def __init__(self, metric):
        self.metric = metric
        self.connection = database_connection.database_connection()
    
    def call_function(self):
        if self.metric == "cpu":
            data = self.connection.retrieve_linux_metrics()
            live_graph.plot_cpu_utilization(data)
        
    
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