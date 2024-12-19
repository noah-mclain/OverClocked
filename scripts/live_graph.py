import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sqlalchemy

from database_connection import engine

query = "SELECT * FROM metrics ORDER BY timestamp DESC LIMIT 10"

try:
    data = pd.read_sql(query, engine)
    print(data)
except Exception as e:
    print(f"Error fetching data: {e}")