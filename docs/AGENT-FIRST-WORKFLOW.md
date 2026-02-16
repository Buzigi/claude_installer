# Agent-First Workflow Configuration

This document describes the Agent-First workflow configuration that ensures Claude Code always delegates tasks to specialized sub-agents.

## Overview

The Agent-First workflow is a configuration pattern that ensures Claude Code **always** uses specialized sub-agents for task execution, rather than handling tasks directly. This provides:

- **Consistent Quality**: Tasks are always handled by the most appropriate specialist
- **Better Orchestration**: Complex multi-step tasks are properly coordinated
- **Improved Reliability**: Agents have specialized tools and knowledge
- **Scalability**: Easy to add new capabilities without modifying core behavior

## Configuration Files

### 1. settings.json

Located at `~/.claude/settings.json`, this file enables the agent orchestration system:

```json
{
  "agentOrchestration": {
    "enabled": true,
    "mode": "always",
    "defaultAgent": "task-manager",
    "agentSelectionStrategy": "automatic",
    "fallbackToDirect": false,
    "minTaskComplexity": 1,
    "preferSpecializedAgents": true,
    "allowAgentChaining": true,
    "maxConcurrentAgents": 5,
    "coordinationTimeout": 300000
  }
}
```

**Key Settings:**
- `enabled: true` - Agent orchestration is active
- `mode: "always"` - Always use agents (never execute directly)
- `fallbackToDirect: false` - Never fall back to direct execution
- `minTaskComplexity: 1` - Use agents even for simple tasks
- `allowAgentChaining: true` - Agents can delegate to other agents

### 2. hooks.json

Located at `~/.claude/hooks.json`, this file enforces agent usage through hooks:

```json
{
  "hooks": {
    "user-prompt-submit": {
      "enabled": true,
      "handler": "agent-orchestrator",
      "config": {
        "forceAgentUsage": true,
        "excludeSimpleTasks": false,
        "allowDirectExecution": false
      }
    }
  }
}
```

**Key Settings:**
- `forceAgentUsage: true` - Always require an agent
- `excludeSimpleTasks: false` - Don't exclude any tasks from agent usage
- `allowDirectExecution: false` - Never allow direct tool usage

### 3. Pre-Prompt Hook

The `pre-prompt-hook.ps1` script automatically adds agent delegation instructions to every prompt:

```powershell
# Runs before every user prompt
# Adds instruction: "Always delegate this task to an appropriate specialized agent"
```

## How It Works

### Flow Diagram

```
User Prompt
    ↓
Pre-Prompt Hook (adds agent instruction)
    ↓
Claude Receives Prompt + Agent Instruction
    ↓
Claude Selects Appropriate Agent
    ↓
Agent Executes Task
    ↓
Agent Returns Result
    ↓
Claude Presents Result to User
```

### Agent Selection

The system automatically selects the most appropriate agent based on the task:

| Task Type | Primary Agent | Secondary Agents |
|-----------|---------------|------------------|
| Complex/Multi-step | task-manager | Any specialized agent |
| Exploration/Structure | project-navigator | Explore agent |
| UI/Frontend | frontend-developer | rapid-prototyper |
| API/Backend | backend-architect | ai-engineer |
| Testing/Quality | test-writer-fixer | experiment-tracker |
| Git/Version Control | git-github-specialist | - |
| Deployment | devops-automator | project-shipper |
| Planning | Plan agent | sprint-prioritizer |
| Research | general-purpose | trend-researcher |

### Available Agents

The installer includes 44+ specialized agents, organized into categories:

#### Core Agents
- **task-manager**: Orchestrates complex, multi-step tasks
- **project-navigator**: Understands project structure and coordinates work
- **software-architect**: Designs system architecture

#### Development Agents
- **frontend-developer**: UI components, React/Vue/Angular
- **backend-architect**: APIs, databases, server logic
- **ai-engineer**: AI/ML features, LLM integration
- **mobile-app-builder**: iOS/Android, React Native
- **fullstack-developer**: End-to-end features

#### Quality Agents
- **test-writer-fixer**: Test creation and fixing
- **code-reviewer**: Code quality and standards
- **security-analyst**: Security vulnerabilities

#### Operations Agents
- **devops-automator**: CI/CD, infrastructure, monitoring
- **git-github-specialist**: Git operations, PRs, branching
- **project-shipper**: Release management

#### Research Agents
- **Explore**: Fast codebase exploration
- **general-purpose**: Complex research tasks
- **trend-researcher**: Market trends and viral features

#### Planning Agents
- **Plan**: Implementation planning
- **sprint-prioritizer**: Feature prioritization
- **studio-producer**: Resource coordination

#### Content Agents
- **claude-code-guide**: Claude Code documentation
- **tiktok-strategist**: TikTok marketing
- **joker**: Humor and entertainment
- **whimsy-injector**: Delightful UX elements

#### Feedback Agents
- **feedback-synthesizer**: User feedback analysis

#### Experimentation Agents
- **experiment-tracker**: A/B test management

#### Prototyping Agents
- **rapid-prototyper**: MVP and prototype creation

#### Coaching Agents
- **studio-coach**: Team coordination and motivation

## Usage Examples

### Example 1: Simple Task

