#Requires -Version 7.0

if (Test-Path variable:script:__CONFIG_LOADED) { return }
$script:__CONFIG_LOADED = $true

. "$PSScriptRoot\common.ps1"

$script:ROOT = $PWD.Path

# Auto-detect paths
$script:COMPILER        = Find-Compiler $script:ROOT
$script:SERVER_EXE      = Find-Server $script:ROOT
$script:INCLUDE_DIR     = Find-IncludeDir $script:ROOT
$script:GAMEMODES_DIR   = Find-GamemodesDir $script:ROOT
$script:FILTERSCRIPTS_DIR = Find-FilterscriptsDir $script:ROOT
$script:MAIN_PWN        = Find-MainPwn $script:GAMEMODES_DIR

$script:PLUGINS_DIR     = [IO.Path]::Combine($script:ROOT, "plugins")
$script:COMPONENTS_DIR  = [IO.Path]::Combine($script:ROOT, "components")
$script:QAWNO_DIR       = [IO.Path]::Combine($script:ROOT, "qawno")
$script:SCRIPTFILES_DIR = [IO.Path]::Combine($script:ROOT, "scriptfiles")
$script:MODELS_DIR      = [IO.Path]::Combine($script:ROOT, "models")

$script:TEMP_DIR = [IO.Path]::Combine([IO.Path]::GetTempPath(), "omp-build-tool")

# Built-in includes (come with open.mp release, safe to overwrite)
$script:BUILTIN_INCLUDES = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        "a_actor.inc", "a_http.inc", "a_mysql.inc", "a_npc.inc",
        "a_objects.inc", "a_players.inc", "a_samp.inc", "a_sampdb.inc",
        "a_vehicles.inc", "args.inc", "console.inc", "core.inc",
        "datagram.inc", "file.inc", "float.inc", "string.inc", "time.inc",
        "_open_mp.inc", "open.mp.inc",
        "omp_actor.inc", "omp_checkpoint.inc", "omp_class.inc",
        "omp_core.inc", "omp_database.inc", "omp_dialog.inc",
        "omp_gangzone.inc", "omp_http.inc", "omp_menu.inc",
        "omp_network.inc", "omp_npc.inc", "omp_object.inc",
        "omp_pickup.inc", "omp_player.inc", "omp_textdraw.inc",
        "omp_textlabel.inc", "omp_variable.inc", "omp_vehicle.inc",
        "omp-callbacks.inc", "pawn.json"
    ),
    [StringComparer]::OrdinalIgnoreCase
)
