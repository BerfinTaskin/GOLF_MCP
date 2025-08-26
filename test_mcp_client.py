#!/usr/bin/env python3
"""
Simple MCP client to test the Smart GMCP server
"""
import asyncio
import json
import aiohttp
from typing import Dict, Any

class MCPClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.token = token
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    async def test_connection(self):
        """Test basic connection to the server"""
        async with aiohttp.ClientSession() as session:
            try:
                # Test SSE endpoint which is the main MCP endpoint
                async with session.get(f"{self.base_url}/sse", headers=self.headers) as response:
                    print(f"✅ SSE endpoint status: {response.status}")
                    if response.status == 200:
                        print("✅ MCP Server SSE endpoint is accessible!")
                        return True
                    else:
                        print(f"❌ SSE endpoint returned: {response.status}")
                        return False
            except Exception as e:
                print(f"❌ Connection failed: {e}")
                return False
    
    async def list_tools(self):
        """List available MCP tools"""
        # This would be MCP protocol specific
        print("📋 Available tools in your MCP server:")
        tools = [
            "mcp_akilli-gmcp-r_arsiv_verileri",
            "mcp_akilli-gmcp-r_ayrintili_depo_hareket_raporu", 
            "mcp_akilli-gmcp-r_beyanname_bazinda_maliyet_raporu",
            "mcp_akilli-gmcp-r_calculator",
            "mcp_akilli-gmcp-r_depo_stok_miktarlari",
            "mcp_akilli-gmcp-r_genel_master_rapor",
            "mcp_akilli-gmcp-r_hello_say",
            "mcp_akilli-gmcp-r_is_emri_listesi",
            "mcp_akilli-gmcp-r_kullanilabilir_stok_raporu"
        ]
        for tool in tools:
            print(f"  - {tool}")
        return tools

async def main():
    print("🚀 Testing Smart GMCP MCP Server")
    print("=" * 50)
    
    # Test with dev token
    client = MCPClient("http://localhost:3000", "dev-token-123")
    
    # Test connection
    connected = await client.test_connection()
    if connected:
        print("✅ MCP Server is running and accessible!")
    else:
        print("❌ Could not connect to MCP Server")
        return
    
    # List available tools
    await client.list_tools()
    
    print("\n📝 Next steps:")
    print("1. Use an MCP-compatible client (like Claude Desktop)")
    print("2. Configure the client to connect to: http://localhost:3000/sse")
    print("3. Use token: dev-token-123")
    print("4. Test the reporting tools with your database")

if __name__ == "__main__":
    asyncio.run(main())
