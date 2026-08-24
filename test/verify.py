#!/usr/bin/env python3
"""
Verification suite for Zion Armageddon v102.

Run from repo root:
  python test/verify.py

Requires: boto3, terraform on PATH, network access to ALB DNS names.
  pip install boto3
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from typing import Any

REGION = "ap-northeast-1"
DOMAIN = "jastek.click"
ALB_OUTPUTS = [
    ("tokyo", "tok-lb_dns_name"),
    ("newyork", "ny-lb_dns_name"),
    ("london", "lon-lb_dns_name"),
    ("australia", "aus-lb_dns_name"),
    ("california", "ca-lb_dns_name"),
    ("hongkong", "hk-lb_dns_name"),
    ("saopaulo", "sao-lb_dns_name"),
]

PASS = FAIL = SKIP = 0


def green(msg: str) -> None:
    print(f"\033[0;32mPASS: {msg}\033[0m")


def red(msg: str) -> None:
    print(f"\033[0;31mFAIL: {msg}\033[0m")


def yellow(msg: str) -> None:
    print(f"\033[0;33mSKIP: {msg}\033[0m")


def passed(msg: str) -> None:
    global PASS
    PASS += 1
    green(msg)


def failed(msg: str) -> None:
    global FAIL
    FAIL += 1
    red(msg)


def skipped(msg: str) -> None:
    global SKIP
    SKIP += 1
    yellow(msg)


def run(cmd: list[str], check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def tf_output(name: str) -> str:
    r = run(["terraform", "output", "-raw", name])
    return r.stdout.strip() if r.returncode == 0 else ""


def http_get_code(url: str, timeout: float = 15.0) -> int:
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return getattr(resp, "status", 200) or 200
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return 0


def main() -> int:
    print("=== Zion Armageddon verification (Python) ===\n")

    if not shutil.which("terraform"):
        failed("terraform not on PATH")
        return 1

    try:
        import boto3
    except ImportError:
        failed("boto3 not installed — pip install boto3")
        return 1

    tok_lb = tf_output("tok-lb_dns_name")
    if not tok_lb:
        failed("terraform outputs unavailable — apply first / correct workspace")
        return 1
    passed("terraform outputs readable")

    syslog_nlb = tf_output("tokyo_syslog_nlb_dns_name")
    if syslog_nlb:
        passed(f"tokyo_syslog_nlb_dns_name={syslog_nlb}")
    else:
        failed("tokyo_syslog_nlb_dns_name missing (foreign forwarders need it)")

    for label, key in ALB_OUTPUTS:
        host = tf_output(key)
        if not host:
            skipped(f"HTTP {label} (no output)")
            continue
        code = http_get_code(f"http://{host}/")
        if code == 200:
            passed(f"HTTP :80 {label} → {code}")
        else:
            failed(f"HTTP :80 {label} → {code} (expected 200)")

    # HTTPS should fail to connect (no listener / SG drop)
    https_code = http_get_code(f"https://{tok_lb}/", timeout=10.0)
    if https_code == 0:
        passed("HTTPS :443 tokyo blocked (no connection)")
    else:
        failed(f"HTTPS :443 tokyo unexpectedly returned {https_code}")

    # DNS via system resolver
    try:
        import socket

        socket.getaddrinfo(DOMAIN, 80)
        passed(f"DNS resolves {DOMAIN}")
    except OSError as e:
        failed(f"DNS resolve {DOMAIN}: {e}")

    session = boto3.Session()
    rds = session.client("rds", region_name=REGION)
    sm = session.client("secretsmanager", region_name=REGION)
    ec2 = session.client("ec2", region_name=REGION)
    ssm = session.client("ssm", region_name=REGION)

    try:
        cluster = rds.describe_db_clusters(DBClusterIdentifier="tok-syslog-aurora")["DBClusters"][0]
        if cluster.get("Status") == "available":
            passed("Aurora tok-syslog-aurora status=available")
        else:
            failed(f"Aurora status={cluster.get('Status')}")
    except Exception as e:
        failed(f"Aurora describe: {e}")

    try:
        instances = rds.describe_db_instances(
            Filters=[{"Name": "db-cluster-id", "Values": ["tok-syslog-aurora"]}]
        )["DBInstances"]
        if instances and instances[0].get("PubliclyAccessible") is False:
            passed("Aurora instance PubliclyAccessible=false")
        else:
            failed(f"Aurora PubliclyAccessible unexpected: {instances}")
    except Exception as e:
        failed(f"Aurora instances: {e}")

    try:
        sm.get_secret_value(SecretId="tok-syslog-aurora-credentials")
        passed("Secrets Manager tok-syslog-aurora-credentials readable")
    except Exception as e:
        failed(f"Secrets Manager: {e}")

    reservations = ec2.describe_instances(
        Filters=[
            {"Name": "tag:Name", "Values": ["tok-syslog-instance"]},
            {"Name": "instance-state-name", "Values": ["running"]},
        ]
    )["Reservations"]
    ec2_instances: list[dict[str, Any]] = [i for r in reservations for i in r["Instances"]]
    if not ec2_instances:
        failed("No running tok-syslog-instance")
        inst_id = None
    else:
        inst = ec2_instances[0]
        inst_id = inst["InstanceId"]
        passed(f"Tokyo syslog instance running ({inst_id})")
        if not inst.get("PublicIpAddress"):
            passed("Tokyo syslog has no public IP (private subnet)")
        else:
            failed(f"Tokyo syslog has public IP {inst.get('PublicIpAddress')}")

    if inst_id:
        info = ssm.describe_instance_information(
            Filters=[{"Key": "InstanceIds", "Values": [inst_id]}]
        ).get("InstanceInformationList", [])
        ping = info[0].get("PingStatus") if info else "None"
        if ping == "Online":
            passed(f"SSM PingStatus=Online for {inst_id}")
            stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
            cmd = ssm.send_command(
                InstanceIds=[inst_id],
                DocumentName="AWS-RunShellScript",
                Parameters={
                    "commands": [
                        f'/usr/local/bin/syslog-db-write.sh "verify-py-{stamp}"',
                        "echo SSM_DB_WRITE_OK",
                    ]
                },
            )
            command_id = cmd["Command"]["CommandId"]
            time.sleep(8)
            inv = ssm.get_command_invocation(CommandId=command_id, InstanceId=inst_id)
            if inv.get("Status") == "Success":
                passed("SSM Run Command syslog-db-write succeeded")
            else:
                failed(f"SSM Run Command status={inv.get('Status')} id={command_id}")
        else:
            failed(f"SSM PingStatus={ping} for {inst_id} (apply SSM IAM/endpoints, wait 2-5 min)")

    print(f"\n=== Summary: {PASS} passed, {FAIL} failed, {SKIP} skipped ===")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
