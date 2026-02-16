#requires -Version 5.1

<#
.SYNOPSIS
    Verify Claude Code installation

.DESCRIPTION
    Comprehensive verification script for Claude Code CLI installation
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$TestsPassed = 0
$TestsFailed = 0
$TestResults = @()

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorVariable Error -ErrorAction SilentlyContinue
    return -not $Error
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }

    Write-Host "[$Status] " -NoNewline -ForegroundColor $Color
    Write-Host $TestName
    if ($Details) {
        Write-Host "      $Details" -ForegroundColor DarkGray
    }

    $Script:TestResults += @{
        Test = $TestName
        Passed = $Passed
        Details = $Details
    }

    if ($Passed) {
        $Script:TestsPassed++
    }
    else {
        $Script:TestsFailed++
    }
}

Write-Host "`nClaude Code Installation Verification" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "`n"

# Test 1: Claude CLI
Write-Host "Testing Claude CLI Installation..." -ForegroundColor Yellow
Write-TestResult "Claude CLI available" (Test-Command "claude")
if (Test-Command "claude") {
    $Version = & claude --version 2>&1
    Write-TestResult "Claude CLI version" ($Version -match "\d+\.\d+\.\d+") $Version
}

# Test 2: Configuration Files
Write-Host "`nTesting Configuration Files..." -ForegroundColor Yellow
$ConfigDir = "$env:USERPROFILE\.claude"
Write-TestResult "Config directory exists" (Test-Path $ConfigDir)

$SettingsFile = "$ConfigDir\settings.json"
Write-TestResult "settings.json exists" (Test-Path $SettingsFile)
if (Test-Path $SettingsFile) {
    try {
        $Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        Write-TestResult "settings.json valid JSON" $true
        Write-TestResult "Model configured" (-not [string]::IsNullOrEmpty($Settings.model)) $Settings.model
    }
    catch {
        Write-TestResult "settings.json valid JSON" $false $_.Exception.Message
    }
}

$LocalSettingsFile = "$ConfigDir\settings.local.json"
Write-TestResult "settings.local.json exists" (Test-Path $LocalSettingsFile)

# Test 3: Skills
Write-Host "`nTesting Skills Installation..." -ForegroundColor Yellow
$SkillsPath = "$ConfigDir\skills"
Write-TestResult "Skills directory exists" (Test-Path $SkillsPath)

if (Test-Path $SkillsPath) {
    $SkillDirs = Get-ChildItem -Path $SkillsPath -Directory
    Write-TestResult "Skills installed" ($SkillDirs.Count -gt 0) "$($SkillDirs.Count) skills found"

    $DrawioSkill = "$SkillsPath\drawio"
    Write-TestResult "drawio skill exists" (Test-Path $DrawioSkill)
    if (Test-Path $DrawioSkill) {
        Write-TestResult "drawio/.skillfish.json exists" (Test-Path "$DrawioSkill\.skillfish.json")
        Write-TestResult "drawio/SKILL.md exists" (Test-Path "$DrawioSkill\SKILL.md")
    }

    $InstallerSkill = "$SkillsPath\claude-installer"
    Write-TestResult "claude-installer skill exists" (Test-Path $InstallerSkill)
}

# Test 4: Agents
Write-Host "`nTesting Agents Installation..." -ForegroundColor Yellow
$AgentsPath = "$ConfigDir\agents"
Write-TestResult "Agents directory exists" (Test-Path $AgentsPath)

if (Test-Path $AgentsPath) {
    $AgentFiles = Get-ChildItem -Path $AgentsPath -File -Filter "*.md"
    Write-TestResult "Agents installed" ($AgentFiles.Count -gt 0) "$($AgentFiles.Count) agents found"

    $CoreAgents = @(
        "task-manager-agent.md",
        "project-navigator-agent.md",
        "software-architect.md"
    )

    foreach ($Agent in $CoreAgents) {
        $AgentPath = "$AgentsPath\$Agent"
        Write-TestResult "$Agent exists" (Test-Path $AgentPath)
    }
}

# Test 5: MCP Servers
Write-Host "`nTesting MCP Server Configuration..." -ForegroundColor Yellow
$ClaudeJson = "$env:USERPROFILE\.claude.json"
Write-TestResult ".claude.json exists" (Test-Path $ClaudeJson)

if (Test-Path $ClaudeJson) {
    try {
        $Config = Get-Content $ClaudeJson -Raw | ConvertFrom-Json
        Write-TestResult ".claude.json valid JSON" $true

        if ($Config.projects) {
            $DefaultProject = $Config.projects.PSObject.Properties | Select-Object -First 1
            if ($DefaultProject) {
                $McpServers = $DefaultProject.Value.mcpServers
                Write-TestResult "MCP servers configured" ($McpServers -and $McpServers.PSObject.Properties.Count -gt 0)

                if ($McpServers -and $McpServers.PSObject.Properties.Count -gt 0) {
                    foreach ($Server in $McpServers.PSObject.Properties) {
                        Write-Host "      - $($Server.Name)" -ForegroundColor DarkGray
                    }
                }
            }
        }
    }
    catch {
        Write-TestResult ".claude.json valid JSON" $false $_.Exception.Message
    }
}

# Test 6: Node.js and npm
Write-Host "`nTesting Dependencies..." -ForegroundColor Yellow
Write-TestResult "Node.js available" (Test-Command "node")
if (Test-Command "node") {
    $NodeVersion = & node --version 2>&1
    Write-TestResult "Node.js version >= 18" ($NodeVersion -match "v1[89]\.|v[2-9]\d\.") $NodeVersion
}

Write-TestResult "npm available" (Test-Command "npm")
if (Test-Command "npm") {
    $NpmVersion = & npm --version 2>&1
    Write-TestResult "npm version >= 9" ($NpmVersion -match "[89]\.|[1-9]\d\.") $NpmVersion
}

# Test 7: PATH Configuration
Write-Host "`nTesting PATH Configuration..." -ForegroundColor Yellow
$NpmPrefix = & npm config get prefix 2>&1
$NpmBin = if ($NpmPrefix) { "$NpmPrefix" } else { "$env:APPDATA\npm" }
Write-TestResult "npm binary directory in PATH" ($env:PATH -like "*$NpmBin*") $NpmBin

# Summary
Write-Host "`n" -NoNewline
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $TestsPassed" -ForegroundColor Green
Write-Host "  Failed: $TestsFailed" -ForegroundColor $(if ($TestsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "  Total:  $($TestsPassed + $TestsFailed)"
Write-Host "`n"

if ($TestsFailed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($Result in $TestResults) {
        if (-not $Result.Passed) {
            Write-Host "  - $($Result.Test)" -ForegroundColor Red
            if ($Result.Details) {
                Write-Host "    $($Result.Details)" -ForegroundColor DarkGray
            }
        }
    }
    Write-Host "`n"
    Write-Host "Please review the failed tests above and refer to TROUBLESHOOTING.md for solutions." -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "All tests passed! Your installation is complete." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Start Claude: claude"
    Write-Host "  2. Test model: claude --model glm5"
    Write-Host "  3. Test skill: claude --skill drawio"
    Write-Host "  4. Test agent: claude --agent task-manager"
    exit 0
}
