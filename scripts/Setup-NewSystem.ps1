<#
.SYNOPSIS
    Bootstraps a fresh Windows installation from a backup bundle produced by
    Backup-System.ps1.

.DESCRIPTION
    Run this script after a clean Windows install to restore:
      1. Core tools (winget, Chocolatey, Scoop)
      2. All winget / choco / scoop packages from the backup
      3. WSL2 + Docker Desktop
      4. Conda + per-environment YAML files
      5. Node.js global packages
      6. VS Code + all extensions + settings
      7. SSH keys, Git config, dotfiles
      8. Environment variables
      9. Hosts file additions
     10. Scheduled tasks

.PARAMETER BundleDir
    Path to the backup bundle folder (the timestamped sub-folder created by
    Backup-System.ps1, e.g. "D:\Backup\2025-05-10_14-30").

.PARAMETER SkipPackages
    Skip reinstalling applications via package managers.

.PARAMETER SkipWSL
    Skip WSL2 setup and distribution import.

.PARAMETER SkipDocker
    Skip Docker Desktop installation.

.EXAMPLE
    .\Setup-NewSystem.ps1 -BundleDir "D:\Backup\2025-05-10_14-30"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BundleDir,
    [switch]$SkipPackages,
    [switch]$SkipWSL,
    [switch]$SkipDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

if (-not (Test-Path $BundleDir)) {
    Write-Error "Bundle directory not found: $BundleDir"
    exit 1
}

function Write-Section { param([string]$t); Write-Host "`n$(('='*60))`n  $t`n$('='*60)" -ForegroundColor Cyan }
function Ok   { param([string]$m); Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn { param([string]$m); Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Skip { param([string]$m); Write-Host "  [SKIP] $m" -ForegroundColor DarkGray }

# Require admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# ---------------------------------------------------------------------------
Write-Section "0 · Prerequisites"

# Ensure execution policy allows scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Ok "ExecutionPolicy set to RemoteSigned"

# Ensure winget is available (ships with Windows 11; install App Installer on W10)
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found. Installing App Installer from Microsoft Store..."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Install 'App Installer' from the Store, then press Enter to continue"
}

# ---------------------------------------------------------------------------
Write-Section "1 · Package managers setup"

# Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Chocolatey..." -ForegroundColor DarkYellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Ok "Chocolatey installed"
} else { Ok "Chocolatey already present" }

# Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Scoop..." -ForegroundColor DarkYellow
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    Ok "Scoop installed"
} else { Ok "Scoop already present" }

# ---------------------------------------------------------------------------
if (-not $SkipPackages) {
    Write-Section "2 · Restore packages"

    # winget
    $wingetFile = Join-Path $BundleDir 'packages\winget-packages.json'
    if (Test-Path $wingetFile) {
        Write-Host "  Restoring winget packages (this may take a while)..." -ForegroundColor DarkYellow
        winget import -i $wingetFile --accept-package-agreements --accept-source-agreements --ignore-unavailable 2>&1
        Ok "winget packages restored"
    } else { Skip "packages\winget-packages.json not found" }

    # Chocolatey
    $chocoFile = Join-Path $BundleDir 'packages\choco-packages.config'
    if (Test-Path $chocoFile) {
        choco install $chocoFile -y 2>&1 | Tee-Object -Variable _
        Ok "Chocolatey packages restored"
    } else { Skip "packages\choco-packages.config not found" }

    # Scoop
    $scoopFile = Join-Path $BundleDir 'packages\scoop-apps.json'
    if (Test-Path $scoopFile) {
        $scoopApps = (Get-Content $scoopFile | ConvertFrom-Json).apps
        foreach ($app in $scoopApps) {
            scoop install $app.Info.Name 2>&1 | Out-Null
        }
        Ok "Scoop apps restored"
    } else { Skip "packages\scoop-apps.json not found" }
} else { Skip "Package restore skipped" }

# ---------------------------------------------------------------------------
if (-not $SkipWSL) {
    Write-Section "3 · WSL2"

    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    if ($wslFeature.State -ne 'Enabled') {
        Write-Host "  Enabling WSL2..." -ForegroundColor DarkYellow
        wsl --install --no-distribution 2>&1
        Ok "WSL2 enabled — a reboot may be required before importing distributions"
    } else { Ok "WSL2 already enabled" }

    $wslDir = Join-Path $BundleDir 'wsl'
    $tarFiles = Get-ChildItem $wslDir -Filter '*.tar' -ErrorAction SilentlyContinue
    foreach ($tar in $tarFiles) {
        $distroName = $tar.BaseName
        $installPath = "$env:USERPROFILE\WSL\$distroName"
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        Write-Host "  Importing WSL distro: $distroName ..." -ForegroundColor DarkYellow
        wsl --import $distroName $installPath $tar.FullName 2>&1
        Ok "WSL distro imported: $distroName"
    }
} else { Skip "WSL setup skipped" }

# ---------------------------------------------------------------------------
if (-not $SkipDocker) {
    Write-Section "4 · Docker Desktop"

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing Docker Desktop via winget..." -ForegroundColor DarkYellow
        winget install --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements -e 2>&1
        Ok "Docker Desktop installed — start it manually to complete setup"
        Warn "After Docker starts, re-run this script or manually load docker images from docker\*.tar"
    } else {
        Ok "Docker already installed"
        # Load exported images
        $dockerDir = Join-Path $BundleDir 'docker'
        $imageTars = Get-ChildItem $dockerDir -Filter 'image_*.tar' -ErrorAction SilentlyContinue
        foreach ($tar in $imageTars) {
            Write-Host "  Loading Docker image: $($tar.Name) ..." -ForegroundColor DarkYellow
            docker load -i $tar.FullName 2>&1
            Ok "Loaded: $($tar.Name)"
        }
    }
} else { Skip "Docker setup skipped" }

