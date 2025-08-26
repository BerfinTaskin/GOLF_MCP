#!/usr/bin/env python3
"""
Test specific MCP tools
"""
import asyncio
import json
import aiohttp

async def test_hello_tool():
    """Test the hello tool"""
    url = "http://localhost:3000/sse"
    headers = {
        'Authorization': 'Bearer dev-token-123',
        'Content-Type': 'application/json'
    }
    
    # MCP tool call payload
    payload = {
        "method": "tools/call",
        "params": {
            "name": "mcp_akilli-gmcp-r_hello_say",
            "arguments": {
                "name": "Smart GMCP User",
                "greeting": "Merhaba",
                "personalized": True
            }
        }
    }
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(url, headers=headers, json=payload) as response:
                print(f"Tool call status: {response.status}")
                result = await response.text()
                print(f"Tool result: {result}")
        except Exception as e:
            print(f"Error testing tool: {e}")

async def test_calculator_tool():
    """Test the calculator tool"""
    url = "http://localhost:3000/sse"
    headers = {
        'Authorization': 'Bearer dev-token-123',
        'Content-Type': 'application/json'
    }
    
    payload = {
        "method": "tools/call",
        "params": {
            "name": "mcp_akilli-gmcp-r_calculator",
            "arguments": {
                "ifade": "2 + 3 * 4",
                "acikla": True
            }
        }
    }
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(url, headers=headers, json=payload) as response:
                print(f"Calculator status: {response.status}")
                result = await response.text()
                print(f"Calculator result: {result}")
        except Exception as e:
            print(f"Error testing calculator: {e}")

async def main():
    print("🧪 Testing MCP Tools")
    print("=" * 30)
    
    print("\n1. Testing Hello Tool:")
    await test_hello_tool()
    
    print("\n2. Testing Calculator Tool:")
    await test_calculator_tool()

if __name__ == "__main__":
    asyncio.run(main())
