# Security Policy

## Reporting a vulnerability

Please **don't** open a public issue. Email **jastek.sweeney@gmail.com** with the affected resource or file and reproduction steps.

This is a lab reference architecture, not a hardened production system.

---

## Security model

**Governing rule:** customer apps may run in every region, but syslog durability and personal data stay inside Japan and travel over private Transit Gateway paths, never the public internet or VPN.

| Layer | Responsible for | Not responsible for |
|---|---|---|
| Regional ALB + app SG | Public HTTP :80 only. App instances accept traffic from the ALB SG only. | TLS (deliberately out of scope under lab limits) |
| WAFv2 (Tokyo ALB) | Managed-rule filtering at the Tokyo edge | Other regions' edges |
| Syslog tier SGs | Ingress from VPC / TGW CIDRs only, no public listeners | Application-level log content |
| Transit Gateway | Private cross-region routing into Tokyo | Encryption beyond AWS backbone defaults |
| Tokyo database | Aurora in private subnets, KMS at rest, credentials in Secrets Manager via VPC endpoints | PII redaction inside log lines |
| Ops access | SSM Session Manager, **no public SSH** | |

Explicitly **not** provided: application-level PII redaction, SIEM features (parsing, retention policy, alerting), or per-line encryption beyond RDS + KMS at rest.

## Secrets

| Secret | Where | Never |
|---|---|---|
| Aurora master credentials | Secrets Manager (`tok-syslog-aurora-credentials`), read by instance role via VPC endpoint | In tfvars, user-data, or code |
| Grafana Cloud / PDC tokens | SSM SecureString under `/zion/observability/` | In `terraform.tfvars` |
| Grafana admin password | Generated, available via `terraform output` (sensitive) | Committed |

The server's instance role writes PDC values to a `0600` env file at boot.

## Repository hygiene

This repository is **public**.

- Gitignored: `*.tfstate`, `*.tfvars`, `*.json` (Cost Explorer exports, state JSON).
- [`terraform.tfvars.example`](terraform.tfvars.example) documents variables with placeholders.
- **Watch for:** `terraform-plan-output.txt`, `terraform-state-evidence.txt`, `terraform-state-list.txt`, and `ce-*.txt` are currently untracked but **not** ignored. Plan and state dumps contain account IDs, ARNs, and endpoints. Keep them out of commits, or add them to `.gitignore`.

## Recommended checks

```bash
terraform validate
checkov -d . --framework terraform
./test/verify.sh      # includes "HTTPS blocked", "Aurora not public", "syslog has no public IP"
```

Testing detail: [`docs/TESTING.md`](docs/TESTING.md).
