#Requires -Version 7.0

param(
    [string]$File,
    [string]$Gamemode,
    [string]$Filter,
    [switch]$Release
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. "$PSScriptRoot\config.ps1"

if (-not $script:COMPILER) {
    LogErr "compiler not found (pawncc.exe)"
    LogInfo "run: server install"
    exit 1
}

$files = @()

if ($File) {
    # -File: explicit path, ignore -Gamemode/-Filter
    $full = [IO.Path]::IsPathRooted($File) ? $File : [IO.Path]::Combine($script:ROOT, $File)
    if (-not (Test-Path $full)) {
        LogErr "file not found: $full"
        exit 1
    }
    $files = @($full)
}
else {
    # Gamemodes
    if ($Gamemode) {
        $gFile = [IO.Path]::Combine($script:GAMEMODES_DIR, $Gamemode)
        if (-not (Test-Path $gFile)) {
            LogErr "gamemode not found: $Gamemode"
            exit 1
        }
        $files += $gFile
    }
    elseif ($script:GAMEMODES_DIR) {
        $files += Get-ChildItem -LiteralPath $script:GAMEMODES_DIR -Filter "*.pwn" -File
            | Select-Object -ExpandProperty FullName
    }

    # Filterscripts
    if ($Filter) {
        if (-not $script:FILTERSCRIPTS_DIR) {
            LogErr "filterscripts/ directory not found"
            exit 1
        }
        $fFile = [IO.Path]::Combine($script:FILTERSCRIPTS_DIR, $Filter)
        if (-not (Test-Path $fFile)) {
            LogErr "filterscript not found: $Filter"
            exit 1
        }
        $files += $fFile
    }
    elseif ($script:FILTERSCRIPTS_DIR -and -not $Gamemode) {
        # Only auto-include filterscripts when building all (no specific target)
        $files += Get-ChildItem -LiteralPath $script:FILTERSCRIPTS_DIR -Filter "*.pwn" -File
            | Select-Object -ExpandProperty FullName
    }
}

if ($files.Count -eq 0) {
    LogErr "no .pwn files found"
    LogInfo "create gamemodes/main.pwn or use -File / -Gamemode / -Filter"
    exit 1
}

$totalErr = 0
$totalWarn = 0
$startTime = [DateTime]::UtcNow
$mode = $Release ? "release" : "debug"

foreach ($pwn in $files) {
    $name = [IO.Path]::GetFileName($pwn)
    $dir  = [IO.Path]::GetDirectoryName($pwn)
    $isFs = $dir -match "filterscripts"
    $outDir = $isFs ? $script:FILTERSCRIPTS_DIR : $script:GAMEMODES_DIR

    LogStep "build $name ($mode)"

    $flags = @($Release ? @("-d0", "-O2") : @("-d3")) + @("-;+", "-(+")
    $result = Invoke-Compiler $script:COMPILER $pwn $outDir $script:INCLUDE_DIR $flags

    $fErr = 0
    $fWarn = 0

    foreach ($line in ($result.Stdout -split "`r?`n")) {
        $t = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) { continue }

        if ($t -match '\)\s*:\s*error\s+\d+:') {
            $fErr++; LogErr $t
        }
        elseif ($t -match '\)\s*:\s*warning\s+\d+:') {
            $fWarn++; Log $t
        }
        elseif ($t -match 'Pawn compiler') {
            LogInfo $t
        }
    }

    # stderr
    if (-not [string]::IsNullOrWhiteSpace($result.Stderr)) {
        foreach ($line in ($result.Stderr -split "`r?`n")) {
            $t = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($t)) { continue }
            if ($t -match '\)\s*:\s*(fatal\s+)?error\s+\d+:') { $fErr++ }
            LogErr $t
        }
    }

    $totalErr += $fErr
    $totalWarn += $fWarn

    if ($result.ExitCode -eq 0 -and $fErr -eq 0) {
        $amx = [IO.Path]::ChangeExtension($pwn, ".amx")
        $size = if (Test-Path $amx) {
            $kb = [math]::Round((Get-Item $amx).Length / 1KB, 1)
            " ($kb KB)"
        } else { "" }
        LogOk "$name$size"
        if ($fWarn -gt 0) { Log "$fWarn warnings" }
    }
    else {
        LogFail "$name ($fErr errors, $fWarn warnings)"
    }
}

$elapsed = [math]::Round(([DateTime]::UtcNow - $startTime).TotalSeconds, 1)
$errStr = $totalErr -gt 0 ? "err=$totalErr" : "err=0"
$warnStr = $totalWarn -gt 0 ? " warn=$totalWarn" : ""

if ($totalErr -gt 0) {
    LogFail "$($files.Count) files, $errStr$warnStr, ${elapsed}s"
    exit 1
}
else {
    LogDone "$($files.Count) files, $errStr$warnStr, ${elapsed}s"
    exit 0
}
