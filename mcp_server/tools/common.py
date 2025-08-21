"""Rapor araçları için paylaşılan yardımcı fonksiyonlar."""

import sys
import os
from typing import Dict, Any
import pandas as pd
import psycopg2
from datetime import datetime

# Ana proje klasöründen import etmek için üst dizini path'e ekle
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

try:
    from db_utils import DatabaseConnection, read_sql_file
except ImportError:
    # Yedek: DatabaseConnection ve read_sql_file'ı doğrudan dahil et
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
            """Veritabanı bağlantısı kur"""
            print("\nVeritabanına bağlanılıyor...")
            self.conn = psycopg2.connect(**self.db_params)
            self.cur = self.conn.cursor()
            print("Bağlantı başarılı!")

        def close(self):
            """Veritabanı bağlantısını kapat"""
            if self.cur:
                self.cur.close()
            if self.conn:
                self.conn.close()
                print("\nVeritabanı bağlantısı kapatıldı.")

        def execute_query(self, query: str) -> pd.DataFrame:
            """Sorguyu çalıştır ve sonuçları DataFrame olarak döndür"""
            try:
                self.cur.execute(query)
                
                # Sorgunun herhangi bir sonuç döndürüp döndürmediğini kontrol et
                if self.cur.description is None:
                    print("Sorgu başarıyla çalıştırıldı ancak hiç sonuç döndürülmedi")
                    return pd.DataFrame()
                
                columns = [desc[0] for desc in self.cur.description]
                results = self.cur.fetchall()
                print(f"Sorgu {len(columns)} sütunlu {len(results)} satır döndürdü")
                
                return pd.DataFrame(results, columns=columns)
                
            except Exception as e:
                print(f"Veritabanı hatası: {str(e)}")
                raise

    def read_sql_file(file_path: str) -> str:
        """SQL sorgusunu dosyadan oku"""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                return file.read()
        except FileNotFoundError:
            raise FileNotFoundError(f"{file_path} dosyası bulunamadı!")


def null_if_empty(val):
    """Boş stringi SQL sorguları için NULL'a çevir."""
    return val if val else "NULL"


def run_report(sql_path: str, params: Dict[str, Any]) -> pd.DataFrame:
    """Parametreli rapor sorgusunu çalıştır ve DataFrame döndür."""
    # Yolu proje köküne göre ayarla
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    full_sql_path = os.path.join(project_root, sql_path)
    
    sql = read_sql_file(full_sql_path)
    
    # SQL'deki parametreleri değiştir
    for key, value in params.items():
        sql = sql.replace(key, str(value))
    
    # Sorguyu çalıştır
    db = DatabaseConnection()
    db.connect()
    try:
        df = db.execute_query(sql)
        return df
    finally:
        db.close()


def format_dataframe_response(df: pd.DataFrame, report_name: str) -> Dict[str, Any]:
    """DataFrame'i yapılandırılmış yanıt olarak formatla."""
    if df.empty:
        return {
            "rapor_adi": report_name,
            "durum": "basarili",
            "mesaj": "Verilen kriterlere göre veri bulunamadı",
            "satir_sayisi": 0,
            "veri": []
        }
    
    # DataFrame'i JSON serileştirme için dict'e çevir
    data = df.to_dict('records')
    
    return {
        "rapor_adi": report_name,
        "durum": "basarili", 
        "satir_sayisi": len(df),
        "sutunlar": list(df.columns),
        "veri": data[:100] if len(data) > 100 else data,  # İlk 100 satırla sınırla
        "kesildi": len(data) > 100,
        "toplam_satir": len(data)
    }
