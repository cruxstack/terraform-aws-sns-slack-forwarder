# ------------------------------------------------------------------- lambda ---

output "lambda_function_arn" {
  description = "ARN of the SNS Slack Forwarder Lambda function"
  value       = try(aws_lambda_function.this[0].arn, null)
}

output "lambda_function_name" {
  description = "Name of the SNS Slack Forwarder Lambda function"
  value       = try(aws_lambda_function.this[0].function_name, null)
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN of the SNS Slack Forwarder Lambda function"
  value       = try(aws_lambda_function.this[0].qualified_arn, null)
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the SNS Slack Forwarder Lambda function"
  value       = try(aws_lambda_function.this[0].invoke_arn, null)
}

# ---------------------------------------------------------------------- iam ---

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the SNS Slack Forwarder Lambda function"
  value       = try(aws_iam_role.this[0].arn, null)
}

output "lambda_role_name" {
  description = "Name of the IAM role used by the SNS Slack Forwarder Lambda function"
  value       = try(aws_iam_role.this[0].name, null)
}

# --------------------------------------------------------------- cloudwatch ---

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for SNS Slack Forwarder Lambda function logs"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for SNS Slack Forwarder Lambda function logs"
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

# ---------------------------------------------------------------- ssm param ---

output "ssm_parameter_slack_token_arn" {
  description = "ARN of the SSM parameter storing the Slack token"
  value       = try(aws_ssm_parameter.slack_token[0].arn, null)
}

output "ssm_parameter_slack_token_name" {
  description = "Name of the SSM parameter storing the Slack token"
  value       = try(aws_ssm_parameter.slack_token[0].name, null)
}

# ---------------------------------------------------------------------- kms ---

output "kms_key_id" {
  description = "ID of the KMS key used for SNS topic encryption"
  value       = try(aws_kms_key.sns[0].key_id, null)
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SNS topic encryption"
  value       = try(aws_kms_key.sns[0].arn, null)
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for SNS topic encryption"
  value       = try(aws_kms_alias.sns[0].name, null)
}

# --------------------------------------------------------------- sns topics ---

output "sns_topic_arns" {
  description = "Map of SNS topic names to their ARNs"
  value       = { for k, v in aws_sns_topic.this : k => v.arn }
}

output "sns_topic_names" {
  description = "Map of SNS topic logical names to their AWS names"
  value       = { for k, v in aws_sns_topic.this : k => v.name }
}

# ------------------------------------------------------------- aws metadata ---

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region name"
  value       = data.aws_region.current.id
}
