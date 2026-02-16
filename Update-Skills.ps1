#requires -Version 5.1

<#
.SYNOPSIS
    Update Claude Code skills

.DESCRIPTION
    Update installed skills from their repositories
#>

[CmdletBinding()]
param(
    [string]$SkillsPath = "$env:USERPROFILE\.claude\skills"
)

$ErrorActionPreference = "Stop"

Write-Host "Updating Claude Code Skills..." -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "`n"

if (-not (Test-Path $SkillsPath)) {
    Write-Error "Skills directory not found: $SkillsPath"
    exit 1
}

$Skills = Get-ChildItem -Path $SkillsPath -Directory
$Updated = 0
$Failed = 0

foreach ($Skill in $Skills) {
    Write-Host "Updating: $($Skill.Name)" -ForegroundColor Yellow

    $MetadataFile = "$($Skill.FullName)\.skillfish.json"

    if (Test-Path $MetadataFile) {
        try {
            $Metadata = Get-Content $MetadataFile -Raw | ConvertFrom-Json

            if ($Metadata.repo -and $Metadata.path) {
                $RepoUrl = "https://github.com/$($Metadata.owner)/$($Metadata.repo)"
                $Branch = if ($Metadata.branch) { $Metadata.branch } else { "main" }

                Write-Host "  From: $RepoUrl" -ForegroundColor DarkGray
                Write-Host "  Path: $($Metadata.path)" -ForegroundColor DarkGray

                # Create temp directory for clone
                $TempDir = Join-Path $env:TEMP "claude-skill-update-$($Skill.Name)"
                if (Test-Path $TempDir) {
                    Remove-Item -Path $TempDir -Recurse -Force
                }

                # Clone repository
                Write-Host "  Cloning..." -ForegroundColor DarkGray
                git clone --depth 1 --branch $Branch "$RepoUrl.git" $TempDir 2>&1 | Out-Null

                # Copy updated files
                $SourcePath = Join-Path $TempDir $Metadata.path
                if (Test-Path $SourcePath) {
                    Write-Host "  Updating files..." -ForegroundColor DarkGray
                    Copy-Item -Path "$SourcePath\*" -Destination $Skill.FullName -Recurse -Force
                    $Updated++
                    Write-Host "  Updated successfully" -ForegroundColor Green
                }
                else {
                    Write-Host "  Source path not found in repository" -ForegroundColor Red
                    $Failed++
                }

                # Cleanup
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                Write-Host "  No repository information found" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  Update failed: $_" -ForegroundColor Red
            $Failed++
        }
    }
    else {
        Write-Host "  No metadata file found" -ForegroundColor Yellow
    }

    Write-Host "`n"
}

Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "Update Summary:" -ForegroundColor Cyan
Write-Host "  Updated: $Updated" -ForegroundColor Green
Write-Host "  Failed:  $Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Total:   $($Skills.Count)"
