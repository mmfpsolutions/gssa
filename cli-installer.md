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
8. Starts coin node, creates wallet, saves address (see **Wallet Address Format** below)
9. Starts PostgreSQL, creates GoSlimStratum database and role
10. Brings up the full 7-container stack

**Wallet Address Format:**

The installer generates a fresh receiving address on the coin node and writes it into the GSS config as the pool's mining/payout address. The format chosen depends on the coin:

| Coin | Address type | Example shape |
|---|---|---|
| **DigiByte (DGB)** | `bech32m` (P2TR / Taproot) | `dgb1p...` |
| **Bitcoin Cash (BCH)** | `legacy` script type, CashAddr format | `bitcoincash:q...` |
| **Bitcoin (BTC)** | `bech32m` (P2TR / Taproot) | `bc1p...` |

For DGB and BTC, Taproot (`bech32m`) is the modern default — lighter spend weight on payouts and forward-compatible with newer features (e.g. DGB's upcoming DigiDollar stablecoin works with legacy addresses too, but starting on Taproot avoids a transfer step later if you decide to mint). BCH has never adopted SegWit or Taproot, so it stays on the standard CashAddr-formatted P2PKH that BCH wallets and exchanges expect.

The generated address is saved to `/data/<coin>/<coin>_wallet.txt` for your records, and patched into `/data/goslimstratum/config/config.json` automatically. You can swap it for a different address at any time by editing the GSS config and restarting the stack.

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


## Deployment

This is a public GitHub repo. Scripts and templates are served via GitHub Pages at `get.mmfpsolutions.io`.

```bash
# CLI installer
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"

# Uninstaller
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)"
