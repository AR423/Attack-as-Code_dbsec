# Attack-as-Code: Automated Offensive Testing of Cloud Databases in a CI/CD Pipeline

Course project for CIT 51600 (Database Security and Auditing), Purdue University Indianapolis.

## Research question

Do automated attacks run inside a CI/CD pipeline detect cloud database misconfigurations
that static Infrastructure-as-Code (IaC) scanning misses, and which approach gives better
coverage with fewer false positives?

## Overview

This project deploys an AWS RDS PostgreSQL database with Terraform in two forms — a
deliberately weak configuration and a hardened one — then compares two detection methods
against each:

1. **Static analysis**: Checkov scanning the Terraform code before deployment.
2. **Live attack testing**: automated offensive checks run against the deployed database
   from a GitHub Actions pipeline (port/service scan, credential checks, snapshot exposure,
   IAM permission abuse tests).

Findings from both methods are recorded and compared for detection coverage and false
positives. The weak configuration's findings are then fixed in code, and the pipeline is
re-run to confirm the hardened version passes.

## Seeded misconfigurations (weak config only)

- Publicly accessible RDS instance
- Open security group (0.0.0.0/0 on port 5432)
- Unencrypted storage
- Over-permissive IAM role attached to the instance
- Weak master password

## Repository structure

```
terraform/
  modules/rds-postgres/   # Shared module parameterized by weak/hardened inputs
  weak/                    # Deliberately vulnerable deployment
  hardened/                # Hardened deployment
attack-stage/              # Offensive testing scripts run against the live DB
.github/workflows/         # CI/CD pipeline: plan, scan, deploy, attack, report, destroy
docs/                      # Findings, comparison report, screenshots
```

## Tools and platforms

AWS (RDS, IAM, VPC security groups, CloudTrail, CloudWatch), Terraform, GitHub Actions,
Checkov, nmap, Hydra, Pacu / AWS CLI, pgaudit.

## Status

🚧 In progress — see `docs/` for findings as they're produced.

## Disclaimer

All testing is performed against infrastructure deployed solely for this coursework, in a
personal AWS account, with dummy data only. No production systems or third-party
infrastructure are targeted.