# ---------------------------------------------------------------------------
Write-Section "5 · Conda environments"

if (Get-Command conda -ErrorAction SilentlyContinue) {
    $pythonDir = Join-Path $BundleDir 'python'
    $yamlFiles = Get-ChildItem $pythonDir -Filter 'conda_env_*.yml' -ErrorAction SilentlyContinue
    foreach ($yml in $yamlFiles) {
        $envName = $yml.BaseName -replace '^conda_env_', ''
        Write-Host "  Creating conda env: $envName ..." -ForegroundColor DarkYellow
        conda env create -f $yml.FullName 2>&1
        Ok "Conda env restored: $envName"
    }
} else {
    Warn "Conda not found. Install Miniconda/Anaconda first, then restore environments manually:"
    Write-Host "    conda env create -f <bundle>\python\conda_env_<name>.yml"
}

# ---------------------------------------------------------------------------
Write-Section "6 · VS Code extensions and settings"

if (Get-Command code -ErrorAction SilentlyContinue) {
    $extFile = Join-Path $BundleDir 'vscode\extensions.txt'
    if (Test-Path $extFile) {
        Get-Content $extFile | ForEach-Object {
            code --install-extension $_ --force 2>&1 | Out-Null
        }
        Ok "VS Code extensions installed"
    }

    $settingsDest = "$env:APPDATA\Code\User"
    New-Item -ItemType Directory -Path $settingsDest -Force | Out-Null

    $settingsSrc = Join-Path $BundleDir 'vscode\settings.json'
    if (Test-Path $settingsSrc) {
        Copy-Item $settingsSrc (Join-Path $settingsDest 'settings.json') -Force
        Ok "VS Code settings restored"
    }
    $keysSrc = Join-Path $BundleDir 'vscode\keybindings.json'
    if (Test-Path $keysSrc) {
        Copy-Item $keysSrc (Join-Path $settingsDest 'keybindings.json') -Force
        Ok "VS Code keybindings restored"
    }
    $snippetsSrc = Join-Path $BundleDir 'vscode\snippets'
    if (Test-Path $snippetsSrc) {
        Copy-Item $snippetsSrc (Join-Path $settingsDest 'snippets') -Recurse -Force
        Ok "VS Code snippets restored"
    }
} else { Warn "VS Code (code) not in PATH — install it first, then run this section again" }

# ---------------------------------------------------------------------------
Write-Section "7 · Git config and SSH keys"

$gitSrc = Join-Path $BundleDir 'git\.gitconfig'
if (Test-Path $gitSrc) {
    Copy-Item $gitSrc "$HOME\.gitconfig" -Force
    Ok "Git config restored"
}

$sshDir = Join-Path $BundleDir 'ssh'
if (Test-Path $sshDir) {
    $dest = "$HOME\.ssh"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Get-ChildItem $sshDir | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $dest $_.Name) -Force
    }
    # Fix SSH key permissions
    Get-ChildItem $dest | Where-Object { $_.Name -match '^id_' -and $_.Name -notmatch '\.pub$' } |
        ForEach-Object {
            icacls $_.FullName /inheritance:r /grant:r "$env:USERNAME:(R)" 2>&1 | Out-Null
        }
    Ok "SSH keys restored (permissions fixed)"
}

# ---------------------------------------------------------------------------
Write-Section "8 · Dotfiles and PowerShell profiles"

$dotfilesDir = Join-Path $BundleDir 'dotfiles'
if (Test-Path $dotfilesDir) {
    Get-ChildItem $dotfilesDir | ForEach-Object {
        $destName = $_.Name -replace '^\.', '.'  # keep the dot
        Copy-Item $_.FullName (Join-Path $HOME $destName) -Force
        Ok "Dotfile: $destName"
    }
}

# ---------------------------------------------------------------------------
Write-Section "9 · Environment variables"

$envScript = Join-Path $BundleDir 'env_vars\Restore-EnvVars.ps1'
if (Test-Path $envScript) {
    Warn "Review $envScript before applying — it sets SYSTEM-level env vars."
    $apply = Read-Host "Apply environment variables now? (y/N)"
    if ($apply -eq 'y') {
        & $envScript
        Ok "Environment variables restored"
    } else { Skip "Environment variable restore deferred — run manually: & '$envScript'" }
}

# ---------------------------------------------------------------------------
Write-Section "10 · Scheduled tasks"

$tasksDir = Join-Path $BundleDir 'tasks'
$taskFiles = Get-ChildItem $tasksDir -Filter '*.xml' -ErrorAction SilentlyContinue
foreach ($tf in $taskFiles) {
    $taskName = $tf.BaseName
    Register-ScheduledTask -Xml (Get-Content $tf.FullName -Raw) -TaskName $taskName -Force 2>&1 | Out-Null
    Ok "Task restored: $taskName"
}

# ---------------------------------------------------------------------------
Write-Section "Done"

Write-Host ""
Write-Host "  Your new system has been set up from the backup bundle." -ForegroundColor Green
Write-Host "  Recommended next steps:" -ForegroundColor Cyan
Write-Host "   1. Read docs\new-system-architecture.md"
Write-Host "   2. Set up Docker containers for AI dev (see docker\ai-dev\)"
Write-Host "   3. Reboot to apply all changes`n"
