#!/usr/bin/env python3
"""
SSE üzerinden MCP araçlarını test et
"""

import requests
import json
import time

def test_mcp_via_sse():
    """SSE üzerinden MCP araçlarını test et"""
    
    base_url = "http://172.22.10.39:3000"
    headers = {
        "Authorization": "Bearer dev-token-123",
        "Content-Type": "application/json"
    }
    
    print("🚀 SSE üzerinden MCP Test")
    print("=" * 50)
    
    # Test 1: Calculator (SQL gerektirmeyen)
    print("\n🧮 Calculator aracını test ediyorum...")
    test_data = {
        "name": "calculator", 
        "params": {
            "ifade": "25 * 4 + 10",
            "acikla": False
        }
    }
    
    try:
        response = requests.post(f"{base_url}/call-tool", headers=headers, json=test_data, timeout=10)
        print(f"   📡 HTTP Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Calculator başarılı: {result}")
        else:
            print(f"   ❌ Calculator hatası: {response.text}")
    except Exception as e:
        print(f"   ❌ Calculator bağlantı hatası: {e}")
    
    # Test 2: Genel Master Rapor (SQL gerektiren)
    print("\n📊 Genel Master Rapor aracını test ediyorum...")
    test_data = {
        "name": "genel_master_rapor",
        "params": {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2025-01-01", 
            "tarih2": "2025-06-30",
            "refnofirma": "",
            "solmazrefno": "",
            "tescilno": "",
            "faturano": ""
        }
    }
    
    try:
        response = requests.post(f"{base_url}/call-tool", headers=headers, json=test_data, timeout=30)
        print(f"   📡 HTTP Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Genel Master Rapor başarılı!")
            if isinstance(result, dict) and 'satir_sayisi' in result:
                print(f"   📈 Satır sayısı: {result['satir_sayisi']}")
            else:
                print(f"   📋 Sonuç tipi: {type(result)}")
        else:
            print(f"   ❌ Genel Master Rapor hatası: {response.text}")
    except Exception as e:
        print(f"   ❌ Genel Master Rapor bağlantı hatası: {e}")

    # Test 3: Depo Stok Miktarları (SQL gerektiren)
    print("\n📦 Depo Stok Miktarları aracını test ediyorum...")
    test_data = {
        "name": "depo_stok_miktarlari",
        "params": {
            "firma": "CMPBHLFKRMD205",
            "lojistikdepo": "DEP421",
            "paletno": ""
        }
    }
    
    try:
        response = requests.post(f"{base_url}/call-tool", headers=headers, json=test_data, timeout=30)
        print(f"   📡 HTTP Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Depo Stok Miktarları başarılı!")
            if isinstance(result, dict) and 'satir_sayisi' in result:
                print(f"   📈 Satır sayısı: {result['satir_sayisi']}")
            else:
                print(f"   📋 Sonuç tipi: {type(result)}")
        else:
            print(f"   ❌ Depo Stok Miktarları hatası: {response.text}")
    except Exception as e:
        print(f"   ❌ Depo Stok Miktarları bağlantı hatası: {e}")

if __name__ == "__main__":
    test_mcp_via_sse()
