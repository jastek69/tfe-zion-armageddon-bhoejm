# Zion Armageddon v102

Multi-region AWS lab: local app hosting in seven cities, Transit Gateway mesh to Japan, geo DNS, and Tokyo-only syslog storage.

---

# Executive Summary

This repository provisions a multi-region AWS footprint for local application hosting in Tokyo, New York, London, São Paulo, Australia, Hong Kong, and California. Each site runs a public HTTP (port 80) application tier and a private syslog tier. Cross-region private routing uses Transit Gateway peering into Tokyo. Public DNS uses Route53 geolocation so clients resolve to a nearby regional load balancer, with unmatched traffic defaulting to Tokyo.

Stage 2 adds Japan-only Aurora MySQL for syslog persistence: Tokyo private syslog instances write events into RDS over private networking, using Secrets Manager credentials reached via VPC endpoints. The stack is expressed as Terraform modules (`regional-network`, `regional-site`, `hub`, `tokyo-database`) rather than seven copy-pasted region file sets. Correctness is verified with `terraform validate` / `plan` / `apply`, Route53 geo resolution, and inserts into the Tokyo `syslog_events` table.

---

## Problem

- Seven near-identical regional stacks were maintained as separate Terraform files, so a single change required seven edits and drift was common.
- Customer traffic had to be served locally, but a single apex DNS record sent everyone to Tokyo.
- Syslog and personal data could not be stored abroad; transfer had to reach Japan without VPN, and public ports beyond 80 were disallowed.
- Stage 1 accidentally mixed Stage 2 concerns (public HTTPS, RDS early, syslog on public ALBs), which would fail the lab’s hard limitations.

---

## Solution

- One `regional-network` + `regional-site` module pair per city, driven by a central `locals.sites` map, with Transit Gateway and hub services kept at the root / `hub` module.
- Route53 geolocation records map country, US subdivision, and continent to the matching regional ALB; default is Tokyo.
- Public path is HTTP :80 only. Syslog lives in private subnets; foreign sites forward; Tokyo stores. Durable syslog data lands in private Aurora in Tokyo only, written by the Tokyo syslog ASG (IAM + Secrets Manager + VPC endpoints).
- Governing rule: **customer apps may run in every region; syslog durability and personal data stay inside Japan’s borders, over private TGW paths—not the public internet or VPN.**

---

## Architecture

```
Internet
   |
   v
Route53 geo (jastek.click)
   |-- JP/AS/default --> Tokyo ALB :80 --> ASG app (public)
   |-- NY/CA/NA      --> US regional ALBs
   |-- GB/EU         --> London ALB
   |-- BR/SA         --> Sao Paulo ALB
   |-- AU/OC         --> Australia ALB
   |-- HK            --> Hong Kong ALB
   |
Private (each region)
   ASG syslog forwarder (private) --TGW--> Tokyo syslog NLB :443 --> ASG storage
                                                                      |
                                                                      v
                                                            Aurora MySQL (Tokyo private)
                                                            Secrets Manager via VPC endpoints
```

| Layer | Role |
|---|---|
| `regional-network` | VPC, public/private/TGW subnets, IGW, route table |
| `regional-site` | ALB :80, app ASG, private syslog ASG, locked SGs; Tokyo also gets private syslog NLB |
| Transit Gateway | Per-region TGW, VPC attachments, inter-region peering to Tokyo |
| `hub` | Geo DNS, query logging (us-east-1), WAF on Tokyo ALB, Lambda/alarms |
| `tokyo-database` | KMS-encrypted Aurora, Secrets Manager, VPC endpoints for private API access |

Foreign syslog tiers are **forwarders**: minute heartbeats plus a local TCP/443 listener that re-ships lines to the Tokyo private NLB over TGW. Tokyo syslog is `storage` mode and owns DB writes.

---

## Technologies

| Domain | Services |
|---|---|
| Compute | EC2, Auto Scaling, Launch Templates (Amazon Linux 2) |
| Networking | VPC, ALB (HTTP only), Transit Gateway + inter-region peering |
| DNS / edge | Route53 (geolocation + query logging), WAFv2 (Tokyo) |
| Data (Japan only) | Aurora MySQL, Secrets Manager, KMS |
| Private AWS API access | VPC endpoints: S3, Secrets Manager, KMS, SSM / ssmmessages / ec2messages |
| Ops access | SSM Session Manager (Tokyo syslog; no public SSH) |
| IaC | Terraform ~> AWS provider 5.46, modules under `modules/` |
| State | S3 backend (`taaops-terraform-state-tokyo`) |

