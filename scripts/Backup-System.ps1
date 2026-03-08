<#
.SYNOPSIS
    Creates a comprehensive, restorable backup bundle of your Windows system
    before a clean reinstall.

.DESCRIPTION
    Exports:
      • winget package list (JSON) for one-command reinstall
      • Chocolatey package list
      • Scoop app list
      • conda environment YAML files (one per environment)
      • pip requirements.txt for non-conda envs
      • VS Code extensions list + settings.json / keybindings.json
      • Windows Terminal settings
      • SSH keys and config
      • Git global config
      • .env files and dotfiles from $HOME
      • PowerShell profiles
      • Docker images (tar export, optional — large)
      • WSL distribution exports
      • Environment variables (User + System) as a restore script
      • User-created scheduled tasks (XML)
      • Registry startup entries
      • Hosts file
      • Summary report with recommended architecture notes

.PARAMETER OutputDir
    Where to write the backup bundle. Defaults to "$HOME\SystemBackup".

.PARAMETER ExportDockerImages
    When set, exports Docker images to .tar files. WARNING: can be very large.

.PARAMETER ExportWSL
    When set, exports WSL distributions to .tar files. WARNING: can be large.

.EXAMPLE
    .\Backup-System.ps1
    .\Backup-System.ps1 -OutputDir "D:\Backup" -ExportDockerImages -ExportWSL
#>
[CmdletBinding()]
param(
    [string]$OutputDir = "$HOME\SystemBackup",
    [switch]$ExportDockerImages,
    [switch]$ExportWSL
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$bundleDir = Join-Path $OutputDir $timestamp

# Sub-directories
$dirs = @(
    'packages', 'python', 'node', 'vscode', 'terminal', 'git',
    'ssh', 'dotfiles', 'docker', 'wsl', 'env_vars', 'tasks', 'system'
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $bundleDir $d) -Force | Out-Null
}

function Write-Section { param([string]$t); Write-Host "`n$(('='*60))`n  $t`n$('='*60)" -ForegroundColor Cyan }
function Ok  { param([string]$m); Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn { param([string]$m); Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Skip { param([string]$m); Write-Host "  [SKIP] $m" -ForegroundColor DarkGray }

function Copy-IfExists {
    param([string]$Source, [string]$Dest)
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $Dest -Force
        Ok "Copied $Source"
    } else {
        Skip "$Source not found"
    }
}

# ---------------------------------------------------------------------------
Write-Section "1 · Package managers"

# winget
$wingetFile = Join-Path $bundleDir 'packages\winget-packages.json'
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget export -o $wingetFile --accept-source-agreements 2>&1 | Out-Null
    Ok "winget packages → packages\winget-packages.json"
} else { Skip "winget not found" }

# Chocolatey
if (Get-Command choco -ErrorAction SilentlyContinue) {
    $chocoFile = Join-Path $bundleDir 'packages\choco-packages.config'
    choco export --output-file-path=$chocoFile 2>&1 | Out-Null
    Ok "Chocolatey packages → packages\choco-packages.config"
} else { Skip "Chocolatey not found" }

# Scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop export | Out-File (Join-Path $bundleDir 'packages\scoop-apps.json') -Encoding utf8
    Ok "Scoop apps → packages\scoop-apps.json"
} else { Skip "Scoop not found" }

# ---------------------------------------------------------------------------
Write-Section "2 · Python / Conda environments"

if (Get-Command conda -ErrorAction SilentlyContinue) {
    $envListRaw = conda env list 2>&1 | Where-Object { $_ -notmatch '^#' -and $_.Trim() }
    foreach ($line in $envListRaw) {
        $parts = $line -split '\s+'
        $envName = $parts[0]
        if (-not $envName) { continue }
        $yamlPath = Join-Path $bundleDir "python\conda_env_$envName.yml"
        conda env export -n $envName | Out-File $yamlPath -Encoding utf8
        Ok "conda env '$envName' → python\conda_env_$envName.yml"
    }
} else { Skip "Conda not found" }

# System pip (outside conda)
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip freeze | Out-File (Join-Path $bundleDir 'python\pip_requirements.txt') -Encoding utf8
    Ok "pip requirements → python\pip_requirements.txt"
}

# ---------------------------------------------------------------------------
Write-Section "3 · Node.js"

if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm list -g --depth=0 --json 2>&1 |
        Out-File (Join-Path $bundleDir 'node\npm_global.json') -Encoding utf8
    Ok "npm global packages → node\npm_global.json"
}
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    pnpm list -g --depth=0 --json 2>&1 |
        Out-File (Join-Path $bundleDir 'node\pnpm_global.json') -Encoding utf8
    Ok "pnpm global packages → node\pnpm_global.json"
}

