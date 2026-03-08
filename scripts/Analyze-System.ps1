<#
.SYNOPSIS
    Deep system analysis — captures everything installed on a Windows machine
    before a clean reinstall so you can make informed decisions about what to
    keep, what to remove, and what needs to be containerised.

.DESCRIPTION
    Gathers:
      • Installed applications (winget, Chocolatey, Scoop, MSI/Add-Remove-Programs)
      • Python / Conda environments and all their packages
      • Node.js global packages (npm, pnpm, yarn)
      • Docker images, containers and volumes
      • WSL2 distributions
      • GPU drivers, CUDA and cuDNN versions
      • VS Code extensions
      • Environment variables (User + System)
      • PATH entries
      • Startup programmes
      • Windows Features
      • Scheduled tasks (user-created)
      • Installed drivers (hardware)

    Output is written to a timestamped folder under $OutputDir.

.PARAMETER OutputDir
    Root directory where the analysis bundle will be saved.
    Defaults to "$HOME\SystemAnalysis".

.PARAMETER SkipDocker
    Skip Docker inspection (useful when Docker Desktop is not running).

.EXAMPLE
    .\Analyze-System.ps1
    .\Analyze-System.ps1 -OutputDir "D:\Backup\Analysis"
#>
[CmdletBinding()]
param(
    [string]$OutputDir = "$HOME\SystemAnalysis",
    [switch]$SkipDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'   # keep going even if one section fails

$timestamp  = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$reportDir  = Join-Path $OutputDir $timestamp
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

function Write-Section {
    param([string]$Title)
    $line = "=" * 60
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$line" -ForegroundColor Cyan
}

function Save-Output {
    param([string]$FileName, [scriptblock]$Command)
    $path = Join-Path $reportDir $FileName
    try {
        $result = & $Command 2>&1
        $result | Out-File -FilePath $path -Encoding utf8
        Write-Host "  [OK] $FileName" -ForegroundColor Green
    } catch {
        "ERROR: $_" | Out-File -FilePath $path -Encoding utf8
        Write-Host "  [WARN] $FileName — $_" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
Write-Section "1 · Installed applications — winget"
Save-Output "apps_winget.txt" {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget list --accept-source-agreements 2>&1
    } else { "winget not found" }
}

# ---------------------------------------------------------------------------
Write-Section "2 · Installed applications — Chocolatey"
Save-Output "apps_choco.txt" {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco list --local-only 2>&1
    } else { "Chocolatey not installed" }
}

# ---------------------------------------------------------------------------
Write-Section "3 · Installed applications — Scoop"
Save-Output "apps_scoop.txt" {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop list 2>&1
    } else { "Scoop not installed" }
}

# ---------------------------------------------------------------------------
Write-Section "4 · Installed applications — Add / Remove Programs (registry)"
Save-Output "apps_registry.csv" {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $apps = foreach ($p in $paths) {
        Get-ItemProperty $p -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation
    }
    $apps | Sort-Object DisplayName -Unique |
        Export-Csv -Path (Join-Path $reportDir "apps_registry.csv") -NoTypeInformation -Encoding utf8
    "Written to apps_registry.csv"
}

# ---------------------------------------------------------------------------
Write-Section "5 · Python environments"
Save-Output "python_envs.txt" {
    $out = @()

    # System / PATH python
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $out += "=== System Python ==="
        $out += (python --version 2>&1)
        $out += (python -m pip list 2>&1)
    }

    # Conda
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        $out += "`n=== Conda environments ==="
        $out += (conda env list 2>&1)
        $envNames = conda env list 2>&1 |
            Where-Object { $_ -match '^\w' -and $_ -notmatch '^#' } |
            ForEach-Object { ($_ -split '\s+')[0] }
        foreach ($env in $envNames) {
            $out += "`n--- conda env: $env ---"
            $out += (conda run -n $env pip list 2>&1)
        }
    } else { $out += "Conda not found" }

    # Pyenv
    if (Get-Command pyenv -ErrorAction SilentlyContinue) {
        $out += "`n=== pyenv versions ==="
        $out += (pyenv versions 2>&1)
    }

    $out
}

