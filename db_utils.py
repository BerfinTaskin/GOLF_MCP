import psycopg2
import pandas as pd
from datetime import datetime
from typing import Optional, Dict, Any
import time

class DatabaseConnection:
    def __init__(self):
        self.db_params = {
            'dbname': 'replikasyondb',
            'user': 'solmazsmart',
            'password': '7Q<3Eg*7u+',
            'host': '172.16.34.48',
            'port': '5432',
            'options': '-c search_path=slz05'
        }
        self.conn = None
        self.cur = None


    def connect(self):
        """Establish database connection"""
        print("\nVeritabanına bağlanılıyor...")
        self.conn = psycopg2.connect(**self.db_params)
        self.cur = self.conn.cursor()
        print("Bağlantı başarılı!")

    def close(self):
        """Close database connection"""
        if self.cur:
            self.cur.close()
        if self.conn:
            self.conn.close()
            print("\nVeritabanı bağlantısı kapatıldı.")

    def execute_query(self, query: str) -> pd.DataFrame:
        """Execute query and return results as DataFrame"""
        try:
            #print(f"Executing query: {query[:200]}...")
            self.cur.execute(query)
            
            # Check if query returned any results
            if self.cur.description is None:
                print("Query executed successfully but no results returned")
                return pd.DataFrame()
            
            columns = [desc[0] for desc in self.cur.description]
            results = self.cur.fetchall()
            print(f"Query returned {len(results)} rows with {len(columns)} columns")
            
            return pd.DataFrame(results, columns=columns)
            
        except Exception as e:
            print(f"Database error: {str(e)}")
            raise

def validate_dates(start_date: str, end_date: str):
    """Validate date format"""
    try:
        datetime.strptime(start_date, '%Y-%m-%d')
        datetime.strptime(end_date, '%Y-%m-%d')
    except ValueError:
        raise ValueError("Tarih formatı YYYY-MM-DD şeklinde olmalıdır!")

def read_sql_file(file_path: str) -> str:
    """Read SQL query from file"""
    import os
    
    # Get the directory of this script (db_utils.py)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # If it's a relative path, make it relative to the project root
    if not os.path.isabs(file_path):
        file_path = os.path.join(current_dir, file_path)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"{file_path} dosyası bulunamadı!")