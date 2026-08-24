#!/bin/bash
set -euo pipefail

yum update -y
yum install -y httpd mariadb jq awscli
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
region=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

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
<p><b>Syslog DB endpoint:</b> ${db_endpoint}</p>
</div>
</body>
</html>
HTML

rm -f /tmp/local_ipv4 /tmp/az /tmp/macid

# --- Aurora syslog wiring (Japan-only storage) ---
install -d -m 0750 /opt/syslog-db
cat >/opt/syslog-db/env.sh <<EOF
export AWS_DEFAULT_REGION="$region"
export SYSLOG_DB_SECRET_ARN="${db_secret_arn}"
export SYSLOG_DB_HOST="${db_endpoint}"
export SYSLOG_DB_NAME="${db_name}"
export SYSLOG_DB_USER="${db_username}"
EOF
chmod 0640 /opt/syslog-db/env.sh

cat >/usr/local/bin/syslog-db-write.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
source /opt/syslog-db/env.sh

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SYSLOG_DB_SECRET_ARN" \
  --query SecretString \
  --output text)

DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')
DB_USER=$(echo "$SECRET_JSON" | jq -r '.username // empty')
DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host // empty')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.dbname // empty')

: "$${DB_USER:=$SYSLOG_DB_USER}"
: "$${DB_HOST:=$SYSLOG_DB_HOST}"
: "$${DB_NAME:=$SYSLOG_DB_NAME}"

MESSAGE="$${1:-heartbeat from $(hostname -f) at $(date -u +%Y-%m-%dT%H:%M:%SZ)}"
SOURCE_HOST="$${2:-$(hostname -f)}"

mysql --protocol=TCP -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
CREATE TABLE IF NOT EXISTS syslog_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  source_host VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  PRIMARY KEY (id),
  KEY idx_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO syslog_events (source_host, message)
VALUES ('$SOURCE_HOST', '$(echo "$MESSAGE" | sed "s/'/''/g")');
SQL
SCRIPT
chmod 0755 /usr/local/bin/syslog-db-write.sh

# Seed schema + prove connectivity
for i in $(seq 1 30); do
  if /usr/local/bin/syslog-db-write.sh "tokyo-syslog storage online"; then
    break
  fi
  sleep 10
done

# Accept forwarded syslog lines on TCP/443 and persist to Aurora.
# Protocol: SOURCE_HOST|MESSAGE (from foreign forwarders) or plain MESSAGE.
cat >/usr/local/bin/syslog-db-listener.sh <<'LISTENER'
#!/bin/bash
set -euo pipefail

persist_line() {
  local line="$1"
  local src msg
  if [[ "$line" == *"|"* ]]; then
    src="$${line%%|*}"
    msg="$${line#*|}"
  else
    src="forwarded"
    msg="$line"
  fi
  [ -z "$msg" ] && return 0
  /usr/local/bin/syslog-db-write.sh "$msg" "$src"
}

while true; do
  ncat -l 443 --keep-open --recv-only 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    persist_line "$line"
  done || nc -l -p 443 | while IFS= read -r line; do
    [ -z "$line" ] && continue
    persist_line "$line"
  done
done
LISTENER
chmod 0755 /usr/local/bin/syslog-db-listener.sh

yum install -y nmap-ncat || yum install -y nc || true

cat >/etc/systemd/system/syslog-db-listener.service <<'UNIT'
[Unit]
Description=Tokyo syslog TCP listener writing to Aurora
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/syslog-db-listener.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

cat >/etc/systemd/system/syslog-db-heartbeat.service <<'UNIT'
[Unit]
Description=Write syslog heartbeat to Tokyo Aurora
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/syslog-db-write.sh
UNIT

cat >/etc/systemd/system/syslog-db-heartbeat.timer <<'UNIT'
[Unit]
Description=Tokyo syslog DB heartbeat every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=syslog-db-heartbeat.service

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now syslog-db-listener.service
systemctl enable --now syslog-db-heartbeat.timer
