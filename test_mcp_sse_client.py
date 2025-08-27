#!/usr/bin/env python3
import asyncio
import json
from mcp import ClientSession
from mcp.client.sse import sse_client

async def test_mcp_sse():
    """Test MCP SSE connection and GTİP report tool"""
    
    print("🔗 Connecting to MCP SSE server...")
    
    try:
        # Create SSE client
        client = sse_client(
            "http://172.22.10.39:3000/sse",
            headers={"Authorization": "Bearer dev-token-123"}
        )
        
        # Create client session
        async with ClientSession(client) as session:
            print("✅ Connected to MCP server!")
            
            # Initialize connection
            await session.initialize()
            print("🚀 Session initialized!")
            
            # List available tools
            tools_result = await session.list_tools()
            print(f"📋 Available tools: {len(tools_result.tools)}")
            
            # Look for our GTİP report tool
            gtip_tool = None
            for tool in tools_result.tools:
                print(f"🔧 Tool: {tool.name}")
                if "firma_beyannameleri_gtip_bazinda_rapor" in tool.name:
                    gtip_tool = tool
                    print(f"✅ Found GTİP report tool: {tool.name}")
                    break
            
            if gtip_tool:
                # Test the GTİP report tool
                print("\n🧪 Testing GTİP report tool...")
                result = await session.call_tool(
                    gtip_tool.name,
                    {
                        "firma": "CMP59BHUBJ1126",
                        "tarih1": "2025-01-01",
                        "tarih2": "2025-01-31"
                    }
                )
                
                print("✅ Tool executed successfully!")
                print(f"📊 Result type: {type(result)}")
                if hasattr(result, 'content') and result.content:
                    print(f"📄 Content length: {len(result.content)}")
                    # Show first part of content
                    for i, content in enumerate(result.content[:2]):
                        print(f"📝 Content {i+1}: {content.type} - {str(content.text)[:200]}...")
                else:
                    print(f"📄 Result: {result}")
            else:
                print("❌ GTİP report tool not found!")
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_mcp_sse())
