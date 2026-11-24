#!/bin/bash
# Run once with sudo: installs the host nginx site and gets the TLS certificate for scanguard.ptitai.org.
set -euo pipefail
D=scanguard.ptitai.org
SRC="$(dirname "$0")/$D.nginx"
# Phase 1: HTTP-only (the 443 block needs the cert to exist).
sed '/listen 443/,$d' "$SRC" | sed '$d' > /etc/nginx/sites-available/$D
ln -sf /etc/nginx/sites-available/$D /etc/nginx/sites-enabled/$D
nginx -t && systemctl reload nginx
certbot certonly --webroot -w /var/www/letsencrypt -d $D --non-interactive --agree-tos --register-unsafely-without-email --keep-until-expiring
# Phase 2: full config with 443.
cp "$SRC" /etc/nginx/sites-available/$D
nginx -t && systemctl reload nginx
echo "OK: https://$D"