# ---------------------------------------------------------------------------
Write-Section "6 · Node.js"
Save-Output "nodejs_packages.txt" {
    $out = @()
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $out += "Node: $(node --version)"
        $out += "npm:  $(npm --version 2>&1)"
        $out += "`n=== Global npm packages ==="
        $out += (npm list -g --depth=0 2>&1)
    } else { $out += "Node.js not found" }
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $out += "`n=== Global pnpm packages ==="
        $out += (pnpm list -g --depth=0 2>&1)
    }
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        $out += "`n=== Global yarn packages ==="
        $out += (yarn global list 2>&1)
    }
    $out
}

# ---------------------------------------------------------------------------
Write-Section "7 · Docker"
if (-not $SkipDocker) {
    Save-Output "docker_images.txt" {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>&1
        } else { "Docker not found" }
    }
    Save-Output "docker_containers.txt" {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>&1
        } else { "Docker not found" }
    }
    Save-Output "docker_volumes.txt" {
        if (Get-Command docker -ErrorAction SilentlyContinue) {
            docker volume ls 2>&1
        } else { "Docker not found" }
    }
    Save-Output "docker_compose_files.txt" {
        Get-ChildItem -Path $HOME -Filter "docker-compose*.yml" -Recurse -ErrorAction SilentlyContinue |
            Select-Object FullName | Format-Table -AutoSize
    }
} else {
    Write-Host "  [SKIP] Docker inspection skipped" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
Write-Section "8 · WSL2 distributions"
Save-Output "wsl_distributions.txt" {
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        wsl --list --verbose 2>&1
    } else { "WSL not available" }
}

# ---------------------------------------------------------------------------
Write-Section "9 · GPU / CUDA / cuDNN"
Save-Output "gpu_info.txt" {
    $out = @()

    # NVIDIA SMI
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($nvidiaSmi) {
        $out += "=== nvidia-smi ==="
        $out += (nvidia-smi 2>&1)
        $out += "`n=== CUDA version ==="
        $out += (nvidia-smi | Select-String "CUDA")
    } else { $out += "nvidia-smi not found (no NVIDIA GPU or driver not installed)" }

    # nvcc (CUDA toolkit)
    if (Get-Command nvcc -ErrorAction SilentlyContinue) {
        $out += "`n=== nvcc (CUDA toolkit) ==="
        $out += (nvcc --version 2>&1)
    } else { $out += "nvcc not found (CUDA toolkit not in PATH)" }

    # cuDNN — look for cudnn header
    $cudnnPaths = @(
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\*\include\cudnn_version.h",
        "C:\tools\cuda\include\cudnn_version.h"
    )
    foreach ($p in $cudnnPaths) {
        $found = Get-Item $p -ErrorAction SilentlyContinue
        if ($found) {
            $out += "`n=== cuDNN version file: $($found.FullName) ==="
            $out += (Get-Content $found.FullName | Select-String "CUDNN_MAJOR|CUDNN_MINOR|CUDNN_PATCHLEVEL")
        }
    }

    # PyTorch CUDA info (if available)
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $out += "`n=== PyTorch CUDA check ==="
        $out += (python -c "import torch; print('torch:', torch.__version__, '| CUDA available:', torch.cuda.is_available(), '| CUDA version:', torch.version.cuda)" 2>&1)
    }

    $out
}

# ---------------------------------------------------------------------------
Write-Section "10 · VS Code extensions"
Save-Output "vscode_extensions.txt" {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code --list-extensions --show-versions 2>&1
    } else { "VS Code (code) not found in PATH" }
}

# ---------------------------------------------------------------------------
Write-Section "11 · Environment variables"
Save-Output "env_vars_system.txt" {
    [System.Environment]::GetEnvironmentVariables('Machine').GetEnumerator() |
        Sort-Object Name |
        ForEach-Object { "$($_.Name)=$($_.Value)" }
}
Save-Output "env_vars_user.txt" {
    [System.Environment]::GetEnvironmentVariables('User').GetEnumerator() |
        Sort-Object Name |
        ForEach-Object { "$($_.Name)=$($_.Value)" }
}

