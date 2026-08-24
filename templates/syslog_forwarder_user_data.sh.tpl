#!/bin/bash
set -euo pipefail

yum update -y
yum install -y httpd nmap-ncat || yum install -y httpd nc
systemctl start httpd
systemctl enable httpd

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 &> /tmp/local_ipv4 &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone &> /tmp/az &
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ &> /tmp/macid &
wait

macid=$(cat /tmp/macid)
local_ipv4=$(cat /tmp/local_ipv4)
az=$(cat /tmp/az)
vpc=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$macid/vpc-id)

cat <<-HTML > /var/www/html/index.html
<!doctype html>
<html lang="en" class="h-100">
<head>
<title>Details for EC2 instance</title>
</head>
<body>
<div>
<h1>${headline_line1}</h1>
<h1>${headline_line2}</h1>
<p><b>Instance Name:</b> $(hostname -f) </p>
<p><b>Instance Private Ip Address: </b> $local_ipv4</p>
<p><b>Availability Zone: </b> $az</p>
<p><b>Virtual Private Cloud (VPC):</b> $vpc</p>
<p><b>Tokyo syslog endpoint (TGW):</b> ${tokyo_syslog_endpoint}:443</p>
</div>
</body>
</html>
HTML

rm -f /tmp/local_ipv4 /tmp/az /tmp/macid

install -d -m 0750 /opt/syslog-forwarder
cat >/opt/syslog-forwarder/env.sh <<EOF
export TOKYO_SYSLOG_ENDPOINT="${tokyo_syslog_endpoint}"
export TOKYO_SYSLOG_PORT="443"
export SITE_NAME="${display_name}"
EOF
chmod 0640 /opt/syslog-forwarder/env.sh

# Send one line to Tokyo private NLB over Transit Gateway (no VPN / no public path).
cat >/usr/local/bin/syslog-forward.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
source /opt/syslog-forwarder/env.sh

HOST="$(hostname -f)"
MSG="$${1:-[$${SITE_NAME}] heartbeat from $${HOST} at $(date -u +%Y-%m-%dT%H:%M:%SZ)}"
# Protocol: SOURCE_HOST|MESSAGE (parsed by Tokyo storage listener)
LINE="$${HOST}|$${MSG}"

if command -v ncat >/dev/null 2>&1; then
  printf '%s\n' "$LINE" | ncat -w 5 "$TOKYO_SYSLOG_ENDPOINT" "$TOKYO_SYSLOG_PORT"
else
  printf '%s\n' "$LINE" | nc -w 5 "$TOKYO_SYSLOG_ENDPOINT" "$TOKYO_SYSLOG_PORT"
fi
SCRIPT
chmod 0755 /usr/local/bin/syslog-forward.sh

# Accept local VPC syslog on TCP/443 and re-forward each line to Japan.
cat >/usr/local/bin/syslog-forward-listener.sh <<'LISTENER'
#!/bin/bash
set -euo pipefail
source /opt/syslog-forwarder/env.sh

while true; do
  if command -v ncat >/dev/null 2>&1; then
    ncat -l 443 --keep-open --recv-only 2>/dev/null | while IFS= read -r line; do
      [ -z "$line" ] && continue
      /usr/local/bin/syslog-forward.sh "$line" || true
    done
  else
    nc -l -p 443 | while IFS= read -r line; do
      [ -z "$line" ] && continue
      /usr/local/bin/syslog-forward.sh "$line" || true
    done
  fi
  sleep 1
done
LISTENER
chmod 0755 /usr/local/bin/syslog-forward-listener.sh

cat >/etc/systemd/system/syslog-forward-listener.service <<'UNIT'
[Unit]
Description=Foreign syslog forwarder listener (local TCP/443 -> Tokyo via TGW)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/syslog-forward-listener.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

cat >/etc/systemd/system/syslog-forward-heartbeat.service <<'UNIT'
[Unit]
Description=Forward syslog heartbeat to Tokyo over Transit Gateway
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/syslog-forward.sh
UNIT

cat >/etc/systemd/system/syslog-forward-heartbeat.timer <<'UNIT'
[Unit]
Description=Foreign syslog TGW heartbeat every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=syslog-forward-heartbeat.service

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now syslog-forward-listener.service
systemctl enable --now syslog-forward-heartbeat.timer

# Prove TGW path as soon as Tokyo listener is reachable
for i in $(seq 1 30); do
  if /usr/local/bin/syslog-forward.sh "[${display_name}] forwarder online"; then
    break
  fi
  sleep 10
done
