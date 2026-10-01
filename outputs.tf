#!/bin/bash
set -euo pipefail

# Install and configure NGINX
amazon-linux-extras enable nginx1
DNF_EXIT_CODE=0
dnf install -y nginx || DNF_EXIT_CODE=$?
if [ "$DNF_EXIT_CODE" -ne 0 ]; then
  echo "nginx installation failed" >&2
  exit "$DNF_EXIT_CODE"
fi

sed -i -E 's/listen\s+80;/listen 127.0.0.1:80;/; /listen\s+\[::\]:80;/d' /etc/nginx/nginx.conf
mkdir -p /etc/systemd/system/nginx.service.d
printf '[Service]\nRestart=on-failure\nRestartSec=5\n' > /etc/systemd/system/nginx.service.d/restart.conf
aws s3 sync s3://${bucket} /usr/share/nginx/html --region ${region}
nginx -t
systemctl daemon-reload
systemctl enable --now nginx

# Install Cloudflared and fetch the tunnel token from Parameter Store
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg
cat > /etc/yum.repos.d/cloudflared.repo <<'EOF'
[cloudflared]
name=cloudflared
baseurl=https://pkg.cloudflare.com/cloudflared/rhel/9/x86_64
enabled=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/keyrings/cloudflare-main.gpg
EOF

dnf install -y cloudflared
mkdir -p /etc/cloudflared
TOKEN=$(aws ssm get-parameter --name ${token_param} --with-decryption --query Parameter.Value --output text --region ${region})
echo "TUNNEL_TOKEN=$TOKEN" > /etc/cloudflared/token.env
chmod 600 /etc/cloudflared/token.env

CF_BIN=$(command -v cloudflared)
cat > /etc/systemd/system/cloudflared.service << UNIT
[Unit]
Description=Cloudflare Tunnel
After=network-online.target nginx.service
Wants=network-online.target
BindsTo=nginx.service

[Service]
EnvironmentFile=/etc/cloudflared/token.env
ExecStart=$CF_BIN --no-autoupdate tunnel run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target nginx.service
UNIT

systemctl daemon-reload
systemctl enable --now cloudflared
