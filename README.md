# Attack-as-Code: Automated Offensive Testing of Cloud Databases in a CI/CD Pipeline

Course project for **CIT 51600 (Database Security and Auditing)**, Purdue University
Indianapolis.

## Research question

Do automated attacks run inside a CI/CD pipeline detect cloud database misconfigurations
that static Infrastructure-as-Code (IaC) scanning misses — and which approach gives better,
more trustworthy coverage?

## Overview

This project deploys an AWS RDS PostgreSQL database with Terraform in two forms — a
deliberately **weak** configuration and a **hardened** one — then compares two detection
methods against each:

1. **Static analysis** — [Checkov](https://www.checkov.io/) scans the Terraform code on
   every push, before anything is deployed, and flags policy violations.
2. **Live attack testing** — a manually-triggered GitHub Actions workflow deploys the real
   instance to AWS, runs four offensive checks against it, uploads the evidence, and tears
   the instance down again:
   - **Port/service scan** (`nmap`) — is the database port actually reachable?
   - **Credential guessing** (`Hydra`) — is the master password actually crackable?
   - **IAM permission abuse check** (`boto3`) — is the attached IAM role actually
     over-permissive?
   - **Snapshot exposure check** (`boto3`) — is any RDS snapshot actually publicly shared?

Both methods are run against both configurations, and the findings are compared for
detection coverage, false positives/negatives, and practical evidentiary value.

## Seeded misconfigurations (weak config) vs. the fix (hardened config)

| | Weak | Hardened |
|---|---|---|
| Public access | `publicly_accessible = true` | `publicly_accessible = false` |
| Network exposure | Security group open to `0.0.0.0/0` on 5432 | Security group restricted to the VPC's own CIDR |
| Storage encryption | `storage_encrypted = false` | `storage_encrypted = true` |
| Attached IAM role | `AdministratorAccess` | `AmazonRDSEnhancedMonitoringRole` only |
| Master password | Weak, wordlist-guessable | Strong, randomly generated |

## Results summary

**Static analysis (Checkov, 32 checks per configuration):**

| Config | Failed checks |
|---|---|
| weak | 14 / 32 |
| hardened | 11 / 32 |

**Live attack testing (same instance, real AWS):**

| Check | Weak | Hardened |
|---|---|---|
| Port/service scan | `5432/tcp` **open** | `5432/tcp` **filtered** |
| Credential guessing | Cracked (`dbadmin` / `Password1`) in **under 1 second** | **0/1** targets completed — unreachable |
| IAM permission abuse check | `AdministratorAccess` attached — **flagged** | Monitoring-only role — **clean** |
| Snapshot exposure check | No snapshots exist (`skip_final_snapshot = true`) | No snapshots exist |

Full raw output for every run is in the workflow artifacts (`attack-results-weak`,
`attack-results-hardened`) and in `docs/`.

## How the pipeline works

```
terraform/modules/rds-postgres/   Shared module, parameterized by weak/hardened inputs
terraform/weak/                   Deliberately vulnerable deployment
terraform/hardened/               Hardened deployment
terraform/github-oidc/            OIDC federation attempt (gitignored — see Known limitations)
attack-stage/                     Offensive testing scripts run against the live DB
.github/workflows/plan-and-scan.yml        Static: terraform plan + Checkov, on every push
.github/workflows/deploy-attack-destroy.yml Live: apply -> attack -> upload results -> destroy
docs/                              Findings, screenshots, comparison report
```

- **`plan-and-scan.yml`** runs automatically on every push to `main`. It plans both the
  `weak` and `hardened` Terraform configurations (matrix build) and runs Checkov against
  each, uploading the scan results as artifacts. No AWS resources are created by this
  workflow.
- **`deploy-attack-destroy.yml`** is triggered manually (`workflow_dispatch`, choice of
  `weak` or `hardened`). It applies the Terraform config for real, waits for the RDS
  instance to come up, runs all four attack-stage scripts against it, uploads the results
  as an artifact, and **always** runs `terraform destroy` afterward — even if an earlier
  step failed — so nothing is left running (and billing) in AWS.

Remote state for both environments is stored in S3 (`dbsec-tfstate-ar423`) with native
S3 state locking.

## Tools and platforms

AWS (RDS, IAM, VPC security groups), Terraform, GitHub Actions, Checkov, nmap, Hydra, boto3.

## Known limitations

- **OIDC federation was attempted and abandoned.** `terraform/github-oidc/` contains a
  working OIDC provider + IAM role design for keyless GitHub Actions → AWS authentication,
  scoped to this repository only. It was blocked by an AWS Organizations Service Control
  Policy that denies `iam:CreateOpenIDConnectProvider` at the account level — an
  unfixable, account-wide governance restriction, not a bug in the Terraform. The folder is
  kept for documentation purposes (and is excluded from CI via `.gitignore`); the pipeline
  instead uses static AWS access-key secrets (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
  scoped to a dedicated, least-privilege-as-possible `terraform-deployer` IAM user.
- **The snapshot exposure check is untested against a real public snapshot.** Both
  configurations use `skip_final_snapshot = true`, so no snapshot is ever created for either
  instance — the check correctly reports "no snapshots found" in both cases. This is a
  valid negative result, not a check failure, but it means the check's true-positive path
  (actually detecting a publicly-shared snapshot) was not exercised in this project.
- **Hardened still fails 11/32 Checkov checks.** These are lower-severity, structural
  findings (e.g. no Multi-AZ, no deletion protection, no custom parameter group) rather than
  the seeded critical misconfigurations, which Checkov confirms are fully resolved.

## Status

✅ Complete — both configurations have full static and live-attack evidence. See `docs/`
for the full comparison report.

## Disclaimer

All testing is performed against infrastructure deployed solely for this coursework, in a
personal AWS account, with dummy data only. No production systems or third-party
infrastructure are targeted.