# ---------------------------------------------------------------------------
Write-Section "12 · PATH entries (de-duplicated)"
Save-Output "path_entries.txt" {
    $systemPath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';'
    $userPath   = [System.Environment]::GetEnvironmentVariable('PATH', 'User')   -split ';'
    $combined   = ($systemPath + $userPath) | Where-Object { $_ } | Sort-Object -Unique
    $combined | ForEach-Object {
        $exists = Test-Path $_
        [PSCustomObject]@{ Path = $_; Exists = $exists }
    } | Format-Table -AutoSize
}

# ---------------------------------------------------------------------------
Write-Section "13 · Startup programmes"
Save-Output "startup_programs.txt" {
    $locations = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($loc in $locations) {
        "=== $loc ==="
        Get-ItemProperty $loc -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -notmatch '^PS' } |
            ForEach-Object {
                $val = (Get-ItemProperty $loc).$($_.Name)
                "$($_.Name) = $val"
            }
    }
    # Startup folder
    "`n=== Startup folder ==="
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue |
        Select-Object Name, FullName | Format-Table -AutoSize
}

# ---------------------------------------------------------------------------
Write-Section "14 · Windows Optional Features"
Save-Output "windows_features.txt" {
    Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Enabled' } |
        Select-Object FeatureName, State |
        Sort-Object FeatureName |
        Format-Table -AutoSize
}

# ---------------------------------------------------------------------------
Write-Section "15 · Installed drivers"
Save-Output "drivers.txt" {
    Get-WmiObject Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate |
        Sort-Object DeviceName |
        Format-Table -AutoSize -Wrap
}

# ---------------------------------------------------------------------------
Write-Section "16 · Scheduled tasks (user-created)"
Save-Output "scheduled_tasks.txt" {
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskPath -notlike '\Microsoft\*' } |
        Select-Object TaskName, TaskPath, State, Description |
        Sort-Object TaskPath, TaskName |
        Format-Table -AutoSize -Wrap
}

# ---------------------------------------------------------------------------
Write-Section "17 · Conflict / interference analysis"
Save-Output "conflict_analysis.txt" {
    $report = @()

    # Multiple Python installations
    $pythons = @(where.exe python 2>$null; where.exe python3 2>$null) | Select-Object -Unique
    if ($pythons.Count -gt 1) {
        $report += "[WARNING] Multiple Python executables found — this is a common source of package conflicts:"
        $pythons | ForEach-Object { $report += "  $_" }
    }

    # Multiple CUDA versions
    $cudaRoots = Get-ChildItem "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\" -ErrorAction SilentlyContinue
    if ($cudaRoots.Count -gt 1) {
        $report += "`n[WARNING] Multiple CUDA versions installed — ensure your frameworks target the same version:"
        $cudaRoots | ForEach-Object { $report += "  $($_.FullName)" }
    }

    # Conda + system pip mixing
    if ((Get-Command conda -ErrorAction SilentlyContinue) -and (Get-Command pip -ErrorAction SilentlyContinue)) {
        $pipPath = (Get-Command pip).Source
        if ($pipPath -notmatch 'conda|Anaconda|Miniconda') {
            $report += "`n[WARNING] pip resolves outside conda — mixing conda and system pip causes dependency hell."
            $report += "  pip path: $pipPath"
        }
    }

    # Long PATH
    $pathLen = $env:PATH.Length
    if ($pathLen -gt 2048) {
        $report += "`n[WARNING] PATH is $pathLen characters long — Windows has a 2048 limit for some tools."
    }

    # Duplicate PATH entries
    $pathEntries = $env:PATH -split ';'
    $dupes = $pathEntries | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
    if ($dupes) {
        $report += "`n[INFO] Duplicate PATH entries (safe to deduplicate):"
        $dupes | ForEach-Object { $report += "  $_" }
    }

    if ($report.Count -eq 0) { $report += "No obvious conflicts detected." }
    $report
}

# ---------------------------------------------------------------------------
# Summary
Write-Section "Done"
$files = Get-ChildItem $reportDir | Measure-Object
Write-Host "`nAnalysis complete. $($files.Count) files written to:" -ForegroundColor Green
Write-Host "  $reportDir" -ForegroundColor Yellow
Write-Host "`nNext step: run Backup-System.ps1 to create a restorable bundle.`n"
