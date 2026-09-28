# Architecture

Diagrams for Zion Armageddon v102. The README carries the design narrative and the layer table. This page is the visual reference.

## Public path — geolocation DNS to regional apps

```mermaid
flowchart TD
    U[Internet users] --> R53["Route 53 geolocation<br/>(query logs → us-east-1 CloudWatch)"]
    R53 -->|JP · AS · default| TK["Tokyo ALB :80<br/>+ WAFv2"]
    R53 -->|US-NY · NA| NY[New York ALB :80]
    R53 -->|US-CA| CA[California ALB :80]
    R53 -->|GB · EU| LN[London ALB :80]
    R53 -->|BR · SA| SP[São Paulo ALB :80]
    R53 -->|AU · OC| AU[Australia ALB :80]
    R53 -->|HK| HK[Hong Kong ALB :80]
    TK & NY & CA & LN & SP & AU & HK --> APP["App ASG per region<br/>SG: HTTP from ALB SG only"]
```

Only port 80 is public. `test/verify.sh` asserts that HTTPS :443 on Tokyo is **blocked**.

## Private path — syslog over the Transit Gateway mesh

```mermaid
flowchart LR
    subgraph Foreign["Each foreign region (6)"]
        FWD["Syslog forwarder ASG<br/>private subnet · heartbeat + TCP/443 relay"]
        TGWf[Regional TGW]
        FWD --> TGWf
    end
    TGWf <-->|inter-region peering| TGWt
    subgraph Tokyo["Tokyo — ap-northeast-1 (data authority)"]
        TGWt[Tokyo TGW hub]
        TGWt --> NLB[Private syslog NLB :443]
        NLB --> ST["Syslog storage ASG<br/>no public IP · SSM Session Manager"]
        ST --> AUR[("Aurora MySQL<br/>syslog_events · KMS")]
        ST -.->|interface endpoints| EP["Secrets Manager · KMS · SSM<br/>+ S3 gateway endpoint"]
    end
```

**Residency rule:** foreign regions forward and never store. Aurora and durable syslog rows exist only in Tokyo private subnets.

## Terraform module structure

```mermaid
flowchart TD
    LOC["locals.tf<br/>locals.sites map (7 cities)"] --> NET["network.tf<br/>7 × module regional-network"]
    LOC --> SITES["sites.tf<br/>7 × module regional-site"]
    NET --> TGW["transit-gateway.tf<br/>TGWs · attachments · peering · routes"]
    NET --> SITES
    SITES --> HUB["hub.tf → module hub<br/>geo DNS · query logging · WAF · alarms"]
    SITES --> DB["database.tf → module tokyo-database<br/>Aurora · Secrets · VPC endpoints"]
    SG["Shared syslog SG<br/>(lifted to root to break a module cycle)"] --> SITES & DB
    OBS["observability.tf → module observability<br/>(enable_observability)"] -.-> SITES
```

## Optional observability (PLG)

```mermaid
flowchart LR
    A["Alloy agents<br/>app tier ×7 + Tokyo storage"] -->|remote_write / Loki push<br/>over TGW| INLB[Tokyo internal NLB<br/>:9090 · :3100]
    INLB --> P[Prometheus] & L[Loki]
    P & L --> G["Grafana 127.0.0.1:3000<br/>via SSM port-forward"]
    P & L -. PDC outbound tunnel .-> GC["Grafana Cloud<br/>(optional front end)"]
```

Metrics and logs stay in Japan. Grafana Cloud receives only the query results a user opens.
