#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Embed API key into Windows installer for CI builds

.DESCRIPTION
    This script replaces the placeholder API key in the Windows installer
    with the actual API key from the build environment.

.PARAMETER ApiKey
    The API key to embed (from Z_AI_API_KEY environment variable)

.PARAMETER InputFile
    Path to the input installer script

.PARAMETER OutputFile
    Path to write the embedded installer

.EXAMPLE
    .\embed-api-key.ps1 -ApiKey "id.secret" -InputFile ".\Install-ClaudeCode.ps1" -OutputFile ".\claude-installer-windows.ps1"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

Write-Host "Embedding API key into Windows installer..." -ForegroundColor Cyan

# Read the installer
$content = Get-Content -Path $InputFile -Raw

# Replace the placeholder with actual API key
# The placeholder is: $script:EmbeddedApiKey = "__EMBEDDED_API_KEY_PLACEHOLDER__"
$embedded = $content -replace '\$script:EmbeddedApiKey = "__EMBEDDED_API_KEY_PLACEHOLDER__"', "`$script:EmbeddedApiKey = `"$ApiKey`""

# Also set the Embedded flag to true in default params
$embedded = $embedded -replace '\[bool\]\$Embedded = \$false', '[bool]$Embedded = $true'

# Write output
Set-Content -Path $OutputFile -Value $embedded -Encoding UTF8

Write-Host "[OK] Embedded installer created: $OutputFile" -ForegroundColor Green
Write-Host "API key length: $($ApiKey.Length) characters" -ForegroundColor DarkGray
