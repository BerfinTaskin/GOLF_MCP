#!/usr/bin/env python3
"""
MCP araçlarını doğrudan test et ve SQL dosya mapping'ini kontrol et
"""

import sys
import os

# MCP server tools klasörünü path'e ekle
sys.path.append('/home/berfintskn/Smart_GMCP/mcp_server/tools')

def test_sql_file_mapping():
    """SQL dosya mapping'ini test et"""
    print("🔍 SQL Dosya Mapping Testi")
    print("="*50)
    
    try:
        from common import get_actual_sql_filename, read_sql_file
        
        # Test edilecek dosya isimleri (araçların kullandığı)
        test_files = [
            "tum_sorgular/Genel_Master_Rapor-POSTGRESQL.sql",
            "tum_sorgular/Arşiv_Verileri-POSTGRESQL.sql", 
            "tum_sorgular/Depo_Stok_Miktarları-POSTGRESQL.sql",
            "tum_sorgular/Ayrıntılı_Depo_Hareket_Raporu-POSTGRESQL.sql",
            "tum_sorgular/Beyanname_Bazinda_Maliyet_Raporu-POSTGRESQL.sql"
        ]
        
        success_count = 0
        
        for test_file in test_files:
            print(f"\n📁 Test dosyası: {test_file}")
            
            # Extract filename
            if "/" in test_file:
                filename_only = test_file.split("/")[-1]
            else:
                filename_only = test_file
                
            print(f"   📄 Çıkarılan dosya adı: {filename_only}")
            
            # Map to actual filename
            actual_filename = get_actual_sql_filename(filename_only)
            print(f"   🎯 Mapped dosya adı: {actual_filename}")
            
            # Full path oluştur
            current_file = os.path.abspath(__file__)
            base_dir = os.path.dirname(current_file)
            sql_base_dir = os.path.join(base_dir, "mcp_server", "dist", "tum_sorgular")
            full_path = os.path.join(sql_base_dir, actual_filename)
            
            print(f"   📍 Tam path: {full_path}")
            print(f"   ✅ Dosya var mı: {os.path.exists(full_path)}")
            
            if os.path.exists(full_path):
                try:
                    content = read_sql_file(full_path)
                    print(f"   📊 SQL içerik uzunluğu: {len(content)} karakter")
                    print(f"   🎉 SUCCESS - Dosya başarıyla okundu!")
                    success_count += 1
                except Exception as e:
                    print(f"   ❌ HATA - Dosya okunamadı: {e}")
            else:
                print(f"   ❌ HATA - Dosya bulunamadı!")
                # Mevcut dosyaları listele
                if os.path.exists(sql_base_dir):
                    available_files = os.listdir(sql_base_dir)
                    print(f"   📋 Mevcut dosyalar: {available_files}")
        
        print(f"\n🎯 SQL Mapping Sonucu: {success_count}/{len(test_files)} başarılı")
        return success_count == len(test_files)
        
    except Exception as e:
        print(f"❌ SQL mapping test hatası: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_actual_files():
    """Gerçekte mevcut dosyaları listele"""
    print("\n🗂️  Mevcut SQL Dosyaları")
    print("="*50)
    
    current_file = os.path.abspath(__file__)
    base_dir = os.path.dirname(current_file)
    sql_base_dir = os.path.join(base_dir, "mcp_server", "dist", "tum_sorgular")
    
    if os.path.exists(sql_base_dir):
        files = os.listdir(sql_base_dir)
        for i, file in enumerate(files, 1):
            print(f"{i:2d}. {file}")
        return True
    else:
        print(f"❌ SQL klasörü bulunamadı: {sql_base_dir}")
        return False

def test_calculator():
    """Calculator aracını test et"""
    try:
        from calculator import mcp_akilli_gmcp_r_calculator
        
        print("🧮 Calculator aracını test ediyorum...")
        result = mcp_akilli_gmcp_r_calculator(ifade="2 + 3", acikla=False)
        print(f"✅ Calculator test başarılı: {result}")
        return True
    except Exception as e:
        print(f"❌ Calculator test hatası: {e}")
        return False

def test_genel_master_rapor():
    """Genel master rapor aracını test et"""
    try:
        from genel_master_rapor import mcp_akilli_gmcp_r_genel_master_rapor
        
        print("📊 Genel Master Rapor aracını test ediyorum...")
        
        # Test parametreleri
        params = {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2025-01-01", 
            "tarih2": "2025-06-30",
            "refnofirma": "",
            "solmazrefno": "",
            "tescilno": "",
            "faturano": ""
        }
        
        result = mcp_akilli_gmcp_r_genel_master_rapor(**params)
        print(f"✅ Genel Master Rapor test başarılı!")
        print(f"📈 Satır sayısı: {result.get('satir_sayisi', 'N/A')}")
        return True
    except Exception as e:
        print(f"❌ Genel Master Rapor test hatası: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_depo_stok_miktarlari():
    """Depo stok miktarları aracını test et"""
    try:
        from depo_stok_miktarlari import mcp_akilli_gmcp_r_depo_stok_miktarlari
        
        print("📦 Depo Stok Miktarları aracını test ediyorum...")
        
        params = {
            "firma": "CMPBHLFKRMD205",
            "lojistikdepo": "DEP421",
            "paletno": ""
        }
        
        result = mcp_akilli_gmcp_r_depo_stok_miktarlari(**params)
        print(f"✅ Depo Stok Miktarları test başarılı!")
        print(f"📈 Satır sayısı: {result.get('satir_sayisi', 'N/A')}")
        return True
    except Exception as e:
        print(f"❌ Depo Stok Miktarları test hatası: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 MCP Araçları Doğrudan Test")
    print("=" * 50)
    
    test_results = []
    
    # Önce SQL dosyalarını kontrol et
    test_results.append(("SQL Dosyalar Mevcut", test_actual_files()))
    test_results.append(("SQL Mapping", test_sql_file_mapping()))
    
    # Calculator test (SQL gerektirmeyen)
    test_results.append(("Calculator", test_calculator()))
    
    # SQL gerektiren araçları test et
    test_results.append(("Genel Master Rapor", test_genel_master_rapor()))
    test_results.append(("Depo Stok Miktarları", test_depo_stok_miktarlari()))
    
    print("\n" + "=" * 50)
    print("📊 Test Sonuçları:")
    
    successful = 0
    failed = 0
    
    for test_name, success in test_results:
        status = "✅ BAŞARILI" if success else "❌ BAŞARISIZ"
        print(f"  {test_name:25} {status}")
        if success:
            successful += 1
        else:
            failed += 1
    
    print(f"\n🎯 Toplam: {successful} başarılı, {failed} başarısız")
    success_rate = (successful / len(test_results)) * 100
    print(f"📈 Başarı Oranı: %{success_rate:.1f}")
