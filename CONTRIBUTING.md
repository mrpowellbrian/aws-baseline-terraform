# Contributing

## Prerequisites

- Terraform >= 1.7
- [terraform-docs](https://terraform-docs.io/) — `brew install terraform-docs`
- [tflint](https://github.com/terraform-linters/tflint) — `brew install tflint`
- [tfsec](https://github.com/aquasecurity/tfsec) — `brew install tfsec`

## Regenerate the variable reference

```bash
terraform-docs markdown . --output-file README.md
```

This replaces the `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` block in README.md.

## Local checks (mirrors CI)

```bash
terraform fmt -recursive -check .
terraform init -backend=false
terraform validate
tflint --init && tflint
tfsec .
```

## Commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add S3 lifecycle rule for Config snapshots
fix: correct CloudTrail bucket policy for GovCloud partitions
docs: update design-decisions section
chore: pin tflint to 0.51
```
