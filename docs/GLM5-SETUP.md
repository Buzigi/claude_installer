# GLM5 Model Setup Guide

This guide explains how to properly configure GLM5 (from Zhipu AI) with Claude Code.

**Reference:** https://aiengineerguide.com/blog/glm-5-in-claude-code/

## What is GLM5?

GLM5 is a large language model from Zhipu AI (z.ai). According to benchmarks, it performs comparably to Anthropic Opus 4.5. It is accessed through a custom proxy endpoint that provides an Anthropic-compatible API.

## API Configuration

GLM5 requires the following configuration in `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_zai_api_key",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
  }
}
```

### Key Configuration Values

1. **API Endpoint (Base URL)**
   ```
   https://api.z.ai/api/anthropic
   ```
   This is a proxy endpoint that provides Anthropic-compatible access to GLM5.

2. **API Key (Auth Token)**
   Format: `id.secret` (e.g., `7fcbc44c8a614fb6bdc3255045217c43.YN6cNs0cmReWRx1D`)

   You need to obtain this from z.ai.

3. **Model Mapping**
   - Haiku → `glm-4.5-air` (lighter, faster model)
   - Sonnet → `glm-5` (main model)
   - Opus → `glm-5` (same as Sonnet for now)

4. **Timeout**
   - `API_TIMEOUT_MS`: `3000000` (50 minutes) - recommended for long operations

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
   - `~/.claude/settings.json` - Contains the `env` block with API configuration
   - `~/.claude/setup-glm5-env.ps1` - Environment setup script

## Configuration Methods

### Method 1: Settings File with Env Block (Recommended)

The installer creates `~/.claude/settings.json` with the correct format:
```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_api_key_here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
  }
}
```

### Method 2: Environment Variables (System Level)

#### Windows (PowerShell)

**PowerShell Command (User level):**
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

#### Linux/macOS (Bash/Zsh)

**Add to shell configuration file:**

For Bash (`~/.bashrc`):
```bash
# GLM5 API Configuration
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="your_api_key_here"
export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5"
```

For Zsh (`~/.zshrc`):
```bash
# GLM5 API Configuration
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="your_api_key_here"
export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5"
```

For Fish (`~/.config/fish/config.fish`):
```fish
# GLM5 API Configuration
set -gx ANTHROPIC_BASE_URL "https://api.z.ai/api/anthropic"
set -gx ANTHROPIC_AUTH_TOKEN "your_api_key_here"
set -gx API_TIMEOUT_MS "3000000"
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL "glm-4.5-air"
set -gx ANTHROPIC_DEFAULT_SONNET_MODEL "glm-5"
set -gx ANTHROPIC_DEFAULT_OPUS_MODEL "glm-5"
```

**Then apply the changes:**
```bash
# For Bash/Zsh
source ~/.bashrc   # or source ~/.zshrc

# For Fish (reloads automatically)
# Or restart your terminal
```

**Using the installer (automatic):**
```bash
chmod +x install-claude-code.sh
./install-claude-code.sh
# The installer will automatically add these to your shell config
```

### Method 3: Per-Session Script

#### Windows (PowerShell)

Run the setup script created by the installer:
```powershell
~/.claude/setup-glm5-env.ps1
```

Or manually set in each session:
```powershell
$env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
$env:ANTHROPIC_AUTH_TOKEN = "your_api_key_here"
$env:API_TIMEOUT_MS = "3000000"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5"
```

#### Linux/macOS (Bash/Zsh)

Add to your current session:
```bash
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="your_api_key_here"
export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5"
```

## How GLM5 Integration Works

### The Proxy Architecture

```
Claude Code CLI
    ↓
Reads ~/.claude/settings.json env block
    ↓
ANTHROPIC_BASE_URL = https://api.z.ai/api/anthropic
ANTHROPIC_DEFAULT_SONNET_MODEL = glm-5
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

4. **Model Mapping**
   - Maps Claude model names to GLM equivalents
   - Haiku → glm-4.5-air, Sonnet/Opus → glm-5

## Testing Your Setup

### 1. Verify Settings File

```bash
# View settings
cat ~/.claude/settings.json

# Should show env block with:
# - ANTHROPIC_AUTH_TOKEN: your key
# - ANTHROPIC_BASE_URL: https://api.z.ai/api/anthropic
# - ANTHROPIC_DEFAULT_SONNET_MODEL: glm-5
```

### 2. Verify Environment Variables (if using system env)

#### Windows (PowerShell)
```powershell
# Check if variables are set
$env:ANTHROPIC_BASE_URL
$env:ANTHROPIC_AUTH_TOKEN
$env:ANTHROPIC_DEFAULT_SONNET_MODEL
```

#### Linux/macOS (Bash/Zsh)
```bash
# Check if variables are set
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_AUTH_TOKEN
echo $ANTHROPIC_DEFAULT_SONNET_MODEL
```

Expected output:
```
https://api.z.ai/api/anthropic
7fcbc44c... (your API key)
glm-5
```

### 3. Test with Claude Code

```bash
# Start Claude Code
claude

# Test simple request
claude "Say hello and confirm you're running GLM5"
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
| **Provider** | Zhipu AI (z.ai) | Anthropic |
| **API Endpoint** | https://api.z.ai/api/anthropic | https://api.anthropic.com |
| **Auth Format** | id.secret | sk-ant-... |
| **Access** | Via proxy | Direct |
| **Haiku Equivalent** | glm-4.5-air | claude-haiku-4-5 |
| **Sonnet Equivalent** | glm-5 | claude-sonnet-4-5 |
| **Opus Equivalent** | glm-5 | claude-opus-4-6 |
| **Benchmark** | Comparable to Opus 4.5 | Native Claude |

**Note:** According to z.ai, `glm-5` is available on the Max plan.

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
2. **Settings File (`~/.claude/settings.json`)**:
   ```json
   {
     "env": {
       "ANTHROPIC_AUTH_TOKEN": "your_key",
       "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
       "API_TIMEOUT_MS": "3000000",
       "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
       "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
       "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
     }
   }
   ```
3. **Environment Variables** (alternative):
   - `ANTHROPIC_BASE_URL` - Points to proxy
   - `ANTHROPIC_AUTH_TOKEN` - Your API key
   - `ANTHROPIC_DEFAULT_SONNET_MODEL` - Model mapping
4. **Installer**: Automatically configures everything

The installer handles all of this for you - just run:
```powershell
.\Install-ClaudeCode.ps1 -Model glm5
```

And provide your API key when prompted!

## References

- [GLM-5 in Claude Code Guide](https://aiengineerguide.com/blog/glm-5-in-claude-code/)
- [Claude Code Setup Docs](https://code.claude.com/docs/en/setup)
- [z.ai Platform](https://open.bigmodel.cn/)
