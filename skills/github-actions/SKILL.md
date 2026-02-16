---
name: github-actions
description: Create and manage GitHub Actions workflows, CI/CD pipelines, and GitHub automation
tools: Read, Write, Edit, Bash, Glob, Grep
---

# GitHub Actions Skill

Comprehensive GitHub Actions workflow creation, CI/CD pipeline management, and GitHub automation capabilities.

## Core Concepts

### Workflow Structure

```yaml
name: Workflow Name
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - name: Step name
        run: echo "Hello World"
```

### Trigger Types

| Trigger | Description |
|---------|-------------|
| `push` | On push to branches/tags |
| `pull_request` | On PR events (open, sync, close) |
| `workflow_dispatch` | Manual trigger |
| `schedule` | Cron schedule |
| `release` | On release creation |
| `workflow_call` | Reusable workflow |

## Common Workflows

### CI Pipeline (Node.js)

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
```

### Docker Build & Push

```yaml
name: Docker Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ secrets.DOCKERHUB_USERNAME }}/myapp

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Deploy to AWS

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push to ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: myapp
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: task-definition.json
          service: myapp-service
          cluster: myapp-cluster
```

### Release Workflow

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            dist/*
            README.md
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Reusable Workflows

### Creating a Reusable Workflow

```yaml
# .github/workflows/ci.yml
name: Reusable CI

on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        required: false
        default: '20.x'
        type: string
    secrets:
      npm-token:
        description: 'NPM token for publishing'
        required: false

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm test
```

### Using a Reusable Workflow

```yaml
name: CI

on:
  push:
    branches: [main]

jobs:
  ci:
    uses: org/repo/.github/workflows/ci.yml@main
    with:
      node-version: '18.x'
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

## Composite Actions

### Creating a Composite Action

```yaml
# .github/actions/setup/action.yml
name: 'Setup Environment'
description: 'Sets up Node.js and installs dependencies'

inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '20.x'

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      shell: bash
      run: npm ci
```

### Using a Composite Action

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/setup
    with:
      node-version: '18.x'
```

## Secrets Management

### Setting Secrets

```bash
# Using GitHub CLI
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY

# Set from file
gh secret set DOCKER_CONFIG < docker-config.json

# List secrets
gh secret list
```

### Using Secrets in Workflows

```yaml
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  API_KEY: ${{ secrets.API_KEY }}

steps:
  - name: Deploy
    env:
      SSH_KEY: ${{ secrets.SSH_KEY }}
    run: |
      echo "$SSH_KEY" > key.pem
      chmod 600 key.pem
      ssh -i key.pem user@server 'deploy.sh'
```

## Environment Variables & Contexts

### Available Contexts

| Context | Description |
|---------|-------------|
| `github` | Workflow run info (sha, ref, actor, etc.) |
| `env` | Environment variables |
| `vars` | Repository/organization variables |
| `secrets` | Encrypted secrets |
| `job` | Job-specific info |
| `steps` | Step outputs |
| `runner` | Runner info |
| `matrix` | Matrix strategy values |

### Example Usage

```yaml
env:
  APP_NAME: myapp
  ENVIRONMENT: ${{ github.ref_name }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}

    steps:
      - name: Get version
        id: version
        run: echo "version=${{ github.sha }}" >> $GITHUB_OUTPUT

      - name: Print info
        run: |
          echo "Repository: ${{ github.repository }}"
          echo "Branch: ${{ github.ref_name }}"
          echo "Commit: ${{ github.sha }}"
          echo "Actor: ${{ github.actor }}"
          echo "Event: ${{ github.event_name }}"
          echo "App: ${{ env.APP_NAME }}"
```

## Caching Strategies

### npm/yarn Cache

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20.x'
    cache: 'npm'  # or 'yarn' or 'pnpm'
```

### Custom Cache

```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  id: cache
  with:
    path: |
      node_modules
      ~/.cache
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-deps-

- name: Install dependencies
  if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

### Docker Layer Cache

```yaml
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: false
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Matrix Strategies

### Basic Matrix

```yaml
strategy:
  matrix:
    node: [16, 18, 20]
    os: [ubuntu-latest, windows-latest, macos-latest]
```

### Advanced Matrix

```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - node: 18
        os: ubuntu-latest
        experimental: false
      - node: 20
        os: ubuntu-latest
        experimental: false
      - node: 21
        os: ubuntu-latest
        experimental: true
    exclude:
      - node: 16
        os: windows-latest
```

## Security Best Practices

### Use SHA Pinning

```yaml
# Good - pinned to SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1

# Acceptable - pinned to major version
- uses: actions/checkout@v4

# Avoid - unpinned
- uses: actions/checkout
```

### Limit Permissions

```yaml
jobs:
  build:
    permissions:
      contents: read
      pull-requests: write
      packages: write
```

### Use OpenID Connect (OIDC)

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/my-github-role
    aws-region: us-east-1
```

## Debugging Workflows

### Enable Debug Logging

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### SSH Debugging

```yaml
- name: SSH Debug
  if: failure()
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 15
```

### Artifact Upload

```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: logs
    path: |
      logs/
      *.log
    retention-days: 5
```

## Self-Hosted Runners

### Using Self-Hosted Runners

```yaml
jobs:
  build:
    runs-on: self-hosted
    # or with labels
    runs-on: [self-hosted, linux, x64, gpu]
```

### Runner Groups

```yaml
jobs:
  build:
    runs-on: [self-hosted, prod]
    environment: production
```

## Conditional Execution

### Using If Expressions

```yaml
steps:
  - name: Only on main
    if: github.ref == 'refs/heads/main'
    run: echo "On main branch"

  - name: Only on success
    if: success()
    run: echo "Previous steps succeeded"

  - name: Only on failure
    if: failure()
    run: echo "Previous step failed"

  - name: Always run
    if: always()
    run: echo "This always runs"
```

### Job Dependencies

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm build

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: npm run deploy
```

## Integration with Claude Code

Use this skill with Claude Code:

```bash
# Create a CI workflow
claude --skill github-actions "Create a CI workflow for a Node.js project with testing and linting"

# Create a deployment workflow
claude --skill github-actions "Create a deployment workflow to AWS ECS"

# Add caching to existing workflow
claude --skill github-actions "Add npm caching to my .github/workflows/ci.yml"

# Create a release workflow
claude --skill github-actions "Create a release workflow that publishes to npm"

# Debug a failing workflow
claude --skill github-actions "Help debug why my GitHub Actions workflow is failing"
```

## Common Templates

### Minimal CI

```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
```

### Full CI/CD Pipeline

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test -- --coverage
      - uses: codecov/codecov-action@v4

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
      - name: Deploy
        run: |
          echo "Deploying to production..."
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
- [Starter Workflows](https://github.com/actions/starter-workflows)
