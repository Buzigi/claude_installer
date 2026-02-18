<#
.SYNOPSIS
    Claude Code Complete Uninstaller (Windows)

.DESCRIPTION
    Removes Claude Code CLI, all configuration, skills, agents, hooks,
    environment variables, and PATH entries created by the installer.

.PARAMETER KeepConfig
    Keep ~/.claude configuration directory (remove CLI only)

.PARAMETER KeepEnvVars
    Keep ANTHROPIC_* environment variables

.PARAMETER Force
    Skip all confirmation prompts

.EXAMPLE
    .\Uninstall-ClaudeCode.ps1

.EXAMPLE
    .\Uninstall-ClaudeCode.ps1 -KeepConfig

.EXAMPLE
    .\Uninstall-ClaudeCode.ps1 -Force
#>

[CmdletBinding()]
param(
    [switch]$KeepConfig,
    [switch]$KeepEnvVars,
    [switch]$Force
)

#region Helper Functions

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message, [int]$StepNumber, [int]$TotalSteps)
    Write-Host ""
    Write-ColorOutput "[$StepNumber/$TotalSteps] $Message" Cyan
    Write-ColorOutput ("=" * 70) Gray
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Confirm-Action {
    param([string]$Message)
    if ($Force) { return $true }
    $response = Read-Host "$Message (y/N)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

#endregion

#region Uninstall Functions

function Remove-ClaudeCLI {
    <#
    .SYNOPSIS
        Remove Claude Code CLI binary and npm package
    #>
    Write-ColorOutput "Removing Claude Code CLI..." Yellow

    # Try native uninstall first
    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    $claudeBinary = Join-Path $localBin "claude.exe"
    $claudeCmd = Join-Path $localBin "claude.cmd"
    $claudeBat = Join-Path $localBin "claude.bat"

    $removed = $false

    # Remove native installer binary
    foreach ($bin in @($claudeBinary, $claudeCmd, $claudeBat)) {
        if (Test-Path $bin) {
            Remove-Item -Path $bin -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed: $bin" DarkGray
            $removed = $true
        }
    }

    # Also check for claude-related files in .local/bin
    if (Test-Path $localBin) {
        $claudeFiles = Get-ChildItem -Path $localBin -Filter "claude*" -ErrorAction SilentlyContinue
        foreach ($file in $claudeFiles) {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed: $($file.FullName)" DarkGray
            $removed = $true
        }

        # Remove .local/bin if empty
        $remaining = Get-ChildItem -Path $localBin -ErrorAction SilentlyContinue
        if (-not $remaining -or $remaining.Count -eq 0) {
            Remove-Item -Path $localBin -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed empty directory: $localBin" DarkGray

            # Remove .local if empty
            $localDir = Join-Path $env:USERPROFILE ".local"
            $remainingLocal = Get-ChildItem -Path $localDir -ErrorAction SilentlyContinue
            if (-not $remainingLocal -or $remainingLocal.Count -eq 0) {
                Remove-Item -Path $localDir -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "  Removed empty directory: $localDir" DarkGray
            }
        }
    }

    # Try npm uninstall
    if (Test-Command "npm") {
        $npmList = npm list -g @anthropic-ai/claude-code 2>&1
        if ($npmList -notmatch "empty|ERR") {
            Write-ColorOutput "  Removing npm package @anthropic-ai/claude-code..." Yellow
            npm uninstall -g @anthropic-ai/claude-code 2>&1 | Out-Null
            $removed = $true
            Write-ColorOutput "  Removed npm package" DarkGray
        }
    }

    if ($removed) {
        Write-ColorOutput "[OK] Claude CLI removed" Green
    }
    else {
        Write-ColorOutput "[SKIP] No Claude CLI installation found" Yellow
    }
}

function Remove-ClaudeConfig {
    <#
    .SYNOPSIS
        Remove ~/.claude directory and ~/.claude.json
    #>
    Write-ColorOutput "Removing Claude configuration..." Yellow

    $configDir = Join-Path $env:USERPROFILE ".claude"
    $configJson = Join-Path $env:USERPROFILE ".claude.json"
    $removed = $false

    if (Test-Path $configDir) {
        # Create a final backup before removal
        $backupPath = Join-Path $env:USERPROFILE ".claude-uninstall-backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-ColorOutput "  Creating backup at: $backupPath" Yellow
        Copy-Item -Path $configDir -Destination $backupPath -Recurse -Force

        Remove-Item -Path $configDir -Recurse -Force
        Write-ColorOutput "  Removed: $configDir" DarkGray
        $removed = $true
    }

    if (Test-Path $configJson) {
        Remove-Item -Path $configJson -Force
        Write-ColorOutput "  Removed: $configJson" DarkGray
        $removed = $true
    }

    if ($removed) {
        Write-ColorOutput '[OK] Claude configuration removed (backup saved)' Green
    }
    else {
        Write-ColorOutput "[SKIP] No Claude configuration found" Yellow
    }
}

function Remove-EnvironmentVariables {
    <#
    .SYNOPSIS
        Remove ANTHROPIC_* and GLM5-related environment variables
    #>
    Write-ColorOutput "Removing environment variables..." Yellow

    $envVars = @(
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL",
        "ANTHROPIC_DEFAULT_SONNET_MODEL",
        "ANTHROPIC_DEFAULT_OPUS_MODEL",
        "API_TIMEOUT_MS"
    )

    $removed = $false

    foreach ($var in $envVars) {
        # Remove from User environment
        $currentValue = [System.Environment]::GetEnvironmentVariable($var, "User")
        if ($currentValue) {
            [System.Environment]::SetEnvironmentVariable($var, $null, "User")
            Write-ColorOutput "  Removed User env: $var" DarkGray
            $removed = $true
        }

        # Remove from current session
        if (Test-Path "Env:\$var") {
            Remove-Item "Env:\$var" -ErrorAction SilentlyContinue
        }
    }

    if ($removed) {
        Write-ColorOutput "[OK] Environment variables removed" Green
    }
    else {
        Write-ColorOutput "[SKIP] No ANTHROPIC environment variables found" Yellow
    }
}

function Remove-PathEntries {
    <#
    .SYNOPSIS
        Remove ~/.local/bin from User PATH
    #>
    Write-ColorOutput "Cleaning PATH entries..." Yellow

    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -and $userPath -like "*$localBin*") {
        $newPath = ($userPath -split ";" | Where-Object { $_ -ne $localBin -and $_ -ne "" }) -join ";"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-ColorOutput "  Removed from User PATH: $localBin" DarkGray

        # Also update current session
        $env:Path = ($env:Path -split ";" | Where-Object { $_ -ne $localBin -and $_ -ne "" }) -join ";"

        Write-ColorOutput "[OK] PATH cleaned" Green
    }
    else {
        Write-ColorOutput "[SKIP] No Claude PATH entries found" Yellow
    }
}

