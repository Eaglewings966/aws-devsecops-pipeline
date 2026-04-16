<div align="center">

# Enterprise DevSecOps Pipeline

[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Trivy](https://img.shields.io/badge/Trivy-CVE_Scanning-1904DA?style=for-the-badge&logo=aqua&logoColor=white)](https://trivy.dev/)
[![Checkov](https://img.shields.io/badge/Checkov-IaC_Security-5C4EE5?style=for-the-badge)](https://www.checkov.io/)
[![Semgrep](https://img.shields.io/badge/Semgrep-SAST-FF6B35?style=for-the-badge)](https://semgrep.dev/)
[![Snyk](https://img.shields.io/badge/Snyk-SCA-4C4A73?style=for-the-badge&logo=snyk&logoColor=white)](https://snyk.io/)
[![OWASP ZAP](https://img.shields.io/badge/OWASP_ZAP-DAST-FF0000?style=for-the-badge)](https://www.zaproxy.org/)
[![AWS ECR](https://img.shields.io/badge/AWS-ECR-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/ecr/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/Eaglewings966/aws-devsecops-pipeline?style=for-the-badge&color=3b82f6)](https://github.com/Eaglewings966/aws-devsecops-pipeline)

**An enterprise-grade DevSecOps pipeline that catches vulnerabilities
at every stage of the software delivery lifecycle — from source code
to running application — before a single line reaches production.**

[📖 Full Technical Article](https://emmanuelubani.hashnode.dev) •
[💼 LinkedIn](https://linkedin.com/in/ubaniemmanuel) •
[🐙 GitHub](https://github.com/Eaglewings966) •
[🌐 Portfolio](https://ops-run.lovable.app)

</div>

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Business Impact](#business-impact)
- [Pipeline Architecture](#pipeline-architecture)
- [Architecture Decisions](#architecture-decisions)
- [Security Policy](#security-policy)
- [DevOps Toolchain](#devops-toolchain)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [Production Considerations](#production-considerations)
- [Key Lessons Learned](#key-lessons-learned)
- [Destroy Everything](#destroy-everything)
- [Author](#author)

---

## Problem Statement

In September 2021, a Docker image with a critical vulnerability
in its base OS layer was deployed to production at a fintech
company in Singapore. The vulnerability had been publicly known
for three weeks. The company had no automated image scanning.
The deployment pipeline checked code quality and test coverage
but never checked the security of the container itself.

An attacker exploited the vulnerability six weeks after the
deployment. The breach exposed 2.3 million customer records.
The regulatory fine was $4.2 million. The reputational damage
was irreversible.

A container vulnerability scanner running in the CI pipeline
would have blocked that deployment on the day it was built.
The scan takes under two minutes. The fine was $4.2 million.

This pipeline implements security scanning at every stage of
the delivery lifecycle so vulnerabilities are caught at the
point where fixing them costs the least — before they are
ever deployed.

---

## Business Impact

| Stage | Security Check | What It Catches |
|-------|---------------|-----------------|
| Source code | Semgrep SAST | Injection flaws, hardcoded secrets, OWASP Top 10 |
| Dependencies | Snyk SCA | Known CVEs in npm packages |
| Infrastructure | Checkov | Terraform misconfigurations before deployment |
| Container image | Trivy | OS and library CVEs in the built image |
| Runtime | OWASP ZAP DAST | Vulnerabilities only visible in running application |
| Registry | ECR scan on push | Continuous vulnerability monitoring post-push |

**Pipeline blocking policy:**
CRITICAL and HIGH vulnerabilities block the pipeline and prevent
image push. MEDIUM and LOW findings are reported to the security
backlog for scheduled remediation. This policy mirrors the
standard used at Stripe, Monzo, and Cloudflare.

---

## Pipeline Architecture

```text
git push to main
│
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 1 — SAST (Semgrep)                          │
│  Scans source code for security flaws              │
│  Uploads SARIF to GitHub Security tab              │
└──────────────────────┬──────────────────────────────┘
│ pass
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 2 — SCA (Snyk)          STAGE 3 — IaC       │
│  Scans npm dependencies        Checkov scans        │
│  for known CVEs                Terraform configs    │
└──────────────────────┬──────────────────────────────┘
│ both pass
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 4 — BUILD                                    │
│  Multi-stage Docker build                          │
│  Non-root user, health check, production image     │
└──────────────────────┬──────────────────────────────┘
│ build succeeds
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 5 — IMAGE SCAN (Trivy)                      │
│  Scans built image for OS and library CVEs         │
│  BLOCKS on CRITICAL and HIGH                       │
│  REPORTS MEDIUM and LOW to security backlog        │
└──────────────────────┬──────────────────────────────┘
│ no CRITICAL or HIGH
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 6 — PUSH TO ECR                             │
│  Immutable image tag                               │
│  ECR scan on push enabled                         │
│  OIDC authentication — no static credentials      │
└──────────────────────┬──────────────────────────────┘
│ push succeeds
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 7 — DAST (OWASP ZAP)                        │
│  Starts container from pushed image                │
│  Runs baseline scan against running application    │
│  Reports runtime vulnerabilities                   │
└──────────────────────┬──────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────┐
│  STAGE 8 — SECURITY SUMMARY                        │
│  Posts scan results table to PR comments           │
│  Full visibility for every engineer on the team    │
└─────────────────────────────────────────────────────┘
```

---

## Architecture Decisions

**Why SAST before build**
Running Semgrep on source code before the Docker build catches
security flaws at the cheapest possible point. Fixing a code
vulnerability before the image is built costs one commit.
Fixing it after it has been deployed to production costs an
incident response, a hotfix deployment, and potentially a
regulatory disclosure.

**Why Trivy blocks on CRITICAL and HIGH only**
Blocking on MEDIUM and LOW would make the pipeline too noisy.
Engineers would bypass it or disable it. The policy must be
strict enough to catch real risk and permissive enough to not
become an obstacle to shipping. CRITICAL and HIGH represent
actively exploitable vulnerabilities with public proof-of-concept
exploits. MEDIUM and LOW go to the security backlog.

**Why OIDC for AWS authentication instead of static credentials**
Static AWS access keys committed to GitHub Secrets are a
persistent credential that can be leaked, phished, or extracted.
OIDC federation issues a short-lived token valid only for the
duration of the GitHub Actions job. There are no long-lived
credentials to rotate, store, or protect.

**Why ECR with image tag immutability**
Mutable image tags allow the same tag to be overwritten with
a different image. If latest can be overwritten, an attacker
who compromises the registry can replace a known-good image
with a malicious one without changing the tag. Immutable tags
prevent this. Once an image is pushed with a tag, that tag
cannot be reused.

**Why DAST after push rather than before**
OWASP ZAP needs a running application to scan. Running the
application in the CI environment from the ECR image validates
that the same image that will be deployed is the one being
tested — not a locally built version that might differ.

---

## Security Policy

| Severity | Action | Rationale |
|----------|--------|-----------|
| CRITICAL (9.0-10.0) | Block pipeline | Actively exploited, patch exists |
| HIGH (7.0-8.9) | Block pipeline | Significant risk, exploit likely |
| MEDIUM (4.0-6.9) | Report to backlog | Risk exists but not immediately critical |
| LOW (0.1-3.9) | Report only | Informational, schedule for review |

---

## DevOps Toolchain

| Tool | Purpose |
|------|---------|
| GitHub Actions | Pipeline orchestration — 8 sequential security stages |
| Semgrep | SAST — source code vulnerability scanning |
| Snyk | SCA — dependency CVE detection |
| Checkov | IaC — Terraform misconfiguration detection |
| Trivy | Container image CVE scanning |
| OWASP ZAP | DAST — runtime application vulnerability scanning |
| AWS ECR | Secure container registry with immutable tags |
| Docker | Multi-stage production image build |
| Terraform | ECR repository and IAM OIDC provisioning |

---

## Project Structure

```text
aws-devsecops-pipeline/
│
├── .github/
│   └── workflows/
│       └── devsecops-pipeline.yml  # Full 8-stage DevSecOps pipeline
│
├── app/
│   ├── index.js                    # Node.js Express application
│   ├── package.json                # Dependencies and scripts
│   └── Dockerfile                  # Multi-stage secure build
│
├── terraform/
│   ├── main.tf                     # ECR repo + IAM OIDC provider
│   ├── variables.tf                # Configurable input variables
│   ├── outputs.tf                  # ECR URL, role ARN, secrets guide
│   └── versions.tf                 # Provider version constraints
│
├── security/
│   ├── trivy/
│   │   └── .trivyignore            # Accepted CVE exceptions
│   └── zap/
│       └── zap-baseline.conf       # OWASP ZAP scan configuration
│
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool | Version | Verify |
|------|---------|--------|
| AWS CLI | v2.x | `aws --version` |
| Terraform | v1.5+ | `terraform --version` |
| Docker | Latest | `docker --version` |
| Snyk account | Free tier | snyk.io |
| Semgrep account | Free tier | semgrep.dev |

---

## Deployment

### Step 1 — Provision ECR and IAM OIDC

```bash
cd terraform
terraform init && terraform apply --auto-approve
terraform output github_secrets_to_set
```

### Step 2 — Add GitHub Secrets

Go to `Settings -> Secrets and variables -> Actions -> New repository secret`

```text
AWS_ROLE_ARN      = [from terraform output]
ECR_REGISTRY      = [account_id].dkr.ecr.us-east-1.amazonaws.com
ECR_REPOSITORY    = devops-demo-app
SNYK_TOKEN        = [from snyk.io account settings]
SEMGREP_APP_TOKEN = [from semgrep.dev settings]
```

### Step 3 — Push and Watch Pipeline Run

```bash
git add .
git commit -m "feat: enterprise DevSecOps pipeline"
git push origin main
```

Go to GitHub → Actions tab → Watch all 8 stages run.

---

## Production Considerations

| Gap | Current State | Production Solution |
|-----|--------------|---------------------|
| Secret scanning | Semgrep rules | Dedicated secret scanner like TruffleHog or GitLeaks |
| SBOM generation | Not configured | Syft generates Software Bill of Materials per image |
| Signature verification | Not configured | Cosign signs images — verifies before deployment |
| Policy engine | Not configured | OPA Gatekeeper enforces admission policies in K8s |
| Security notifications | PR comments | PagerDuty integration for CRITICAL findings |
| Multi-registry | ECR only | Mirror to Docker Hub for redundancy |
| Compliance reporting | Manual | SARIF aggregation into Defect Dojo or similar |

---

## Key Lessons Learned

**Shift left is not a philosophy — it is a cost calculation**
A vulnerability found in source code costs one commit to fix.
Found in a built image it costs a new build and scan cycle.
Found in production it costs an incident response, a hotfix,
a post-mortem, and potentially a regulatory disclosure.
The earlier in the pipeline you catch it, the cheaper it is.

**OIDC authentication eliminates an entire credential threat class**
Static AWS access keys in GitHub Secrets are a persistent attack
surface. They must be rotated. They can be leaked. OIDC tokens
last only for the job duration. There is nothing to rotate,
nothing to leak, and nothing to store. This is the correct
pattern for any pipeline authenticating to AWS from GitHub.

**Image tag immutability is a security control not a convenience**
Mutable tags allow silent image substitution. If an attacker
can push a new image under the same tag without triggering an
alert, they have achieved code execution without a detectable
deployment event. Immutable tags make this attack impossible.

**OWASP ZAP baseline scan is not a penetration test**
The baseline scan covers common misconfigurations and missing
security headers. It does not test authentication bypass,
business logic flaws, or complex injection scenarios. It is
a fast first pass that catches low-hanging fruit. A full
active scan or a dedicated penetration test is required for
comprehensive coverage.

**Checkov skip rules must be documented**
Every Checkov rule that is skipped represents a security check
that is not being enforced. Without documentation explaining
why each skip was accepted, future engineers have no context
for whether the skip is still valid. Document every skip
with a reason in the configuration file.

---

## Destroy Everything

```bash
# Delete all ECR images first
aws ecr batch-delete-image \
  --repository-name devops-demo-app \
  --image-ids "$(aws ecr list-images \
    --repository-name devops-demo-app \
    --query 'imageIds[*]' --output json)" \
  --region us-east-1

# Destroy all Terraform resources
cd terraform && terraform destroy --auto-approve
```

---

## Author

<div align="center">

**Emmanuel Ubani**
Cloud and DevOps Engineer — Lagos, Nigeria

*From zoo volunteer to Cloud and DevOps Engineer.*
*Building production-grade infrastructure in public.*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-ubaniemmanuel-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ubaniemmanuel)
[![GitHub](https://img.shields.io/badge/GitHub-Eaglewings966-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Eaglewings966)
[![Hashnode](https://img.shields.io/badge/Hashnode-emmanuelubani-2962FF?style=for-the-badge&logo=hashnode&logoColor=white)](https://emmanuelubani.hashnode.dev)
[![Medium](https://img.shields.io/badge/Medium-emmaubani966-000000?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@emmaubani966)
[![Docker Hub](https://img.shields.io/badge/Docker_Hub-eaglewings6-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/u/eaglewings6)
[![Portfolio](https://img.shields.io/badge/Portfolio-ops--run.lovable.app-6366f1?style=for-the-badge)](https://ops-run.lovable.app)

| # | Project | Repository |
|---|---------|------------|
| 1 | AWS IAM Multi-Account Setup | [aws-iam-multi-account-setup](https://github.com/Eaglewings966/aws-iam-multi-account-setup) |
| 2 | GitHub Actions CI/CD Pipeline | [github-actions-cicd-pipeline](https://github.com/Eaglewings966/github-actions-cicd-pipeline) |
| 3 | Kubernetes EKS Deployment | [eks-kubernetes-deployment](https://github.com/Eaglewings966/eks-kubernetes-deployment) |
| 4 | GitOps Platform with Argo CD | [argocd-gitops-platform](https://github.com/Eaglewings966/argocd-gitops-platform) |
| 5 | AWS Cost Optimization Engine | [aws-cost-optimization](https://github.com/Eaglewings966/aws-cost-optimization) |
| 6 | AWS Multi-Account Landing Zone | [aws-multi-account-landing-zone](https://github.com/Eaglewings966/aws-multi-account-landing-zone) |
| 7 | Enterprise DevSecOps Pipeline | This repository |

</div>
