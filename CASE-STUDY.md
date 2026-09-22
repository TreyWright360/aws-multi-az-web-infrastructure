# Case study: multi-AZ web infrastructure

**Portfolio status:** Code published; incident labs and performance claims are not yet supported by dated evidence.

## Business problem

Model a web service that can distribute requests across two Availability Zones, replace unhealthy instances, and keep its database private. This is a portfolio scenario, not a claim about a production customer's availability.

## Architecture and technologies

Terraform defines a VPC with public/private subnets, an Application Load Balancer, EC2 Auto Scaling, security groups, and PostgreSQL RDS. See [root wiring](main.tf), [ALB](modules/alb/main.tf), [ASG](modules/asg/main.tf), [RDS](modules/rds/main.tf), and [VPC](modules/vpc/main.tf). GitHub Actions validates Terraform and can apply it when credentials are present.

## What is implemented

The ALB forwards HTTP to EC2 targets and checks `/health`. The ASG uses ELB health checks, a 300-second grace period, and CPU target tracking. RDS is private and can be Multi-AZ based on configuration. The web page is static and does not query RDS.

## Failure modes and runbooks

- [ALB 504 investigation](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/load-balancing/alb-504.md)
- [Auto Scaling replacement loop](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/compute/autoscaling-failures.md)
- [RDS connectivity](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/databases/rds-connectivity.md)
- [Availability Zone exercise](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/disaster-recovery/availability-zone-failure.md)

## Test evidence and video

**DOCUMENTATION ONLY.** No dated failure injection, recovery screenshots, measured RTO, uptime, load test, or video is checked in. The [handbook evidence rules](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/evidence/README.md) define the next lab record.

## Security and cost controls

Application and database instances are in private subnets; security groups limit the ALB-to-app and app-to-database paths. The design creates one NAT gateway, which costs money while deployed and leaves private-subnet egress dependent on one AZ. RDS backup retention is configured for seven days; final snapshots and deletion protection are disabled in the current module.

## Production improvements

Add HTTPS and certificate management, ALB logs and 504 alarms, an application path that exercises RDS, tested deployment rollback, protected state storage, and a recovery design for NAT and database dependencies. Measure availability and cost rather than treating targets as achieved results.
