data "aws_caller_identity" "current" {}

# ── Optional: create a test VPC if no vpc_id is provided ────────────────────

resource "aws_vpc" "test" {
  count                = var.vpc_id == "" ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "network-monitoring-test-vpc" }
}

locals {
  target_vpc_id = var.vpc_id != "" ? var.vpc_id : aws_vpc.test[0].id
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/flow-logs"
  retention_in_days = var.flow_log_retention_days
  tags              = { Name = "vpc-flow-logs" }
}

# ── IAM Role for VPC Flow Logs ────────────────────────────────────────────────

resource "aws_iam_role" "flow_logs" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "vpc-flow-logs-role" }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# ── VPC Flow Log ──────────────────────────────────────────────────────────────

resource "aws_flow_log" "main" {
  vpc_id                   = local.target_vpc_id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  max_aggregation_interval = 60
  tags                     = { Name = "vpc-flow-log" }
}

# ── CloudWatch Metric Filters ─────────────────────────────────────────────────

resource "aws_cloudwatch_log_metric_filter" "accepted_bytes" {
  name           = "vpc-accepted-bytes"
  log_group_name = aws_cloudwatch_log_group.flow_logs.name
  pattern        = "[version, accountId, interfaceId, srcAddr, dstAddr, srcPort, dstPort, protocol, packets, bytes, start, end, action=\"ACCEPT\", logStatus]"

  metric_transformation {
    name      = "AcceptedBytes"
    namespace = "VPC/FlowLogs"
    value     = "$bytes"
    unit      = "Bytes"
  }
}

resource "aws_cloudwatch_log_metric_filter" "rejected_packets" {
  name           = "vpc-rejected-packets"
  log_group_name = aws_cloudwatch_log_group.flow_logs.name
  pattern        = "[version, accountId, interfaceId, srcAddr, dstAddr, srcPort, dstPort, protocol, packets, bytes, start, end, action=\"REJECT\", logStatus]"

  metric_transformation {
    name      = "RejectedPackets"
    namespace = "VPC/FlowLogs"
    value     = "$packets"
    unit      = "Count"
  }
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

resource "aws_sns_topic" "alarms" {
  count = var.alarm_email != "" ? 1 : 0
  name  = "vpc-network-alarms"
  tags  = { Name = "vpc-network-alarms" }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "high_rejected" {
  alarm_name          = "vpc-high-rejected-connections"
  alarm_description   = "Unusually high rejected connection rate — possible SG misconfiguration or scan"
  namespace           = "VPC/FlowLogs"
  metric_name         = "RejectedPackets"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = var.high_reject_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  tags = { Name = "vpc-high-rejected-alarm" }
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "network" {
  dashboard_name = "Network-Overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Accepted Traffic (bytes/min)"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["VPC/FlowLogs", "AcceptedBytes", { stat = "Sum", period = 60 }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Rejected Packets/min — security group blocks"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["VPC/FlowLogs", "RejectedPackets", { stat = "Sum", period = 60, color = "#d62728" }]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 6
        width  = 24
        height = 3
        properties = {
          title  = "Active Alarms"
          alarms = [aws_cloudwatch_metric_alarm.high_rejected.arn]
        }
      }
    ]
  })
}
