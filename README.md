# 🚀 High-Availability Multi-AZ Web Infrastructure on AWS (Automated via Terraform & CI/CD)

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Evidence](https://img.shields.io/badge/Incident%20Labs-Documentation%20Only-yellow?style=for-the-badge)

> **Portfolio evidence status:** Infrastructure code is published. No dated AWS failure-test results, uptime measurements, cost comparison, or deployment-duration measurements are checked into this repository yet. See the [AWS Cloud Operations Handbook](https://github.com/TreyWright360/aws-cloud-operations-handbook) for runbooks and the [ALB 504 lab plan](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/load-balancing/alb-504.md).

For a recruiter-friendly summary of implementation, failure modes, evidence, and limits, see the [project case study](CASE-STUDY.md).

---

## 📌 Executive Summary & Business Impact
* **Design goal:** Provide a repeatable two-AZ web infrastructure lab for availability, scaling, and incident-response exercises.
* **Implemented:** Modular Terraform for VPC, ALB, EC2 Auto Scaling, security groups, and optional Multi-AZ PostgreSQL RDS, plus a GitHub Actions validation and deployment workflow.
* **Still to measure:** Availability during a controlled AZ exercise, response under load, deployment duration, and cost. The static Apache page does not connect to RDS, so database failover needs an application test path.

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

## 🔄 CI/CD Pipeline and Current Recovery Limit

1. On push and pull request, GitHub Actions runs `terraform fmt`, `terraform init -backend=false`, `terraform validate`, and a non-blocking `tfsec` scan.
2. On a `main` push with AWS credentials configured, the workflow runs `terraform apply` and checks the ALB `/health` endpoint.
3. A failed health check marks the job failed. **The workflow does not currently perform an automatic rollback or measure an error-rate threshold.** Rolling instance refresh is configured in the ASG module; an end-to-end deployment rollback still needs implementation and a lab test.

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

* **Scenario to test:** Auto Scaling replacement after a failing health check or slow bootstrap.
* **Current code:** `health_check_grace_period = 300` and a lightweight `/health` file are present. The original failure timeline and measured startup duration are not checked in.
* **Runbook:** [Auto Scaling replacement loop](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/compute/autoscaling-failures.md).

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
terraform apply -var-file="environments/dev.tfvars"
```
