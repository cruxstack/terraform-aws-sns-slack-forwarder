# ================================================================== general ===

variable "topics" {
  description = "SNS topics to create and use as triggers for Slack Bot"
  type = map(object({
    enabled = optional(bool, true)
  }))
}

variable "default_slack_channel" {
  description = "Slack channel ID for use as a fallback for messages that do not match any route"
  type        = string
  default     = ""
}

variable "debug_enabled" {
  description = "Enable debug logging in Lambda function"
  type        = bool
  default     = false
}

variable "route_config" {
  description = "Configure how SNS messages are routed to Slack"
  type = map(object({
    sns_topic_arn_pattern   = optional(string, ".*")
    message_subject_pattern = optional(string)
    slack_channel_id        = string
    priority                = number
    enabled                 = optional(bool, true)
  }))
  default = {}

  validation {
    condition = length([
      for key, value in var.route_config : value.priority
      ]) == length(distinct([
        for key, value in var.route_config : value.priority
    ]))
    error_message = "Each route configuration must have a unique priority value. Duplicate priorities are not allowed."
  }
}

# ================================================================== lambda ===

variable "bot_version" {
  description = "Version of the SNS Slack Forwarder bot to use. Use 'latest' for the main branch or a specific version tag like 'v0.1.0'."
  type        = string
  default     = "latest"
}

variable "bot_repo" {
  description = "GitHub repository URL for the SNS Slack Forwarder source code."
  type        = string
  default     = "https://github.com/cruxstack/aws-sns-slack-forwarder-go.git"
}

variable "bot_force_rebuild_id" {
  description = "ID to force rebuilding the Lambda function source code. Increment this value to trigger a rebuild."
  type        = string
  default     = ""
}

variable "lambda_config" {
  description = "Configuration for the SNS Slack Forwarder Lambda function."
  type = object({
    memory_size                    = optional(number, 256)
    timeout                        = optional(number, 30)
    runtime                        = optional(string, "provided.al2023")
    architecture                   = optional(string, "x86_64")
    reserved_concurrent_executions = optional(number, -1)
  })
  default = {}

  validation {
    condition     = var.lambda_config.memory_size >= 128 && var.lambda_config.memory_size <= 10240
    error_message = "Lambda memory_size must be between 128 and 10240 MB."
  }

  validation {
    condition     = var.lambda_config.timeout >= 1 && var.lambda_config.timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_log_retention_days" {
  description = "Number of days to retain Lambda function logs in CloudWatch Logs."
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.lambda_log_retention_days)
    error_message = "Lambda log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "lambda_environment_variables" {
  description = "Additional environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

# --------------------------------------------------------------------- ssm ---

variable "ssm_parameter_arns" {
  description = "List of SSM Parameter Store ARNs that the Lambda function should have access to for secrets retrieval."
  type        = list(string)
  default     = []
}

# --------------------------------------------------------------------- kms ---

variable "kms_key_policy" {
  description = "Full JSON KMS key policy document to use for the SNS topic encryption key. When null (default), a policy is generated that grants key administration to the account root and scopes CloudWatch, SNS, and EventBridge service access to the current AWS account, with SNS access further scoped to this module's own topics."
  type        = string
  default     = null
}
