<#
.SYNOPSIS
    Installer for the scrolls.md CLI on Windows.

.DESCRIPTION
    Downloads the latest `scrolls-windows-x64.exe` from the latest GitHub
    release of absilutely/scrolls-releases, installs it to
    %LOCALAPPDATA%\scrolls\scrolls.exe, and adds that folder to the user PATH.

    Safe to re-run: it overwrites the existing binary with the latest release.

.EXAMPLE
    irm https://raw.githubusercontent.com/absilutely/scrolls-releases/main/install.ps1 | iex
#>

# Stop on the first error and treat warnings from cmdlets seriously.
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
$Repo    = 'absilutely/scrolls-releases'
$Asset   = 'scrolls-windows-x64.exe'   # published per release
$Url     = "https://github.com/$Repo/releases/latest/download/$Asset"
$InstallDir = Join-Path $env:LOCALAPPDATA 'scrolls'
$Dest       = Join-Path $InstallDir 'scrolls.exe'

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
function Write-Info { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Message) Write-Host $Message -ForegroundColor Green }

# ----------------------------------------------------------------------------
# 1. Ensure the install directory exists
# ----------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ----------------------------------------------------------------------------
# 2. Download the binary to a temp file, then move it into place
#    (so a failed download never clobbers a working install).
# ----------------------------------------------------------------------------
Write-Info "Downloading $Asset"
Write-Info $Url

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("scrolls-" + [System.Guid]::NewGuid().ToString('N') + '.exe')
try {
    # Use TLS 1.2+ on older PowerShell hosts.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Tmp -UseBasicParsing
}
catch {
    Remove-Item -LiteralPath $Tmp -Force -ErrorAction SilentlyContinue
    Write-Error @"
Could not download $Asset.
No matching release asset was found (yet) for Windows x64.
Check the available downloads at:
  https://github.com/$Repo/releases/latest
Underlying error: $($_.Exception.Message)
"@
    return
}

# Guard against an empty file (e.g. an error page saved as the asset).
if ((Get-Item -LiteralPath $Tmp).Length -eq 0) {
    Remove-Item -LiteralPath $Tmp -Force -ErrorAction SilentlyContinue
    Write-Error "Downloaded file is empty - the $Asset asset may not be published yet. See https://github.com/$Repo/releases/latest"
    return
}

Move-Item -LiteralPath $Tmp -Destination $Dest -Force
Write-Info "Installed to $Dest"

# ----------------------------------------------------------------------------
# 3. Add the install dir to the *user* PATH (persistent) if it isn't there
# ----------------------------------------------------------------------------
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ([string]::IsNullOrEmpty($userPath)) { $userPath = '' }

$sep = [System.IO.Path]::PathSeparator   # ';' on Windows
$alreadyOnPath = $userPath.Split($sep) | Where-Object { $_.TrimEnd('\') -ieq $InstallDir.TrimEnd('\') }
if (-not $alreadyOnPath) {
    $trimmed = $userPath.TrimEnd($sep)
    if ([string]::IsNullOrEmpty($trimmed)) {
        $newPath = $InstallDir
    }
    else {
        $newPath = $trimmed + $sep + $InstallDir
    }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Info "Added $InstallDir to your user PATH (restart your terminal to pick it up)."
}

# Also update PATH in the current session so `scrolls` works immediately.
if ($env:Path.Split($sep) -notcontains $InstallDir) {
    $env:Path = $env:Path + $sep + $InstallDir
}

# ----------------------------------------------------------------------------
# 4. Success message + version hint
# ----------------------------------------------------------------------------
Write-Ok "`nDone! Verify with:"
Write-Host "  scrolls --version"
