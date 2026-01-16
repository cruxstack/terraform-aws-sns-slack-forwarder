# terraform-aws-sns-slack-forwarder Project Overview

## Module Purpose

This Terraform module creates AWS SNS topics and deploys a Lambda-based service that
forwards SNS messages to Slack channels based on configurable routing rules.

## Architecture Overview

The module implements the following architecture:

```
┌─────────────────────────────────────────────────────┐
│            Your Services/Applications               │
├─────────────────────────────────────────────────────┤
│                    SNS Topics                       │
│  ├─ security-alerts                                │
│  ├─ infrastructure                                 │
│  └─ application                                    │
├─────────────────────────────────────────────────────┤
│         Lambda Function (SNS Subscriber)            │
│  ├─ Receives SNS events                            │
│  ├─ Evaluates routing rules                        │
│  ├─ Retrieves Slack token from SSM                 │
│  └─ Forwards to Slack channel                      │
├─────────────────────────────────────────────────────┤
│              Slack Workspace                        │
│  ├─ #security-alerts                               │
│  ├─ #infrastructure                                │
│  ├─ #application-alerts                            │
│  └─ #general (fallback)                            │
└─────────────────────────────────────────────────────┘
```

## Key Components

### 1. SNS Topics
- Created based on `topics` variable
- KMS encryption enabled by default (AWS managed key)
- Naming convention: `{module.this.id}-{topic_key}`

### 2. Lambda Function
- Runtime: `provided.al2023` (customizable)
- Handler: `bootstrap` (binary handler)
- Artifact: Built from Docker image via terraform-docker-artifact-packager
- Environment variables configured for routing and Slack token location

### 3. Routing Engine
- Pattern-based matching on SNS topic ARN and message subject
- Priority-based evaluation (lower priority number = higher priority)
- Fallback channel for non-matching messages
- Debug mode for troubleshooting

### 4. Secrets Management
- Slack token stored in AWS SSM Parameter Store (SecureString)
- Route configuration stored in SSM (String type)
- Lambda function has scoped IAM permissions to access these parameters

### 5. Monitoring
- CloudWatch Logs integration
- Configurable log retention
- Debug logging available via environment variable

## Module Files

### Core Terraform Files
- **versions.tf** - Terraform and provider requirements
- **context.tf** - CloudPosse label/naming context (20+ options)
- **main.tf** - All resource definitions (Lambda, SNS, IAM, logs)
- **variables.tf** - Input variable definitions with validation
- **outputs.tf** - Output values (ARNs, names, topic mappings)

### Documentation
- **README.md** - Comprehensive module documentation (registry-formatted)
- **CONTRIBUTING.md** - Contribution guidelines
- **PROJECT.md** - This file, providing overview and architecture

