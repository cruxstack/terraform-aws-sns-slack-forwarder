# =================================================================== locals ===

locals {
  enabled             = module.this.enabled
  fallback_enabled    = var.default_slack_channel != ""
  ssm_param_namespace = "/component/aws-sns-slack-forwarder/${module.this.name}"

  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region_name = data.aws_region.current.id
  aws_partition   = data.aws_partition.current.partition

  # Lambda environment variables
  lambda_environment = merge(
    {
      SLACK_DEFAULT_CHANNEL   = var.default_slack_channel
      FALLBACK_ENABLED        = local.fallback_enabled
      DEBUG_ENABLED           = var.debug_enabled
      SLACK_TOKEN             = aws_ssm_parameter.slack_token[0].arn
      SNS_ROUTES_PARAM_ARN    = aws_ssm_parameter.route_config[0].arn
      VALIDATE_SNS_SIGNATURES = false
      NOTIFY_ON_SUBSCRIPTION  = true
    },
    var.lambda_environment_variables
  )

  # Filter enabled topics
  topics = local.enabled ? {
    for k, v in var.topics : k => v
    if v.enabled
  } : {}

  # Sort route config by priority for deterministic ordering
  # Convert to list with priority-prefixed keys for sorting
  route_config_for_sort = {
    for key, value in var.route_config :
    format("%05d", value.priority) => merge(value, { name = key })
  }
  # Sort by keys (which now have priority prefix)
  route_config_sorted_keys = sort(keys(local.route_config_for_sort))

  # Build final array without priority field
  route_config_array = [
    for sort_key in local.route_config_sorted_keys :
    merge(
      {
        name                  = local.route_config_for_sort[sort_key].name
        sns_topic_arn_pattern = local.route_config_for_sort[sort_key].sns_topic_arn_pattern
        slack_channel_id      = local.route_config_for_sort[sort_key].slack_channel_id
        enabled               = local.route_config_for_sort[sort_key].enabled
      },
      local.route_config_for_sort[sort_key].message_subject_pattern != null ? {
        message_subject_pattern = local.route_config_for_sort[sort_key].message_subject_pattern
      } : {}
    )
  ]
}

# ================================================================= data sources ===

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ================================================================== lambda ===

module "bot_artifact" {
  source = "github.com/cruxstack/terraform-docker-artifact-packager?ref=v1.4.0"

  count = local.enabled ? 1 : 0

  attributes             = ["lambda"]
  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/lambda-function")
  docker_build_target    = "package"
  force_rebuild_id       = var.bot_force_rebuild_id

  docker_build_args = {
    BOT_VERSION = var.bot_version
    BOT_REPO    = var.bot_repo
  }

  context = module.this.context
}

resource "aws_lambda_function" "this" {
  count = local.enabled ? 1 : 0

  function_name                  = module.this.id
  description                    = "SNS Slack Forwarder - Forwards SNS alerts to Slack"
  role                           = aws_iam_role.this[0].arn
  handler                        = "bootstrap"
  runtime                        = var.lambda_config.runtime
  memory_size                    = var.lambda_config.memory_size
  timeout                        = var.lambda_config.timeout
  reserved_concurrent_executions = var.lambda_config.reserved_concurrent_executions
  architectures                  = [var.lambda_config.architecture]

  filename = module.bot_artifact[0].artifact_package_path

  environment {
    variables = local.lambda_environment
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.this,
    module.bot_artifact
  ]

  tags = module.this.tags
}

resource "aws_cloudwatch_log_group" "this" {
  count = local.enabled ? 1 : 0

  name              = "/aws/lambda/${module.this.id}"
  retention_in_days = var.lambda_log_retention_days
  tags              = module.this.tags
}

# ================================================================= ssm params ===

resource "aws_ssm_parameter" "route_config" {
  count = local.enabled ? 1 : 0

  name  = "${local.ssm_param_namespace}/config/routes"
  type  = "String"
  value = jsonencode(local.route_config_array)
}

resource "aws_ssm_parameter" "slack_token" {
  count = local.enabled ? 1 : 0

  name        = "${local.ssm_param_namespace}/tokens/slack"
  description = "Slack token to use for AWS SNS Slack Forwarder"
  type        = "SecureString"
  value       = "placeholder"

  lifecycle {
    ignore_changes = [value]
  }

  tags = module.this.tags
}

# ================================================================ sns topics ===

resource "aws_sns_topic" "this" {
  for_each = local.topics

  name              = "${module.this.id}-${each.key}"
  kms_master_key_id = "alias/aws/sns"

  tags = module.this.tags
}

# ========================================================== sns subscriptions ===

resource "aws_sns_topic_subscription" "this" {
  for_each = local.topics

  topic_arn = aws_sns_topic.this[each.key].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this[0].arn
}

# ========================================================== lambda permissions ===

resource "aws_lambda_permission" "this" {
  for_each = local.topics

  statement_id  = "AllowExecutionFromSNS${title(each.key)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this[each.key].arn
}

# ---------------------------------------------------------------------- iam ---

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name        = module.this.id
  description = "IAM role for AWS SNS Slack Forwarder Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { "Service" : "lambda.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = module.this.tags
}

data "aws_iam_policy_document" "this" {
  count = local.enabled ? 1 : 0

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:${local.aws_partition}:logs:${local.aws_region_name}:${local.aws_account_id}:log-group:/aws/lambda/${module.this.id}:*"]
  }

  dynamic "statement" {
    for_each = local.enabled ? [1] : []

    content {
      sid    = "SSMParameterAccess"
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = concat(var.ssm_parameter_arns, [aws_ssm_parameter.slack_token[0].arn, aws_ssm_parameter.route_config[0].arn])
    }
  }
}

resource "aws_iam_role_policy" "this" {
  count = local.enabled ? 1 : 0

  name   = module.this.id
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}
