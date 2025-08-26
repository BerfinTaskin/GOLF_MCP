#!/bin/bash
# Security hardening script for Smart GMCP MCP Server

echo "🔒 Smart GMCP MCP Server Security Hardening"
echo "=========================================="

echo ""
echo "Current network exposure:"
netstat -tlnp | grep :3000

echo ""
echo "🛡️ Security Options:"
echo ""
echo "1. RESTRICT TO LOCALHOST ONLY (Most Secure)"
echo "   - Only local applications can connect"
echo "   - Prevents network access"
echo ""
echo "2. ADD FIREWALL RULES (Network + Protection)"
echo "   - Allow specific IPs only"
echo "   - Block unauthorized network access"
echo ""
echo "3. CHANGE AUTHENTICATION TOKENS (Essential)"
echo "   - Replace dev tokens with secure tokens"
echo "   - Use environment variables"
echo ""
echo "4. ENABLE HTTPS/TLS (Production)"
echo "   - Encrypt all communications"
echo "   - Prevent token interception"

echo ""
echo "To restrict to localhost only, set environment variable:"
echo "export HOST=127.0.0.1"
echo ""
echo "To use custom tokens, edit mcp_server/auth.py"