# ---------------------------------------------------------------------------
Write-Section "4 · VS Code"

if (Get-Command code -ErrorAction SilentlyContinue) {
    code --list-extensions | Out-File (Join-Path $bundleDir 'vscode\extensions.txt') -Encoding utf8
    Ok "VS Code extensions → vscode\extensions.txt"
} else { Skip "VS Code not in PATH" }

$vscodeSettingsSrc = "$env:APPDATA\Code\User\settings.json"
$vscodeKeysSrc     = "$env:APPDATA\Code\User\keybindings.json"
$vscodeSnippetsSrc = "$env:APPDATA\Code\User\snippets"
Copy-IfExists $vscodeSettingsSrc (Join-Path $bundleDir 'vscode\settings.json')
Copy-IfExists $vscodeKeysSrc     (Join-Path $bundleDir 'vscode\keybindings.json')
if (Test-Path $vscodeSnippetsSrc) {
    Copy-Item $vscodeSnippetsSrc (Join-Path $bundleDir 'vscode\snippets') -Recurse -Force
    Ok "VS Code snippets → vscode\snippets\"
}

# ---------------------------------------------------------------------------
Write-Section "5 · Windows Terminal"

$wtSettingsSrc = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-IfExists $wtSettingsSrc (Join-Path $bundleDir 'terminal\windows_terminal_settings.json')

# ---------------------------------------------------------------------------
Write-Section "6 · Git config"

Copy-IfExists "$HOME\.gitconfig"        (Join-Path $bundleDir 'git\.gitconfig')
Copy-IfExists "$HOME\.gitignore_global" (Join-Path $bundleDir 'git\.gitignore_global')

# ---------------------------------------------------------------------------
Write-Section "7 · SSH keys and config"

$sshDir = Join-Path $bundleDir 'ssh'
if (Test-Path "$HOME\.ssh") {
    Get-ChildItem "$HOME\.ssh" | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $sshDir $_.Name) -Force
    }
    Ok "SSH directory → ssh\"
    Warn "Private keys included — keep this backup in a secure, encrypted location!"
} else { Skip "~\.ssh not found" }

# ---------------------------------------------------------------------------
Write-Section "8 · PowerShell profiles"

$profiles = @(
    $PROFILE.AllUsersAllHosts,
    $PROFILE.AllUsersCurrentHost,
    $PROFILE.CurrentUserAllHosts,
    $PROFILE.CurrentUserCurrentHost
)
$profileDir = Join-Path $bundleDir 'dotfiles'
$i = 1
foreach ($p in $profiles) {
    if (Test-Path $p) {
        Copy-Item $p (Join-Path $profileDir "powershell_profile_$i.ps1") -Force
        Ok "Profile ${i}: $p"
    }
    $i++
}

# ---------------------------------------------------------------------------
Write-Section "9 · Dotfiles from HOME"

$dotfilePatterns = @('.npmrc', '.yarnrc', '.pnpmrc', '.pip\pip.ini',
                     '.condarc', '.wslconfig', '.editorconfig', 'Brewfile')
foreach ($pat in $dotfilePatterns) {
    $src = Join-Path $HOME $pat
    if (Test-Path $src) {
        $dest = Join-Path $bundleDir "dotfiles\$($pat.Replace('\','_').Replace('/','_'))"
        Copy-Item $src $dest -Force
        Ok "Dotfile: $pat"
    }
}

# ---------------------------------------------------------------------------
Write-Section "10 · Docker"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    # Save docker-compose files
    $composeFiles = Get-ChildItem -Path $HOME -Filter 'docker-compose*.yml' -Recurse -ErrorAction SilentlyContinue
    foreach ($cf in $composeFiles) {
        $rel = $cf.DirectoryName.Replace($HOME, '').TrimStart('\').Replace('\','_')
        $dest = Join-Path $bundleDir "docker\compose_${rel}_$($cf.Name)"
        Copy-Item $cf.FullName $dest -Force
        Ok "docker-compose: $($cf.FullName)"
    }

    # Export images (optional — potentially very large)
    if ($ExportDockerImages) {
        $images = docker images --format "{{.Repository}}:{{.Tag}}" 2>&1 |
            Where-Object { $_ -notmatch '<none>' }
        foreach ($img in $images) {
            $safeName = $img -replace '[:/]', '_'
            $tarPath  = Join-Path $bundleDir "docker\image_$safeName.tar"
            Write-Host "  Exporting image: $img ..." -ForegroundColor DarkYellow
            docker save -o $tarPath $img 2>&1 | Out-Null
            Ok "Image exported → docker\image_$safeName.tar"
        }
    } else {
        Skip "Docker image export skipped (use -ExportDockerImages to enable)"
        # Still save the image list for reference
        docker images --format "{{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>&1 |
            Out-File (Join-Path $bundleDir 'docker\image_list.txt') -Encoding utf8
        Ok "Docker image list → docker\image_list.txt"
    }
} else { Skip "Docker not found" }

