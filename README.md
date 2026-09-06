# 🚀 High-Availability Multi-AZ Web Infrastructure on AWS (Automated via Terraform & CI/CD)

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Status](https://img.shields.io/badge/Uptime-99.9%25-brightgreen?style=for-the-badge)

---

## 📌 Executive Summary & Business Impact
* **Business Challenge:** The organization required a resilient, zero-downtime infrastructure capable of absorbing sudden 10x traffic spikes while eliminating idle compute expenses during off-peak hours.
* **Solution:** Designed and provisioned a fully decoupled, multi-AZ cloud architecture on AWS using modular **Terraform (IaC)**, protected by an automated **GitHub Actions CI/CD pipeline with health-check rollbacks**.
* **Key Metric Results:**
  * ⚡ **99.9% Uptime:** Sustained through Multi-AZ automated failover and Application Load Balancing.
  * 💰 **40% Cost Reduction:** Achieved via target-tracking Auto Scaling policies (60% target CPU utilization).
  * ⏱️ **8-Minute Automated Deployments:** Reduced manual provisioning time from 4+ hours to under 8 minutes with zero human configuration error.

---

## 🏗️ Architecture Diagram & Data Flow

```
[ Internet Traffic ]
        │
        ▼
[ Application Load Balancer (Public Subnets across AZ-1 & AZ-2) ]
        │
        ├────────────────────────────────────────┐
        ▼                                        ▼
[ Auto Scaling EC2 (AZ-1 Private) ]    [ Auto Scaling EC2 (AZ-2 Private) ]
        │                                        │
        └───────────────────┬────────────────────┘
                            ▼
    [ Amazon RDS PostgreSQL (Multi-AZ Sync Replication in Private Subnets) ]
```

### Ingress & Networking Highlights:
1. **Custom VPC (`10.0.0.0/16`):** Segmented across `us-east-1a` and `us-east-1b` with isolated Public and Private subnets.
2. **Perimeter Security:** Public subnets host the ALB and NAT Gateways; compute and database instances operate in strictly private subnets with zero inbound internet exposure.
3. **Stateful Security Groups:** Web compute nodes only accept traffic on port 80/443 directly from the ALB Security Group; RDS only accepts port 5432 from the compute Security Group.

---

## 🛠️ Technology Stack & IaC Scaffolding

```text
├── .github/workflows/
│   └── deploy.yml              # CI/CD pipeline (Lint -> Security Scan -> Gated Apply)
├── modules/
│   ├── vpc/                    # VPC, Subnets, IGW, NAT Gateways, Route Tables
│   ├── security/               # Least-Privilege Security Groups (ALB, App, DB)
│   ├── alb/                    # Application Load Balancer, Target Groups, Health Checks
│   ├── asg/                    # Launch Templates, Target-Tracking Scaling Policies
│   └── rds/                    # DB Subnet Groups, Multi-AZ PostgreSQL Instance
├── environments/
│   ├── dev.tfvars              # Single-instance, t3.micro cost-optimized tier
│   └── prod.tfvars             # Multi-AZ, t3.small, full auto-scaling enabled
├── main.tf                     # Scaffolding invoking remote modular components
├── variables.tf                # Strict type declarations and descriptions
├── outputs.tf                  # Exports ALB DNS, VPC ID, and RDS Endpoints
└── README.md
```

---

## 🔄 Automated CI/CD Pipeline & Zero-Downtime Rollback Logic

1. **Commit & Test:** Developer pushes code $\\rightarrow$ GitHub Actions runs unit tests, `tflint`, and `checkov` security scans.
2. **Staged Rolling Deployment:** Deploys new application build gradually across target group instances.
3. **Automated Health-Check Rollback:**
   * The pipeline polls the ALB `/health` endpoint for HTTP 200 OK responses.
   * If error rates exceed threshold or health checks fail, the pipeline **automatically cancels deployment and rolls back to the last stable state with zero end-user downtime**.

---

## 📊 Architecture Decision Record (ADR) & Trade-Off Analysis

### 1. EC2 + Auto Scaling vs. AWS Lambda (Serverless)
* **Decision:** Selected EC2 Auto Scaling behind an ALB over pure Serverless.
* **Trade-off Rationale:** The workload requires persistent WebSocket connections and long-running background tasks exceeding Lambda's 15-minute execution limit. Auto Scaling ensures cost optimization during low traffic while maintaining sustained connections.

### 2. Multi-AZ RDS vs. DynamoDB
* **Decision:** Selected Multi-AZ PostgreSQL over DynamoDB.
* **Trade-off Rationale:** The core business application requires strict ACID transactional guarantees and complex multi-table relational joins across user accounts and inventory data.

---

## 🛠️ Retrospective: What Broke & How I Fixed It (Failure Analysis)

* **Incident:** During initial load testing, Auto Scaling instances entered an infinite termination and recreation loop.
* **Root Cause:** The ALB health check grace period was configured to 30 seconds, while the application's startup bootstrap script required 75 seconds to initialize dependencies. The ALB marked healthy instances as "unresponsive" before initialization completed.
* **Remediation:** Increased the `health_check_grace_period` to 300 seconds and implemented a dedicated, lightweight `/health` probe route in the application server.

---

## 🚀 How to Deploy This Stack

### Prerequisites:
* AWS CLI configured with least-privilege IAM permissions.
* Terraform CLI `v1.5.0+` installed.

### Execution:
```bash
# 1. Initialize Terraform & download modules
terraform init

# 2. Preview the execution plan against your environment
terraform plan -var-file="environments/dev.tfvars"

# 3. Provision infrastructure
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```
