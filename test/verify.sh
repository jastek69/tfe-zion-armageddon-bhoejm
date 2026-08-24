#!/usr/bin/env bash
# Verification suite for Zion Armageddon v102.
# Run from repo root:  ./test/verify.sh
# Requires: terraform, aws, curl; optional: jq, python3

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REGION_TOKYO="ap-northeast-1"
DOMAIN="${DOMAIN_NAME:-jastek.click}"
PASS=0
FAIL=0
SKIP=0

green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

pass() { green "PASS: $*"; PASS=$((PASS + 1)); }
fail() { red "FAIL: $*"; FAIL=$((FAIL + 1)); }
skip() { yellow "SKIP: $*"; SKIP=$((SKIP + 1)); }

need() {
  command -v "$1" >/dev/null 2>&1 || {
    fail "missing required command: $1"
    exit 1
  }
}

need terraform
need aws
need curl

echo "=== Zion Armageddon verification ==="
echo "Repo: $ROOT"
echo

# --- Terraform outputs ---
out() {
  terraform output -raw "$1" 2>/dev/null || true
}

TOK_LB="$(out tok-lb_dns_name)"
NY_LB="$(out ny-lb_dns_name)"
LON_LB="$(out lon-lb_dns_name)"
AUS_LB="$(out aus-lb_dns_name)"
CA_LB="$(out ca-lb_dns_name)"
HK_LB="$(out hk-lb_dns_name)"
SAO_LB="$(out sao-lb_dns_name)"
DB_ENDPOINT="$(out tokyo_syslog_db_endpoint)"
SYSLOG_NLB="$(out tokyo_syslog_nlb_dns_name)"

if [[ -z "$TOK_LB" ]]; then
  fail "terraform outputs unavailable — run from applied workspace"
  exit 1
fi
pass "terraform outputs readable"

if [[ -n "$SYSLOG_NLB" ]]; then
  pass "tokyo_syslog_nlb_dns_name=$SYSLOG_NLB"
else
  fail "tokyo_syslog_nlb_dns_name missing (foreign forwarders need it)"
fi

# --- HTTP 80 on regional ALBs ---
check_http() {
  local name="$1" host="$2"
  if [[ -z "$host" ]]; then
    skip "HTTP $name (no output)"
    return
  fi
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 20 "http://${host}/" || true)"
  if [[ "$code" == "200" ]]; then
    pass "HTTP :80 $name → $code"
  else
    fail "HTTP :80 $name → $code (expected 200)"
  fi
}

check_http "tokyo" "$TOK_LB"
check_http "newyork" "$NY_LB"
check_http "london" "$LON_LB"
check_http "australia" "$AUS_LB"
check_http "california" "$CA_LB"
check_http "hongkong" "$HK_LB"
check_http "saopaulo" "$SAO_LB"

# --- HTTPS 443 must NOT connect (timeout / fail) ---
https_code="$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 8 --max-time 15 "https://${TOK_LB}/" || true)"
https_exit=0
curl -sk -o /dev/null --connect-timeout 8 --max-time 15 "https://${TOK_LB}/" || https_exit=$?
if [[ "$https_exit" -ne 0 ]] || [[ "$https_code" == "000" ]]; then
  pass "HTTPS :443 tokyo blocked (exit=$https_exit code=$https_code)"
else
  fail "HTTPS :443 tokyo unexpectedly succeeded (code=$https_code)"
fi

# --- DNS apex resolves ---
if command -v nslookup >/dev/null 2>&1; then
  if nslookup "$DOMAIN" >/dev/null 2>&1; then
    pass "DNS resolves $DOMAIN"
  else
    fail "DNS does not resolve $DOMAIN"
  fi
else
  skip "nslookup not available"
fi

