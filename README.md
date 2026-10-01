# Terraform static site on AWS + Cloudflare

This project deploys a private static website on AWS with:

- a dedicated VPC and private subnets
- EC2 web nodes behind an autoscaling group
- an S3 bucket for static site content
- Cloudflare Zero Trust tunnel for ingress
- optional Cloudflare Access protection for a private preview
- DNS and HTTPS hardening for the apex domain

This is a sanitized, reusable template intended for public portfolio or learning use. Replace the example values with your own account-specific settings before deploying.

## What it provisions

- AWS VPC with private subnets and NAT
- EC2 launch template running Amazon Linux 2023
- NGINX on each instance serving content from S3
- Cloudflared tunnel routing requests to localhost:80
- Cloudflare DNS and security settings for the root domain
- S3 gateway endpoint for private access from the VPC
- Cloudflare Access policy for private preview mode

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with access to your account
- Cloudflare account with a zone for the target domain
- A Cloudflare API token with permission to manage tunnels and DNS
- The following environment variable set before running Terraform:

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-token"
```

## Quick start

1. Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your real values:

```hcl
aws_region = "us-east-1"
aws_profile = "default"
project_name = "portfolio-site"
domain_name = "example.com"
cloudflare_account_id = "your-cloudflare-account-id"
cloudflare_zone_id = "your-cloudflare-zone-id"
access_allowed_emails = ["you@example.com"]
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Notes

- This repo keeps the site private by default using Cloudflare Access.
- To make the site public, remove or disable `access.tf` and re-run `terraform apply`.
- The EC2 instance role is intentionally minimal: it can read from the site S3 bucket and access SSM for the tunnel token.

## Security notes

- No production secrets are stored in the repository.
- The tunnel token is stored in AWS SSM Parameter Store as a SecureString.
- Instance metadata uses IMDSv2 (`http_tokens = "required"`).

## File layout

```text
.
├── access.tf
├── cloudflare.tf
├── compute.tf
├── dns.tf
├── iam.tf
├── network.tf
├── outputs.tf
├── providers.tf
├── README.md
├── storage.tf
├── terraform.tfvars.example
├── user_data.sh
├── variables.tf
├── versions.tf
└── .gitignore
```
