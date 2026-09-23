# Case study: multi-AZ web infrastructure

**Portfolio status:** PARTIALLY TESTED. Deployed live to AWS on 2026-09-23. Instance-replacement and NAT-dependency labs are verified with dated evidence; ALB 504 and full AZ-outage exercises remain undone.

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

**PARTIALLY TESTED.** [Dated evidence](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/evidence/multi-az-instance-replacement/INDEX.md) covers two labs: (1) terminating a healthy instance — zero user-visible downtime, 2m 8s to a healthy replacement; (2) removing the shared NAT gateway route to test the risk flagged below — this reproduced the documented Auto Scaling replacement loop for real (a replacement instance ran 6 minutes and was killed for failing its health check, with a second replacement booting into the same trap), then recovered in 2m 40s once the route was restored and the stuck instance was force-replaced. No load test, ALB 504 exercise, or video is checked in yet.

## Security and cost controls

Application and database instances are in private subnets; security groups limit the ALB-to-app and app-to-database paths. The design creates one NAT gateway, which costs money while deployed and leaves private-subnet egress dependent on one AZ. RDS backup retention is configured for seven days; final snapshots and deletion protection are disabled in the current module.

## Production improvements

Add HTTPS and certificate management, ALB logs and 504 alarms, an application path that exercises RDS, tested deployment rollback, protected state storage, and a recovery design for NAT and database dependencies. Measure availability and cost rather than treating targets as achieved results.

## CI/CD and deployment validation

- **CI status:** Verified passing without AWS credentials or terraform apply on PR and main push.
- **PR validation run:** [Run #35785654408](https://github.com/TreyWright360/aws-multi-az-web-infrastructure/actions/runs/35785654408) (passed)
- **Main branch validation run:** [Run #35786494558](https://github.com/TreyWright360/aws-multi-az-web-infrastructure/actions/runs/35786494558) (passed, non-deploying)
- **Deployment safeguards:** Automatic deployment is removed from push to `main`. Deployment is isolated in `.github/workflows/deploy-production.yml`, requiring manual `workflow_dispatch` trigger and approval via the protected `production` environment. The false health-check rollback claim was removed.

