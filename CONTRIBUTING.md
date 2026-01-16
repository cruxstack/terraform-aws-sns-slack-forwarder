# Contributing to terraform-aws-sns-slack-forwarder

Thank you for your interest in contributing! This document provides guidelines and
instructions for contributing to the terraform-aws-sns-slack-forwarder module.

## Code of Conduct

Please be respectful and constructive in all interactions with other contributors
and maintainers.

## Getting Started

### Prerequisites

- Terraform >= 1.3
- AWS CLI configured with appropriate credentials
- Git
- Docker (for building Lambda artifacts)
- Make (optional, for common tasks)

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/terraform-aws-sns-slack-forwarder.git
   cd terraform-aws-sns-slack-forwarder
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the code style guidelines below
   - Update documentation as needed
   - Add/update examples if introducing new features

## Code Style Guidelines

### Terraform

- **Indentation**: 2 spaces (enforced via `.editorconfig`)
- **File Organization**: Keep standard structure (main.tf, variables.tf, outputs.tf,
  versions.tf, context.tf)
- **Naming Conventions**:
  - Resources: lowercase with hyphens (e.g., `aws_lambda_function`)
  - Variables: lowercase with underscores (e.g., `lambda_config`)
  - Outputs: descriptive, lowercase with underscores
  - Comments: Brief, describing the "why" not the "what"

- **Code Organization in Files**:
  1. Locals/data sources
  2. Resources/modules (in logical order)
  3. Well-commented sections with comment headers

  Example header:
  ```hcl
  # ================================================================== section name ===
  ```

- **Variable Validation**: Include validation blocks for complex inputs
- **Comments**: Use comment headers to organize sections; inline comments for complex logic

### Variable Definitions

- Always include `description` field
- Use appropriate `type` definitions (avoid `any` when possible)
- Provide sensible `default` values where appropriate
- Add `validation` blocks for constrained inputs

### Outputs

- Group related outputs with comments
- Include descriptive `description` fields
- Mark sensitive outputs with `sensitive = true`

### Documentation

- **Line Length**: 80 characters max for Markdown (except code blocks, tables, URLs)
- **Tables**: Align columns for readability
- **Code Examples**: Use proper syntax highlighting with triple backticks and language
- **Headers**: Use consistent heading hierarchy (# > ## > ###)

### Commit Messages

Follow conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring without feature changes
- `test:` Adding or updating tests
- `chore:` Dependency updates, tooling changes
- `style:` Code style changes (formatting, etc.)

**Examples:**
```
feat(routing): add pattern matching for SNS topics

Implement regex pattern matching for SNS topic ARNs in route configuration,
allowing more flexible routing rules.

Closes #123
```

```
fix(lambda): correct environment variable reference

Fix incorrect reference to SLACK_TOKEN environment variable that was
causing runtime failures.
```

## Making Changes

### Adding Features

1. **Design First**: Discuss significant changes in an issue before implementing
2. **Backward Compatible**: Ensure changes don't break existing configurations
3. **Update Examples**: Add/update examples/complete to demonstrate new features
4. **Update README**: Document new variables, outputs, and behavior
5. **Test Scenarios**: Document test cases in PR description

### Fixing Bugs

1. **Create Issue**: Describe the bug and how to reproduce it
2. **Minimal Fix**: Keep changes focused on the specific bug
3. **Test Thoroughly**: Verify the fix works and doesn't introduce regressions
4. **Update Docs**: If behavior changes, update documentation

### Updating Dependencies

1. **CloudPosse Label Module**: Keep updated to latest stable version
2. **AWS Provider**: Stay within supported version range (>= 5.0)
3. **Test Compatibility**: Verify changes work with stated version requirements

## Testing

### Manual Testing

1. **Validate Syntax**:
   ```bash
   cd examples/complete
   terraform init -backend=false
   terraform validate
   ```

2. **Plan Deployment**:
   ```bash
   terraform plan -out=tfplan
   ```

3. **Review Changes**: Carefully review the plan before applying

### Best Practices

- Test with multiple configurations (different variable combinations)
- Test with CloudPosse context variations
- Verify outputs are correct and non-null when expected
- Check IAM permissions are scoped appropriately
- Validate SNS topic creation and subscriptions

## Documentation

### README Updates

When adding features:
1. Add to Features section if it's a major capability
2. Add input variable to Inputs table
3. Add output to Outputs table if applicable
4. Update example code if demonstrating the feature
5. Add troubleshooting section if common issues exist

### Code Comments

- Explain complex logic (the "why")
- Use section headers for major blocks
- Keep comments concise and accurate
- Remove commented-out code

## Pull Requests

### Before Submitting

1. **Update from main**: Rebase on latest main branch
2. **Test locally**: Run terraform validate and plan
3. **Update documentation**: README, comments, examples
4. **Clean commits**: Use meaningful commit messages
5. **Self-review**: Read through your changes

### PR Description

Include:
- Clear description of changes
- Links to related issues
- Motivation and context
- Testing performed
- Checklist of completeness

Example template:
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123

## Testing
Describe how you tested the changes

## Checklist
- [ ] Code follows style guidelines
- [ ] README updated
- [ ] Examples updated if needed
- [ ] Tested locally with terraform plan
```

## Review Process

1. **Maintainer Review**: Initial review of code and tests
2. **Changes Requested**: Address any feedback
3. **Approval**: Once approved, PR will be merged
4. **Release**: Changes included in next version release

## Releasing

Maintainers will handle releases using semantic versioning:
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

## Reporting Issues

### Bug Reports

Include:
- Terraform version
- AWS provider version
- Module version (or main branch)
- Minimal reproducible example
- Expected vs actual behavior
- Terraform plan output if relevant

### Feature Requests

Include:
- Use case description
- Proposed variable/output names
- Example configuration
- Benefits over current approach

## Questions?

- Check existing issues and PRs
- Review module documentation
- Reach out to maintainers

## License

By contributing, you agree that your contributions will be licensed under the same
MIT License as the project.
