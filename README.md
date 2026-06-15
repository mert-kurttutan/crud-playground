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
aws cloudformation deploy \
  --template-file infra/codebuild-ecr.yml \
  --stack-name crud-codebuild-ecr \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

Start a backend image build:

```bash
aws codebuild start-build \
  --project-name crud-backend-image \
  --region us-east-1
```

The image URI is:

```text
<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:latest
```

### Backend API: Lambda and API Gateway

The CloudFormation template `infra/serverless-api.yml` creates:

- Lambda function `crud-fastapi`
- API Gateway HTTP API
- default API routes `ANY /` and `ANY /{proxy+}`

Deploy or update the API stack:

```bash
aws cloudformation deploy \
  --template-file infra/serverless-api.yml \
  --stack-name crud-serverless-api \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

Get the API outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name crud-serverless-api \
  --region us-east-1 \
  --query "Stacks[0].Outputs"
```

If a new image is pushed to the same `latest` tag, Lambda does not update
automatically. Refresh the function code:

```bash
aws lambda update-function-code \
  --function-name crud-fastapi \
  --image-uri <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/crud/fastapi:latest \
  --region us-east-1
```

Wait for the update:

```bash
aws lambda wait function-updated \
  --function-name crud-fastapi \
  --region us-east-1
```

Test the API:

```bash
curl <ApiEndpoint>/
curl <ApiEndpoint>/api/v1/health
```

The `ApiEndpoint` value is available from the `crud-serverless-api` stack
outputs.
