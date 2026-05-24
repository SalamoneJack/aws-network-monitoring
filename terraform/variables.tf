variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to enable flow logs on. Leave empty to create a new test VPC."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR for the test VPC (only used if vpc_id is empty)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "flow_log_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch"
  type        = number
  default     = 90
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications (optional)"
  type        = string
  default     = ""
}

variable "high_reject_threshold" {
  description = "Number of rejected connections per minute to trigger alarm"
  type        = number
  default     = 100
}
