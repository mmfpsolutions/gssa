# GSSA - GoSlimStratum Assets

Online repository for publishing install scripts for MMFP Products.

## Installers

### CLI Installer (`install-cli.sh`) - RECOMMENDED - FASTEST

Full deployment of the MMFP mining infrastructure entirely via terminal prompts — no web UI required. Supports **DigiByte (DGB)**, **Bitcoin Cash (BCH)**, and **Bitcoin (BTC)**.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"
```

**What it deploys (7 containers):**
- Coin node (DigiByte, Bitcoin Cash, or Bitcoin Knots — user selects during install)
- GoSlimStratum mining stratum server
- PostgreSQL 18 database
- MIM management dashboard
- AxeOS monitoring dashboard
- Dozzle log viewer
- Watchtower auto-updater

**What it does:**
1. Preflight checks (root, Ubuntu 24.04+, ARM64/AMD64, memory, openssl)
2. Creates `/data` directory
3. Checks for Docker Engine — installs official Docker if needed (interactive)
4. Coin selection (DGB/BCH/BTC) + collects configuration (passwords, RPC credentials, pruning, server IP)
5. Downloads config templates from GitHub (base + coin-specific)
6. Creates MIM system user with sudo/docker access
7. Generates all config files from templates
8. Starts coin node, creates wallet, saves address
9. Starts PostgreSQL, creates GoSlimStratum database and role
10. Brings up the full 7-container stack

### Uninstaller (`uninstall.sh`)

Removes MMFP components with tiered prompts — choose what to keep and what to remove.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)"
```

**Prompts to remove (in order):**
1. Stop and remove all MMFP containers (+ optionally remove Docker images)
2. Delete `/data` directory (wallet warning, defaults to No)
3. Remove `mim` system user (defaults to No)
4. Remove Docker Engine entirely (defaults to No)

## Requirements

- Ubuntu Server 24.04 or later
- Root access
- Internet connection
- ARM64 or AMD64 architecture
- 16 GB RAM minimum (configurable via `MIN_MEMORY_GB`)

## Manual testing

```bash
# CLI installer
sudo bash scripts/install-cli.sh

# Uninstaller
sudo bash scripts/uninstall.sh

# Web installer (optional)
sudo bash scripts/install-web.sh
```

## Project Structure

```
gssa/
├── README.md
├── scripts/
│   ├── install-cli.sh          # Full CLI installer (multi-coin)
│   ├── uninstall.sh            # Tiered uninstaller
│   └── install-web.sh          # Web installer (MIM Bootstrap, optional)
├── templates/                   # Config templates (served via GitHub Pages)
│   ├── docker-compose.yml       # Base services (GSS, Postgres, MIM, AxeOS, etc.)
│   ├── env.template
│   ├── goslimstratum/
│   │   └── config.json.template
│   ├── axeos-dashboard/
│   │   ├── config.json.template
│   │   ├── rpcConfig.json.template
│   │   ├── access.json
│   │   └── jsonWebTokenKey.json
│   ├── mim-config/
│   │   └── servers.json.template
│   ├── postgres/
│   │   └── user-db-setup.sql.template
│   └── coins/                   # Per-coin templates
│       ├── dgb/                 # DigiByte
│       │   ├── docker-compose.yml
│       │   ├── node.conf.template
│       │   └── gss-coin.json.template
│       ├── bch/                 # Bitcoin Cash
│       │   ├── docker-compose.yml
│       │   ├── node.conf.template
│       │   └── gss-coin.json.template
│       └── btc/                 # Bitcoin (Knots)
│           ├── docker-compose.yml
│           ├── node.conf.template
│           └── gss-coin.json.template
└── design-documents/
    └── install-cli-design.md
```

## Deployment

This is a public GitHub repo. Scripts and templates are served via GitHub Pages at `get.mmfpsolutions.io`.

```bash
# CLI installer
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"

# Uninstaller
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)"

# Web installer (optional)
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-web.sh)"
```

### Web Installer — Optional (`install-web.sh`) - SLOWEST - ONLY SUPPORTS DGB

Alternative installer that launches the MIM Bootstrap web UI for guided setup. Use this if you prefer a browser-based workflow.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-web.sh)"
```

**What it does:**
1. Verifies Ubuntu 24.04+ and supported architecture (ARM64/AMD64)
2. Creates `/data` directory
3. Checks for Docker Engine — installs official Docker if needed (interactive)
4. Pulls and starts MIM Bootstrap container on port 3002
5. Prints the web installer URL