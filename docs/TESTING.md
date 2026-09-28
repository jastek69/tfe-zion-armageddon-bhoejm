# Testing

This stack is infrastructure, so it's verified against a **live, applied deployment**. There are two layers: static checks before apply, and scripted verification after.

---

## 1. Static checks (before apply)

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -out=tfplan        # review; never commit tfplan
```

Things `plan` catches that have bitten this repo before (README, Lessons Learned):

- ALB `name_prefix` longer than 6 characters
- Route 53 query logging pointed at a non-`us-east-1` log group
- `count` depending on apply-time values (gate on `enable_syslog_db`, not the Aurora endpoint)

## 2. Scripted verification (after apply)

Run from the applied workspace. The scripts read `terraform output`.

```bash
./test/verify.sh
# or
pip install boto3 && python test/verify.py
```

Both implement the same checks and end with `Summary: N passed, N failed, N skipped`.

| # | Check | Proves |
|---|---|---|
| 1 | Terraform outputs readable | Run from the right workspace |
| 2 | `tokyo_syslog_nlb_dns_name` present | Foreign forwarders have a target |
| 3 | HTTP :80 → 200 for all seven regional ALBs | Public app tier up everywhere |
| 4 | HTTPS :443 on Tokyo **blocked** | Only port 80 is public (hard lab limit) |
| 5 | Domain resolves | Route 53 zone and records live |
| 6 | Aurora `tok-syslog-aurora` status `available` | Tokyo DB up |
| 7 | Aurora `PubliclyAccessible=false` | Data isn't reachable from the internet |
| 8 | Secrets Manager `tok-syslog-aurora-credentials` readable | Credential path works via IAM |
| 9 | Tokyo syslog instance running | Storage tier up |
| 10 | Tokyo syslog has **no public IP** | Storage stays private |
| 11 | SSM `PingStatus=Online` | Session Manager reachable over VPC endpoints |
| 12 | SSM Run Command `syslog-db-write` succeeds | End-to-end write into `syslog_events` over private networking |

Checks skip rather than fail when an output doesn't exist (for example, database wiring disabled).

## 3. Manual verification (runbook)

[`RUNBOOK.md`](RUNBOOK.md) covers what the scripts don't:

| Section | Verifies |
|---|---|
| Verify — Geo DNS | Per-country resolution to the expected regional ALB |
| Verify — Tokyo syslog → Aurora (B, D, E) | Heartbeat rows arriving, foreign forwarder → Tokyo over TGW, a test line through TCP 443 |
| Verify — compliance spot checks | No durable syslog outside Tokyo, no public syslog listeners |
| Common failures | Symptom → cause → fix |

## Continuous integration

There's no CI workflow yet. Recommended minimum: a GitHub Actions job running `terraform fmt -check` and `terraform validate` with `-backend=false` on pull requests. No cloud credentials are needed for that.

## Known gaps

- **Geo DNS checks are manual.** Automating them needs resolvers in each geography, or Route 53's `test-dns-answer` API per location.
- **Foreign forwarder relay** isn't asserted by the scripts, only by runbook §D.
- **Observability stack** (optional) has no scripted checks yet.
- **No `terraform test`** coverage for module inputs.
