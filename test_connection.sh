#!/bin/bash

echo "🔍 Testing connection to backend API..."
echo ""

# Test 1: Basic connectivity
echo "1️⃣ Testing HTTPS connection to api.carbonvoice.app..."
if curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://api.carbonvoice.app/oauth/token | grep -q "404\|405\|400"; then
    echo "✅ Connection successful! (Got HTTP response - endpoint may require POST, but connection works)"
else
    echo "❌ Connection failed!"
fi

echo ""
echo "2️⃣ Testing with verbose output..."
curl -v --max-time 5 https://api.carbonvoice.app/oauth/token 2>&1 | head -20

echo ""
echo "3️⃣ Checking firewall status..."
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
    echo "⚠️  Firewall is ENABLED"
    echo "   → This may be blocking the app's network connections"
    echo "   → Solution: Temporarily disable firewall in System Settings → Network → Firewall"
else
    echo "✅ Firewall is disabled"
fi

echo ""
echo "📝 Next steps:"
echo "   - If connection works but app doesn't: Firewall is blocking the app"
echo "   - If connection fails: Check internet/VPN/proxy settings"









