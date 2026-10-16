# terraform-aws-sns-slack-forwarder

Terraform module that creates SNS topics and forwards SNS messages to Slack channels
based on configurable routing rules.

## What

This Terraform module deploys a complete AWS SNS to Slack integration with intelligent
message routing capabilities:

- **SNS Topic Creation** - Automatically provisions SNS topics with customer-managed KMS
  encryption for CloudWatch compatibility
- **Smart Message Routing** - Routes SNS notifications to specific Slack channels based on
  topic ARN patterns and message subject patterns
- **Lambda Forwarder** - Go-based Lambda function that processes SNS messages and formats
  them for Slack with rich message blocks
- **CloudWatch Integration** - Enables CloudWatch alarms to publish to SNS topics with
  proper KMS key permissions
- **EventBridge Integration** - Enables EventBridge rules (e.g. service state-change
  events) to publish to SNS topics with the required topic and KMS key permissions

## Why

AWS services generate notifications through SNS, but routing these alerts to the right
Slack channels requires custom integration. This module solves that problem by:

- **Centralizing Alert Management** - Single Terraform module to manage all SNS-to-Slack
  routing without writing custom Lambda code
- **Flexible Routing** - Priority-based pattern matching ensures critical alerts go to
  the right teams (e.g., security alerts to #security, infrastructure warnings to #ops)
- **Zero Maintenance** - Serverless Lambda architecture with automatic log rotation and
  secure token management via SSM Parameter Store
- **CloudWatch Compatible** - Customer-managed KMS keys allow CloudWatch alarms to
  trigger SNS notifications without permission errors
- **EventBridge Compatible** - A topic policy plus KMS key grant let EventBridge rules
  target these topics directly, so any AWS service event (DMS task state changes, etc.)
  can be forwarded to Slack with no extra plumbing
- **Production Ready** - Built-in debug logging, configurable timeouts, and fallback
  channels ensure reliable message delivery

## Features

- **SNS Topic Management** - Create and manage SNS topics with KMS encryption
- **Message Routing** - Route SNS messages to Slack channels based on topic ARN and
  message subject patterns
- **Priority-Based Routing** - Configure route priorities to handle messages with
  multiple matching rules
- **Channel Fallback** - Default Slack channel for messages that don't match any route
- **Lambda-Based Processing** - Serverless message forwarding with minimal cold start
- **Debug Support** - Enable debug logging to troubleshoot routing issues
- **CloudWatch Logs** - Automatic log group creation with configurable retention
- **Secure Secrets** - Slack token stored in AWS SSM Parameter Store (SecureString)

## Usage

```hcl
module "sns_slack_forwarder" {
  source = "github.com/cruxstack/terraform-aws-sns-slack-forwarder?ref=v1.0.0"

  namespace   = "myco"
  environment = "prod"
  stage       = "ops"
  name        = "alerts"

  # SNS topics to create
  topics = {
    security_alerts = { enabled = true }
    infrastructure  = { enabled = true }
    application     = { enabled = true }
  }

  # Route configuration with priorities
  route_config = {
    security_critical = {
      sns_topic_arn_pattern   = ".*security.*"
      message_subject_pattern = "CRITICAL|ALERT"
      slack_channel_id        = "C1234567890"
      priority                = 1
      enabled                 = true
    }
    ops_general = {
      sns_topic_arn_pattern = ".*"
      slack_channel_id      = "C0987654321"
      priority              = 2
      enabled               = true
    }
  }

  # Default fallback channel
  default_slack_channel = "C1111111111"

  # Lambda configuration
  lambda_config = {
    memory_size  = 256
    timeout      = 30
    architecture = "x86_64"
  }

  lambda_log_retention_days = 30
  debug_enabled             = false

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Quick Start

1. **Set up Slack Bot Token** - Create a Slack app with appropriate scopes and
   obtain a bot token (xoxb-...)
   
   **Option A: Use App Manifest (Recommended)**
   
   Use the provided app manifest for quick setup:
   
   a. Go to https://api.slack.com/apps and click "Create New App"
   
   b. Select "From an app manifest"
   
   c. Choose your workspace
   
   d. Copy the contents of [`assets/slack/slack-app-manifest.yaml`](assets/slack/slack-app-manifest.yaml)
      and paste it into the manifest editor
   
   e. Add the bot icon: Upload [`assets/slack/aws-sns-icon.png`](assets/slack/aws-sns-icon.png)
      in "Display Information" settings under "App Icon & Preview"
   
   f. Install the app to your workspace and copy the Bot User OAuth Token (xoxb-...)
   
   **Option B: Manual Setup**
   
   a. Create a new Slack app at https://api.slack.com/apps
   
   b. Navigate to "OAuth & Permissions" and add the following Bot Token Scopes:
      - `chat:write`
      - `chat:write.public`
   
   c. Install the app to your workspace and copy the Bot User OAuth Token (xoxb-...)

2. **Deploy Module** - Use the example configuration above or see
   [Complete Example](examples/complete) for a full working setup

3. **Update Slack Token** - After deployment, update the SSM parameter with your
   Slack token:
   ```bash
   aws ssm put-parameter \
     --name "/component/aws-sns-slack-forwarder/alerts/tokens/slack" \
     --value "xoxb-your-slack-token" \
     --type SecureString \
     --overwrite
   ```

4. **Publish Messages** - Publish messages to your SNS topics; they will be
   forwarded to Slack based on the routing configuration

## Route Configuration

Route rules are matched in priority order (lowest to highest). The first matching
route sends the message; if no routes match, the message is sent to the default
channel (if configured).

### Route Rule Attributes

- `sns_topic_arn_pattern` - Regex pattern to match SNS topic ARN (default: `.*`)
- `message_subject_pattern` - Regex pattern to match SNS message subject (optional)
- `slack_channel_id` - Slack channel ID to send matching messages to
- `priority` - Route priority (lower number = higher priority; must be unique)
- `enabled` - Whether this route is active (default: `true`)

### Example Route Configurations

```hcl
# Match all security topics with CRITICAL messages - highest priority
security_critical = {
  sns_topic_arn_pattern   = ".*security.*"
  message_subject_pattern = "CRITICAL|ALERT"
  slack_channel_id        = "C1234567890"
  priority                = 1
  enabled                 = true
}

# Match infrastructure topics - medium priority
infra_warnings = {
  sns_topic_arn_pattern   = ".*infrastructure.*"
  message_subject_pattern = "WARNING|ERROR"
  slack_channel_id        = "C0987654321"
  priority                = 2
  enabled                 = true
}

# Catch-all for remaining messages - lowest priority
general_alerts = {
  sns_topic_arn_pattern = ".*"
  slack_channel_id      = "C1111111111"
  priority              = 3
  enabled               = true
}
```

## Inputs

| Name                          | Description                                                                  | Type           | Default                                                   | Required |
|-------------------------------|------------------------------------------------------------------------------|----------------|-----------------------------------------------------------|:--------:|
| `namespace`                   | ID element: organization name abbreviation (e.g., 'eg', 'cp')                | `string`       | `null`                                                    |    no    |
| `environment`                 | ID element: region or role (e.g., 'uw2', 'us-west-2', 'prod', 'staging')    | `string`       | `null`                                                    |    no    |
| `stage`                       | ID element: role indicator (e.g., 'prod', 'staging', 'dev')                 | `string`       | `null`                                                    |    no    |
| `name`                        | ID element: solution name (e.g., 'alerts', 'notifications')                 | `string`       | `null`                                                    |    no    |
| `enabled`                     | Set to false to prevent the module from creating any resources               | `bool`         | `null`                                                    |    no    |
| `topics`                      | SNS topics to create and use as triggers for Slack Bot                       | `map(object)`  | n/a                                                       |   yes    |
| `default_slack_channel`       | Slack channel ID for fallback when no route matches                          | `string`       | `""`                                                      |    no    |
| `debug_enabled`               | Enable debug logging in Lambda function                                     | `bool`         | `false`                                                   |    no    |
| `route_config`                | Configure how SNS messages are routed to Slack                               | `map(object)`  | `{}`                                                      |    no    |
| `bot_version`                 | Version of SNS Slack Forwarder to use ('latest' or specific tag)             | `string`       | `"latest"`                                                |    no    |
| `bot_repo`                    | GitHub repository URL for SNS Slack Forwarder source code                    | `string`       | `"https://github.com/cruxstack/sns-slack-forwarder.git"`  |    no    |
| `bot_force_rebuild_id`        | Increment to force Lambda rebuild                                            | `string`       | `""`                                                      |    no    |
| `lambda_config`               | Configuration for Lambda function (memory, timeout, runtime, etc.)           | `object`       | `{}`                                                      |    no    |
| `lambda_log_retention_days`   | CloudWatch log retention in days                                             | `number`       | `30`                                                      |    no    |
| `lambda_environment_variables`| Additional environment variables for Lambda                                   | `map(string)`  | `{}`                                                      |    no    |
| `ssm_parameter_arns`          | List of SSM Parameter Store ARNs Lambda can access                           | `list(string)` | `[]`                                                      |    no    |

### CloudPosse Context Variables

The module supports all CloudPosse label/naming variables for maximum flexibility:

- `namespace` - Organization abbreviation
- `tenant` - Customer identifier (rarely used)
- `environment` - Region or environment name
- `stage` - Role indicator (prod, staging, dev)
- `name` - Component/solution name
- `delimiter` - Delimiter between ID elements (default: `-`)
- `attributes` - Additional attributes to add to ID
- `tags` - Additional tags for all resources
- `additional_tag_map` - Additional key-value pairs for tags
- `label_order` - Custom label order
- `id_length_limit` - Limit ID length
- `label_key_case` - Control tag key case (lower, title, upper)
- `label_value_case` - Control label case (lower, title, upper, none)
- `regex_replace_chars` - Regex to remove characters from IDs
- `descriptor_formats` - Additional descriptor formats

### Lambda Configuration

```hcl
lambda_config = {
  memory_size                    = 256        # MB, default: 256
  timeout                        = 30         # seconds, default: 30
  runtime                        = "provided.al2023"  # default: provided.al2023
  architecture                   = "x86_64"   # or "arm64", default: x86_64
  reserved_concurrent_executions = -1         # -1 = unreserved, default: -1
}
```

## Outputs

| Name                              | Description                                          | Type       |
|-----------------------------------|------------------------------------------------------|------------|
| `lambda_function_arn`             | ARN of the Lambda function                           | `string`   |
| `lambda_function_name`            | Name of the Lambda function                          | `string`   |
| `lambda_function_qualified_arn`   | Qualified ARN of the Lambda function                 | `string`   |
| `lambda_function_invoke_arn`      | Invoke ARN of the Lambda function                    | `string`   |
| `lambda_role_arn`                 | ARN of the IAM role for Lambda                       | `string`   |
| `lambda_role_name`                | Name of the IAM role for Lambda                      | `string`   |
| `cloudwatch_log_group_name`       | Name of the CloudWatch log group                     | `string`   |
| `cloudwatch_log_group_arn`        | ARN of the CloudWatch log group                      | `string`   |
| `sns_topic_arns`                  | Map of SNS topic names to their ARNs                 | `map`      |
| `sns_topic_names`                 | Map of SNS topic logical names to AWS names          | `map`      |
| `aws_account_id`                  | AWS account ID                                       | `string`   |
| `aws_region`                      | AWS region name                                      | `string`   |

## Architecture

```
                        +--------------------+
                        |   Your Services    |
                        +----+--------+------+
                             |        |
                    Publish  |        | Publish
                             v        v
          +------------------+--------+------------------+
          |                   SNS Topics                  |
          |  - security-alerts                           |
          |  - infrastructure                            |
          |  - application                               |
          +------------------+------------------+--------+
                             |                  |
                    Subscribe |                  | Subscribe
                             v                  v
                    +---------+--------+--------+
                    |     Lambda       |
                    | SNS-Slack        |
                    | Forwarder        |
                    +---------+--------+
                             |
                    Post/Send |
                             v
                    +---------+--------+
                    |   Slack APIs    |
                    +--------+--------+
                             |
                             v
                    +---------+--------+
                    |  Slack Channels |
                    |  - #security    |
                    |  - #ops         |
                    |  - #general     |
                    +----------------+
```

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.3  |
| aws       | >= 5.0  |

## IAM Permissions

The Lambda execution role requires the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/*"
    },
    {
      "Sid": "SSMParameterAccess",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/component/aws-sns-slack-forwarder/*"
    }
  ]
}
```

### SNS Topic & KMS Key Policies

Each SNS topic's KMS key grants `kms:Decrypt`/`kms:GenerateDataKey` to `cloudwatch.amazonaws.com`,
`sns.amazonaws.com`, and `events.amazonaws.com`, and each topic carries an `aws_sns_topic_policy`
allowing `events.amazonaws.com` to `sns:Publish` (scoped to the same account via
`aws:SourceAccount`). CloudWatch Alarms don't need the topic-policy statement - AWS allows
same-account alarm actions to publish without one - but EventBridge rule targets do, so any
EventBridge rule in the same account can publish directly to these topics without further setup.

## Examples

- [Complete Example](examples/complete) - Full configuration demonstrating all
  features with multiple topics and routing rules

## Troubleshooting

### Messages not appearing in Slack

1. **Check Lambda logs**: View CloudWatch logs for the Lambda function
2. **Verify Slack token**: Ensure the SSM parameter has a valid token
3. **Review routing rules**: Check route priorities and patterns match your topics
4. **Enable debug mode**: Set `debug_enabled = true` for verbose logging
5. **Test SNS message**: Publish a test message with a known subject pattern

### Slack token errors

Update the SSM parameter with your Slack token:

```bash
aws ssm put-parameter \
  --name "/component/aws-sns-slack-forwarder/YOUR_NAME/tokens/slack" \
  --value "xoxb-your-token" \
  --type SecureString \
  --overwrite \
  --region us-east-1
```

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.

## References

- [Slack API Documentation](https://api.slack.com/)
- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
