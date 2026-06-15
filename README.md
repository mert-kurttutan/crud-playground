# Benchmark Repository Playground

This project is a personal playground for trying out CRUD development concepts in a domain I find interesting: benchmarking. The benchmark repository idea gives the app a concrete shape, with users, memberships, benchmark scripts, hardware profiles, and benchmark results, but the main goal is to explore full-stack CRUD patterns through a practical example.

## Stack

- Frontend: `SvelteKit` with `TypeScript`
- Backend: `FastAPI`
- Database: `PostgreSQL`
- ORM and migrations: `SQLAlchemy` + `Alembic`

## Development

Run it locally with separate frontend and backend services.

1. Start PostgreSQL locally.
2. Run the FastAPI backend.
3. Run the SvelteKit frontend.

### Prepare Environment

You need to have necessary dependencies to continue development. You can get them in different ways, e.g. nix below.

#### Nix

Enter the development shell from the repository root:

```bash
nix develop
```

### Run Services

```bash
# backend
cd backend
uv sync
cp .env.example .env
uv run uvicorn app.main:app --reload

# frontend
cd frontend
pnpm install
pnpm dev
```

## Deployment

The current deployment is split between Cloudflare and AWS:

- Frontend: Cloudflare Pages, serving the static SvelteKit build.
- Backend: AWS Lambda container image behind API Gateway HTTP API.
- Backend image build: AWS CodeBuild builds `backend/Dockerfile` and pushes to private ECR.

### Frontend: Cloudflare Pages

Build the static frontend:

```bash
pnpm --dir frontend install
pnpm --dir frontend build
```

Deploy with Wrangler from the repository root:

```bash
wrangler pages deploy
```

The Pages output directory is configured in `wrangler.toml`:

```toml
name = "crud-playground"
pages_build_output_dir = "frontend/build"
```

Wrangler can authenticate with a token instead of browser login. Export these before deploying:

```bash
export CLOUDFLARE_ACCOUNT_ID="..."
export CLOUDFLARE_API_TOKEN="..."
```

The token needs Cloudflare Pages edit access for the account.

### Backend Image: CodeBuild and ECR

The backend image is built from `backend/Dockerfile`. The CloudFormation template
`infra/codebuild-ecr.yml` creates:

- private ECR repository `crud/fastapi`
- CodeBuild project `crud-backend-image`
- CodeBuild service role with ECR push permissions

Deploy or update the build stack:

```bash
infra/deploy-codebuild-ecr.nu
```

Deploy the stack and immediately start the first backend image build:

```bash
infra/deploy-codebuild-ecr.nu --start-build
```

Builds are tagged with the Git commit hash. The image URI shape is:

```text
<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:<git-commit-sha>
```

### Backend API: Lambda and API Gateway

The CloudFormation template `infra/serverless-api.yml` bootstraps stable
serverless infrastructure:

- Lambda function `crud-fastapi`
- API Gateway HTTP API
- default API routes `ANY /` and `ANY /{proxy+}`

Deploy or update the infrastructure stack with the custom domain:

```bash
infra/deploy-serverless-api.nu \
  --image-uri <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:<git-commit-sha>
```

Get the API outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name crud-serverless-api \
  --region us-east-1 \
  --query "Stacks[0].Outputs"
```

Routine backend releases should update only the Lambda container image, not the
whole infrastructure stack:

```bash
infra/update-serverless-image.nu \
  --image-uri <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:<git-commit-sha> \
  --wait
```

Test the API:

```bash
curl <ApiEndpoint>/
curl <ApiEndpoint>/api/v1/health
```

The `ApiEndpoint` value is available from the `crud-serverless-api` stack
outputs.

### Backend API Custom Domain

The API custom domain uses an ACM certificate in AWS and a CNAME record in
Cloudflare. The deploy script automatically finds an issued certificate for
`api.crud.mert-kurttutan.com`. Set `CERTIFICATE_ARN` only when you need to
override that lookup.

Request the certificate once:

```bash
aws acm request-certificate \
  --domain-name api.crud.mert-kurttutan.com \
  --validation-method DNS \
  --region us-east-1
```

Get the DNS validation record:

```bash
CertificateArn=$(aws acm list-certificates \
  --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='api.crud.mert-kurttutan.com'].CertificateArn" \
  --output text)

aws acm describe-certificate \
  --certificate-arn "$CertificateArn" \
  --region us-east-1 \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord"
```

Add the returned CNAME to Cloudflare DNS as DNS only, then wait for validation:

```bash
aws acm wait certificate-validated \
  --certificate-arn "$CertificateArn" \
  --region us-east-1
```

Deploy the serverless stack with the custom domain:

```bash
infra/deploy-serverless-api.nu \
  --image-uri <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:<git-commit-sha>
```

### Cloudflare API DNS

After the API stack has a custom domain output, sync the Cloudflare CNAME with:

```bash
export CLOUDFLARE_API_TOKEN="..."
export CLOUDFLARE_ZONE_ID="..."

infra/sync-cloudflare-api-dns.nu
```

Defaults:

```text
RECORD_NAME=api.crud.mert-kurttutan.com
STACK_NAME=crud-serverless-api
AWS_REGION=us-east-1
CLOUDFLARE_PROXIED=false
```

Override them inline when needed:

```bash
RECORD_NAME=api.crud.mert-kurttutan.com \
CLOUDFLARE_PROXIED=false \
infra/sync-cloudflare-api-dns.nu
```

Detach the Cloudflare DNS record:

```bash
infra/desync-cloudflare-api-dns.nu
```

Delete the serverless stack:

```bash
infra/delete-serverless-api.nu --wait
```

Delete the CodeBuild/ECR stack after emptying the ECR repository:

```bash
infra/delete-codebuild-ecr.nu --wait
```
