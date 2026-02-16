# Claude Code Installer - Troubleshooting Guide

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Configuration Problems](#configuration-problems)
3. [Skills Not Working](#skills-not-working)
4. [Agents Not Responding](#agents-not-responding)
5. [Performance Issues](#performance-issues)
6. [MCP Server Issues](#mcp-server-issues)
7. [Common Error Messages](#common-error-messages)
8. [Getting Help](#getting-help)

## Installation Issues

### "claude: command not found"

**Symptoms:**
- Command not found after installation
- CLI not accessible in terminal

**Solutions:**

1. **Restart PowerShell/Terminal**
   ```powershell
   # Close and reopen PowerShell
   # Or refresh environment variables
   $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
   ```

2. **Check npm global installation**
   ```powershell
   # Verify npm global location
   npm config get prefix

   # Check if claude is installed
   npm list -g @anthropic-ai/claude-code

   # Reinstall if missing
   npm install -g @anthropic-ai/claude-code
   ```

3. **Add npm to PATH**
   ```powershell
   # Get npm prefix
   $npmPrefix = npm config get prefix

   # Add to PATH (temporary)
   $env:Path += ";$npmPrefix"

   # Add to PATH (permanent)
   [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
   ```

### "Execution Policy Restriction"

**Symptoms:**
- Cannot run PowerShell scripts
- "Execution policy" error message

**Solutions:**

```powershell
# Check current policy
Get-ExecutionPolicy

# Set for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for current session
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### "Permission Denied" Errors

**Symptoms:**
- Cannot create files in .claude directory
- Access denied errors

**Solutions:**

1. **Run as Administrator**
   ```powershell
   # Right-click PowerShell > Run as Administrator
   ```

2. **Fix Directory Permissions**
   ```powershell
   # Take ownership
   icacls "$env:USERPROFILE\.claude" /grant "$env:USERNAME:(OI)(CI)F"
   ```

3. **Check Antivirus**
   - Temporarily disable antivirus
   - Add exclusion for Claude Code directory

### "Node.js Not Found"

**Symptoms:**
- npm command not found
- Node.js not installed

**Solutions:**

```powershell
# Install Node.js using Chocolatey
choco install nodejs -y

# Or download from https://nodejs.org/

# Verify installation
node --version
npm --version
```

## Configuration Problems

### "Invalid JSON" Errors

**Symptoms:**
- Configuration not loading
- JSON parse errors

**Solutions:**

1. **Validate JSON Syntax**
   ```powershell
   # Test JSON file
   Get-Content $env:USERPROFILE\.claude\settings.json | ConvertFrom-Json

   # If error, fix syntax issues
   ```

2. **Common JSON Issues:**
   - Missing commas between properties
   - Trailing commas (not allowed in JSON)
   - Unquoted property names
   - Single quotes instead of double quotes

3. **Use JSON Validator**
   - https://jsonlint.com/
   - VS Code: Install JSON extension

### Configuration Not Applied

**Symptoms:**
- Settings not taking effect
- Old configuration still used

**Solutions:**

1. **Restart Claude Code**
   ```bash
   exit
   claude
   ```

2. **Clear Cache**
   ```powershell
   # Remove cache directory
   Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\cache"

   # Restart Claude
   ```

3. **Check Multiple Config Files**
   ```powershell
   # Check settings.local.json overrides
   cat $env:USERPROFILE\.claude\settings.local.json

   # Check project-specific .claude.json
   cat .claude.json
   ```

### Model Not Available

**Symptoms:**
- "Model not found" error
- Cannot use GLM5

**Solutions:**

1. **Verify Model Name**
   ```json
   {
     "model": "glm5"
   }
   ```

2. **Check API Configuration**
   ```json
   {
     "apiEndpoint": "https://api.anthropic.com/v1/messages"
   }
   ```

3. **Test Model Access**
   ```bash
   claude --model glm5 "test"
   ```

## Skills Not Working

### "Skill Not Found"

**Symptoms:**
- Cannot use installed skill
- "Skill not found" error

**Solutions:**

1. **Verify Skill Installation**
   ```powershell
   # Check skill directory
   ls $env:USERPROFILE\.claude\skills

   # Check specific skill
   ls $env:USERPROFILE\.claude\skills\drawio
   ```

2. **Check Skill Metadata**
   ```powershell
   # Verify .skillfish.json exists
   Test-Path "$env:USERPROFILE\.claude\skills\drawio\.skillfish.json"

   # Check content
   cat "$env:USERPROFILE\.claude\skills\drawio\.skillfish.json"
   ```

3. **Verify SKILL.md**
   ```powershell
   # Check SKILL.md exists
   Test-Path "$env:USERPROFILE\.claude\skills\drawio\SKILL.md"

   # Check frontmatter
   cat "$env:USERPROFILE\.claude\skills\drawio\SKILL.md"
   ```

### Skill Not Loading

**Symptoms:**
- Skill installed but not active
- No error message

**Solutions:**

1. **Restart Claude Code**
   ```bash
   exit
   claude
   ```

2. **Check Skill Frontmatter**
   ```markdown
   ---
   name: skill-name
   description: Skill description
   tools: Read, Write, Bash
   ---
   ```

3. **Update Skills**
   ```powershell
   .\Update-Skills.ps1
   ```

## Agents Not Responding

### "Agent Not Found"

**Symptoms:**
- Cannot use installed agent
- "Agent not found" error

**Solutions:**

1. **Verify Agent Installation**
   ```powershell
   # List agents
   ls $env:USERPROFILE\.claude\agents

   # Check specific agent
   Test-Path "$env:USERPROFILE\.claude\agents\task-manager-agent.md"
   ```

2. **Check Agent File Format**
   ```markdown
   ---
   name: agent-name
   description: Agent description
   tools: Read, Write, Bash
   ---
   ```

3. **Verify File Extension**
   ```powershell
   # Must be .md extension
   Get-ChildItem $env:USERPROFILE\.claude\agents -Filter "*.md"
   ```

### Agent Not Following Instructions

**Symptoms:**
- Agent doesn't follow defined behavior
- Unexpected responses

**Solutions:**

1. **Check Agent Instructions**
   ```powershell
   # Review agent file
   cat $env:USERPROFILE\.claude\agents\agent-name.md
   ```

2. **Verify Tools Section**
   ```markdown
   ---
   tools: Read, Write, Bash, Glob, Grep
   ---
   ```

3. **Test with Simple Task**
   ```bash
   claude --agent agent-name "test"
   ```

## Performance Issues

### Slow Response Times

**Symptoms:**
- Long delays in responses
- Commands hang

**Solutions:**

1. **Check Network Connection**
   ```powershell
   # Test connectivity
   Test-NetConnection api.anthropic.com -Port 443
   ```

2. **Reduce Cache Size**
   ```json
   {
     "cacheSizeMB": 256
   }
   ```

3. **Disable Features**
   ```json
   {
     "streaming": false,
     "thinkingMode": false
   }
   ```

### High Memory Usage

**Symptoms:**
- Claude Code uses excessive memory
- System slowdown

**Solutions:**

1. **Clear Cache**
   ```powershell
   Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\cache"
   ```

2. **Reduce History**
   ```json
   {
     "historyMaxEntries": 100,
     "historyDaysToKeep": 7
   }
   ```

3. **Restart Regularly**
   ```bash
   exit
   claude
   ```

## MCP Server Issues

### MCP Server Not Starting

**Symptoms:**
- MCP server connection errors
- Server not available

**Solutions:**

1. **Check Server Configuration**
   ```powershell
   cat $env:USERPROFILE\.claude.json
   ```

2. **Verify Server Installation**
   ```powershell
   # Test chrome-devtools MCP
   npx chrome-devtools-mcp@latest --version
   ```

3. **Check Server Command**
   ```json
   {
     "mcpServers": {
       "chrome-devtools": {
         "command": "npx",
         "args": ["chrome-devtools-mcp@latest"]
       }
     }
   }
   ```

### MCP Server Timeout

**Symptoms:**
- Server starts but times out
- Intermittent failures

**Solutions:**

1. **Increase Timeout**
   ```json
   {
     "timeout": 30000
   }
   ```

2. **Check Server Logs**
   ```powershell
   cat $env:USERPROFILE\.claude\debug\mcp.log
   ```

3. **Restart Server**
   ```powershell
   # Kill existing server
   Get-Process | Where-Object {$_.ProcessName -like "*chrome-devtools*"} | Stop-Process

   # Restart Claude
   ```

## Common Error Messages

### "API Key Invalid"

**Solution:**
```bash
# Re-authenticate
claude --login
```

### "Rate Limit Exceeded"

**Solution:**
```json
{
  "rateLimit": {
    "requestsPerMinute": 60,
    "retryAfter": 60
  }
}
```

### "File Not Found"

**Solution:**
```powershell
# Check file path
Test-Path "C:\path\to\file"

# Use absolute paths
claude --agent project-navigator "Find file in C:\Users\YourName\project"
```

### "Permission Denied"

**Solution:**
```powershell
# Run as Administrator
# Or check file permissions
icacls "C:\path\to\file"
```

## Getting Help

### Debug Mode

Enable debug logging:

```powershell
# Enable debug mode
$env:CLAUDE_DEBUG = "true"

# Run with verbose output
claude --verbose
```

### Log Files

Check log files:

```powershell
# Claude logs
ls $env:USERPROFILE\.claude\debug

# Recent logs
Get-Content "$env:USERPROFILE\.claude\debug\latest.log" -Tail 50
```

### Reporting Issues

When reporting issues, include:

1. **System Information**
   ```powershell
   $PSVersionTable
   node --version
   npm --version
   ```

2. **Error Messages**
   - Full error text
   - Stack traces

3. **Configuration**
   ```powershell
   cat $env:USERPROFILE\.claude\settings.json
   ```

4. **Steps to Reproduce**
   - What you did
   - What you expected
   - What happened

### Support Resources

- **Documentation**: [docs/](.)
- **GitHub Issues**: [claude-installer/issues](https://github.com/your-org/claude-installer/issues)
- **Community**: [Discord/Slack]
- **Email**: support@example.com

### Reinstallation

As last resort, reinstall:

```powershell
# Backup configuration
Copy-Item $env:USERPROFILE\.claude $env:USERPROFILE\.claude.backup -Recurse

# Uninstall
npm uninstall -g @anthropic-ai/claude-code

# Remove config
Remove-Item $env:USERPROFILE\.claude -Recurse -Force

# Reinstall
.\Install-ClaudeCode.ps1

# Restore config (if needed)
Copy-Item $env:USERPROFILE\.claude.backup\settings.json $env:USERPROFILE\.claude\settings.json
```

## Prevention

### Regular Maintenance

1. **Keep Updated**
   ```powershell
   npm update -g @anthropic-ai/claude-code
   .\Update-Skills.ps1
   ```

2. **Clean Cache**
   ```powershell
   Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\cache"
   ```

3. **Backup Configuration**
   ```powershell
   Copy-Item $env:USERPROFILE\.claude $env:USERPROFILE\.claude.backup.$(Get-Date -Format "yyyyMMdd") -Recurse
   ```

### Best Practices

1. **Run installer as Administrator**
2. **Restart terminal after installation**
3. **Verify installation with test script**
4. **Keep configuration files backed up**
5. **Update regularly**
6. **Monitor disk space for cache**
7. **Use appropriate permissions**
8. **Read error messages carefully**
9. **Check logs for issues**
10. **Report bugs with details**
