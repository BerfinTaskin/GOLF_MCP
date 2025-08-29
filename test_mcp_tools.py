#!/usr/bin/env python3
"""
MCP Tool Test Client
Bu script MCP server'ındaki tool'ları SSE üzerinden test eder
"""

import asyncio
import aiohttp
import json
import sys
from datetime import datetime

# Test edilecek tool'lar ve parametreleri
TEST_TOOLS = [
    {
        "name": "hello_say",
        "params": {
            "name": "Test User",
            "greeting": "Merhaba",
            "personalized": False
        }
    },
    {
        "name": "calculator",
        "params": {
            "ifade": "10 + 5 * 2",
            "acikla": False
        }
    },
    # Database tool'ları - test verileri ile
    {
        "name": "depo_stok_miktarlari",
        "params": {
            "firma": "CMPBHLFKRMD205",
            "lojistikdepo": "DEP421"
        }
    },
    {
        "name": "ayrintili_depo_hareket_raporu",
        "params": {
            "firma": "CMPBHLFKRMD205", 
            "lojistikdepo": "DEP421",
            "tarih1": "2024-01-01",
            "tarih2": "2024-01-31"
        }
    },
    {
        "name": "genel_master_rapor",
        "params": {
            "firma": "CMP59BHUBJ1126",
            "tarih1": "2024-01-01",
            "tarih2": "2024-01-31"
        }
    }
]

BASE_URL = "http://172.22.10.39:3000"
AUTH_TOKEN = "dev-token-123"

class MCPTestClient:
    def __init__(self):
        self.session = None
        self.session_id = None
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        await self.get_session_id()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def get_session_id(self):
        """SSE endpoint'inden session ID al"""
        try:
            headers = {
                "Authorization": f"Bearer {AUTH_TOKEN}",
                "Accept": "text/event-stream"
            }
            
            async with self.session.get(f"{BASE_URL}/sse", headers=headers) as response:
                if response.status == 200:
                    async for line in response.content:
                        line = line.decode('utf-8').strip()
                        if line.startswith('data: /messages/?session_id='):
                            self.session_id = line.split('session_id=')[1]
                            print(f"✅ Session ID alındı: {self.session_id}")
                            break
                        # İlk event'i aldıktan sonra bağlantıyı kapat
                        break
        except Exception as e:
            print(f"❌ Session ID alınamadı: {e}")
            
    async def list_tools(self):
        """Tool'ları listele"""
        if not self.session_id:
            print("❌ Session ID yok")
            return None
            
        try:
            headers = {
                "Authorization": f"Bearer {AUTH_TOKEN}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/list",
                "params": {}
            }
            
            url = f"{BASE_URL}/messages/?session_id={self.session_id}"
            
            async with self.session.post(url, headers=headers, json=payload) as response:
                if response.status == 200:
                    result = await response.json()
                    return result
                else:
                    text = await response.text()
                    print(f"❌ Tools list error: {response.status} - {text}")
                    return None
                    
        except Exception as e:
            print(f"❌ Tools list error: {e}")
            return None
    
    async def call_tool(self, tool_name, params):
        """Bir tool'u çağır"""
        if not self.session_id:
            print("❌ Session ID yok")
            return None
            
        try:
            headers = {
                "Authorization": f"Bearer {AUTH_TOKEN}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": tool_name,
                    "arguments": params
                }
            }
            
            url = f"{BASE_URL}/messages/?session_id={self.session_id}"
            
            async with self.session.post(url, headers=headers, json=payload) as response:
                result = await response.json()
                return result
                
        except Exception as e:
            print(f"❌ Tool call error: {e}")
            return None

async def test_tools():
    """Tool'ları test et"""
    print("🏌️ MCP Tool Test Suite")
    print("=" * 60)
    print(f"🕐 Test başlangıcı: {datetime.now()}")
    print(f"🌐 Server: {BASE_URL}")
    print("=" * 60)
    
    async with MCPTestClient() as client:
        if not client.session_id:
            print("❌ Session ID alınamadı, test iptal ediliyor")
            return
            
        # Tool'ları listele
        print("\n📋 Mevcut tool'ları listeleniyor...")
        tools_result = await client.list_tools()
        
        if tools_result and "result" in tools_result:
            tools = tools_result["result"].get("tools", [])
            print(f"✅ {len(tools)} tool bulundu:")
            for tool in tools:
                print(f"  - {tool.get('name', 'Unknown')}: {tool.get('description', 'No description')}")
        else:
            print("❌ Tool'lar listelenemedi")
            print(f"Response: {tools_result}")
        
        # Her test case'ini çalıştır
        print(f"\n🧪 {len(TEST_TOOLS)} tool test ediliyor...")
        
        for i, test_case in enumerate(TEST_TOOLS, 1):
            tool_name = test_case["name"]
            params = test_case["params"]
            
            print(f"\n{'-'*40}")
            print(f"🔧 Test {i}/{len(TEST_TOOLS)}: {tool_name}")
            print(f"📝 Parametreler: {params}")
            print(f"{'-'*40}")
            
            result = await client.call_tool(tool_name, params)
            
            if result:
                if "result" in result:
                    print("✅ Tool başarıyla çalıştı!")
                    tool_result = result["result"]
                    
                    # Content varsa göster
                    if "content" in tool_result:
                        content = tool_result["content"]
                        if isinstance(content, list) and content:
                            for item in content[:2]:  # İlk 2 item'ı göster
                                if "text" in item:
                                    text = item["text"]
                                    if len(text) > 200:
                                        text = text[:200] + "..."
                                    print(f"📄 İçerik: {text}")
                        else:
                            print(f"📄 İçerik: {content}")
                    else:
                        print(f"📄 Sonuç: {tool_result}")
                        
                elif "error" in result:
                    error = result["error"]
                    print(f"❌ Tool hatası: {error.get('message', 'Unknown error')}")
                    if "code" in error:
                        print(f"   Hata kodu: {error['code']}")
                else:
                    print(f"❓ Beklenmeyen sonuç: {result}")
            else:
                print("❌ Tool çağrısı başarısız")
                
            # Test'ler arası kısa bekleme
            await asyncio.sleep(0.5)
    
    print(f"\n{'='*60}")
    print("🎉 Test Suite Tamamlandı!")
    print(f"🕐 Test bitişi: {datetime.now()}")
    print(f"{'='*60}")

if __name__ == "__main__":
    asyncio.run(test_tools())
