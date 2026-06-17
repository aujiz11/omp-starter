# omp-starter

Build tool for open.mp gamemode development.

## Quick Start

### 1. Download

Download the latest version from [Releases](https://github.com/aujiz11/omp-starter/releases):

```
omp-starter-vX.Y.Z.zip
├── server.bat
└── tools/
    ├── common.ps1
    ├── config.ps1
    ├── install.ps1
    ├── build.ps1
    ├── run.ps1
    └── build-and-run.ps1
```

### 2. Setup

**New project:**

```bash
mkdir my-server && cd my-server
# extract omp-starter.zip here
server install
```

**Existing project:**

```bash
cd your-project
# extract omp-starter.zip here (server.bat + tools/)
server install
```

### 3. Code

Create `gamemodes/main.pwn`:

```c
#include <open.mp>

main() {
    print("Hello open.mp!");
}

public OnPlayerConnect(playerid) {
    SendClientMessage(playerid, -1, "Welcome!");
    return 1;
}
```

### 4. Build & Run

```bash
server build
server run
```

## Requirements

- Windows 10+
- [PowerShell 7+](https://github.com/PowerShell/PowerShell/releases) (`pwsh`)

## Commands

```
server install [version]
server build [-Gamemode x] [-Filter y] [-File z.pwn] [-Release]
server run [-Window]
server build-and-run [-Release]
```

### install

Download open.mp server from GitHub and extract into project. Does not overwrite custom files.

```bash
server install                   # latest
server install 1.5.8.3079        # specific version
```

### build

Compile Pawn gamemode. By default, builds all `.pwn` files in `gamemodes/` + `filterscripts/`.

```bash
server build                                  # build all
server build -Release                         # release mode (-d0 -O2)
server build -Gamemode "main.pwn"             # single gamemode
server build -Filter "vip.pwn"                # single filterscript
server build -Gamemode "main.pwn" -Filter "vip.pwn"
server build -File "gamemodes\custom.pwn"     # arbitrary path
```

### run

Start omp-server. Automatically kills the previous server process if running.

```bash
server run                # foreground (Ctrl+C to stop)
server run -Window        # separate window
```

### build-and-run

Build then run.

```bash
server build-and-run
server build-and-run -Release
```

## Auto-detect

Auto-detects:

- `pawncc.exe` in `qawno/`, root, or PATH
- `omp-server.exe` in root, `server/`, or `bin/`
- Includes in `qawno/include/` or `include/`
- Gamemodes in `gamemodes/*.pwn`
- Filterscripts in `filterscripts/*.pwn`
