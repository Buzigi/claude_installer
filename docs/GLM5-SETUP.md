# GLM5 Model Setup Guide

This guide explains how to properly configure GLM5 (from Zhipu AI) with Claude Code.

## What is GLM5?

GLM5 is a large language model from Zhipu AI (a Chinese AI company). It is accessed through a custom proxy endpoint that provides an Anthropic-compatible API.

## API Configuration

GLM5 requires two key configuration values:

### 1. API Endpoint (Base URL)
```
https://api.z.ai/api/anthropic
```

This is a proxy endpoint that provides Anthropic-compatible access to GLM5.

### 2. API Key (Auth Token)
Format: `id.secret` (e.g., `7fcbc44c8a614fb6bdc3255045217c43.YN6cNs0cmReWRx1D`)

You need to obtain this from your GLM5/Zhipu AI provider.

## Installation Process

When you run the installer with `-Model glm5`, it will:

1. **Prompt for API Key**
   ```powershell
   Enter your GLM5 API key (format: id.secret):
   ```

2. **Set Environment Variables** (optional)
   - `ANTHROPIC_BASE_URL` = `https://api.z.ai/api/anthropic`
   - `ANTHROPIC_AUTH_TOKEN` = your_api_key

3. **Create Configuration Files**
   - `~/.claude/settings.json` - Contains API URL and key
   - `~/.claude/setup-glm5-env.ps1` - Environment setup script

## Configuration Methods

### Method 1: Environment Variables (Recommended for Security)

Set system environment variables:

**PowerShell (User level):**
```powershell
[System.Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', 'https://api.z.ai/api/anthropic', 'User')
[System.Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', 'your_api_key_here', 'User')
```

**GUI Method:**
1. Press `Win+R` and type: `sysdm.cpl`
2. Go to **Advanced** tab → **Environment Variables**
3. Add new **User variables**:
   - Variable: `ANTHROPIC_BASE_URL`
   - Value: `https://api.z.ai/api/anthropic`
   - Variable: `ANTHROPIC_AUTH_TOKEN`
   - Value: `your_api_key_here`
4. Click OK and restart PowerShell

### Method 2: Configuration File

The installer creates `~/.claude/settings.json` with:
```json
{
  "model": "glm5",
  "apiUrl": "https://api.z.ai/api/anthropic",
  "apiKey": "your_api_key_here"
}
```

### Method 3: Per-Session Script

Run the setup script created by the installer:
```powershell
~/.claude/setup-glm5-env.ps1
```

Or manually set in each session:
```powershell
$env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
$env:ANTHROPIC_AUTH_TOKEN = "your_api_key_here"
```

## How GLM5 Integration Works

### The Proxy Architecture

```
Claude Code CLI
    ↓
Uses Anthropic-compatible API
    ↓
ANTHROPIC_BASE_URL = https://api.z.ai/api/anthropic
    ↓
Zhipu AI Proxy Server
    ↓
Translates to GLM5 format
    ↓
GLM5 Model (Zhipu AI)
    ↓
Returns response in Anthropic format
    ↓
Claude Code receives response
```

### Why This Works

The Zhipu AI proxy (`https://api.z.ai/api/anthropic`) provides:

1. **Anthropic-Compatible Endpoints**
   - Same request/response format as Anthropic's API
   - Allows using existing Claude Code CLI without modification

2. **Protocol Translation**
   - Converts Anthropic API requests to GLM5 format
   - Converts GLM5 responses back to Anthropic format

3. **Authentication**
   - Uses `ANTHROPIC_AUTH_TOKEN` instead of standard Anthropic API key
   - Format: `id.secret` (Zhipu AI format)

## Testing Your Setup

### 1. Verify Environment Variables

```powershell
# Check if variables are set
$env:ANTHROPIC_BASE_URL
$env:ANTHROPIC_AUTH_TOKEN
```

Expected output:
```
https://api.z.ai/api/anthropic
7fcbc44c... (your API key)
```

### 2. Test with Claude Code

```bash
# Start Claude Code
claude

# Test simple request
claude --model glm5 "Say hello and confirm you're running GLM5"
```

### 3. Check Configuration

```powershell
# View settings
cat ~/.claude/settings.json

# Should show:
# - model: "glm5"
# - apiUrl: "https://api.z.ai/api/anthropic"
# - apiKey: "your_api_key"
```

