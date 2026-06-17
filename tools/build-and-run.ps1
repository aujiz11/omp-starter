#Requires -Version 7.0

param(
    [switch]$Release,
    [switch]$NoRun,
    [switch]$NoKill
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$buildArgs = @()
if ($Release) { $buildArgs += "-Release" }

& "$PSScriptRoot\build.ps1" @buildArgs
if ($LASTEXITCODE -ne 0) { exit 1 }

if ($NoRun) {
    LogInfo "build ok, skipping run (-NoRun)"
    exit 0
}

$runArgs = @()
if ($NoKill) { $runArgs += "-NoKill" }

& "$PSScriptRoot\run.ps1" @runArgs
