config {
  # Enable module inspection
  # Options: all (default), local, none
  call_module_type = "all"

  # Force zero exit code on warnings
  force = false

  # Disable plugin discovery
  plugin_dir = "~/.tflint.d/plugins"
}

# Enable the AWS plugin
plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Enable Terraform plugin for general best practices
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS-specific rules
rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Name",
    "Environment",
  ]
}

# Terraform general rules
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}
