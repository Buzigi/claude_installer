# Claude Code Installer - Installation Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Step-by-Step Installation](#step-by-step-installation)
4. [Post-Installation](#post-installation)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Windows 10/11**: Any edition (Home, Pro, Enterprise)
- **PowerShell**: Version 5.1 or higher
- **Node.js**: Version 18.0 or higher
- **npm**: Version 9.0 or higher
- **Git**: For cloning skills and agents repositories

### Checking Prerequisites

Open PowerShell and run:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check Node.js
node --version

# Check npm
npm --version

# Check Git
git --version
```

### Installing Missing Prerequisites

#### Node.js

1. Download from https://nodejs.org/
2. Run the installer
3. Restart PowerShell

```powershell
# Or using Chocolatey
choco install nodejs -y
```

#### Git

```powershell
# Using Chocolatey
choco install git -y
```

## Installation Methods

### Method 1: Quick Install (Recommended)

For most users, use the quick install with defaults:

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to installer directory
cd C:\Users\YourUsername\projects\claude-installer

# 3. Run installer
.\Install-ClaudeCode.ps1
```

### Method 2: Custom Install

Specify custom paths and options:

```powershell
.\Install-ClaudeCode.ps1 `
  -Model glm5 `
  -InstallPath "C:\Development" `
  -SkillsPath "C:\Custom\Skills" `
  -AgentsPath "C:\Custom\Agents" `
  -IncludeMCP
```

### Method 3: Skip CLI Installation

If Claude CLI is already installed:

```powershell
.\Install-ClaudeCode.ps1 -SkipCLI
```

## Step-by-Step Installation

### Step 1: Prepare System

1. **Open PowerShell as Administrator**

   ```powershell
   # Right-click Start button > Windows PowerShell (Admin)
   # or press Win+X, then A
   ```

2. **Set Execution Policy** (if needed)

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```

3. **Navigate to Installer Directory**

   ```powershell
   cd C:\Users\$env:USERNAME\projects\claude-installer
   ```

### Step 2: Run Installer

```powershell
# View all options
Get-Help .\Install-ClaudeCode.ps1 -Full

# Run with default settings
.\Install-ClaudeCode.ps1

# Or with specific options
.\Install-ClaudeCode.ps1 -Model glm5 -IncludeMCP
```

### Step 3: Follow Prompts

The installer will:

1. Display configuration options
2. Ask for confirmation
3. Install Claude Code CLI (if needed)
4. Create configuration files
5. Install skills and agents
6. Configure MCP servers (if enabled)
7. Set up self-referential capabilities
8. Run verification tests

### Step 4: Restart Terminal

Close and reopen PowerShell to apply changes:

```powershell
# Or refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## Post-Installation

### Initial Configuration

1. **Verify Installation**

   ```powershell
   claude --version
   ```

2. **Check Configuration**

   ```powershell
   # View main settings
   cat $env:USERPROFILE\.claude\settings.json

   # View local settings
   cat $env:USERPROFILE\.claude\settings.local.json
   ```

3. **List Installed Skills**

   ```powershell
   ls $env:USERPROFILE\.claude\skills
   ```

4. **List Installed Agents**

   ```powershell
   ls $env:USERPROFILE\.claude\agents
   ```

### First Run

```bash
# Start Claude Code
claude

# Try the GLM5 model
claude --model glm5 "Hello, what can you do?"

# Test a skill
claude --skill drawio "Create a flowchart for a login process"

# Test an agent
claude --agent task-manager "Plan a simple web application"
```

### Customization

#### Change Default Model

Edit `$env:USERPROFILE\.claude\settings.json`:

```json
{
  "model": "glm5"
}
```

#### Add Custom Skills

```powershell
# Create skill directory
mkdir $env:USERPROFILE\.claude\skills\my-skill

# Create skill metadata
echo '{"version":1,"owner":"me","repo":"my-skills"}' > $env:USERPROFILE\.claude\skills\my-skill\.skillfish.json

# Create skill documentation
# Create SKILL.md with skill instructions
```

#### Add Custom Agents

```powershell
# Create agent file
cat > $env:USERPROFILE\.claude\agents\my-agent.md << 'EOF'
---
name: my-agent
description: My custom agent
tools: Read, Write, Bash
---

# My Custom Agent

Instructions for my custom agent...
EOF
```

## Verification

### Run Verification Script

```powershell
.\Verify-Installation.ps1
```

### Manual Verification Checklist

- [ ] Claude CLI is accessible: `claude --version`
- [ ] Configuration files exist: `Test-Path $env:USERPROFILE\.claude\settings.json`
- [ ] Skills are installed: `ls $env:USERPROFILE\.claude\skills`
- [ ] Agents are installed: `ls $env:USERPROFILE\.claude\agents`
- [ ] MCP servers configured (if enabled): Check `.claude.json`
- [ ] Can run basic commands: `claude --model glm5 "test"`

### Test Installation

```powershell
# Test CLI
claude --version

# Test model
claude --model glm5 "What is 2+2?"

# Test skill
claude --skill drawio "Create a simple diagram"

# Test agent
claude --agent project-navigator "What files are in the current directory?"
```

## Troubleshooting

### Common Issues

#### Issue: "claude command not found"

**Solution:**

1. Restart PowerShell
2. Check npm global location:

   ```powershell
   npm config get prefix
   ```

3. Add to PATH if needed:

   ```powershell
   $npmPath = npm config get prefix
   $env:Path += ";$npmPath"
   [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
   ```

#### Issue: "Execution Policy Restriction"

**Solution:**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue: "Permission Denied"

**Solution:**

1. Run PowerShell as Administrator
2. Or configure folder permissions:

   ```powershell
   icacls "$env:USERPROFILE\.claude" /grant "$env:USERNAME:(OI)(CI)F"
   ```

#### Issue: "Skills Not Loading"

**Solution:**

1. Verify skill directory structure:

   ```powershell
   ls $env:USERPROFILE\.claude\skills
   ```

2. Check skill metadata:

   ```powershell
   cat $env:USERPROFILE\.claude\skills\drawio\.skillfish.json
   ```

3. Ensure SKILL.md exists

#### Issue: "Agents Not Available"

**Solution:**

1. Verify agent files:

   ```powershell
   ls $env:USERPROFILE\.claude\agents
   ```

2. Check agent frontmatter:

   ```powershell
   cat $env:USERPROFILE\.claude\agents\task-manager-agent.md
   ```

### Getting Help

If issues persist:

1. Check logs: `$env:USERPROFILE\.claude\debug\`
2. Review configuration: `$env:USERPROFILE\.claude\settings.json`
3. Run with debug mode:

   ```powershell
   $VerbosePreference = "Continue"
   .\Install-ClaudeCode.ps1 -Verbose
   ```

4. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions

## Next Steps

- Read [CONFIGURATION.md](CONFIGURATION.md) for advanced configuration
- Explore available skills and agents
- Customize settings for your workflow
- Check for updates: `.\Update-Installer.ps1`

## Support

- GitHub Issues: [claude-installer/issues](https://github.com/your-org/claude-installer/issues)
- Documentation: [docs/](.)
- Community: [Discord/Slack]
