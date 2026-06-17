#Requires -Version 7.0

# Guard
if (Test-Path variable:script:__COMMON_LOADED) { return }
$script:__COMMON_LOADED = $true

# ANSI support
$script:HasAnsi = $null -ne $PSStyle
$script:Ansi = @{
    Reset = $script:HasAnsi ? $PSStyle.Reset : ""
    Dim   = $script:HasAnsi ? $PSStyle.Dim : ""
    Bold  = $script:HasAnsi ? $PSStyle.Bold : ""
    Red   = $script:HasAnsi ? $PSStyle.Foreground.Red : ""
    Green = $script:HasAnsi ? $PSStyle.Foreground.BrightGreen : ""
    Yellow= $script:HasAnsi ? $PSStyle.Foreground.BrightYellow : ""
    Cyan  = $script:HasAnsi ? $PSStyle.Foreground.BrightCyan : ""
    White = $script:HasAnsi ? $PSStyle.Foreground.White : ""
}

function Log([string]$Message) {
    Write-Host "  $Message"
}

function LogOk([string]$Message) {
    Write-Host "  $($script:Ansi.Green)ok$($script:Ansi.Reset) $Message"
}

function LogSkip([string]$Message) {
    Write-Host "  $($script:Ansi.Yellow)skip$($script:Ansi.Reset) $Message"
}

function LogErr([string]$Message) {
    Write-Host "  $($script:Ansi.Red)err$($script:Ansi.Reset) $Message"
}

function LogInfo([string]$Message) {
    Write-Host "  $($script:Ansi.Cyan)info$($script:Ansi.Reset) $Message"
}

function LogStep([string]$Message) {
    Write-Host "`n$Message"
}

function LogDone([string]$Message) {
    Write-Host "`n$($script:Ansi.Green)done$($script:Ansi.Reset) $Message"
}

function LogFail([string]$Message) {
    Write-Host "`n$($script:Ansi.Red)fail$($script:Ansi.Reset) $Message"
}

function Find-FirstExisting([string[]]$Paths) {
    foreach ($p in $Paths) {
        if (-not [string]::IsNullOrEmpty($p) -and (Test-Path $p)) { return $p }
    }
    return $null
}

function Find-Compiler([string]$Root) {
    Find-FirstExisting @(
        [IO.Path]::Combine($Root, "qawno", "pawncc.exe"),
        [IO.Path]::Combine($Root, "pawncc.exe"),
        (Get-Command pawncc.exe -ErrorAction SilentlyContinue)?.Source
    )
}

function Find-Server([string]$Root) {
    Find-FirstExisting @(
        [IO.Path]::Combine($Root, "omp-server.exe"),
        [IO.Path]::Combine($Root, "server", "omp-server.exe"),
        [IO.Path]::Combine($Root, "bin", "omp-server.exe")
    )
}

function Find-IncludeDir([string]$Root) {
    Find-FirstExisting @(
        [IO.Path]::Combine($Root, "qawno", "include"),
        [IO.Path]::Combine($Root, "include"),
        [IO.Path]::Combine($Root, "pawno", "include")
    )
}

function Find-GamemodesDir([string]$Root) {
    Find-FirstExisting @(
        [IO.Path]::Combine($Root, "gamemodes"),
        [IO.Path]::Combine($Root, "gamemode")
    )
}

function Find-FilterscriptsDir([string]$Root) {
    $dir = [IO.Path]::Combine($Root, "filterscripts")
    if ((Test-Path $dir) -and (Get-ChildItem -Path $dir -Filter "*.pwn" -File -ErrorAction SilentlyContinue)) {
        return $dir
    }
    return $null
}

function Find-MainPwn([string]$GamemodesDir) {
    if (-not $GamemodesDir) { return $null }
    # Find the first .pwn file (or main.pwn specifically)
    $main = [IO.Path]::Combine($GamemodesDir, "main.pwn")
    if (Test-Path $main) { return $main }
    # Fallback: any .pwn file
    Get-ChildItem -Path $GamemodesDir -Filter "*.pwn" -File | Select-Object -First 1 -ExpandProperty FullName
}

function Invoke-Compiler([string]$CompilerExe, [string]$SourceFile, [string]$OutputDir, [string]$IncludeDir, [string[]]$ExtraFlags) {
    $args = @(
        "`"$SourceFile`""
        "-D`"$OutputDir`""
        "-i`"$IncludeDir`""
    ) + $ExtraFlags

    $psi = [System.Diagnostics.ProcessStartInfo]@{
        FileName               = $CompilerExe
        Arguments              = $args -join " "
        RedirectStandardOutput = $true
        RedirectStandardError  = $true
        UseShellExecute        = $false
        CreateNoWindow         = $true
    }

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    try {
        $null = $proc.Start()
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        return @{
            ExitCode = $proc.ExitCode
            Stdout   = $stdout
            Stderr   = $stderr
        }
    }
    finally { $proc.Dispose() }
}
