# Runbook — Zion Armageddon v102

Operational procedures for deploy, verify, and teardown. Architecture context lives in [README.md](../README.md).

---

## Prerequisites

| Requirement | Notes |
|---|---|
| AWS account | Permissions in all seven regions + `us-east-1` (Route53 query logs) |
| Terraform | Compatible with AWS provider `~> 5.46` |
| CLI | `aws`, `terraform`, `dig` or `nslookup` |
| Route53 | Public hosted zone for `jastek.click` (or override `domain_name`) |
| State backend | S3 bucket in `providers.tf` must already exist |

Optional: Session Manager access to private Tokyo syslog instances (no public SSH).

---

## Deploy

```bash
cd zion-armageddon-v102
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Useful outputs after apply:

```bash
terraform output
terraform output -raw tokyo_syslog_db_endpoint
terraform output -raw tokyo_syslog_db_secret_arn
terraform output tok-lb_dns_name
```

First apply can take a long time (seven regions, TGW peering, Aurora). Aurora typically finishes after the ALBs.

---

## Verify — regional app (port 80)

1. List ALB DNS names:

```bash
terraform output | findstr lb_dns
```

2. Hit each ALB over HTTP (expect 200 and the regional HTML page):

```bash
curl -sI "http://$(terraform output -raw tok-lb_dns_name)/"
curl -sI "http://$(terraform output -raw ny-lb_dns_name)/"
curl -sI "http://$(terraform output -raw lon-lb_dns_name)/"
# repeat for aus, ca, hk, sao
```

3. Confirm **no public HTTPS** on ALBs (connection should fail or not be served as an HTTPS listener):

```bash
curl -vk "https://$(terraform output -raw tok-lb_dns_name)/" || true
```

---

## Verify — Geo DNS

Domain defaults to `jastek.click` (`var.domain_name`).

1. Confirm geo records exist in Route53 (console: Hosted zone → records with Routing policy **Geolocation**), or:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id "$(terraform output -raw route53_zone_id)" \
  --query "ResourceRecordSets[?Name=='jastek.click.']" \
  --output table
```

2. Resolve from your network (result depends on your client location):

```bash
dig jastek.click A +short
# or
nslookup jastek.click
```

3. Expected mapping (summary):

| Client match | Target ALB |
|---|---|
| JP / Asia (AS) / default `*` | Tokyo |
| US-NY / North America (NA) | New York |
| US-CA | California |
| GB / Europe (EU) | London |
| BR / South America (SA) | São Paulo |
| AU / Oceania (OC) | Australia |
| HK | Hong Kong |

To force-check an ALB independently of geo, curl the `*_lb_dns_name` outputs directly (section above).

---

## Verify — Tokyo syslog → Aurora

### A. Confirm RDS is private and up

```bash
terraform output -raw tokyo_syslog_db_endpoint
aws rds describe-db-clusters --region ap-northeast-1 \
  --db-cluster-identifier tok-syslog-aurora \
  --query "DBClusters[0].{Status:Status,Endpoint:Endpoint,Subnets:DBSubnetGroup}"
```

Instances must show `PubliclyAccessible: false`.

### B. Confirm heartbeats are writing (Session Manager)

After applying SSM IAM (`AmazonSSMManagedInstanceCore`) and Tokyo VPC endpoints (`ssm`, `ssmmessages`, `ec2messages`), wait 2–5 minutes, then confirm the instance is Online:

```bash
aws ssm describe-instance-information --region ap-northeast-1 \
  --filters "Key=tag:Name,Values=tok-syslog-instance"
```

`PingStatus` must be `Online`. Start a session:

```bash
aws ssm start-session --region ap-northeast-1 --target i-xxxxxxxx
```

On the instance:

```bash
sudo /usr/local/bin/syslog-db-write.sh "runbook manual check"
```

Or run the automated suite from the repo root:

```bash
./test/verify.sh
# or
python test/verify.py
```

Manual SQL check (password from Secrets Manager):
# Inspect recent rows (password from Secrets Manager)
SECRET_ARN=$(aws secretsmanager list-secrets --region ap-northeast-1 \
  --query "SecretList[?Name=='tok-syslog-aurora-credentials'].ARN" --output text)
SECRET=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
HOST=$(echo "$SECRET" | jq -r .host)
USER=$(echo "$SECRET" | jq -r .username)
PASS=$(echo "$SECRET" | jq -r .password)
DB=$(echo "$SECRET" | jq -r .dbname)

