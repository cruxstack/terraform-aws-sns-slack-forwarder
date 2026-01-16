provider "aws" {
  region = var.aws_region
}

module "sns_slack_forwarder" {
  source = "../../"

  # ========================================================= naming context ===

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  name        = var.name

  # ============================================================ enable/disable ===

  enabled = var.enabled

  # =============================================================== sns topics ===

  topics = {
    security_alerts = {
      enabled = true
    }
    infrastructure = {
      enabled = true
    }
    application = {
      enabled = true
    }
  }

  # ========================================================== slack config ===

  default_slack_channel = var.default_slack_channel
  debug_enabled         = var.debug_enabled

  # =========================================================== routing rules ===

  route_config = {
    # High priority: Security critical messages
    security_critical = {
      sns_topic_arn_pattern   = ".*security.*"
      message_subject_pattern = "CRITICAL|ALERT|BREACH"
      slack_channel_id        = var.security_critical_channel
      priority                = 1
      enabled                 = true
    }

    # Medium priority: Infrastructure warnings
    infrastructure_warnings = {
      sns_topic_arn_pattern   = ".*infrastructure.*"
      message_subject_pattern = "WARNING|ERROR|FAILURE"
      slack_channel_id        = var.infrastructure_channel
      priority                = 2
      enabled                 = true
    }

    # Medium priority: Application errors
    application_errors = {
      sns_topic_arn_pattern   = ".*application.*"
      message_subject_pattern = "ERROR|EXCEPTION|PANIC"
      slack_channel_id        = var.application_channel
      priority                = 2
      enabled                 = true
    }

    # Low priority: Catch-all for remaining messages
    general_alerts = {
      sns_topic_arn_pattern = ".*"
      slack_channel_id      = var.default_slack_channel
      priority              = 3
      enabled               = true
    }
  }

  # ========================================================== lambda config ===

  bot_version = var.bot_version

  lambda_config = {
    memory_size                    = var.lambda_memory_size
    timeout                        = var.lambda_timeout
    runtime                        = var.lambda_runtime
    architecture                   = var.lambda_architecture
    reserved_concurrent_executions = var.lambda_reserved_concurrency
  }

  lambda_log_retention_days = var.lambda_log_retention_days
  lambda_environment_variables = {
    # Add any additional environment variables here
  }

  # ==================================================================== tags ===

  tags = merge(
    {
      Environment = var.environment
      Team        = var.team
    },
    var.additional_tags
  )
}
