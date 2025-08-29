"""Rapor araçları için paylaşılan yardımcı fonksiyonlar."""

import sys
import os
import json
from typing import Dict, Any
import pandas as pd
import psycopg2
import numpy as np
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
            # Dosya varlığını önce kontrol et
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"{file_path} dosyası bulunamadı!")
            
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
                if not content.strip():
                    raise ValueError(f"{file_path} dosyası boş!")
                return content
        except FileNotFoundError:
            raise FileNotFoundError(f"SQL dosyası bulunamadı: {file_path}")
        except UnicodeDecodeError as e:
            raise ValueError(f"SQL dosyası encoding hatası ({file_path}): {str(e)}")
        except Exception as e:
            raise ValueError(f"SQL dosyası okuma hatası ({file_path}): {str(e)}")


def null_if_empty(val):
    """Boş stringi SQL sorguları için NULL'a çevir."""
    return val if val else "NULL"


def run_report(sql_path: str, params: Dict[str, Any]) -> pd.DataFrame:
    """Parametreli rapor sorgusunu çalıştır ve DataFrame döndür."""
    try:
        # Proje dizin yapısını hesapla
        current_file = os.path.abspath(__file__)
        tools_dir = os.path.dirname(current_file)      # mcp_server/tools
        mcp_server_dir = os.path.dirname(tools_dir)    # mcp_server
        project_root = os.path.dirname(mcp_server_dir) # Smart_GMCP
        
        # SQL dosyasının tam yolunu oluştur
        full_sql_path = os.path.join(mcp_server_dir, 'dist', sql_path)
        
        # Debug bilgisi
        print(f"DEBUG: SQL dosya yolu - {full_sql_path}")
        
        # SQL dosyasını oku
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
            
    except FileNotFoundError as e:
        print(f"SQL dosya hatası: {str(e)}")
        raise
    except ValueError as e:
        print(f"SQL içerik hatası: {str(e)}")
        raise
    except Exception as e:
        print(f"Genel rapor hatası: {str(e)}")
        raise


def safe_json_convert(obj):
    """JSON serileştirme için güvenli dönüştürme."""
    if isinstance(obj, (np.integer, int)):
        return int(obj)
    elif isinstance(obj, (np.floating, float)):
        if np.isnan(obj) or np.isinf(obj):
            return None
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif pd.isna(obj):
        return None
    elif isinstance(obj, (pd.Timestamp, datetime)):
        return str(obj)
    else:
        return obj


def calculate_optimal_rows(df: pd.DataFrame) -> int:
    """DataFrame karakteristiklerine göre optimal satır sayısını hesapla."""
    column_count = len(df.columns)
    
    # Sütun sayısına göre adaptif satır sınırı
    if column_count > 30:
        return 15
    elif column_count > 20:
        return 25
    elif column_count > 15:
        return 35
    elif column_count > 10:
        return 40
    else:
        return 50


def format_summary_response(df: pd.DataFrame, report_name: str) -> Dict[str, Any]:
    """Büyük datasets için özet yanıt formatla."""
    if df.empty:
        return format_dataframe_response(df, report_name)
    
    # Sayısal sütunlar için istatistik
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    summary_stats = {}
    
    for col in numeric_cols:
        summary_stats[col] = {
            "toplam": safe_json_convert(df[col].sum()),
            "ortalama": safe_json_convert(df[col].mean()),
            "min": safe_json_convert(df[col].min()),
            "max": safe_json_convert(df[col].max())
        }
    
    return {
        "rapor_adi": f"{report_name} (Özet)",
        "durum": "basarili",
        "satir_sayisi": int(len(df)),
        "sutunlar": list(df.columns),
        "istatistikler": summary_stats,
        "ilk_5_satir": df.head(5).apply(lambda col: col.apply(safe_json_convert)).to_dict('records'),
        "son_5_satir": df.tail(5).apply(lambda col: col.apply(safe_json_convert)).to_dict('records') if len(df) > 5 else [],
        "ozet_modu": True
    }


def format_dataframe_response(df: pd.DataFrame, report_name: str, max_rows: int = None) -> Dict[str, Any]:
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
    # NaN ve inf değerleri None'a çevir, float değerleri JSON uyumlu hale getir
    df_clean = df.copy()
    
    # Tüm sütunları kontrol et ve JSON uyumlu hale getir
    for col in df_clean.columns:
        df_clean[col] = df_clean[col].apply(safe_json_convert)
    
    data = df_clean.to_dict('records')
    
    # Ekstra güvenlik: sonuçları JSON serileştirme testi yap
    try:
        json.dumps(data)
    except Exception as e:
        print(f"JSON serileştirme hatası: {e}")
        # Hata durumunda tüm değerleri string'e çevir
        data = df.astype(str).replace('nan', None).to_dict('records')
    
    # Adaptif satır sayısı hesapla
    if max_rows is None:
        adaptive_max_rows = calculate_optimal_rows(df)
    else:
        adaptive_max_rows = max_rows
    
    column_count = len(df.columns)
    
    # Response boyutunu kontrol et ve gerekirse daha da azalt
    limited_data = data[:adaptive_max_rows] if len(data) > adaptive_max_rows else data
    
    result = {
        "rapor_adi": report_name,
        "durum": "basarili", 
        "satir_sayisi": int(len(df)),
        "sutunlar": list(df.columns),
        "veri": limited_data,
        "kesildi": len(data) > adaptive_max_rows,
        "toplam_satir": int(len(data)),
        "gosterilen_satir": len(limited_data)
    }
    
    # Response boyutu kontrolü
    try:
        result_json = json.dumps(result)
        result_size = len(result_json)
        print(f"DEBUG: Response boyutu: {result_size} karakter, {len(limited_data)} satır, {column_count} sütun")
        
        # Eğer hala çok büyükse daha da azalt (25K token = ~100K karakter civarı)
        if result_size > 80000:  # Conservative limit for token safety
            new_max = max(10, len(limited_data) // 2)
            print(f"UYARI: Response çok büyük ({result_size}), satır sayısı {len(limited_data)} -> {new_max} azaltılıyor")
            result["veri"] = data[:new_max]
            result["gosterilen_satir"] = new_max
            result["kesildi"] = True
            
            # Eğer hala büyükse özet moduna geç
            if len(json.dumps(result)) > 80000:
                print("UYARI: Özet moduna geçiliyor - veri çok büyük")
                return format_summary_response(df, report_name)
            
    except Exception as e:
        print(f"HATA: Final JSON serileştirme başarısız: {e}")
        print(f"Problematik veri türleri: {[(k, type(v)) for k, v in result.items()]}")
    
    return result