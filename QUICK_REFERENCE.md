# Quick Reference

## Module Location
```bash
./new/terraform-aws-sns-slack-forwarder/
```

## Minimal Example
```hcl
module "slack_forwarder" {
  source = "github.com/cruxstack/terraform-aws-sns-slack-forwarder?ref=v1.0.0"

  name   = "alerts"
  topics = { security = { enabled = true } }
  default_slack_channel = "C1234567890"
}
```

## Variable Quick Reference
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `topics` | map | required | SNS topics to create |
| `default_slack_channel` | string | "" | Fallback Slack channel |
| `debug_enabled` | bool | false | Enable debug logging |
| `route_config` | map | {} | Message routing rules |
| `lambda_config` | object | defaults | Lambda settings |
| `namespace` | string | null | Organization name |
| `environment` | string | null | Region/environment |
| `stage` | string | null | Role (prod/dev/staging) |
| `name` | string | null | Component name |

## Output Quick Reference
| Output | Description |
|--------|-------------|
| `lambda_function_arn` | Lambda function ARN |
| `lambda_function_name` | Lambda function name |
| `sns_topic_arns` | Map of SNS topic ARNs |
| `sns_topic_names` | Map of SNS topic names |
| `cloudwatch_log_group_name` | CloudWatch log group |
| `aws_account_id` | AWS account ID |
| `aws_region` | AWS region |

## Common Commands
```bash
# Validate module
terraform init -backend=false
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Deploy
terraform apply tfplan

# Update Slack token
aws ssm put-parameter \
  --name "/component/aws-sns-slack-forwarder/NAME/tokens/slack" \
  --value "xoxb-YOUR-TOKEN" \
  --type SecureString \
  --overwrite

# Test SNS
aws sns publish \
  --topic-arn "TOPIC_ARN" \
  --subject "Test" \
  --message "Test message"

# View logs
aws logs tail /aws/lambda/FUNCTION_NAME --follow
```

## File Structure
```
terraform-aws-sns-slack-forwarder/
├── main.tf                  # Resources
├── variables.tf             # Variables
├── outputs.tf               # Outputs
├── versions.tf              # Requirements
├── context.tf               # CloudPosse
├── README.md                # Documentation
├── QUICKSTART.md            # Quick start
├── PROJECT.md               # Architecture
├── CONTRIBUTING.md          # Contributing
├── LICENSE                  # MIT
├── .gitignore               # Git ignore
├── .editorconfig            # Editor config
├── examples/complete/       # Example
└── assets/lambda-function/  # Docker assets
```

## Key Concepts
- **Topics**: Create SNS topics that trigger Lambda
- **Routing**: Pattern-match on topic ARN and message subject
- **Priority**: Lower priority number = evaluated first
- **Fallback**: Default channel for non-matching messages
- **Secrets**: Slack token in SSM Parameter Store (SecureString)

## Validation Steps
1. Run `terraform validate` in module root
2. Run `terraform validate` in examples/complete
3. Run `terraform plan` in examples/complete
4. Review README.md and QUICKSTART.md
5. Check VALIDATION_CHECKLIST.md

## Documentation
- **README.md** - Complete feature documentation
- **QUICKSTART.md** - 5-minute setup guide
- **PROJECT.md** - Architecture and design
- **CONTRIBUTING.md** - Contribution guidelines
- **VALIDATION_CHECKLIST.md** - Pre-deployment checklist

## Resources Created
- SNS Topics (with KMS encryption)
- Lambda Function (custom runtime)
- IAM Role & Policy
- CloudWatch Log Group
- SSM Parameters (Slack token, Route config)

## Important Notes
1. Slack token must be manually updated in SSM post-deployment
2. Bot function source fetched from GitHub at deployment time
3. Uses terraform-docker-artifact-packager for Lambda builds
4. CloudPosse label module provides enterprise naming
5. All resources tagged automatically

## Troubleshooting
- Check CloudWatch logs: `aws logs tail /aws/lambda/NAME --follow`
- Verify Slack token: `aws ssm get-parameter --name PARAM_NAME --with-decryption`
- Test SNS: `aws sns publish --topic-arn ARN --subject "Test" --message "Test"`
- Enable debug: Set `debug_enabled = true`

## Registry Publishing
1. Create GitHub repository
2. Push module code
3. Go to https://registry.terraform.io/
4. Sign in with GitHub
5. Click "Add Module"
6. Select this repository
7. Create version tags (v1.0.0, etc.)

## Support
- Full documentation: See README.md
- Quick setup: See QUICKSTART.md
- Troubleshooting: See README.md Troubleshooting section
- Contributing: See CONTRIBUTING.md