function Remove-ProfileEntries {
    <#
    .SYNOPSIS
        Remove Claude-related entries from PowerShell profile
    #>
    Write-ColorOutput "Cleaning PowerShell profile..." Yellow

    if (Test-Path $PROFILE) {
        $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "Claude Code CLI") {
            # Remove the Claude Code CLI PATH block
            $cleaned = $content -replace '(?s)\r?\n# Claude Code CLI - ensure ~/\.local/bin is in PATH.*?}', ''
            # Remove any extra blank lines left behind
            $cleaned = $cleaned -replace '(\r?\n){3,}', "`n`n"
            $cleaned = $cleaned.TrimEnd()

            Set-Content -Path $PROFILE -Value $cleaned
            Write-ColorOutput "  Removed Claude entries from: $PROFILE" DarkGray
            Write-ColorOutput "[OK] PowerShell profile cleaned" Green
        }
        else {
            Write-ColorOutput "[SKIP] No Claude entries in PowerShell profile" Yellow
        }
    }
    else {
        Write-ColorOutput "[SKIP] No PowerShell profile found" Yellow
    }
}

function Remove-NodeModulesCache {
    <#
    .SYNOPSIS
        Remove Claude-related npm cache entries
    #>
    Write-ColorOutput 'Cleaning npm cache (Claude packages)...' Yellow

    if (Test-Command "npm") {
        $cacheDir = (npm config get cache 2>$null)
        if ($cacheDir -and (Test-Path $cacheDir)) {
            # Clean specific package from cache
            npm cache clean --force 2>&1 | Out-Null
            Write-ColorOutput "  npm cache cleaned" DarkGray
        }
    }

    # Remove npx cache for claude-related packages
    $npxCache = Join-Path $env:LOCALAPPDATA "npm-cache\_npx"
    if (Test-Path $npxCache) {
        $claudeNpx = Get-ChildItem -Path $npxCache -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*claude*" -or $_.Name -like "*anthropic*" }
        foreach ($dir in $claudeNpx) {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed npx cache: $($dir.Name)" DarkGray
        }
    }

    Write-ColorOutput "[OK] Cache cleaned" Green
}

