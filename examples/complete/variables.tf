# ============================================================ environment ===

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

# ============================================================ naming context ===

variable "namespace" {
  type        = string
  description = "ID element: organization name abbreviation (e.g., 'eg', 'cp')"
  default     = "eg"
}

variable "environment" {
  type        = string
  description = "ID element: region or environment name (e.g., 'uw2', 'us-west-2')"
  default     = "uw2"
}

variable "stage" {
  type        = string
  description = "ID element: role indicator (e.g., 'prod', 'staging', 'dev')"
  default     = "prod"
}

variable "name" {
  type        = string
  description = "ID element: component or solution name (e.g., 'alerts')"
  default     = "slack-forwarder"
}

variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources"
  default     = true
}

# ============================================================ slack config ===

variable "default_slack_channel" {
  type        = string
  description = "Slack channel ID for fallback when no route matches"
  example     = "C1111111111"
}

variable "security_critical_channel" {
  type        = string
  description = "Slack channel ID for security critical alerts"
  example     = "C1234567890"
}

variable "infrastructure_channel" {
  type        = string
  description = "Slack channel ID for infrastructure alerts"
  example     = "C0987654321"
}

variable "application_channel" {
  type        = string
  description = "Slack channel ID for application alerts"
  example     = "C1111222222"
}

variable "debug_enabled" {
  type        = bool
  description = "Enable debug logging in Lambda function"
  default     = false
}

# ============================================================ lambda config ===

variable "bot_version" {
  type        = string
  description = "Version of SNS Slack Forwarder to use ('latest' or specific tag)"
  default     = "latest"
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda function memory in MB"
  default     = 256
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 30
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda function runtime"
  default     = "provided.al2023"
}

variable "lambda_architecture" {
  type        = string
  description = "Lambda function architecture (x86_64 or arm64)"
  default     = "x86_64"
}

variable "lambda_reserved_concurrency" {
  type        = number
  description = "Lambda reserved concurrent executions (-1 for unreserved)"
  default     = -1
}

variable "lambda_log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

# ================================================================ tags ===

variable "team" {
  type        = string
  description = "Team responsible for this resource"
  default     = "platform"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
