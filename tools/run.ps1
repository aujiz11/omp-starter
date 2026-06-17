#Requires -Version 7.0

param(
    [switch]$NoKill,
    [switch]$Window
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. "$PSScriptRoot\config.ps1"

if (-not $script:SERVER_EXE) {
    LogErr "omp-server.exe not found"
    LogInfo "run: server install"
    exit 1
}

$mainAmx = if ($script:GAMEMODES_DIR) {
    [IO.Path]::Combine($script:GAMEMODES_DIR, "main.amx")
} else { $null }

if ($mainAmx -and -not (Test-Path $mainAmx)) {
    LogErr "main.amx not found"
    LogInfo "run: server build"
    exit 1
}

$procName = "omp-server"
$existing = Get-Process -Name $procName -ErrorAction SilentlyContinue

if ($existing) {
    if ($NoKill) {
        LogErr "server already running (PID $($existing.Id))"
        LogInfo "stop it first, or remove -NoKill"
        exit 1
    }
    LogInfo "stopping previous server (PID $($existing.Id))"
    Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue

    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while ((Get-Process -Name $procName -ErrorAction SilentlyContinue) -and ([DateTime]::UtcNow -lt $deadline)) {
        Start-Sleep -Milliseconds 300
    }

    if (Get-Process -Name $procName -ErrorAction SilentlyContinue) {
        LogErr "failed to stop previous server"
        exit 1
    }
    LogOk "stopped"
    Start-Sleep -Seconds 1
}

$exeName = [IO.Path]::GetFileName($script:SERVER_EXE)
LogStep "run $exeName"

if ($Window) {
    Start-Process -FilePath $script:SERVER_EXE -WorkingDirectory $script:ROOT -WindowStyle Normal
    LogOk "started in new window"
}
else {
    try {
        & $script:SERVER_EXE
        $code = $LASTEXITCODE
    }
    catch {
        LogInfo "server stopped: $_"
        $code = 1
    }
    Write-Host ""
    $msg = $code -eq 0 ? "exited cleanly" : "exited with code $code"
    LogInfo $msg
    exit $code
}