# --- Aurora cluster ---
if [[ -n "$DB_ENDPOINT" ]]; then
  status="$(aws rds describe-db-clusters --region "$REGION_TOKYO" \
    --db-cluster-identifier tok-syslog-aurora \
    --query 'DBClusters[0].Status' --output text 2>/dev/null || echo missing)"
  if [[ "$status" == "available" ]]; then
    pass "Aurora tok-syslog-aurora status=available"
  else
    fail "Aurora status=$status (expected available)"
  fi

  pub="$(aws rds describe-db-instances --region "$REGION_TOKYO" \
    --filters Name=db-cluster-id,Values=tok-syslog-aurora \
    --query 'DBInstances[0].PubliclyAccessible' --output text 2>/dev/null || echo unknown)"
  if [[ "$pub" == "False" || "$pub" == "false" ]]; then
    pass "Aurora instance PubliclyAccessible=false"
  else
    fail "Aurora PubliclyAccessible=$pub (expected false)"
  fi
else
  skip "Aurora checks (no tokyo_syslog_db_endpoint output)"
fi

# --- Secrets Manager ---
secret_ok="$(aws secretsmanager get-secret-value --region "$REGION_TOKYO" \
  --secret-id tok-syslog-aurora-credentials \
  --query 'SecretString' --output text 2>/dev/null || true)"
if [[ -n "$secret_ok" ]]; then
  pass "Secrets Manager tok-syslog-aurora-credentials readable"
else
  fail "Cannot read tok-syslog-aurora-credentials"
fi

# --- Tokyo syslog EC2 ---
inst_json="$(aws ec2 describe-instances --region "$REGION_TOKYO" \
  --filters "Name=tag:Name,Values=tok-syslog-instance" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{Id:InstanceId,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress}' \
  --output json 2>/dev/null || echo '[]')"

inst_id="$(echo "$inst_json" | sed -n 's/.*"Id": "\(i-[^"]*\)".*/\1/p' | head -1)"
pub_ip="$(echo "$inst_json" | sed -n 's/.*"PublicIp": "\([^"]*\)".*/\1/p' | head -1)"

if [[ -n "$inst_id" ]]; then
  pass "Tokyo syslog instance running ($inst_id)"
else
  fail "No running tok-syslog-instance in $REGION_TOKYO"
fi

if [[ -z "$pub_ip" || "$pub_ip" == "None" || "$pub_ip" == "null" ]]; then
  pass "Tokyo syslog has no public IP (private subnet)"
else
  fail "Tokyo syslog has public IP $pub_ip (should be private)"
fi

# --- SSM managed instance ---
if [[ -n "$inst_id" ]]; then
  ping_status="$(aws ssm describe-instance-information --region "$REGION_TOKYO" \
    --filters "Key=InstanceIds,Values=${inst_id}" \
    --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || echo None)"
  if [[ "$ping_status" == "Online" ]]; then
    pass "SSM PingStatus=Online for $inst_id"

    cmd_id="$(aws ssm send-command --region "$REGION_TOKYO" \
      --instance-ids "$inst_id" \
      --document-name "AWS-RunShellScript" \
      --parameters 'commands=["/usr/local/bin/syslog-db-write.sh verify-suite-$(date -u +%Y%m%dT%H%M%SZ)","echo SSM_DB_WRITE_OK"]' \
      --query 'Command.CommandId' --output text 2>/dev/null || true)"

    if [[ -n "$cmd_id" && "$cmd_id" != "None" ]]; then
      sleep 8
      cmd_status="$(aws ssm get-command-invocation --region "$REGION_TOKYO" \
        --command-id "$cmd_id" --instance-id "$inst_id" \
        --query 'Status' --output text 2>/dev/null || echo Failed)"
      if [[ "$cmd_status" == "Success" ]]; then
        pass "SSM Run Command syslog-db-write succeeded"
      else
        fail "SSM Run Command status=$cmd_status (command-id=$cmd_id)"
      fi
    else
      fail "SSM send-command failed"
    fi
  else
    fail "SSM PingStatus=$ping_status for $inst_id (apply SSM endpoints/IAM, wait 2-5 min)"
  fi
else
  skip "SSM checks (no instance id)"
fi

echo
echo "=== Summary: $PASS passed, $FAIL failed, $SKIP skipped ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
