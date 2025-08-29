#!/usr/bin/env python3
"""
Kalan MCP Tool'larını Test Et
"""

import requests
import json
import time

BASE_URL = "http://172.22.10.39:3000"
AUTH_TOKEN = "dev-token-123"

# Geri kalan tool'lar
REMAINING_TOOLS = [
    {
        "name": "gun_bazli_antrepo_stok_durumu",
        "description": "Gün bazlı antrepo stok durumu",
        "params": {
            "firma": "CMPBHLFKRMD205",
            "lojistikdepo": "DEP421",
            "tarih1": "2024-01-15"
        }
    },
    {
        "name": "stk_bazli_stok_kalan_gun_raporu",
        "description": "STK bazlı stok kalan gün raporu",
        "params": {
            "firma": "CMPBHLFKRMD205",
            "lojistikdepo": "DEP421", 
            "tarih1": "2024-01-15"
        }
    },
    {
        "name": "gonderi_sorgulama_lokasyon_raporu",
        "description": "Gönderi sorgulama lokasyon raporu",
        "params": {
            "firma": "CMP84HLHHS111W",
            "tarih1": "2024-01-01",
            "tarih2": "2024-01-31"
        }
    },
    {
        "name": "arsiv_verileri",
        "description": "Arşiv verileri raporu", 
        "params": {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2024-01-01",
            "tarih2": "2024-01-31",
            "refnofirma": "",
            "solmazrefno": "",
            "tescilno": "",
            "faturano": ""
        }
    },
    {
        "name": "islemdeki_dosyalar_raporu",
        "description": "İşlemdeki dosyalar raporu",
        "params": {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2024-01-01", 
            "tarih2": "2024-01-31",
            "refnofirma": "",
            "solmazrefno": "",
            "tescilno": ""
        }
    },
    {
        "name": "firma_beyannameleri_gtip_bazinda_rapor",
        "description": "Firma beyannameleri GTİP bazında rapor",
        "params": {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2024-01-01",
            "tarih2": "2024-01-31",
            "refnofirma": "",
            "solmazrefno": "",
            "tescilno": ""
        }
    }
]

def call_single_tool(tool_name, params, max_retries=2):
    """Tek bir tool'u çağır"""
    
    for attempt in range(max_retries):
        try:
            print(f"  🔄 Deneme {attempt + 1}/{max_retries}")
            
            # Yeni session al
            headers = {
                "Authorization": f"Bearer {AUTH_TOKEN}",
                "Accept": "text/event-stream"
            }
            
            sse_response = requests.get(f"{BASE_URL}/sse", headers=headers, stream=True, timeout=3)
            
            if sse_response.status_code == 200:
                session_id = None
                for line in sse_response.iter_lines():
                    if line:
                        line = line.decode('utf-8').strip()
                        if line.startswith('data: /messages/?session_id='):
                            session_id = line.split('session_id=')[1]
                            break
                
                if session_id:
                    # Tool çağrısı yap
                    headers = {
                        "Authorization": f"Bearer {AUTH_TOKEN}",
                        "Content-Type": "application/json"
                    }
                    
                    payload = {
                        "jsonrpc": "2.0",
                        "id": 1,
                        "method": "tools/call",
                        "params": {
                            "name": tool_name,
                            "arguments": params
                        }
                    }
                    
                    url = f"{BASE_URL}/messages/?session_id={session_id}"
                    response = requests.post(url, headers=headers, json=payload, timeout=15)
                    
                    if response.status_code == 202:
                        return {"status": "success", "code": 202, "message": "Tool çağrısı kabul edildi"}
                    else:
                        return {"status": "error", "code": response.status_code, "message": response.text}
                else:
                    return {"status": "error", "code": 0, "message": "Session ID alınamadı"}
            else:
                return {"status": "error", "code": sse_response.status_code, "message": "SSE bağlantısı başarısız"}
                
        except Exception as e:
            if attempt == max_retries - 1:
                return {"status": "error", "code": 0, "message": str(e)}
            time.sleep(1)

def main():
    print("🏌️ Smart GMCP - Kalan Tool'ları Test Et")
    print("=" * 70)
    print(f"📅 Test Zamanı: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 Server: {BASE_URL}")
    print("=" * 70)
    
    results = []
    
    for i, tool in enumerate(REMAINING_TOOLS, 1):
        tool_name = tool["name"]
        description = tool["description"]
        params = tool["params"]
        
        print(f"\n📋 Test {i:2d}/{len(REMAINING_TOOLS)}: {tool_name}")
        print(f"📝 Açıklama: {description}")
        print(f"⚙️  Parametreler: {params}")
        print("-" * 50)
        
        start_time = time.time()
        result = call_single_tool(tool_name, params)
        duration = time.time() - start_time
        
        if result["status"] == "success":
            print(f"✅ BAŞARILI (HTTP {result['code']}) - {duration:.2f}s")
            print(f"📄 Mesaj: {result['message']}")
        else:
            print(f"❌ BAŞARISIZ (HTTP {result['code']}) - {duration:.2f}s")
            print(f"🚨 Hata: {result['message']}")
        
        results.append({
            "tool": tool_name,
            "description": description,
            "status": result["status"],
            "code": result["code"],
            "duration": duration,
            "message": result["message"]
        })
        
        # Tool'lar arası kısa bekleme
        time.sleep(0.5)
    
    # Özet rapor
    print("\n" + "=" * 70)
    print("📊 KALAN TOOL'LAR TEST SONUÇLARI")
    print("=" * 70)
    
    successful = len([r for r in results if r["status"] == "success"])
    failed = len([r for r in results if r["status"] == "error"])
    
    print(f"✅ Başarılı: {successful}/{len(results)}")
    print(f"❌ Başarısız: {failed}/{len(results)}")
    print(f"📈 Başarı Oranı: {(successful/len(results)*100):.1f}%")
    
    print(f"\n📋 Detaylı Sonuçlar:")
    for result in results:
        status_icon = "✅" if result["status"] == "success" else "❌"
        print(f"  {status_icon} {result['tool']:35} ({result['duration']:.2f}s)")
    
    if failed > 0:
        print(f"\n🚨 Başarısız Tool'lar:")
        for result in results:
            if result["status"] == "error":
                print(f"  ❌ {result['tool']}: {result['message']}")
    
    print("\n🎉 Kalan tool test'leri tamamlandı!")

if __name__ == "__main__":
    main()
