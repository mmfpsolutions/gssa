# GSSA - GoSlimStratum Assets

Online repository for publishing install scripts for MMFP Products.

## Installers

### Web Installer (`install-web.sh`)

One-command installer that sets up Docker and launches the MIM Bootstrap web UI for guided setup.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-web.sh)"
```

**What it does:**
1. Verifies Ubuntu 24.04+ and supported architecture (ARM64/AMD64)
2. Creates `/data` directory
3. Checks for Docker Engine — installs official Docker if needed (interactive)
4. Pulls and starts MIM Bootstrap container on port 3002
5. Prints the web installer URL

### CLI Installer (`install-cli.sh`)

Full deployment of the MMFP mining infrastructure entirely via terminal prompts — no MIM Bootstrap web UI required.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"
```

**What it deploys (7 containers):**
- DigiByte Core node
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
4. Collects configuration (passwords, RPC credentials, pruning, server IP)
5. Downloads config templates from GitHub
6. Creates MIM system user with sudo/docker access
7. Generates all config files from templates
8. Starts DigiByte Core, creates wallet, saves address to `/data/dgb/dgb_wallet.txt`
9. Starts PostgreSQL, creates GoSlimStratum database and role
10. Brings up the full 7-container stack

## Requirements

- Ubuntu Server 24.04 or later
- Root access
- Internet connection
- ARM64 or AMD64 architecture
- 16 GB RAM minimum (configurable via `MIN_MEMORY_GB`)

## Manual testing

```bash
# Web installer
sudo bash scripts/install-web.sh

# CLI installer
sudo bash scripts/install-cli.sh
```

## Project Structure

```
gssa/
├── README.md
├── scripts/
│   ├── install-web.sh          # Web installer (MIM Bootstrap)
│   └── install-cli.sh          # Full CLI installer
├── templates/                   # Config templates (served via GitHub Pages)
│   ├── docker-compose.yml
│   ├── .env.template
│   ├── digibyte.conf.template
│   ├── goslimstratum/
│   │   └── config.json.template
│   ├── axeos-dashboard/
│   │   ├── config.json.template
│   │   ├── rpcConfig.json.template
│   │   ├── access.json
│   │   └── jsonWebTokenKey.json
│   ├── mim-config/
│   │   └── servers.json.template
│   └── postgres/
│       └── user-db-setup.sql.template
└── design-documents/
    └── install-cli-design.md
```

## Deployment

This is a public GitHub repo. Scripts and templates are served via GitHub Pages at `get.mmfpsolutions.io`.

```bash
# Web installer
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-web.sh)"

# CLI installer
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"
```