**User Input:**
```
Create a new function to calculate Fibonacci numbers
```

**Agent-First Behavior:**
1. Pre-prompt hook adds: "Always delegate this task to an appropriate specialized agent"
2. Claude selects: `backend-architect` or `general-purpose` depending on context
3. Agent creates the function with proper testing
4. Result presented to user

### Example 2: Complex Task

**User Input:**
```
Add user authentication to the app
```

**Agent-First Behavior:**
1. Pre-prompt hook adds agent instruction
2. Claude selects: `task-manager` (for orchestration)
3. Task-manager coordinates:
   - `backend-architect`: Designs auth API
   - `frontend-developer`: Creates login UI
   - `test-writer-fixer`: Adds tests
   - `security-analyst`: Reviews for vulnerabilities
4. Coordinated result presented

### Example 3: Exploration

**User Input:**
```
Where is the error handling for API calls?
```

**Agent-First Behavior:**
1. Pre-prompt hook adds agent instruction
2. Claude selects: `Explore` or `project-navigator`
3. Agent searches codebase and finds relevant files
4. Result presented with file paths and line numbers

## Permissions Configuration

### Full Permissions (Except Delete)

The configuration grants full permissions for all operations:

```json
{
  "permissions": {
    "defaultMode": "allow",
    "allowedTools": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "Task(*)",
      "TaskOutput(*)",
      "TaskStop(*)",
      "NotebookEdit(*)",
      "WebSearch(*)",
      "WebFetch(*)",
      "AskUserQuestion(*)",
      "Skill(*)",
      "EnterPlanMode(*)",
      "ExitPlanMode(*)",
      "TodoWrite(*)",
      "mcp__4_5v_mcp__analyze_image(*)",
      "mcp__web_reader__webReader(*)"
    ],
    "deniedTools": [],
    "askBeforeUse": []
  }
}
```

### Delete Protection

Destructive operations require confirmation:

```json
{
  "deleteProtection": {
    "enabled": true,
    "confirmBeforeDelete": true,
    "protectedPaths": [
      "~/.claude",
      "~/projects",
      "C:/Users/*/projects"
    ],
    "requireConfirmationFor": [
      "Bash",
      "Edit",
      "Write"
    ],
    "deleteCommands": [
      "rm",
      "rmdir",
      "del",
      "Remove-Item",
      "git clean"
    ]
  }
}
```

**Protected Operations:**
- Any Bash command with `rm`, `rmdir`, `del`, `Remove-Item`, or `git clean`
- Write operations to protected paths
- Edit operations that replace large content blocks
- Git operations that delete history

**Behavior:**
- Pre-tool hook detects destructive operations
- Creates automatic backup
- Requires explicit acknowledgment
- Requests user permission

## Troubleshooting

### Agent Not Being Used

If Claude is not using agents:

1. **Check settings.json**:
   ```powershell
   Get-Content ~/.claude/settings.json | ConvertFrom-Json | Select agentOrchestration
   ```

2. **Verify hook is installed**:
   ```powershell
   Test-Path ~/.claude/hooks/pre-prompt.ps1
   ```

3. **Check hook is executable**:
   ```powershell
   Get-Content ~/.claude/hooks/pre-prompt.ps1
   ```

4. **Restart Claude Code**:
   ```powershell
   # Restart to reload configuration
   ```

### Delete Protection Not Working

If delete operations proceed without confirmation:

1. **Verify hooks.json exists**:
   ```powershell
   Test-Path ~/.claude/hooks.json
   ```

2. **Check pre-tool hook**:
   ```powershell
   Get-Content ~/.claude/hooks/pre-tool.ps1
   ```

3. **Verify delete protection enabled**:
   ```powershell
   Get-Content ~/.claude/settings.json | ConvertFrom-Json | Select deleteProtection
   ```

## Best Practices

### 1. Trust the Agent System

The agent-first approach works best when you:
- Let agents handle tasks fully
- Don't try to micro-manage
- Provide clear requirements
- Trust agent specialization

### 2. Use Appropriate Agents

Different tasks benefit from different agents:
- **Complex tasks**: task-manager
- **Exploration**: Explore or project-navigator
- **Implementation**: Specialized dev agents
- **Testing**: test-writer-fixer
- **Deployment**: devops-automator or project-shipper

### 3. Leverage Agent Chaining

Agents can delegate to other agents:
- task-manager → backend-architect → test-writer-fixer
- project-navigator → frontend-developer → whimsy-injector
- Plan agent → task-manager → implementation agents

### 4. Monitor Agent Activity

Enable debug mode to see agent activity:
```json
{
  "advanced": {
    "agentDebugEnabled": true
  },
  "uiPreferences": {
    "showAgentActivity": true,
    "showTaskProgress": true
  }
}
```

## Summary

The Agent-First workflow ensures:

✅ **Always uses agents** - No direct tool usage
✅ **Automatic selection** - Best agent chosen automatically
✅ **Full permissions** - Can execute any operation
✅ **Delete protection** - Destructive ops require confirmation
✅ **Agent chaining** - Complex tasks coordinated automatically
✅ **Consistent quality** - Specialists handle specialized tasks

This configuration maximizes Claude Code's capabilities while maintaining safety through delete protection.