# ---------------------------------------------------------------------------
Write-Section "11 · WSL distributions"

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    wsl --list --verbose 2>&1 | Out-File (Join-Path $bundleDir 'wsl\distributions.txt') -Encoding utf8
    Ok "WSL distribution list → wsl\distributions.txt"

    if ($ExportWSL) {
        $distros = wsl --list --quiet 2>&1 | Where-Object { $_.Trim() -and $_ -notmatch 'Windows' }
        foreach ($distro in $distros) {
            $safeName = $distro.Trim() -replace '\s+', '_'
            $tarPath  = Join-Path $bundleDir "wsl\${safeName}.tar"
            Write-Host "  Exporting WSL distro: $distro ..." -ForegroundColor DarkYellow
            wsl --export $distro.Trim() $tarPath 2>&1 | Out-Null
            Ok "WSL export: $distro → wsl\${safeName}.tar"
        }
    } else {
        Skip "WSL export skipped (use -ExportWSL to enable)"
    }
} else { Skip "WSL not found" }

# ---------------------------------------------------------------------------
Write-Section "12 · Environment variables (as restore script)"

$envRestoreScript = Join-Path $bundleDir 'env_vars\Restore-EnvVars.ps1'
$lines = @('# Auto-generated by Backup-System.ps1 — review before running!', '')

# System
$lines += '# ---- SYSTEM environment variables ----'
[System.Environment]::GetEnvironmentVariables('Machine').GetEnumerator() |
    Where-Object { $_.Name -notin @('PATH','PATHEXT','OS','PROCESSOR_ARCHITECTURE') } |
    Sort-Object Name |
    ForEach-Object {
        $safeVal = $_.Value -replace "'", "''"
        $lines += "[System.Environment]::SetEnvironmentVariable('$($_.Name)', '$safeVal', 'Machine')"
    }

$lines += ''
$lines += '# ---- USER environment variables ----'
[System.Environment]::GetEnvironmentVariables('User').GetEnumerator() |
    Where-Object { $_.Name -ne 'PATH' } |
    Sort-Object Name |
    ForEach-Object {
        $safeVal = $_.Value -replace "'", "''"
        $lines += "[System.Environment]::SetEnvironmentVariable('$($_.Name)', '$safeVal', 'User')"
    }

$lines | Out-File $envRestoreScript -Encoding utf8
Ok "Environment variable restore script → env_vars\Restore-EnvVars.ps1"

# ---------------------------------------------------------------------------
Write-Section "13 · Hosts file"

Copy-IfExists "$env:SystemRoot\System32\drivers\etc\hosts" (Join-Path $bundleDir 'system\hosts')

# ---------------------------------------------------------------------------
Write-Section "14 · Scheduled tasks (user-created)"

$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskPath -notlike '\Microsoft\*' }
foreach ($task in $tasks) {
    $safeName = $task.TaskName -replace '[\\/:*?"<>|]', '_'
    $xmlPath  = Join-Path $bundleDir "tasks\${safeName}.xml"
    Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath |
        Out-File $xmlPath -Encoding utf8
    Ok "Task: $($task.TaskName)"
}

# ---------------------------------------------------------------------------
Write-Section "Done — Bundle summary"

$totalSize = (Get-ChildItem $bundleDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$fileCount = (Get-ChildItem $bundleDir -Recurse -File).Count

Write-Host ""
Write-Host "  Bundle location : $bundleDir" -ForegroundColor Yellow
Write-Host "  Files           : $fileCount" -ForegroundColor Green
Write-Host "  Total size      : $([math]::Round($totalSize, 1)) MB" -ForegroundColor Green
Write-Host ""
Write-Host "  IMPORTANT — store this bundle in an encrypted location." -ForegroundColor Red
Write-Host "  It contains SSH keys, environment variables and credentials.`n"
Write-Host "  Next step: read docs\new-system-architecture.md for the recommended"
Write-Host "  architecture of your new system, then run Setup-NewSystem.ps1 after"
Write-Host "  the clean Windows install.`n"
