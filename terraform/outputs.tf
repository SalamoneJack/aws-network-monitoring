output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.main.id
}

output "log_group_name" {
  description = "CloudWatch Log Group name for flow logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=Network-Overview"
}

output "logs_insights_url" {
  description = "CloudWatch Logs Insights URL for querying flow logs"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:logs-insights"
}

output "target_vpc_id" {
  description = "VPC ID that flow logs are attached to"
  value       = local.target_vpc_id
}