### Examples
- **examples/complete/** - Full-featured example demonstrating all capabilities
  - main.tf - Module invocation with all features
  - variables.tf - Variable definitions with descriptions
  - outputs.tf - Output definitions and post-deployment instructions
  - versions.tf - Provider requirements
  - terraform.tfvars.example - Sample values to customize

### Docker Assets
- **assets/lambda-function/Dockerfile** - Multi-stage build for Lambda packaging
- **assets/lambda-function/.dockerignore** - Files to exclude from build

### Configuration Files
- **.gitignore** - Standard Terraform and IDE ignores
- **.editorconfig** - Consistent editor settings (2-space indentation)
- **LICENSE** - MIT License

## Design Decisions

### 1. CloudPosse Label Module
- **Why**: Enables enterprise-grade naming with 20+ customization options
- **Trade-off**: Adds dependency on external module
- **Benefit**: Consistent naming across infrastructure, registry-ready

### 2. SSM Parameter Store for Secrets
- **Why**: Avoids storing secrets in Terraform state
- **How**: Parameters created with placeholder; user updates with actual values
- **Benefit**: Secure, auditable, can be rotated independently

### 3. Docker-Based Lambda Packaging
- **Why**: Flexible build process supporting multiple languages
- **How**: Uses terraform-docker-artifact-packager for consistent builds
- **Benefit**: Reproducible, version-controlled builds; can fetch from any Git repo

### 4. Priority-Based Routing
- **Why**: Allows complex routing logic without multiple Lambda functions
- **How**: Routes evaluated in order; first match wins
- **Benefit**: Flexible, maintainable, single point of configuration

### 5. SNS Topic Creation
- **Why**: Provides complete solution, not just forwarding
- **How**: Topics created with naming convention; user can also use external topics
- **Benefit**: Self-contained module that can operate independently

## Variable Strategy

### Required Variables
Only `topics` is truly required. All other inputs have sensible defaults or can be
omitted.

### Flexible Configuration
All configurable aspects have corresponding variables:
- Lambda sizing (memory, timeout, concurrency)
- Slack integration (channels, debug mode)
- Routing rules (patterns, priorities, enabled flag)
- Secrets location (SSM parameter ARNs)

### CloudPosse Integration
Full CloudPosse label context support allows:
- Custom ID formatting
- Flexible naming conventions
- Tag management and propagation
- Label case controls

## Security Considerations

### IAM Permissions
- Lambda role has minimal permissions
- CloudWatch Logs access scoped to Lambda function logs
- SSM Parameter access scoped to module-specific parameters
- Additional SSM parameters can be granted via `ssm_parameter_arns` variable

### Secrets Management
- No secrets stored in Terraform code or state
- Slack token stored in SSM with SecureString type
- User responsible for setting actual token value post-deployment
- Can be rotated independently without module redeployment

### Network Security
- SNS topics accessible only via AWS API
- Lambda execution triggered only via SNS
- No public endpoints or network exposure

## Extensibility

### Adding Features
Module can be extended by:
1. Adding new Lambda environment variables
2. Adding new routes without module changes
3. Extending IAM permissions for additional services
4. Customizing routing logic (if SNS Slack Forwarder supports it)

### Integration Points
- Publish to SNS topics from any AWS service
- Consume Slack channel messages in workflows
- Monitor Lambda execution via CloudWatch
- Audit parameter access via CloudTrail

## Testing Strategy

### Manual Testing Approach
1. Deploy example configuration
2. Publish test message to SNS topic
3. Verify message appears in Slack
4. Check CloudWatch Logs for execution details
5. Test multiple routes with different patterns
6. Verify fallback channel behavior

### Common Test Cases
- Message matches highest priority route
- Message matches lower priority route (higher number)
- Message doesn't match any route (goes to fallback)
- No fallback channel configured
- Multiple message patterns
- Subject pattern matching

## Deployment Flow

### Initial Setup
1. Configure variables (topics, channels, routing rules)
2. Deploy module with Terraform
3. Retrieve SSM parameter names from outputs
4. Update Slack token in SSM Parameter Store
5. Test message routing

### Post-Deployment
1. Publish test messages to verify routing
2. Monitor CloudWatch Logs for issues
3. Adjust routing rules as needed (via variable changes)
4. Update Slack token if needed (manual SSM update)

## Registry Requirements Met

✅ Proper directory naming: `terraform-aws-sns-slack-forwarder`
✅ Standard file structure: versions.tf, main.tf, variables.tf, outputs.tf
✅ Comprehensive README with examples and tables
✅ LICENSE file (MIT)
✅ examples/ directory with complete, working example
✅ Proper variable descriptions and types
✅ Organized outputs with descriptions
✅ CloudPosse label integration for naming

## Maintenance Notes

### Update Procedures
1. Update `bot_version` to deploy newer Lambda function
2. Update `bot_repo` if SNS Slack Forwarder moves
3. Increase `bot_force_rebuild_id` to force rebuild
4. Add new routes via `route_config` variable changes
5. Update `lambda_config` to resize function as needed

### Troubleshooting
- Check CloudWatch Logs for Lambda errors
- Verify SSM parameters have correct values
- Review routing rules for pattern matches
- Enable debug mode for verbose logging
- Test SNS publish manually with AWS CLI

## Future Enhancements

Potential areas for module evolution:
1. Support for multiple Slack workspaces
2. Message formatting customization
3. Message filtering/transformation
4. DLQ for failed messages
5. Metrics and alarms
6. Cost optimization options
7. Additional integration targets (Webhooks, Email, etc.)

## Dependencies

### External Modules
- `cloudposse/label/null` (v0.25.0) - Naming and context management

### AWS Services
- SNS - Topic creation and message delivery
- Lambda - Serverless compute for message processing
- SSM Parameter Store - Secrets and configuration storage
- CloudWatch Logs - Function logging
- IAM - Permission management
- KMS - SNS topic encryption (optional)

### Build Tools
- Docker - Lambda artifact packaging
- Git - Source code and dependency management

## Support and Questions

Refer to the main README.md for:
- Detailed usage examples
- Input/output reference
- Troubleshooting guide
- Architecture diagrams
- Feature descriptions

See CONTRIBUTING.md for:
- Code style guidelines
- Testing procedures
- Contribution workflow
- PR submission process
