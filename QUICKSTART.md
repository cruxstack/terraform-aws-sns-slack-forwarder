# Quick Start Guide

Get up and running with terraform-aws-sns-slack-forwarder in 5 minutes.

## Prerequisites

- Terraform >= 1.3
- AWS CLI configured
- Slack workspace with app installation permissions

## Step 1: Create a Slack App

1. Go to https://api.slack.com/apps/new
2. Choose "From scratch"
3. Name: "SNS Slack Forwarder"
4. Select your workspace
5. Go to "OAuth & Permissions"
6. Add these Bot Token Scopes:
   - `chat:write`
   - `chat:write.public`
7. Install to workspace
8. Copy the "Bot User OAuth Token" (starts with `xoxb-`)

## Step 2: Create Terraform Configuration

Create a file `main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "slack_forwarder" {
  source = "github.com/cruxstack/terraform-aws-sns-slack-forwarder?ref=v1.0.0"

  namespace   = "myco"
  environment = "prod"
  stage       = "ops"
  name        = "alerts"

  # Create SNS topics
  topics = {
    alerts       = { enabled = true }
    notifications = { enabled = true }
  }

  # Slack channels (get these from Slack)
  default_slack_channel = "C1234567890"

  # Simple routing: all messages go to default channel
  route_config = {
    default = {
      sns_topic_arn_pattern = ".*"
      slack_channel_id      = "C1234567890"
      priority              = 1
      enabled               = true
    }
  }

  tags = {
    Environment = "production"
  }
}

output "sns_topics" {
  value = module.slack_forwarder.sns_topic_arns
}
```

## Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy
terraform apply
```

## Step 4: Configure Slack Token

Get the SSM parameter name from outputs:

```bash
# Get parameter name
PARAM_NAME=$(terraform output -raw ssm_parameter_slack_token_name)

# Update with your Slack token
aws ssm put-parameter \
  --name "$PARAM_NAME" \
  --value "xoxb-YOUR-SLACK-TOKEN" \
  --type SecureString \
  --overwrite
```

## Step 5: Test

Publish a test message to your SNS topic:

```bash
# Get topic ARN
TOPIC_ARN=$(terraform output -json sns_topic_arns | jq -r '.alerts')

# Publish test message
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Test Alert" \
  --message "This is a test message from SNS"
```

Check your Slack channel - the message should appear!

## Advanced Routing Example

To route different message types to different channels:

```hcl
route_config = {
  security = {
    sns_topic_arn_pattern   = ".*security.*"
    message_subject_pattern = "CRITICAL|ALERT"
    slack_channel_id        = "C9999999999"  # #security
    priority                = 1
    enabled                 = true
  }

  infrastructure = {
    sns_topic_arn_pattern   = ".*infra.*"
    message_subject_pattern = "WARNING|ERROR"
    slack_channel_id        = "C8888888888"  # #infrastructure
    priority                = 2
    enabled                 = true
  }

  default = {
    sns_topic_arn_pattern = ".*"
    slack_channel_id      = "C1234567890"  # #general
    priority              = 3
    enabled               = true
  }
}
```

## Finding Slack Channel IDs

In Slack:
1. Right-click on a channel
2. Select "View details"
3. Copy the channel ID from the URL or details panel

Or via Slack API:

```bash
# List channels (requires Slack CLI or API call)
curl -X GET https://slack.com/api/conversations.list \
  -H "Authorization: Bearer xoxb-YOUR-TOKEN" | jq '.channels[] | {name, id}'
```

## Troubleshooting

### Message not appearing in Slack

1. **Check Lambda logs:**
   ```bash
   aws logs tail /aws/lambda/myco-prod-ops-alerts --follow
   ```

2. **Verify Slack token:**
   ```bash
   aws ssm get-parameter --name "/component/aws-sns-slack-forwarder/..." \
     --with-decryption --query 'Parameter.Value'
   ```

3. **Enable debug mode:**
   ```hcl
   debug_enabled = true
   ```

4. **Test SNS directly:**
   ```bash
   aws sns publish \
     --topic-arn "arn:aws:sns:us-east-1:123456789:myco-prod-ops-alerts-alerts" \
     --subject "TEST" \
     --message "Test message"
   ```

### Slack token errors

- Verify token is valid and starts with `xoxb-`
- Check token hasn't expired in Slack workspace settings
- Ensure bot is invited to channels (right-click channel > Add apps)

### Route not matching

- Test regex patterns: https://regex101.com/
- Check SNS topic ARN format (right-click topic in AWS console)
- Enable debug mode to see matching logic in CloudWatch Logs
- Verify priority values are unique

## Next Steps

- Review complete example: `examples/complete/`
- Read full documentation: `README.md`
- Explore advanced features in variables
- Set up monitoring and alerts
- Customize routing rules for your use case

## Common Commands

```bash
# View outputs
terraform output

# View Lambda logs
aws logs tail /aws/lambda/FUNCTION_NAME --follow

# Publish test message
aws sns publish --topic-arn TOPIC_ARN --subject "Test" --message "Test"

# Update Slack token
aws ssm put-parameter --name PARAM_NAME --value "TOKEN" --type SecureString --overwrite

# Destroy resources
terraform destroy
```

## Support

- Full documentation: See README.md
- Examples: See examples/complete/
- Issues: GitHub issues
- Contributing: See CONTRIBUTING.md
