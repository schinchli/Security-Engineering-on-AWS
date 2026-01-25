#!/bin/bash
set -e

echo "=============================================="
echo "   AWS WAF Protection Test"
echo "=============================================="

if [ -z "$CF_DOMAIN" ] && [ -z "$CF_ID" ]; then
  echo "Set CF_ID or CF_DOMAIN environment variable"
  exit 1
fi

if [ -z "$CF_DOMAIN" ]; then
  CF_DOMAIN=$(aws cloudfront get-distribution --id "$CF_ID" \
    --query 'Distribution.DomainName' --output text)
fi

echo "Testing: https://$CF_DOMAIN"

# Test normal request
echo -n "Normal request... "
CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$CF_DOMAIN/" 2>/dev/null)
[ "$CODE" == "200" ] && echo "PASSED (HTTP $CODE)" || echo "FAILED (HTTP $CODE)"

# Test SQL injection
echo -n "SQL Injection block... "
CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$CF_DOMAIN/?id=1'%20OR%20'1'='1" 2>/dev/null)
[ "$CODE" == "403" ] && echo "PASSED (HTTP $CODE)" || echo "FAILED (HTTP $CODE)"

# Test XSS
echo -n "XSS block... "
CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$CF_DOMAIN/?q=%3Cscript%3Ealert(1)%3C/script%3E" 2>/dev/null)
[ "$CODE" == "403" ] && echo "PASSED (HTTP $CODE)" || echo "FAILED (HTTP $CODE)"

echo "Testing complete!"