#endregion

#region Main

function Start-Uninstall {
    Write-ColorOutput '+===============================================================+' Red
    Write-ColorOutput '|          Claude Code Uninstaller - Windows                    |' Red
    Write-ColorOutput '+===============================================================+' Red
    Write-Host ""

    Write-ColorOutput "This will remove the following:" Yellow
    Write-Host '  - Claude Code CLI (native binary and/or npm package)'
    if (-not $KeepConfig) {
        Write-Host '  - Configuration directory (~/.claude)'
        Write-Host '  - MCP configuration (~/.claude.json)'
        Write-Host "  - Skills, agents, and hooks"
    }
    if (-not $KeepEnvVars) {
        Write-Host "  - ANTHROPIC_* environment variables"
    }
    Write-Host '  - PATH entries (~/.local/bin)'
    Write-Host "  - PowerShell profile entries"
    Write-Host '  - npm/npx cache (Claude packages)'
    Write-Host ""

    if (-not (Confirm-Action "Are you sure you want to uninstall Claude Code?")) {
        Write-ColorOutput "Uninstall cancelled." Yellow
        return
    }

    Write-Host ""
    $TotalSteps = 6
    $CurrentStep = 0

    # Step 1: Remove CLI
    $CurrentStep++
    Write-Step -Message "Removing Claude CLI" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    Remove-ClaudeCLI

    # Step 2: Remove config
    $CurrentStep++
    Write-Step -Message "Removing Configuration" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if ($KeepConfig) {
        Write-ColorOutput '[SKIP] Keeping configuration (-KeepConfig)' Yellow
    }
    else {
        Remove-ClaudeConfig
    }

    # Step 3: Remove environment variables
    $CurrentStep++
    Write-Step -Message "Removing Environment Variables" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    if ($KeepEnvVars) {
        Write-ColorOutput '[SKIP] Keeping environment variables (-KeepEnvVars)' Yellow
    }
    else {
        Remove-EnvironmentVariables
    }

    # Step 4: Clean PATH
    $CurrentStep++
    Write-Step -Message "Cleaning PATH" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    Remove-PathEntries

    # Step 5: Clean PowerShell profile
    $CurrentStep++
    Write-Step -Message "Cleaning PowerShell Profile" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    Remove-ProfileEntries

    # Step 6: Clean caches
    $CurrentStep++
    Write-Step -Message "Cleaning Caches" -StepNumber $CurrentStep -TotalSteps $TotalSteps
    Remove-NodeModulesCache

    # Summary
    Write-Host ""
    Write-ColorOutput '+===============================================================+' Green
    Write-ColorOutput '|          Uninstall Complete                                   |' Green
    Write-ColorOutput '+===============================================================+' Green
    Write-Host ""
    Write-ColorOutput "Claude Code has been removed from this system." Green

    if (-not $KeepConfig) {
        Write-Host ""
        Write-ColorOutput "A backup of your configuration was saved to:" Yellow
        $backups = Get-ChildItem -Path $env:USERPROFILE -Filter ".claude-uninstall-backup_*" -Directory -ErrorAction SilentlyContinue
        if ($backups) {
            foreach ($b in $backups) {
                Write-Host "  $($b.FullName)"
            }
            Write-Host ""
            Write-ColorOutput "Delete the backup manually when you no longer need it." DarkGray
        }
    }

    Write-Host ""
    Write-ColorOutput "Please restart your terminal for all changes to take effect." Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
}

try {
    Start-Uninstall
}
catch {
    Write-Host "`nUNINSTALL ERROR: $_" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }
    Write-Host ""
    Read-Host "Press Enter to exit"
}

#endregion
