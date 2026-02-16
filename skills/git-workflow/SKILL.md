---
name: git-workflow
description: Advanced Git workflow management, branching strategies, and automation
tools: Read, Write, Bash, Glob, Grep
---

# Git Workflow Skill

Comprehensive Git workflow management and automation capabilities.

## Core Concepts

### Branching Strategies

#### Git Flow

```
main (production)
  ↑
  develop
  ↑
feature/*          hotfix/*
release/*
```

#### Trunk-Based Development

```
main (trunk)
  ↑
feature/* (short-lived)
```

#### GitHub Flow

```
main
  ↑
feature/* → PR → Review → Merge
```

## Common Workflows

### Feature Development

```bash
# Start feature
git checkout -b feature/user-auth

# Work on feature
git add .
git commit -m "Add login form"

# Push and create PR
git push -u origin feature/user-auth
```

### Hotfix Process

```bash
# Create hotfix from main
git checkout main
git checkout -b hotfix/critical-bug

# Fix and commit
git add .
git commit -m "Fix critical security issue"

# Merge to main and develop
git checkout main
git merge hotfix/critical-bug
git checkout develop
git merge hotfix/critical-bug
```

### Release Process

```bash
# Start release
git checkout develop
git checkout -b release/1.0.0

# Finalize release
git add .
git commit -m "Bump version to 1.0.0"

# Merge to main and develop
git checkout main
git merge release/1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"
git checkout develop
git merge release/1.0.0
```

## Advanced Operations

### Interactive Rebase

```bash
# Rebase last 3 commits
git rebase -i HEAD~3

# Rebase onto main
git checkout feature-branch
git rebase main
```

### Cherry-Picking

```bash
# Cherry-pick specific commit
git cherry-pick abc123

# Cherry-pick multiple commits
git cherry-pick def456..ghi789
```

### Squashing

```bash
# Squash last 3 commits
git reset --soft HEAD~3
git commit -m "Squashed commit message"
```

## Automation

### Git Hooks

#### Pre-commit Hook

```bash
#!/bin/bash
# Run tests before commit
npm test
if [ $? -ne 0 ]; then
  echo "Tests failed. Aborting commit."
  exit 1
fi
```

#### Pre-push Hook

```bash
#!/bin/bash
# Run lint before push
npm run lint
if [ $? -ne 0 ]; then
  echo "Lint failed. Aborting push."
  exit 1
fi
```

### Aliases

```bash
# Useful aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual 'log --graph --oneline --all --decorate'
```

## Best Practices

### Commit Messages

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: feat, fix, docs, style, refactor, test, chore

Example:

```
feat(auth): add user login

- Implement login form
- Add JWT authentication
- Include error handling

Closes #123
```

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Urgent production fixes
- `release/version` - Release preparation
- `experiment/description` - Experimental features

### Code Review

1. Keep PRs focused and small
2. Include clear descriptions
3. Reference related issues
4. Ensure CI passes
5. Request appropriate reviewers

## Troubleshooting

### Undo Last Commit

```bash
# Keep changes
git reset --soft HEAD~1

# Discard changes
git reset --hard HEAD~1
```

### Recover Lost Commit

```bash
# Find lost commit
git reflog

# Restore commit
git checkout <commit-hash>
git branch recovery-branch
```

### Resolve Merge Conflicts

```bash
# Mark conflict as resolved
git add <file>

# Abort merge
git merge --abort

# Continue merge
git commit
```

## Integration with Claude Code

Use this skill with Claude Code:

```bash
# Create feature branch
claude --skill git-workflow "Create a new feature branch for user authentication"

# Resolve conflicts
claude --skill git-workflow "Help resolve merge conflicts in payment module"

# Clean up history
claude --skill git-workflow "Squash last 5 commits into one"
```

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