## Troubleshooting

### Issue: "API key not found"

**Solution:**
```powershell
# Set environment variables
$env:ANTHROPIC_AUTH_TOKEN = "your_api_key_here"
$env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
```

### Issue: "Connection refused" or "API unreachable"

**Possible causes:**
1. Wrong API endpoint
2. Network/firewall blocking access to `api.z.ai`
3. API service down

**Solution:**
```powershell
# Test connectivity
Test-NetConnection -ComputerName api.z.ai -Port 443

# Check endpoint is correct
$env:ANTHROPIC_BASE_URL  # Should be: https://api.z.ai/api/anthropic
```

### Issue: "Authentication failed"

**Possible causes:**
1. Invalid API key
2. Wrong API key format
3. Expired API key

**Solution:**
```powershell
# Verify API key format (should be id.secret)
$env:ANTHROPIC_AUTH_TOKEN -match '^\w+\.\w+$'

# Re-enter API key if needed
$env:ANTHROPIC_AUTH_TOKEN = "correct_api_key_here"
```

### Issue: "Model not found"

**Possible causes:**
1. Model name mismatch
2. API doesn't support requested model

**Solution:**
```powershell
# Verify model in settings
cat ~/.claude/settings.json | Select-String "model"

# Should show: "model": "glm5"
```

## Security Best Practices

### 1. Protect Your API Key

**❌ Don't:**
- Commit API keys to git
- Share API keys publicly
- Write keys in plain text scripts

**✅ Do:**
- Use environment variables
- Add `.claude/settings.json` to `.gitignore`
- Rotate keys regularly
- Use different keys for different environments

### 2. Git Ignore Configuration

Add to your global `.gitignore` or project `.gitignore`:
```
# Claude Code settings
.claude/settings.json
.claude/settings.local.json
.claude/glm5-key.json
```

### 3. File Permissions

```powershell
# Restrict access to Claude config directory
icacls ~/.claude /inheritance:r
icacls ~/.claude /grant:r "$($env:USERNAME):(F)"
```

## Advanced Configuration

### Custom Model Parameters

Edit `~/.claude/settings.json`:
```json
{
  "model": "glm5",
  "apiUrl": "https://api.z.ai/api/anthropic",
  "apiKey": "your_api_key",
  "advanced": {
    "maxTokens": 8192,
    "temperature": 0.7,
    "topP": 0.95,
    "topK": 40
  }
}
```

### Multiple Model Support

To support switching between GLM5 and other models:

```powershell
# Create alias for GLM5
function claude-glm5 {
    $oldBaseUrl = $env:ANTHROPIC_BASE_URL
    $oldAuthToken = $env:ANTHROPIC_AUTH_TOKEN

    $env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
    $env:ANTHROPIC_AUTH_TOKEN = "your_glm5_key"

    claude @args

    $env:ANTHROPIC_BASE_URL = $oldBaseUrl
    $env:ANTHROPIC_AUTH_TOKEN = $oldAuthToken
}
```

## Comparison: GLM5 vs Anthropic Models

| Feature | GLM5 (Zhipu AI) | Anthropic Models |
|---------|-----------------|------------------|
| **Provider** | Zhipu AI | Anthropic |
| **API Endpoint** | https://api.z.ai/api/anthropic | https://api.anthropic.com |
| **Auth Format** | id.secret | sk-ant-... |
| **Access** | Via proxy | Direct |
| **Cost** | Varies | Public pricing |
| **Capabilities** | Similar to Claude | Native Claude |

## Getting Your API Key

To obtain a GLM5 API key:

1. **Zhipu AI Platform**: Visit https://open.bigmodel.cn/
2. **Register**: Create an account
3. **API Keys**: Generate API key in dashboard
4. **Format**: Will be in `id.secret` format
5. **Copy**: Safely store your key

## Summary

GLM5 integration with Claude Code works through:

1. **Proxy Endpoint**: `https://api.z.ai/api/anthropic`
2. **Environment Variables**:
   - `ANTHROPIC_BASE_URL` - Points to proxy
   - `ANTHROPIC_AUTH_TOKEN` - Your API key
3. **Configuration**: Settings in `~/.claude/settings.json`
4. **Installer**: Automatically configures everything

The installer handles all of this for you - just run:
```powershell
.\Install-ClaudeCode.ps1 -Model glm5
```

And provide your API key when prompted!
