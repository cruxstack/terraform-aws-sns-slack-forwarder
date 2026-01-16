# ================================================================ lambda ===

output "lambda_function_arn" {
  description = "ARN of the SNS Slack Forwarder Lambda function"
  value       = module.sns_slack_forwarder.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the SNS Slack Forwarder Lambda function"
  value       = module.sns_slack_forwarder.lambda_function_name
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = module.sns_slack_forwarder.lambda_function_qualified_arn
}

# ================================================================= iam ===

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = module.sns_slack_forwarder.lambda_role_arn
}

output "lambda_role_name" {
  description = "Name of the IAM role used by the Lambda function"
  value       = module.sns_slack_forwarder.lambda_role_name
}

# ==================================================== cloudwatch logs ===

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.sns_slack_forwarder.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.sns_slack_forwarder.cloudwatch_log_group_arn
}

# ================================================================ sns ===

output "sns_topic_arns" {
  description = "Map of SNS topic names to their ARNs"
  value       = module.sns_slack_forwarder.sns_topic_arns
}

output "sns_topic_names" {
  description = "Map of SNS topic logical names to their AWS names"
  value       = module.sns_slack_forwarder.sns_topic_names
}

# ========================================================== aws metadata ===

output "aws_account_id" {
  description = "AWS account ID"
  value       = module.sns_slack_forwarder.aws_account_id
}

output "aws_region" {
  description = "AWS region name"
  value       = module.sns_slack_forwarder.aws_region
}

# ================================================================ usage ===

output "ssm_parameter_slack_token_name" {
  description = "Name of SSM parameter containing Slack token"
  value       = "/component/aws-sns-slack-forwarder/${module.sns_slack_forwarder.lambda_function_name}/tokens/slack"
}

output "next_steps" {
  description = "Next steps to configure and use the module"
  value       = <<-EOT
    1. Update the Slack token in AWS SSM Parameter Store:
       aws ssm put-parameter \
         --name "${"/component/aws-sns-slack-forwarder/${module.sns_slack_forwarder.lambda_function_name}/tokens/slack"}" \
         --value "xoxb-YOUR-SLACK-BOT-TOKEN" \
         --type SecureString \
         --overwrite \
         --region ${module.sns_slack_forwarder.aws_region}

    2. Test by publishing a message to one of the SNS topics:
       aws sns publish \
         --topic-arn "${module.sns_slack_forwarder.sns_topic_arns["security_alerts"]}" \
         --subject "TEST: Security Alert" \
         --message "This is a test message" \
         --region ${module.sns_slack_forwarder.aws_region}

    3. Check CloudWatch Logs for debugging:
       aws logs tail ${module.sns_slack_forwarder.cloudwatch_log_group_name} --follow
  EOT
}
