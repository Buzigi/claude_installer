<#
.SYNOPSIS
    Claude Code CLI Installer with GLM5 Configuration

.DESCRIPTION
    Automated installation script for Claude Code CLI with GLM5 model,
    complete skills repository, and full agent suite deployment.

.PARAMETER Model
    Model to configure (default: glm5)

.PARAMETER InstallPath
    Claude Code installation path (default: user home)

.PARAMETER SkillsPath
    Skills installation path (default: .claude/skills)

.PARAMETER AgentsPath
    Agents installation path (default: .claude/agents)

.PARAMETER SkipCLI
    Skip CLI installation if already installed

.PARAMETER IncludeMCP
    Include MCP server configuration

.EXAMPLE
    .\Install-ClaudeCode.ps1

.EXAMPLE
    .\Install-ClaudeCode.ps1 -Model glm5 -IncludeMCP

.EXAMPLE
    .\Install-ClaudeCode.ps1 -SkipCLI -SkillsPath "C:\custom\skills"
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('glm5', 'opus', 'sonnet', 'haiku')]
    [string]$Model = 'glm5',

    [string]$InstallPath = $env:USERPROFILE,

    [string]$SkillsPath = "$env:USERPROFILE\.claude\skills",

    [string]$AgentsPath = "$env:USERPROFILE\.claude\agents",

    [switch]$SkipCLI = $false,

    [switch]$IncludeMCP = $true
)

# GitHub repo base URL for remote execution
$RepoBaseUrl = "https://raw.githubusercontent.com/Buzigi/claude_installer/master"
$IsRemoteExecution = [string]::IsNullOrEmpty($PSScriptRoot)

# Check for admin privileges (soft check instead of #requires -RunAsAdministrator)
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "WARNING: Running without Administrator privileges. Some operations may fail." -ForegroundColor Yellow
    Write-Host "Tip: Right-click PowerShell and select 'Run as Administrator' for best results." -ForegroundColor Yellow
    Write-Host ""
}

#region Helper Functions

function Write-ColorOutput {
    <#
    .SYNOPSIS
        Write colored output to console
    #>
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    <#
    .SYNOPSIS
        Write installation step header
    #>
    param(
        [string]$Message,
        [int]$StepNumber,
        [int]$TotalSteps
    )
    Write-Host "`n" -NoNewline
    Write-ColorOutput "[$StepNumber/$TotalSteps] $Message" Cyan
    Write-ColorOutput ("=" * 80) Gray
}

function Test-Command {
    <#
    .SYNOPSIS
        Test if a command exists
    #>
    param([string]$Command)
    $null = Get-Command $Command -ErrorVariable CommandError -ErrorAction SilentlyContinue
    if ($CommandError) { return $false }
    return $true
}

function Invoke-Step {
    <#
    .SYNOPSIS
        Execute installation step with error handling
    #>
    param(
        [string]$StepName,
        [scriptblock]$ScriptBlock
    )
    try {
        Write-ColorOutput "Executing: $StepName..." Yellow
        & $ScriptBlock
        Write-ColorOutput "[OK] $StepName completed successfully" Green
        return $true
    }
    catch {
        Write-ColorOutput "[FAIL] $StepName failed: $_" Red
        return $false
    }
}

function New-DirectoryStructure {
    <#
    .SYNOPSIS
        Create directory structure if it doesn't exist
    #>
    param([string[]]$Paths)
    foreach ($Path in $Paths) {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-ColorOutput "Created directory: $Path" DarkGray
        }
    }
}

function Copy-ItemRecursive {
    <#
    .SYNOPSIS
        Copy items recursively with progress
    #>
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Filter = "*"
    )
    if (Test-Path $Source) {
        $Items = Get-ChildItem -Path $Source -Filter $Filter -Recurse
        $Total = $Items.Count
        $Current = 0

        foreach ($Item in $Items) {
            $Current++
            $Percentage = [math]::Round(($Current / $Total) * 100)
            Write-Progress -Activity "Copying files" -Status "$($Item.Name)" -PercentComplete $Percentage

            $DestinationPath = $Item.FullName.Replace($Source, $Destination)
            $DestinationDir = Split-Path $DestinationPath -Parent

            if (-not (Test-Path $DestinationDir)) {
                New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
            }

            Copy-Item -Path $Item.FullName -Destination $DestinationPath -Force
        }
        Write-Progress -Activity "Copying files" -Completed
    }
}

function Backup-ExistingConfig {
    <#
    .SYNOPSIS
        Backup existing configuration files
    #>
    param([string]$ConfigPath)
    if (Test-Path $ConfigPath) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BackupPath = "$ConfigPath.backup_$Timestamp"
        Copy-Item -Path $ConfigPath -Destination $BackupPath -Force
        Write-ColorOutput "Backed up: $ConfigPath -> $BackupPath" DarkGray
        return $BackupPath
    }
    return $null
}

#endregion

#region Installation Functions