---

## Deployment

**Prerequisites:** AWS credentials for an account that can create resources in all seven regions; Terraform installed; Route53 public hosted zone for `jastek.click` (or set `var.domain_name`); S3 state bucket already created.

```bash
terraform init
terraform plan
terraform apply
```

Teardown:

```bash
terraform destroy
```

The hub S3 bucket used for resolver query logs has `force_destroy = true`. Aurora (`db.t3.medium` × 2) dominates idle cost—destroy when not demonstrating. Detailed verification and failure recovery: [docs/RUNBOOK.md](docs/RUNBOOK.md). Automated checks:

```bash
./test/verify.sh
# or
pip install boto3 && python test/verify.py
```

---

## Security

- **Public edge:** Only port 80 on regional ALBs. App instances accept HTTP only from the ALB security group.
- **Syslog:** Private subnets; no public ALB attachment. Ingress limited to VPC / TGW CIDRs. Tokyo storage accepts foreign VPC CIDRs over TGW for forwarders.
- **Data residency:** Aurora and durable syslog rows exist only in Tokyo private subnets. Master credentials live in Secrets Manager; instances read them via IAM role + VPC endpoints (no public NAT required for that path).
- **Not responsible for:** Application-level PII redaction, full SIEM product features, or encrypting every log line beyond RDS/KMS at rest. Those are Stage 2+ product concerns.

Nothing sensitive is intended to be stored outside Japan. VPN is not used for cross-region syslog transfer.

---

## Repository Structure

```
.
├── modules/
│   ├── regional-network/   # VPC + subnets per site
│   ├── regional-site/      # ALB, ASGs, SGs, optional Tokyo DB wiring
│   ├── hub/                # Geo DNS, WAF, query logging, alarms
│   └── tokyo-database/     # Aurora + secrets + VPC endpoints
├── templates/              # EC2 user-data (app + syslog storage)
├── test/                   # verify.sh + verify.py
├── network.tf / sites.tf   # Seven network + site module calls
├── transit-gateway.tf      # TGW mesh + hub/spoke routes
├── hub.tf / database.tf    # Hub + Tokyo syslog DB
├── locals.tf               # sites map, tags, CIDRs
└── providers.tf            # Multi-region providers + S3 backend
```

| Document | Covers |
|---|---|
| `README.md` | Project overview, architecture, security model |
| `docs/RUNBOOK.md` | Deploy, verify (geo DNS, ALBs, syslog→Aurora), teardown, common failures |
| `test/verify.sh` | Bash verification suite (ALB, HTTPS blocked, RDS, Secrets, SSM) |
| `test/verify.py` | Python verification suite (same checks via boto3) |

---

## Lessons Learned

- **ALB `name_prefix` maxes out at 6 characters.** Values like `aus-alb-` fail validation; use fixed `name` values under the 32-character limit instead.
- **Route53 public query logging only accepts CloudWatch log groups in `us-east-1`.** Pointing at a Tokyo log group yields “ARN is invalid,” not a clear region error.
- **Module refactors create circular dependencies when A needs B’s SG and B needs A’s endpoint.** Lift the shared security group to the root so both modules consume it.
- **Private-subnet writers cannot reach Secrets Manager without NAT or VPC endpoints.** Interface endpoints for Secrets Manager/KMS (plus S3 gateway for yum) were required for Tokyo syslog→RDS wiring.
- **`count` cannot depend on values unknown until apply.** Gate IAM/DB wiring with `enable_syslog_db` (bool), not the Aurora endpoint string.

---

## Future Improvements

- **Geo DNS coverage** can be extended with more country records; US coverage today is NY/CA subdivisions plus NA continent fallback.
- **SIEM product layer** (real log parsing, retention policies, alerting) is still a stub beyond `syslog_events` inserts.
- **NAT for private app debugging** would help ops without opening SSH; Tokyo syslog already uses SSM Session Manager.