mysql --protocol=TCP -h "$HOST" -u "$USER" -p"$PASS" "$DB" \
  -e "SELECT id, received_at, source_host, LEFT(message,80) AS message FROM syslog_events ORDER BY id DESC LIMIT 10;"
```

Expect rows from `syslog-db-heartbeat.timer` about once per minute and any manual writes.

### C. Confirm listener service

```bash
systemctl status syslog-db-listener.service
systemctl status syslog-db-heartbeat.timer
journalctl -u syslog-db-listener -n 50 --no-pager
```

### D. Foreign forwarder → Tokyo (TGW)

Foreign syslog instances run `syslog-forward-heartbeat.timer` and push `SOURCE|MESSAGE` lines to the Tokyo private NLB on TCP 443 over Transit Gateway (not VPN / not public internet).

1. Confirm the Tokyo NLB endpoint:

```bash
terraform output -raw tokyo_syslog_nlb_dns_name
```

2. On a **foreign** syslog instance (SSM or console; tagged `Tier=syslog-forwarder`):

```bash
systemctl status syslog-forward-heartbeat.timer
systemctl status syslog-forward-listener.service
sudo /usr/local/bin/syslog-forward.sh "runbook forwarder check"
```

3. On Tokyo storage, confirm the row landed (step B). `source_host` should be the foreign instance hostname; message should mention the site name (e.g. `[London]`).

### E. Optional — send a line to Tokyo syslog TCP 443

From a host that can reach the Tokyo syslog NLB over TGW:

```bash
NLB=$(terraform output -raw tokyo_syslog_nlb_dns_name)
echo "manual-test|forwarded test $(date -u)" | nc -w 3 "$NLB" 443
```

Then re-query `syslog_events` (step B).
---

## Verify — compliance spot checks

| Check | How |
|---|---|
| Public port 80 only | ALB listeners: only HTTP :80; SG on ALB allows 80 from `0.0.0.0/0` |
| App not open to world | App SG ingress = ALB SG only |
| Syslog private | Syslog ASG in private subnets; not registered to public ALB target groups |
| Syslog DB in Japan | Aurora in `ap-northeast-1`, private subnets, SG allows Tokyo syslog SG on 3306 only |
| No VPN for transfer | TGW peering + VPC routes only |

---

## Common failures

| Symptom | Likely cause | Fix |
|---|---|---|
| `name_prefix` longer than 6 characters | ALB/TG name_prefix too long | Use fixed `name` (already fixed in module) |
| Route53 query log “ARN invalid” | Log group not in `us-east-1` | Hub creates log group with `aws.us-east-1` |
| Invalid `count` on syslog IAM / SG | `count` depended on unknown resource IDs | Use `enable_syslog_db`, `create_syslog_security_group`, and `enable_syslog_forwarder` booleans (known at plan) |
| BucketNotEmpty on destroy | Objects in `jasopstokyo` | Bucket has `force_destroy`; or empty with `aws s3 rm s3://jasopstokyo --recursive` |
| Syslog cannot reach Secrets Manager | No NAT / endpoints | Ensure VPC endpoints for secretsmanager + kms applied |
| Syslog cannot `yum install` | No S3 gateway endpoint | Ensure S3 gateway endpoint on Tokyo route table |
| Geo always Tokyo | Client country unmatched | Expected for default `*`; curl regional ALB DNS to test apps |
| Circular dependency site ↔ DB | SG created inside site module | Shared `aws_security_group.tokyo_syslog` at root |

Targeted apply (only if plan cannot infer counts — prefer the boolean fix above):

```bash
terraform apply -target=module.tokyo_syslog_db
terraform apply
```

---

## Teardown

```bash
terraform destroy
```

If destroy stops on a non-empty S3 bucket:

```bash
aws s3 rm s3://jasopstokyo --recursive
aws s3 rb s3://jasopstokyo
terraform state rm 'module.hub.aws_s3_bucket.jasopstokyo'   # only if already gone in AWS
terraform destroy
```

Do **not** delete the Terraform state backend bucket (`taaops-terraform-state-tokyo`) unless you intend to abandon remote state.

---

## Cost note

Aurora (`db.t3.medium` × 2) and seven regional ASG/ALB footprints dominate cost. Destroy when not demonstrating. Heartbeat traffic to RDS is negligible; instance hours are not.
