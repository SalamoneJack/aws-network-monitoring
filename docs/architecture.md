# Architecture Diagram

Add your draw.io architecture diagram here as `architecture.png`.

## Suggested draw.io Elements

- VPC box with EC2 instances and RDS
- VPC Flow Logs icon with arrow to CloudWatch Logs log group
- CloudWatch Logs fan out to three destinations:
  1. Logs Insights (query icon)
  2. CloudWatch Dashboard (graph icon)
  3. CloudWatch Alarms → SNS → Email
- Log group label: `/vpc/flow-logs`
- IAM Role icon with arrow from VPC Flow Logs to CloudWatch

## Export

Export as PNG at 1200px wide, save as `docs/architecture.png`.
Update the README image reference: `![Architecture](docs/architecture.png)`
