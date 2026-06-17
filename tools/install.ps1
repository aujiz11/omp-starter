#Requires -Version 7.0

param(
    [string]$Version,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. "$PSScriptRoot\config.ps1"

if (-not $Version) {
    LogStep "install fetching latest version from GitHub ..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        $release = Invoke-RestMethod "https://api.github.com/repos/openmultiplayer/open.mp/releases/latest"
        $ProgressPreference = 'Continue'
        $Version = $release.tag_name -replace '^v', ''
        LogInfo "latest = $Version"
    }
    catch {
        LogErr "failed to fetch latest version: $_"
        LogInfo "specify version manually: install -Version X.Y.Z"
        exit 1
    }
}

LogStep "install open.mp v$Version"

$zipUrl = "https://github.com/openmultiplayer/open.mp/releases/download/v$Version/open.mp-win-x86.zip"
$zipPath = [IO.Path]::Combine($script:TEMP_DIR, "omp-release.zip")

if (Test-Path $script:TEMP_DIR) { Remove-Item $script:TEMP_DIR -Recurse -Force }
$null = New-Item -ItemType Directory -Path $script:TEMP_DIR -Force

LogInfo "downloading $zipUrl"
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    LogOk "downloaded $([math]::Round((Get-Item $zipPath).Length / 1MB, 1)) MB"
}
catch {
    LogErr "download failed: $_"
    LogInfo "https://github.com/openmultiplayer/open.mp/releases"
    exit 1
}

$extractDir = [IO.Path]::Combine($script:TEMP_DIR, "extracted")
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
$sourceRoot = (Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1)?.FullName ?? $extractDir
LogOk "extracted"

$copied = 0
$skipped = 0

$allFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -ErrorAction SilentlyContinue
$totalFiles = ($allFiles | Measure-Object).Count
LogInfo "copying $totalFiles files ..."

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Substring($sourceRoot.Length + 1)
    $destPath = [IO.Path]::Combine($script:ROOT, $relativePath)

    $isInclude = $relativePath -like "qawno\include\*"
    if ($isInclude -and -not $Force) {
        $fileName = $file.Name
        $parentRel = [IO.Path]::GetDirectoryName($relativePath)
        if ($parentRel -eq "qawno\include" -and -not $script:BUILTIN_INCLUDES.Contains($fileName)) {
            if (Test-Path $destPath) {
                LogSkip "$relativePath (custom)"
                $skipped++
                continue
            }
        }
    }

    if (-not $Force -and (Test-Path $destPath)) {
        $srcTime = $file.LastWriteTimeUtc
        $dstTime = (Get-Item $destPath).LastWriteTimeUtc
        if ($srcTime -le $dstTime) {
            $skipped++
            continue
        }
    }

    $destDir = [IO.Path]::GetDirectoryName($destPath)
    if (-not (Test-Path $destDir)) {
        $null = New-Item -ItemType Directory -Path $destDir -Force
    }

    Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force
    $copied++
    LogOk $relativePath
}

Remove-Item $script:TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

# Re-detect paths after install
$script:COMPILER   = Find-Compiler $script:ROOT
$script:SERVER_EXE = Find-Server $script:ROOT
$script:INCLUDE_DIR = Find-IncludeDir $script:ROOT

LogDone "installed open.mp v$Version ($script:copied files)"