function Install-ClaudeCLI {
    <#
    .SYNOPSIS
        Install Claude Code CLI using native installer (recommended)
    #>
    Write-ColorOutput "Checking for existing Claude CLI installation..." Yellow

    if (Test-Command "claude") {
        $CurrentVersion = & claude --version 2>&1
        Write-ColorOutput "Claude CLI already installed: $CurrentVersion" Green

        $Update = Read-Host "Update to latest version? (y/N)"
        if ($Update -eq 'y' -or $Update -eq 'Y') {
            Write-ColorOutput "Updating Claude CLI..." Yellow
            & claude update
        }
    }
    else {
        Write-ColorOutput "Installing Claude CLI via native installer (recommended)..." Yellow
        Write-ColorOutput "Running: irm https://claude.ai/install.ps1 | iex" Cyan

        try {
            # Use the official native installer (npm installation is deprecated)
            $installScript = Invoke-RestMethod -Uri "https://claude.ai/install.ps1"
            Invoke-Command -ScriptBlock ([scriptblock]::Create($installScript))

            # Refresh PATH so the current session can find the newly installed binary
            $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $env:Path = "$machinePath;$userPath"

            # Also add the common install location explicitly if not already present
            $localBin = Join-Path $env:USERPROFILE ".local\bin"
            if ((Test-Path $localBin) -and ($env:Path -notlike "*$localBin*")) {
                $env:Path = "$localBin;$env:Path"
            }

            # Persist ~/.local/bin to User PATH so it survives new sessions
            if ((Test-Path $localBin)) {
                $persistentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
                if (-not $persistentUserPath -or $persistentUserPath -notlike "*$localBin*") {
                    if ($persistentUserPath) {
                        [Environment]::SetEnvironmentVariable("Path", "$localBin;$persistentUserPath", "User")
                    }
                    else {
                        [Environment]::SetEnvironmentVariable("Path", $localBin, "User")
                    }
                    Write-ColorOutput "Added $localBin to persistent User PATH" Green
                }

                # Also add to PowerShell profile for extra reliability
                $profileDir = Split-Path $PROFILE -Parent
                if (-not (Test-Path $profileDir)) {
                    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
                }
                if (-not (Test-Path $PROFILE)) {
                    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
                }
                $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
                $pathSnippet = '# Claude Code CLI - ensure ~/.local/bin is in PATH'
                if (-not $profileContent -or $profileContent -notlike "*$pathSnippet*") {
                    $profileBlock = @"

$pathSnippet
`$localBin = Join-Path `$env:USERPROFILE ".local\bin"
if ((Test-Path `$localBin) -and (`$env:Path -notlike "*`$localBin*")) {
    `$env:Path = "`$localBin;`$env:Path"
}
"@
                    Add-Content -Path $PROFILE -Value $profileBlock
                    Write-ColorOutput "Added PATH entry to PowerShell profile: $PROFILE" Green
                }
            }

            if (Test-Command "claude") {
                Write-ColorOutput "Claude CLI installed successfully" Green
            }
            else {
                throw "Claude CLI binary not found after installation. Check that the installer completed correctly."
            }
        }
        catch {
            Write-ColorOutput "Native installer failed, trying npm fallback (deprecated)..." Yellow
            if (-not (Test-Command "npm")) {
                throw "npm is not installed. Please install Node.js from https://nodejs.org/ or fix network issues"
            }
            npm install -g @anthropic-ai/claude-code
            Write-ColorOutput "Claude CLI installed via npm (deprecated method)" Green
        }
    }
}

function Initialize-ClaudeConfig {
    <#
    .SYNOPSIS
        Initialize Claude Code configuration with Agent-First workflow and GLM5
    #>
    $ConfigDir = "$env:USERPROFILE\.claude"
    $ConfigFile = "$ConfigDir\settings.json"
    $LocalConfigFile = "$ConfigDir\settings.local.json"

    New-DirectoryStructure @($ConfigDir)

    # Backup existing configs
    Backup-ExistingConfig $ConfigFile
    Backup-ExistingConfig $LocalConfigFile

    # Prompt for GLM5 API key if using glm5 model
    $ApiKey = ""
    $ApiUrl = "https://api.z.ai/api/anthropic"

    if ($Model -eq 'glm5') {
        Write-ColorOutput "`nGLM5 API Configuration Required" Yellow
        Write-ColorOutput "GLM5 is accessed via Zhipu AI proxy: $ApiUrl" Cyan
        Write-Host ""

        # Check if API key is already in environment
        $EnvKey = $env:ANTHROPIC_AUTH_TOKEN
        if ($EnvKey) {
            Write-ColorOutput "Found API key in ANTHROPIC_AUTH_TOKEN environment variable" Green
            $UseEnvKey = Read-Host "Use existing environment variable key? (Y/n)"
            if ($UseEnvKey -ne 'n' -and $UseEnvKey -ne 'N') {
                $ApiKey = $EnvKey
            }
        }

        # Prompt for API key if not using env variable
        if (-not $ApiKey) {
            Write-ColorOutput "Enter your GLM5 API key (format: id.secret):" Yellow
            # Use -AsSecureString for PS 5.1 compat, then convert back to plain text
            $SecureKey = Read-Host "API Key" -AsSecureString
            $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
            )

            if (-not $ApiKey) {
                Write-ColorOutput "Warning: No API key provided. You'll need to configure it manually." Yellow
                $ApiKey = "YOUR_GLM5_API_KEY_HERE"
            }
        }

        # Ask about setting environment variables
        Write-Host ""
        $SetEnvVars = Read-Host "Set GLM5 environment variables permanently? (Y/n)"
        if ($SetEnvVars -ne 'n' -and $SetEnvVars -ne 'N') {
            # Set for current session
            $env:ANTHROPIC_BASE_URL = $ApiUrl
            $env:ANTHROPIC_AUTH_TOKEN = $ApiKey

            # Set permanently at user level
            try {
                [System.Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', $ApiUrl, 'User')
                [System.Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', $ApiKey, 'User')
                Write-ColorOutput "[OK] Environment variables set permanently (User level)" Green
                Write-ColorOutput "  Note: Restart all terminals/apps to use new variables" Yellow
            }
            catch {
                Write-ColorOutput "Warning: Could not set permanent environment variables: $_" Yellow
                Write-ColorOutput "Variables set for current session only" Yellow
            }
        }
    }

    # Create settings.json with GLM5 environment configuration
    # GLM5 requires specific env variables as per https://aiengineerguide.com/blog/glm-5-in-claude-code/
    $SettingsConfig = @{
        _comment = "Claude Code Configuration - GLM5 via Zhipu AI proxy"
        _comment2 = "GLM5 API: https://api.z.ai/api/anthropic (Zhipu AI proxy)"
        env = @{
            ANTHROPIC_AUTH_TOKEN = $ApiKey
            ANTHROPIC_BASE_URL = $ApiUrl
            API_TIMEOUT_MS = "3000000"
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air"
            ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5"
            ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5"
        }
        permissions = @{
            defaultMode = "bypassPermissions"
            allowedTools = @(
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
            )
            deniedTools = @()
            askBeforeUse = @()
        }
        agentOrchestration = @{
            enabled = $true
            mode = "always"
            defaultAgent = "task-manager"
            agentSelectionStrategy = "automatic"
            fallbackToDirect = $false
            minTaskComplexity = 1
            preferSpecializedAgents = $true
            allowAgentChaining = $true
            maxConcurrentAgents = 5
            coordinationTimeout = 300000
        }
        deleteProtection = @{
            enabled = $true
            confirmBeforeDelete = $true
            protectedPaths = @(
                "~/.claude",
                "~/projects",
                "C:/Users/*/projects"
            )
            requireConfirmationFor = @(
                "Bash",
                "Edit",
                "Write"
            )
            deleteCommands = @(
                "rm",
                "rmdir",
                "del",
                "Remove-Item",
                "git clean"
            )
        }
        uiPreferences = @{
            theme = "dark"
            fontSize = 14
            tabSize = 2
            showLineNumbers = $true
            wordWrap = $true
            showAgentActivity = $true
            showTaskProgress = $true
        }
        featureFlags = @{
            thinkingMode = $true
            planMode = $true
            streaming = $true
            autoSave = $true
            autoAgentMode = $true
            multiAgentCoordination = $true
        }
        advanced = @{
            maxTokens = 8192
            temperature = 0.7
            cacheEnabled = $true
            debugMode = $false
            agentDebugEnabled = $true
        }
        hooks = @{
            "PreToolUse" = @(
                @{
                    matcher = "*"
                    hooks = @(
                        @{
                            type = "command"
                            command = "powershell -File ~/.claude/hooks/pre-tool.ps1"
                        }
                    )
                }
            )
            "PostToolUse" = @(
                @{
                    matcher = "*"
                    hooks = @(
                        @{
                            type = "command"
                            command = "powershell -File ~/.claude/hooks/post-tool.ps1"
                        }
                    )
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    Set-Content -Path $ConfigFile -Value $SettingsConfig
    Write-ColorOutput "Created: $ConfigFile (Agent-First enabled)" Green

    # Create settings.local.json
    $LocalSettingsConfig = @{
        permissions = @{
            defaultMode = "bypassPermissions"
            allowedTools = @(
                "Bash(dir:*)",
                "Bash(move:*)",
                "Bash(ls:*)",
                "Bash(exiftool:*)",
                "Bash(findstr:*)",
                "Bash(choco install:*)",
                "Bash(curl:*)",
                "Bash(powershell:*)"
            )
            deniedTools = @()
            askBeforeUse = @()
        }
    } | ConvertTo-Json -Depth 10

    Set-Content -Path $LocalConfigFile -Value $LocalSettingsConfig
    Write-ColorOutput "Created: $LocalConfigFile" Green

    # Create environment setup script for GLM5
    if ($Model -eq 'glm5') {
        $EnvScriptPath = "$ConfigDir\setup-glm5-env.ps1"
        $EnvScript = @"
# GLM5 Environment Setup Script
# Run this script in each PowerShell session to configure GLM5 environment

# Set GLM5 API environment variables
`$env:ANTHROPIC_BASE_URL = "$ApiUrl"
`$env:ANTHROPIC_AUTH_TOKEN = "$ApiKey"

Write-Host "GLM5 environment configured:" -ForegroundColor Green
Write-Host "  ANTHROPIC_BASE_URL = `$env:ANTHROPIC_BASE_URL" -ForegroundColor Cyan
Write-Host "  ANTHROPIC_AUTH_TOKEN = *** (set)" -ForegroundColor Cyan
Write-Host ""
Write-Host "To make these variables permanent, add them to System Environment Variables:" -ForegroundColor Yellow
Write-Host "  1. Press Win+R and type: sysdm.cpl" -ForegroundColor Cyan
Write-Host "  2. Go to Advanced > Environment Variables" -ForegroundColor Cyan
Write-Host "  3. Add new system or user variables:" -ForegroundColor Cyan
Write-Host "     ANTHROPIC_BASE_URL = $ApiUrl" -ForegroundColor White
Write-Host "     ANTHROPIC_AUTH_TOKEN = $ApiKey" -ForegroundColor White
"@
        Set-Content -Path $EnvScriptPath -Value $EnvScript
        Write-ColorOutput "Created: $EnvScriptPath (run this in new sessions)" Green
    }
}

function Install-Skills {
    <#
    .SYNOPSIS
        Install skills from repository
    #>
    Write-ColorOutput "Installing skills..." Yellow

    # Create skills directory
    New-DirectoryStructure @($SkillsPath)

    # Copy skills from installer (local) or download from GitHub (remote)
    if (-not $IsRemoteExecution) {
        $InstallerSkillsPath = Join-Path $PSScriptRoot "skills"
        if (Test-Path $InstallerSkillsPath) {
            $SkillDirs = Get-ChildItem -Path $InstallerSkillsPath -Directory
            foreach ($SkillDir in $SkillDirs) {
                $DestPath = Join-Path $SkillsPath $SkillDir.Name
                Write-ColorOutput "Installing skill: $($SkillDir.Name)" DarkGray
                Copy-Item -Path $SkillDir.FullName -Destination $DestPath -Recurse -Force
            }
            Write-ColorOutput "Installed $($SkillDirs.Count) skills" Green
        }
        else {
            Write-ColorOutput "No skills found in installer directory" Yellow
        }
    }
    else {
        # Remote execution: download skills from GitHub
        Write-ColorOutput "Downloading skills from GitHub repository..." Yellow
        $SkillNames = @("critical-researcher", "git-workflow", "github-actions")
        $InstalledCount = 0
        foreach ($SkillName in $SkillNames) {
            $DestPath = Join-Path $SkillsPath $SkillName
            New-DirectoryStructure @($DestPath)
            try {
                $SkillContent = Invoke-RestMethod -Uri "$RepoBaseUrl/skills/$SkillName/SKILL.md"
                Set-Content -Path (Join-Path $DestPath "SKILL.md") -Value $SkillContent -Encoding UTF8
                Write-ColorOutput "Installed skill: $SkillName" DarkGray
                $InstalledCount++
            }
            catch {
                Write-ColorOutput "Failed to download skill: $SkillName - $_" Yellow
            }
        }
        Write-ColorOutput "Installed $InstalledCount skills from GitHub" Green
    }

    # Install drawio skill if not present
    $DrawioSkillPath = Join-Path $SkillsPath "drawio"
    if (-not (Test-Path $DrawioSkillPath)) {
        Write-ColorOutput "Installing drawio skill from GitHub..." Yellow
        git clone --depth 1 https://github.com/akiojin/llm-router.git "$env:TEMP\llm-router"
        if (Test-Path "$env:TEMP\llm-router\.claude\skills\drawio") {
            Copy-Item -Path "$env:TEMP\llm-router\.claude\skills\drawio" -Destination $DrawioSkillPath -Recurse -Force
            Write-ColorOutput "Drawio skill installed" Green
        }
        Remove-Item -Path "$env:TEMP\llm-router" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-Agents {
    <#
    .SYNOPSIS
        Install agents from repository
    #>
    Write-ColorOutput "Installing agents..." Yellow

    # Create agents directory
    New-DirectoryStructure @($AgentsPath)

    # Copy agents from installer (local) or download from GitHub (remote)
    if (-not $IsRemoteExecution) {
        $InstallerAgentsPath = Join-Path $PSScriptRoot "agents"
        if (Test-Path $InstallerAgentsPath) {
            $AgentFiles = Get-ChildItem -Path $InstallerAgentsPath -File -Filter "*.md"
            foreach ($AgentFile in $AgentFiles) {
                $DestPath = Join-Path $AgentsPath $AgentFile.Name
                Write-ColorOutput "Installing agent: $($AgentFile.BaseName)" DarkGray
                Copy-Item -Path $AgentFile.FullName -Destination $DestPath -Force
            }
            Write-ColorOutput "Installed $($AgentFiles.Count) agents" Green
        }
        else {
            Write-ColorOutput "No agents found in installer directory" Yellow
        }
    }
    else {
        # Remote execution: download agents from GitHub
        Write-ColorOutput "Downloading agents from GitHub repository..." Yellow
        $AgentNames = @(
            "git-github-specialist.md",
            "project-navigator-agent.md",
            "software-architect.md",
            "task-manager-agent.md"
        )
        $InstalledCount = 0
        foreach ($AgentName in $AgentNames) {
            $DestPath = Join-Path $AgentsPath $AgentName
            try {
                $AgentContent = Invoke-RestMethod -Uri "$RepoBaseUrl/agents/$AgentName"
                Set-Content -Path $DestPath -Value $AgentContent -Encoding UTF8
                Write-ColorOutput "Installed agent: $([System.IO.Path]::GetFileNameWithoutExtension($AgentName))" DarkGray
                $InstalledCount++
            }
            catch {
                Write-ColorOutput "Failed to download agent: $AgentName - $_" Yellow
            }
        }
        Write-ColorOutput "Installed $InstalledCount agents from GitHub" Green
    }

    # Install additional agents from GitHub if not present
    $AgentsRepoUrl = "https://raw.githubusercontent.com/anthropics/anthropic-agents/main"
    $RequiredAgents = @(
        "task-manager-agent.md",
        "project-navigator-agent.md",
        "software-architect.md",
        "backend-dev.md",
        "frontend-dev.md",
        "test-runner.md",
        "devops-engineer.md"
    )

    foreach ($Agent in $RequiredAgents) {
        $DestPath = Join-Path $AgentsPath $Agent
        if (-not (Test-Path $DestPath)) {
            try {
                Write-ColorOutput "Downloading agent: $Agent" DarkGray
                Invoke-RestMethod -Uri "$AgentsRepoUrl/agents/$Agent" -OutFile $DestPath
            }
            catch {
                Write-ColorOutput "Failed to download $Agent" Yellow
            }
        }
    }
}

function Initialize-MCPServers {
    <#
    .SYNOPSIS
        Initialize MCP server configuration
    #>
    if (-not $IncludeMCP) {
        Write-ColorOutput "MCP server configuration skipped" Yellow
        return
    }

    Write-ColorOutput "Configuring MCP servers..." Yellow

    $ConfigFile = "$env:USERPROFILE\.claude.json"

    # Read existing config or create new
    if (Test-Path $ConfigFile) {
        $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    }
    else {
        $Config = [PSCustomObject]@{
            projects = [PSCustomObject]@{}
        }
    }

    # Ensure projects property exists
    if (-not $Config.PSObject.Properties['projects'] -or $null -eq $Config.projects) {
        $Config | Add-Member -NotePropertyName 'projects' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    # Add MCP servers to default project
    $DefaultProjectPath = $InstallPath
    if (-not $Config.projects.PSObject.Properties[$DefaultProjectPath]) {
        $Config.projects | Add-Member -NotePropertyName $DefaultProjectPath -NotePropertyValue ([PSCustomObject]@{
            mcpServers = [PSCustomObject]@{}
            allowedTools = @()
        }) -Force
    }

    # Ensure mcpServers property exists on the project
    $ProjectConfig = $Config.projects.$DefaultProjectPath
    if (-not $ProjectConfig.PSObject.Properties['mcpServers'] -or $null -eq $ProjectConfig.mcpServers) {
        $ProjectConfig | Add-Member -NotePropertyName 'mcpServers' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    # Add chrome-devtools MCP server
    $ProjectConfig.mcpServers | Add-Member -NotePropertyName "chrome-devtools" -NotePropertyValue ([PSCustomObject]@{
        type = "stdio"
        command = "npx"
        args = @("chrome-devtools-mcp@latest")
        env = [PSCustomObject]@{}
    }) -Force

    # Save config
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile
    Write-ColorOutput "MCP servers configured" Green
}

function Initialize-SelfReferential {
    <#
    .SYNOPSIS
        Initialize self-referential capabilities
    #>
    Write-ColorOutput "Configuring self-referential capabilities..." Yellow

    # Create installer skill
    $InstallerSkillPath = Join-Path $SkillsPath "claude-installer"
    New-DirectoryStructure @($InstallerSkillPath)

    $SkillMetadata = @{
        version = 1
        owner = "claude-installer"
        repo = "claude-installer"
        path = ".claude/skills/claude-installer"
        branch = "main"
        sha = "self-generated"
    } | ConvertTo-Json -Depth 10

    Set-Content -Path "$InstallerSkillPath\.skillfish.json" -Value $SkillMetadata

    # Create skill documentation
    $SkillContent = @"
---
name: claude-installer
description: Create and modify Claude Code installer configurations, skills, and agents. Self-referential capability for the installer to improve itself.
---

# Claude Installer Skill

Self-referential skill for creating and modifying Claude Code installer components.

## Capabilities

### Create New Skills

Create new skills in the skills repository:

\`\`\`bash
claude --skill claude-installer "Create a new skill for TypeScript development"
\`\`\`

### Modify Agents

Update or create new agents:

\`\`\`bash
claude --skill claude-installer "Update the task-manager agent to include new coordination features"
\`\`\`

### Generate Installation Scripts

Create custom installation scripts:

\`\`\`bash
claude --skill claude-installer "Create a PowerShell script to install Python development tools"
\`\`\`

### Self-Documentation

Document and improve the installer:

\`\`\`bash
claude --skill claude-installer "Update the README with new features"
\`\`\`

## Directory Structure

\`\`\`
.claude/
├── skills/
│   └── claude-installer/
│       ├── .skillfish.json
│       └── SKILL.md
├── agents/
│   └── claude-installer-agent.md
└── projects/
    └── claude-installer/
\`\`\`

## Usage Examples

### Adding a New Skill Template

\`\`\`powershell
# Template for new skill
New-SkillTemplate -Name "my-skill" -Description "My custom skill"
\`\`\`

### Creating Custom Agents

\`\`\`powershell
# Create specialized agent
New-Agent -Name "my-specialist" -Role "Specialist in specific domain"
\`\`\`

## Best Practices

1. Always backup existing configurations before modifying
2. Test new skills/agents in isolation first
3. Document changes and maintain version history
4. Validate syntax before applying changes
5. Use appropriate permissions and security measures

## Self-Improvement Loop

The installer can continuously improve itself:

1. **Analyze Usage**: Collect feedback and usage patterns
2. **Identify Improvements**: Find areas for enhancement
3. **Generate Solutions**: Create new skills/agents
4. **Test and Validate**: Ensure changes work correctly
5. **Deploy Updates**: Apply improvements to itself

## Contributing

When creating new installer components:

1. Follow the existing structure and conventions
2. Include proper documentation
3. Add metadata for tracking
4. Test thoroughly before deployment
5. Version your changes
"@

    Set-Content -Path "$InstallerSkillPath\SKILL.md" -Value $SkillContent

    Write-ColorOutput "Self-referential capabilities configured" Green
}

function Install-Hooks {
    <#
    .SYNOPSIS
        Install hooks for Agent-First workflow and delete protection
    #>
    Write-ColorOutput "Installing Agent-First hooks..." Yellow

    $HooksDir = "$env:USERPROFILE\.claude\hooks"
    $BackupsDir = "$env:USERPROFILE\.claude\backups"
    $LogsDir = "$env:USERPROFILE\.claude\logs"

    New-DirectoryStructure @($HooksDir, $BackupsDir, $LogsDir)

    # Install hooks.json
    $HooksConfig = @{
        _comment = "Claude Code Hooks Configuration - Enforces Agent-First Workflow"
        version = "1.0.0"
        enabled = $true
        hooks = @{
            'Notification' = @{
                enabled = $true
                handler = "agent-orchestrator"
                config = @{
                    forceAgentUsage = $true
                    minComplexityThreshold = 1
                    excludeSimpleTasks = $false
                    defaultAgents = @(
                        "task-manager",
                        "project-navigator",
                        "frontend-developer",
                        "backend-architect",
                        "test-writer-fixer"
                    )
                    agentSelection = "automatic"
                    allowDirectExecution = $false
                    requireApprovalForDirect = $true
                }
            }
            'PreToolUse' = @{
                enabled = $true
                handler = "delete-protector"
                config = @{
                    protectedOperations = @("Write", "Edit", "Bash")
                    deletePatterns = @("rm", "rmdir", "del", "Remove-Item", "Remove-Item -Recurse", "git clean", "git reset --hard")
                    protectedPaths = @("~/.claude", "~/projects", "~/.ssh", "~/.config", "C:/Users/*/projects")
                    requireConfirmation = $true
                    backupBeforeDelete = $true
                    backupLocation = "~/.claude/backups"
                }
            }
            'PostToolUse' = @{
                enabled = $true
                handler = "operation-logger"
                config = @{
                    logAllOperations = $true
                    logFile = "~/.claude/logs/operations.log"
                    logLevel = "info"
                    includeTimestamp = $true
                    includeToolResult = $true
                }
            }
            'Stop' = @{
                enabled = $true
                handler = "agent-coordinator"
                config = @{
                    autoChainAgents = $true
                    suggestNextAgent = $true
                    allowAgentHandoff = $true
                    maxAgentChainLength = 10
                }
            }
        }
        permissions = @{
            allowBypass = $false
            adminOverride = $true
            requireExplicitPermission = $false
        }
        agentDefaults = @{
            'task-manager' = @{
                priority = 1
                useFor = @("complex", "multi-step", "coordination")
            }
            'project-navigator' = @{
                priority = 2
                useFor = @("exploration", "structure", "navigation")
            }
            'frontend-developer' = @{
                priority = 3
                useFor = @("ui", "frontend", "react", "vue")
            }
            'backend-architect' = @{
                priority = 3
                useFor = @("api", "backend", "database")
            }
            'test-writer-fixer' = @{
                priority = 4
                useFor = @("testing", "validation", "quality")
            }
        }
    } | ConvertTo-Json -Depth 10

    Set-Content -Path "$HooksDir\hooks.json" -Value $HooksConfig
    Write-ColorOutput "Created: $HooksDir\hooks.json" Green

    # Install pre-prompt hook
    $PrePromptHook = @'
# Claude Code Pre-Prompt Hook
# This hook runs before every user prompt and enforces agent-first workflow

param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,

    [Parameter(Mandatory=$true)]
    [hashtable]$Context
)

$HookConfigPath = "$env:USERPROFILE\.claude\hooks\hooks.json"
if (Test-Path $HookConfigPath) {
    $HookConfig = Get-Content $HookConfigPath -Raw | ConvertFrom-Json
    $AgentOrchestrator = $HookConfig.hooks.'Notification'

    if ($AgentOrchestrator.enabled -and $AgentOrchestrator.config.forceAgentUsage) {
        # Add agent delegation instruction to the prompt
        $AgentInstruction = @"

IMPORTANT: Always delegate this task to an appropriate specialized agent using the Task tool.
- Use the Task tool with the most suitable subagent_type for this request
- Available agents include: task-manager, project-navigator, frontend-developer, backend-architect, test-writer-fixer, and many more
- DO NOT attempt to handle complex tasks directly - always use agents
- For simple tasks, still consider using an agent for consistency and quality
"@

        # Return modified prompt with agent instruction
        return $Prompt + $AgentInstruction
    }
}

# Return original prompt if hook is disabled
return $Prompt
'@

    Set-Content -Path "$HooksDir\pre-prompt.ps1" -Value $PrePromptHook
    Write-ColorOutput "Created: $HooksDir\pre-prompt.ps1" Green

    # Install pre-tool hook
    $PreToolHook = @'
# Claude Code Pre-Tool Hook
# This hook runs before every tool use and protects against destructive operations

param(
    [Parameter(Mandatory=$true)]
    [string]$ToolName,

    [Parameter(Mandatory=$true)]
    [hashtable]$ToolInput,

    [Parameter(Mandatory=$true)]
    [hashtable]$Context
)

$HookConfigPath = "$env:USERPROFILE\.claude\hooks\hooks.json"
if (-not (Test-Path $HookConfigPath)) {
    return @{ allow = $true }
}

$HookConfig = Get-Content $HookConfigPath -Raw | ConvertFrom-Json
$DeleteProtector = $HookConfig.hooks.'PreToolUse'

if (-not $DeleteProtector.enabled) {
    return @{ allow = $true }
}

$config = $DeleteProtector.config

# Check for destructive operations
if ($ToolName -in $config.protectedOperations) {
    $command = ""

    if ($ToolName -eq "Bash" -and $ToolInput.ContainsKey('command')) {
        $command = $ToolInput.command
    } elseif ($ToolName -eq "Write" -and $ToolInput.ContainsKey('file_path')) {
        $command = "Write to $($ToolInput.file_path)"
    } elseif ($ToolName -eq "Edit" -and $ToolInput.ContainsKey('file_path')) {
        $command = "Edit $($ToolInput.file_path)"
    }

    # Check for delete patterns
    $isDeleteOperation = $false
    foreach ($pattern in $config.deletePatterns) {
        if ($command -match [regex]::Escape($pattern)) {
            $isDeleteOperation = $true
            break
        }
    }

    # Check for protected paths
    $isProtectedPath = $false
    foreach ($path in $config.protectedPaths) {
        $expandedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        if ($command -match [regex]::Escape($expandedPath)) {
            $isProtectedPath = $true
            break
        }
    }

    if ($isDeleteOperation -or $isProtectedPath) {
        # Create backup if configured
        if ($config.requireConfirmation -and $config.backupBeforeDelete) {
            $backupPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($config.backupLocation)
            if (-not (Test-Path $backupPath)) {
                New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
            }
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupFile = Join-Path $backupPath "pre_delete_backup_$timestamp.json"
            @{
                allow = $false
                reason = "DESTRUCTIVE OPERATION DETECTED: $command

This operation involves deletion or modification of a protected path.

⚠️  PROTECTED ACTION REQUIRED ⚠️

To proceed, you must:
1. Acknowledge this is a destructive operation
2. Confirm you understand the consequences
3. Request explicit user permission

Example response:
'This is a destructive operation that will: [describe impact]
I understand the consequences and request user permission to proceed.'

Backup will be created at: $backupFile"
                backupLocation = $backupFile
            }
            return
        }
    }
}

# Allow the operation
return @{ allow = $true }
'@

    Set-Content -Path "$HooksDir\pre-tool.ps1" -Value $PreToolHook
    Write-ColorOutput "Created: $HooksDir\pre-tool.ps1" Green

    # Install post-tool hook
    $PostToolHook = @'
# Claude Code Post-Tool Hook
# This hook runs after every tool use and logs operations

param(
    [Parameter(Mandatory=$true)]
    [string]$ToolName,

    [Parameter(Mandatory=$true)]
    [hashtable]$ToolResult,

    [Parameter(Mandatory=$true)]
    [hashtable]$Context
)

$HookConfigPath = "$env:USERPROFILE\.claude\hooks\hooks.json"
if (-not (Test-Path $HookConfigPath)) {
    return
}

$HookConfig = Get-Content $HookConfigPath -Raw | ConvertFrom-Json
$OperationLogger = $HookConfig.hooks.'PostToolUse'

if (-not $OperationLogger.enabled) {
    return
}

$config = $OperationLogger.config
$logPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($config.logFile)
$logDir = Split-Path $logPath -Parent

if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "[$timestamp] Tool: $ToolName"

if ($config.includeToolResult) {
    $logEntry += " | Result: $($ToolResult | ConvertTo-Json -Compress)"
}

Add-Content -Path $logPath -Value $logEntry
'@

    Set-Content -Path "$HooksDir\post-tool.ps1" -Value $PostToolHook
    Write-ColorOutput "Created: $HooksDir\post-tool.ps1" Green

    Write-ColorOutput "Agent-First hooks installed successfully" Green
    return $true
}

function Test-Installation {
    <#
    .SYNOPSIS
        Test installation
    #>
    Write-ColorOutput "`nTesting installation..." Yellow

    $TestsPassed = 0
    $TestsFailed = 0

    # Test CLI
    if (Test-Command "claude") {
        Write-ColorOutput "[OK] Claude CLI available" Green
        $TestsPassed++
    }
    else {
        # Try refreshing PATH one more time before failing
        $localBin = Join-Path $env:USERPROFILE ".local\bin"
        if ((Test-Path $localBin) -and ($env:Path -notlike "*$localBin*")) {
            $env:Path = "$localBin;$env:Path"
        }
        if (Test-Command "claude") {
            Write-ColorOutput "[OK] Claude CLI available (after PATH refresh)" Green
            # Persist fix for future sessions
            $persistentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if (-not $persistentUserPath -or $persistentUserPath -notlike "*$localBin*") {
                if ($persistentUserPath) {
                    [Environment]::SetEnvironmentVariable("Path", "$localBin;$persistentUserPath", "User")
                }
                else {
                    [Environment]::SetEnvironmentVariable("Path", $localBin, "User")
                }
                Write-ColorOutput "Persisted $localBin to User PATH for future sessions" Green
            }
            $TestsPassed++
        }
        else {
            Write-ColorOutput "[FAIL] Claude CLI not found" Red
            $TestsFailed++
        }
    }

    # Test config
    if (Test-Path "$env:USERPROFILE\.claude\settings.json") {
        Write-ColorOutput "[OK] Configuration file exists" Green
        $TestsPassed++
    }
    else {
        Write-ColorOutput "[FAIL] Configuration file missing" Red
        $TestsFailed++
    }

    # Test skills
    if (Test-Path $SkillsPath) {
        $SkillCount = (Get-ChildItem -Path $SkillsPath -Directory).Count
        Write-ColorOutput "[OK] Skills installed ($SkillCount skills)" Green
        $TestsPassed++
    }
    else {
        Write-ColorOutput "[FAIL] Skills directory missing" Red
        $TestsFailed++
    }

    # Test agents
    if (Test-Path $AgentsPath) {
        $AgentCount = (Get-ChildItem -Path $AgentsPath -File -Filter "*.md").Count
        Write-ColorOutput "[OK] Agents installed ($AgentCount agents)" Green
        $TestsPassed++
    }
    else {
        Write-ColorOutput "[FAIL] Agents directory missing" Red
        $TestsFailed++
    }

    Write-ColorOutput "`nTest Results: $TestsPassed passed, $TestsFailed failed" $(if ($TestsFailed -eq 0) { "Green" } else { "Yellow" })

    if ($TestsFailed -gt 0) {
        throw "$TestsFailed test(s) failed. Review the output above for details."
    }
}

function Show-NextSteps {
    <#
    .SYNOPSIS
        Display next steps
    #>
    Write-Host "`n"
    Write-ColorOutput "╔═══════════════════════════════════════════════════════════════╗" Cyan
    Write-ColorOutput "║          Installation Complete!                              ║" Cyan
    Write-ColorOutput "╚═══════════════════════════════════════════════════════════════╝" Cyan
    Write-Host "`n"

    Write-ColorOutput "Next Steps:" Yellow
    Write-Host "  1. Start a new terminal session"
    Write-Host "  2. Run: claude"
    Write-Host "  3. Test model: claude --model $Model"
    Write-Host "  4. Test skills: claude --skill drawio"
    Write-Host "  5. Test agents: claude --agent task-manager"
    Write-Host "`n"

    Write-ColorOutput "Configuration Files:" Yellow
    Write-Host "  - Settings: $env:USERPROFILE\.claude\settings.json"
    Write-Host "  - Skills: $SkillsPath"
    Write-Host "  - Agents: $AgentsPath"
    Write-Host "`n"

    Write-ColorOutput "Documentation:" Yellow
    if (-not $IsRemoteExecution) {
        Write-Host "  - README: $(Join-Path $PSScriptRoot "README.md")"
        Write-Host "  - Configuration: $(Join-Path $PSScriptRoot "docs\CONFIGURATION.md")"
        Write-Host "  - Troubleshooting: $(Join-Path $PSScriptRoot "docs\TROUBLESHOOTING.md")"
    }
    else {
        Write-Host "  - README: https://github.com/Buzigi/claude_installer/blob/master/README.md"
        Write-Host "  - Configuration: https://github.com/Buzigi/claude_installer/blob/master/docs/CONFIGURATION.md"
        Write-Host "  - Troubleshooting: https://github.com/Buzigi/claude_installer/blob/master/docs/TROUBLESHOOTING.md"
    }
    Write-Host "`n"

    Write-ColorOutput "For self-referential capabilities:" Yellow
    Write-Host "  claude --skill claude-installer ""Create a new skill for my workflow"""
}

#endregion

#region Main Installation

function Start-Installation {
    <#
    .SYNOPSIS
        Main installation workflow
    #>
    $ErrorActionPreference = "Stop"
    $TotalSteps = 8
    $CurrentStep = 0

    Write-ColorOutput "╔═══════════════════════════════════════════════════════════════╗" Cyan
    Write-ColorOutput "║     Claude Code Installer - GLM5 Edition                      ║" Cyan
    Write-ColorOutput "╚═══════════════════════════════════════════════════════════════╝" Cyan
    Write-Host "`n"

    Write-ColorOutput "Installation Configuration:" Yellow
    Write-Host "  Model: $Model"
    Write-Host "  Install Path: $InstallPath"
    Write-Host "  Skills Path: $SkillsPath"
    Write-Host "  Agents Path: $AgentsPath"
    Write-Host "  Include MCP: $IncludeMCP"
    Write-Host "`n"

    $Confirm = Read-Host "Proceed with installation? (Y/n)"
    if ($Confirm -eq 'n' -or $Confirm -eq 'N') {
        Write-ColorOutput "Installation cancelled" Yellow
        return
    }

    # Step 1: Install CLI
    $CurrentStep++
    Write-Step -Message "Installing Claude Code CLI" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not $SkipCLI) {
        if (-not (Invoke-Step -StepName "CLI Installation" -ScriptBlock ${function:Install-ClaudeCLI})) {
            Write-ColorOutput "CLI installation failed. Aborting." Red
            return
        }
    }
    else {
        Write-ColorOutput "Skipping CLI installation (as requested)" Yellow
    }

    # Step 2: Initialize Configuration
    $CurrentStep++
    Write-Step -Message "Initializing Configuration" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "Configuration Initialization" -ScriptBlock ${function:Initialize-ClaudeConfig})) {
        Write-ColorOutput "Configuration initialization failed. Aborting." Red
        return
    }

    # Step 3: Install Skills
    $CurrentStep++
    Write-Step -Message "Installing Skills" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "Skills Installation" -ScriptBlock ${function:Install-Skills})) {
        Write-ColorOutput "Skills installation failed, continuing..." Yellow
    }

    # Step 4: Install Agents
    $CurrentStep++
    Write-Step -Message "Installing Agents" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "Agents Installation" -ScriptBlock ${function:Install-Agents})) {
        Write-ColorOutput "Agents installation failed, continuing..." Yellow
    }

    # Step 5: Configure MCP Servers
    $CurrentStep++
    Write-Step -Message "Configuring MCP Servers" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "MCP Configuration" -ScriptBlock ${function:Initialize-MCPServers})) {
        Write-ColorOutput "MCP configuration failed, continuing..." Yellow
    }

    # Step 6: Initialize Self-Referential
    $CurrentStep++
    Write-Step -Message "Configuring Self-Referential Capabilities" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "Self-Referential Setup" -ScriptBlock ${function:Initialize-SelfReferential})) {
        Write-ColorOutput "Self-referential setup failed, continuing..." Yellow
    }

    # Step 7: Install Agent-First Hooks
    $CurrentStep++
    Write-Step -Message "Installing Agent-First Hooks" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if (-not (Invoke-Step -StepName "Hooks Installation" -ScriptBlock ${function:Install-Hooks})) {
        Write-ColorOutput "Hooks installation failed, continuing..." Yellow
    }

    # Step 8: Test Installation
    $CurrentStep++
    Write-Step -Message "Testing Installation" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    $TestResult = Invoke-Step -StepName "Installation Testing" -ScriptBlock ${function:Test-Installation}

    # Show next steps
    Show-NextSteps

    if ($TestResult) {
        Write-ColorOutput "`nInstallation completed successfully!" Green
    }
    else {
        Write-ColorOutput "`nInstallation completed with errors. Please review the output above." Yellow
    }

    # Keep window open so user can read output
    Write-Host ""
    Read-Host "Press Enter to exit"
}

# Start installation
try {
    Start-Installation
}
catch {
    Write-Host "`nINSTALLATION ERROR: $_" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }
    Write-Host ""
    Read-Host "Press Enter to exit"
}
