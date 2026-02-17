# GSSA — GoSlimStratum Assets

Public repository for MMFP Solutions deployment scripts, configuration templates, and product documentation. Assets are served via GitHub Pages at [get.mmfpsolutions.io](https://get.mmfpsolutions.io).

---

## What Is MMFP?

MMFP (MMFP Solutions Full Platform) is a complete, production-ready mining infrastructure stack. A single installer deploys 7 Docker containers that together provide a fully operational mining pool with monitoring, management, and automatic updates.

**Supported cryptocurrencies:** DigiByte (DGB), Bitcoin Cash (BCH), Bitcoin (BTC/Knots)

**Deployed containers:**

| Container        | Purpose                                             |
|------------------|-----------------------------------------------------|
| Coin Node        | Full or pruned blockchain node (DGB, BCH, or BTC)  |
| GoSlimStratum    | Mining stratum server and pool                      |
| PostgreSQL 18    | Database for share tracking and metrics             |
| MIM              | Infrastructure management dashboard                 |
| AxeOS Dashboard  | Miner monitoring dashboard                          |
| Dozzle           | Docker log viewer                                   |
| Watchtower       | Automatic container updates                         |

---

## Quick Start

### CLI Installer (Recommended)

Full deployment via terminal prompts — fastest method, supports all coins.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"
```

### Uninstaller

Tiered removal — choose what to keep and what to remove.

```bash
sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)"
```

**System Requirements:** Ubuntu Server 24.04+, ARM64 or AMD64, root access, 16 GB RAM minimum, internet connection.

For full installer details, see [cli-installer.md](cli-installer.md).

---

## Repository Structure

```
gssa/
├── scripts/                  # Deployment and removal scripts
├── templates/                # Configuration templates (served via GitHub Pages)
│   ├── docker-compose.yml
│   ├── env.template
│   ├── axeos-dashboard/
│   ├── goslimstratum/
│   ├── mim-config/
│   ├── postgres/
│   └── coins/                # Per-coin templates (dgb/, bch/, btc/)
├── documents/                # Product documentation and configuration guides
│   ├── GoSlimStratum/
│   ├── GSS Miners/
│   ├── MIM/
│   ├── AxeOS Dashboard/
│   ├── examples/             # Example configuration files for each product
│   │   ├── GoSlimStratum/    # gss-config.example.json, coins.example.json
│   │   ├── GSS Miners/       # config.example.json, notifications.example.json
│   │   ├── MIM/              # servers.example.json
│   │   └── AxeOS Dashboard/  # config.json, access.json, rpcConfig.json, jsonWebTokenKey.json, notifications.json
│   └── diagrams/
├── design-documents/         # Internal technical specifications
├── cli-installer.md          # CLI installer reference
└── README.md                 # This file
```

---

## Documentation

### GoSlimStratum (GSS)

GoSlimStratum is the stratum mining server at the core of MMFP. It manages miner connections, share validation, difficulty adjustment, and block reward payouts.

| Document                                                                    | Description                                                             |
|-----------------------------------------------------------------------------|-------------------------------------------------------------------------|
| [Global Config Guide](documents/GoSlimStratum/gss-global-config-guide.md)  | Logging, metrics/database, web UI, and notifications configuration      |
| [Coin Config Guide](documents/GoSlimStratum/gss-coin-config-guide.md)      | Per-coin settings: node connection, stratum, mining, vardiff, and payout |

Example configs: [documents/examples/GoSlimStratum/](documents/examples/GoSlimStratum/)

---

### GSS Miners (GSSM)

GSS Miners is a monitoring dashboard for mining devices (Bitaxe, Antminer, AvalonQ, Nano3S), GoSlimStratum pools, and blockchain nodes — all in one place.

| Document                                                                      | Description                                                        |
|-------------------------------------------------------------------------------|--------------------------------------------------------------------|
| [Config Guide](documents/GSS%20Miners/gssm-config-guide.md)                  | Device setup, pool/node integration, thresholds, refresh intervals |
| [Notifications Guide](documents/GSS%20Miners/gssm-notifications-guide.md)    | Email, Telegram, webhook alerting for device/pool/node events      |

Example configs: [documents/examples/GSS Miners/](documents/examples/GSS%20Miners/)

---

### MIM (Mining Infrastructure Manager)

MIM is a Docker management dashboard that lets you start, stop, update, and monitor containers across one or more servers — all from a single web interface.

| Document                                                  | Description                                        |
|-----------------------------------------------------------|----------------------------------------------------|
| [Config Guide](documents/MIM/mim-config-guide.md)        | Server definitions (SSH/Docker), timeouts, logging |

Example configs: [documents/examples/MIM/](documents/examples/MIM/)

---

### AxeOS Dashboard

AxeOS Dashboard is a monitoring dashboard focused on AxeOS-based miners (Bitaxe, NerdQAxe), with optional integration for CGMiner devices, GoSlimStratum pools, and blockchain nodes.

| Document                                                                                    | Description                                                                                |
|---------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| [Config Guide](documents/AxeOS%20Dashboard/axeos-dashboard-config-guide.md)                | All five config files: main config, authentication, JWT, RPC credentials, and notifications |

Example configs: [documents/examples/AxeOS Dashboard/](documents/examples/AxeOS%20Dashboard/)

---

### Additional Guides

| Document                                                    | Description                                                                     |
|-------------------------------------------------------------|---------------------------------------------------------------------------------|
| [Tailscale Install Guide](documents/tailscale-install.md)  | Setting up Tailscale VPN for secure remote access to your mining infrastructure |

---

## Architecture

Architecture diagrams for GoSlimStratum are available in [documents/diagrams/GoSlimStratum-Architecture/](documents/diagrams/GoSlimStratum-Architecture/):

- `highlevel-architecture.png` — Overall system overview
- `payout-system-design.png` — Payout system architecture
- `payout-system-details.png` — Detailed payout flow

---

## Templates

Configuration templates in `templates/` are served via GitHub Pages and consumed by the installer scripts. They contain placeholder variables (e.g., `{{RPC_USER}}`) that are substituted during installation.

Templates are versioned — archived releases preserve backward compatibility with older installer versions.

---

## License

© 2026 MMFP Solutions, LLC. Proprietary license. Free to use.
