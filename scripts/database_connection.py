import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('mysql+mysqlconnector://username:password@hostname/databasename')