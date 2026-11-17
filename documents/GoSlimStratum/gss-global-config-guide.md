# GoSlimStratum Global Configuration Guide

Complete reference for the global configuration settings in GoSlimStratum (GSS).

*Current for GoSlimStratum 6.0.0.*

---

## Summary
> **Note:** Most of these settings can be changed in the WebUI.

GoSlimStratum keeps its configuration in a few JSON files in its config directory:

- **`config.json`** — The main configuration file. Contains global settings that apply to the entire pool (logging, metrics, web UI) as well as all per-coin configurations.
- **`notifications.json`** — Optional. Controls alert notifications via email, Telegram, Discord, or custom webhooks.
- **`coins.json`** — Optional. Defines extra SHA256d coins that are not built in. See the [Coin Configuration Guide](gss-coin-config-guide.md).
- **`hopper.json`** — Optional (v6.0.0+). The Hash Hopper's settings. See the [Hash Hopper Guide](gss-hash-hopper-guide.md).

This guide covers the global sections of `config.json` and the full `notifications.json`. For per-coin configuration settings, see the [Coin Configuration Guide](gss-coin-config-guide.md). If something isn't working as expected, see the [Troubleshooting Guide](gss-troubleshooting-guide.md).

> **Note:** Most configuration changes require a restart of GoSlimStratum to take effect. It is recommended to use the WebUI for edits where possible.
>
> These apply as soon as you save them on the Global Config page, with no restart: **Animated Background**, **Default Pool**, and **Show Coin Price and Value**. Log levels changed on the **Log Stream** page also apply at once; log levels changed on the Global Config page apply at the next restart.

---

## Example Global Configuration

```json
{
    "global": {
        "pool_name": "My Mining Pool",
        "connection_timeout_seconds": 600
    },
    "logging": {
        "level": "info",
        "share_log_level": "info",
        "log_to_file": true,
        "log_file_path": "/app/logs/goslimstratum.log",
        "max_size_mb": 20,
        "max_age_days": 30,
        "max_backups": 10,
        "compress": false
    },
    "metrics": {
        "enabled": true,
        "database_host": "127.0.0.1",
        "database_port": 5432,
        "database_name": "goslimstratum",
        "database_user": "db_username",
        "database_password": "db_password",
        "database_ssl_mode": "disable",
        "database_max_connections": 20,
        "database_connection_timeout": 30,
        "batch_size": 100,
        "flush_interval_seconds": 10,
        "share_retention_hours": 48,
        "snapshot_interval_seconds": 60,
        "network_poll_interval_seconds": 60,
        "network_stats_retention_days": 7,
        "cleanup_interval_hours": 24,
        "hashrate_windows": [60, 300, 900],
        "log_interval_seconds": 30,
        "connection_flush_interval_seconds": 2,
        "enable_api_cache": true,
        "enable_http_api": true,
        "http_api_port": 4004
    },
    "web": {
        "enabled": true,
        "host": "0.0.0.0",
        "port": 3003,
        "api_base_url": "/api/v1",
        "animated_background": "hash-drift",
        "default_coin": "",
        "block_explorer_urls": {
            "DGB": "https://chainz.cryptoid.info/dgb/block.dws?{hash}",
            "BTC": "https://chainz.cryptoid.info/btc/block.dws?{hash}",
            "BCH": "https://blockchair.com/bitcoin-cash/block/{hash}"
        },
        "tx_explorer_urls": {
            "DGB": "https://chainz.cryptoid.info/dgb/tx.dws?{txid}",
            "BTC": "https://chainz.cryptoid.info/btc/tx.dws?{txid}",
            "BCH": "https://blockchair.com/bitcoin-cash/transaction/{txid}"
        },
        "address_explorer_urls": {
            "DGB": "https://chainz.cryptoid.info/dgb/address.dws?{address}",
            "BTC": "https://chainz.cryptoid.info/btc/address.dws?{address}",
            "BCH": "https://blockchair.com/bitcoin-cash/address/{address}"
        },
        "refresh_intervals": {
            "pool_stats": 5,
            "miners": 10,
            "blocks": 30,
            "network": 30
        }
    },
    "sv2": {
        "authority_key_path": "/app/config/gssv2-authority.key",
        "variants": {
            "bip324": { "static_key_path": "/app/config/gssv2-static-bip324.key" }
        }
    },
    "updates": {
        "enabled": true
    },
    "coin_value": {
        "enabled": false,
        "currency": "usd"
    },
    "coins": {
        "...": "see gss-coin-config-guide.md"
    }
}
```

---

## Global Section

Top-level pool identity settings.

| Field | Default | Description |
|-----|-------|-----------|
| `pool_name` | `"GoSlimStratum Pool"` | The display name of your pool. Shown in the web dashboard and used in notifications. |
| `connection_timeout_seconds` | `600` | Default connection timeout for all coins (seconds). Can be overridden per coin in the stratum section. Applies to Stratum V1 miners; Stratum V2 connections are watched by the TCP keepalive settings below. |

### TCP Keepalive (advanced) - AS OF Version 5.1.0

GSS asks the operating system to check that every miner connection (Stratum V1 and V2) is still alive. The defaults suit almost every pool; leave them alone unless you know why you are changing them.

| Field | Default | Description |
|-----|-------|-----------|
| `tcp_keepalive_idle_seconds` | `30` | Seconds a connection may be idle before the first keepalive probe is sent. |
| `tcp_keepalive_interval_seconds` | `15` | Seconds between probes. |
| `tcp_keepalive_count` | `4` | Unanswered probes before the connection is closed. |
| `tcp_user_timeout_ms` | `0` (automatic) | Milliseconds that sent data may go unacknowledged before the connection is closed. `0` works it out from the three values above: (idle + count × interval) × 1000, which is `90000` with the defaults. Linux only. |

> **Note:** These four settings are not on the Global Config page. They can only be changed by editing `config.json`. A value of `0` means "use the default". Each can also be set per coin in that coin's `stratum` section; a coin that doesn't set one uses the global value.

---

## Logging Section

Controls how GSS writes log output — to the console, to a file, or both.

| Field | Default | Description |
|-----|-------|-----------|
| `level` | `"info"` | Log verbosity level. Controls what gets written to the log. See levels below. |
| `share_log_level` | `"info"` | Separate verbosity level specifically for share validation events. See levels below. |
| `log_to_file` | `false` | Set to `true` to write logs to a file in addition to console output. |
| `log_file_path` | `""` | Path to the log file. Required if `log_to_file` is `true`. |
| `max_size_mb` | `20` | Maximum size of the log file in megabytes before it is rotated. |
| `max_age_days` | `30` | Number of days to retain old log files before deletion. |
| `max_backups` | `10` | Maximum number of rotated log files to keep on disk. |
| `compress` | `false` | Compress rotated log files with gzip to save disk space. |

### Log Levels

| Level | What Gets Logged |
|-----|----------------|
| `debug` | Everything — connection details, job dispatches, share validation steps |
| `info` | Normal operational events — starts, stops, connections, accepted shares |
| `warn` | Recoverable issues — retries, stale shares, configuration fallbacks |
| `error` | Failures only — connection errors, invalid configs, payout failures |

### Share Log Levels

Share logging can be tuned separately since high-hashrate setups generate extremely high share volume.

| Level | What Gets Logged |
|-----|----------------|
| `debug` | Every share received, including full validation details |
| `info` | Accepted and rejected shares |
| `error` | Rejected shares only |

> **Tip:** For production pools, `level: "info"` and `share_log_level: "error"` reduces log noise significantly while still capturing important events.

---

## Metrics Section

GSS uses a PostgreSQL database to store share data, hashrate snapshots, block history, and miner statistics. This section configures that database connection and controls how data flows into it.

> **Note:** If `enabled` is set to `false`, the metrics system, HTTP API, and web dashboard will not function.

### Database Connection

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `true` | Enable the metrics system. Required for the HTTP API and web UI. |
| `database_host` | `"localhost"` | Hostname or IP address of the PostgreSQL server. |
| `database_port` | `5432` | Port the PostgreSQL server is listening on. |
| `database_name` | `"goslimstratum"` | Name of the PostgreSQL database to use. |
| `database_user` | `""` | Database user account. Must have read/write access to the database. |
| `database_password` | `""` | Password for the database user. |
| `database_ssl_mode` | `"disable"` | SSL mode for the database connection. See options below. |
| `database_max_connections` | `20` | Maximum number of open connections in the connection pool. |
| `database_connection_timeout` | `30` | Seconds to wait when acquiring a database connection before failing. |

#### SSL Mode Options

| Mode | Description |
|----|-----------|
| `disable` | No SSL. Safe for local connections. |
| `require` | Use SSL, but do not verify the certificate. |
| `verify-ca` | Verify the server certificate is signed by a trusted CA. |
| `verify-full` | Verify certificate and that the hostname matches. Recommended for remote DBs. |

### Buffering & Flushing

Shares are buffered in memory before being written to the database in batches. This reduces database write pressure on high-hashrate setups.

| Field | Default | Description |
|-----|-------|-----------|
| `batch_size` | `100` | Number of shares to accumulate before flushing to the database. |
| `flush_interval_seconds` | `10` | Maximum seconds between flushes, even if the batch isn't full. |
| `connection_flush_interval_seconds` | `2` | How many connections before they are flushed to the connections table in the database. |
| `enable_api_cache` | `true` | Enabled cache layer for API, improve performance and reduce DB load. |

> **Tip:** Lower `flush_interval_seconds` means more real-time data but more frequent DB writes. Higher values reduce load but delay dashboard updates.

### Data Retention & Cleanup

| Field | Default | Description |
|-----|-------|-----------|
| `share_retention_hours` | `48` | How many hours of share data to keep in the database. Older shares are pruned. |
| `cleanup_interval_hours` | `24` | How often (in hours) the cleanup job runs to remove expired data. |
| `network_stats_retention_days`|`7`| How many days of network stats to keep in the database. Older stats are pruned. |

**When the cleanup runs:** the interval is counted from when GoSlimStratum starts. A restart starts it again, so the first cleanup comes one full interval after the restart. If you restart more often than the interval, the scheduled cleanup never gets its turn and old rows build up.

**Run Cleanup Now (v6.0.0+):** the button at the foot of the Metrics section on the Global Config page runs the same cleanup straight away. It does not change the schedule. Use it after a restart if you restart often. If you have the `system.cleanup` notification turned on, a manual run sends it too.

From v6.0.0 the cleanup also prunes each miner's difficulty-change history, on the same window as `share_retention_hours`. Blocks, payments and earnings are never pruned.

### Snapshots & Polling

| Field | Default | Description |
|-----|-------|-----------|
| `snapshot_interval_seconds` | `60` | How often GSS writes a hashrate snapshot to the database for charting. |
| `network_poll_interval_seconds` | `60` | How often GSS polls the node for network difficulty and block height. |
| `log_interval_seconds` | `30` | How often GSS logs a pool status summary to the console/log file. |

### Hashrate Windows

| Field | Default | Description |
|-----|-------|-----------|
| `hashrate_windows` | `[60, 300, 900]` | Time windows (in seconds) used for calculating hashrate averages. These correspond to 1-minute, 5-minute, and 15-minute windows. Adjust or add windows as needed. |

### HTTP API

| Field | Default | Description |
|-----|-------|-----------|
| `enable_http_api` | `false` | Enable the HTTP REST API. Required for the web dashboard and external integrations. |
| `http_api_port` | `4004` | Port the HTTP API server listens on. |

> **Note:** The web UI's `api_base_url` must point to this address and port.

---

## Web Section

Controls the built-in web dashboard served by GSS.

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable the web dashboard. |
| `host` | `"0.0.0.0"` | IP address to bind the web server to. `"0.0.0.0"` accepts connections on all interfaces. |
| `port` | `3003` | Port the web dashboard is served on. |
| `api_base_url` | `"/api/v1"` | URL the web frontend uses to fetch data from the HTTP API. Auto-rewritten to `/api/v1` at startup — the web UI proxies API calls through port 3003 to the backend on port 4004 internally. No need to configure an external URL. |
| `animated_background` | `"hash-drift"` | The animation behind the dashboard: `"hash-drift"`, `"node-mesh"`, `"share-pulse"`, `"nonce-hunt"` or `"none"`. Applies on save, no restart. |
| `default_coin` | `""` (automatic) | **Default Pool (v5.4.1+).** The coin pool the web UI opens on: a coin's key from the `coins` section, for example `"BTCS"`. Empty means automatic: DGB if it is loaded, otherwise the first loaded pool. If the chosen pool isn't loaded, the automatic choice is used until it is. From v6.0.0, `"@hopper"` opens the Hash Hopper page while the Hash Hopper is turned on. Applies on save, no restart. |

### Block Explorer URLs

> **Note (v4.1.0+):** Block hash and height links in the Blocks and Earnings dashboards now use the built-in block explorer instead of external URLs. These settings are no longer used for block lookups. They remain in the config for backward compatibility but can be removed.

Configures external block explorer links. Use the coin ticker symbol as the key. Use `{hash}` as a placeholder for the block hash.

```json
"block_explorer_urls": {
    "DGB": "https://chainz.cryptoid.info/dgb/block.dws?{hash}",
    "BTC": "https://chainz.cryptoid.info/btc/block.dws?{hash}",
    "BCH": "https://blockchair.com/bitcoin-cash/block/{hash}"
}
```

### Transaction Explorer URLs

Links to transaction details on an external explorer. Use `{txid}` as the placeholder. Still used for pool-mode payout transactions (which are not in blocks mined by the pool).

```json
"tx_explorer_urls": {
    "DGB": "https://chainz.cryptoid.info/dgb/tx.dws?{txid}",
    "BTC": "https://chainz.cryptoid.info/btc/tx.dws?{txid}",
    "BCH": "https://blockchair.com/bitcoin-cash/transaction/{txid}"
}
```

### Address Explorer URLs

Links to address lookups on an external explorer. Use `{address}` as the placeholder. Still used — address lookups require `txindex` which most nodes don't run.

```json
"address_explorer_urls": {
    "DGB": "https://chainz.cryptoid.info/dgb/address.dws?{address}",
    "BTC": "https://chainz.cryptoid.info/btc/address.dws?{address}",
    "BCH": "https://blockchair.com/bitcoin-cash/address/{address}"
}
```

### Refresh Intervals

Controls how often the web dashboard polls the API to update each section (in seconds).

| Field | Default | Description |
|-----|-------|-----------|
| `pool_stats` | `5` | How often the pool summary stats (hashrate, miners, shares) refresh. |
| `miners` | `10` | How often the active miners list refreshes. |
| `blocks` | `30` | How often the recent blocks list refreshes. |
| `network` | `30` | How often the network difficulty and block height refreshes. |

> **Tip:** Lower refresh intervals give more real-time data but increase API load. The defaults are suitable for most setups.

---

## Coin Value Section - AS OF Version 5.5.0

Shows each coin's price, and what your pool's rewards are worth today, on the dashboard and the Earnings page. On the Global Config page this is **Show Coin Price and Value**, under Web Server Settings. It applies on save, with no restart.

```json
"coin_value": {
    "enabled": false,
    "currency": "usd"
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Turn coin price and value on. |
| `currency` | `"usd"` | The fiat currency to show, as a lowercase code (`"usd"`, `"eur"`, `"gbp"`, `"jpy"` and so on). Any currency the price source supports. |

- **Off by default.** While it is off, GSS makes no price requests at all. While it is on, GSS asks CoinGecko (`api.coingecko.com`) for prices every 15 minutes, for all built-in coins in one request.
- **Built-in coins on mainnet only.** Coins added in `coins.json`, and testnet or regtest pools, show no price. WojakCoin (WJK) has no price: the price source doesn't list it.
- **Today's price only.** GSS does not record what a coin was worth when a block was found or paid, so this is not a tax or accounting figure.
- **No price, no number.** If a price isn't available, the value and price lines don't appear. A zero or made-up price is never shown.

---

## Updates Section - AS OF Version 5.1.1

GSS checks whether a newer version has been released and shows an "update available" badge in the footer and on the Version page. It never updates itself and never sends a notification about it.

```json
"updates": {
    "enabled": true
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `true` | Turn the check on or off. Set to `false` if you want GSS to make no outbound request for it. |
| `url` | `"https://get.mmfpsolutions.io/versions/gss/latest.json"` | Where the latest version is read from. Only change this if you run a private mirror. |

The check runs when GSS starts and then about once a day. If the request fails (no internet, a firewall), nothing is shown and nothing is logged as an error.

---

## Stratum V2 Keys - AS OF Version 5.0.0

If you plan to enable Stratum V2 listeners on any coin (see the [Coin Configuration Guide](gss-coin-config-guide.md) for the per-coin `sv2` array), GSS needs two types of cryptographic key files. These are configured **once, pool-wide**, then reused across every V2 listener.

```json
"sv2": {
    "authority_key_path": "/app/config/gssv2-authority.key",
    "variants": {
        "bip324": { "static_key_path": "/app/config/gssv2-static-bip324.key" }
    }
}
```

### What These Keys Do

| Key | Purpose | Rotation Impact |
|-----|---------|-----------------|
| **Authority Keypair** | One per pool. The base58 public key is what each miner pastes into their `sv2_auth_pk` NVS field. Miners verify the server certificate during the Noise handshake using this key. | **High** — rotating means every miner needs the new pubkey pasted into NVS. |
| **Per-Variant Static Keypair** | One per supported variant (today: `bip324`). Used internally during the handshake transcript binding — never published, never pasted into miners. | **Low** — rotating only requires a GSS restart; miners don't need updates. |

### Fields

| Field | Description |
|-----|-----------|
| `authority_key_path` | Filesystem path to the authority private key file. The corresponding base58 public key is what miners paste into the `sv2_auth_pk` NVS field. One authority key per pool — shared across every coin. |
| `variants.<variant>.static_key_path` | Filesystem path to the per-variant static private key file. Used during the Noise handshake. Today only `bip324` is supported. |

> **Default paths:** Both fields default to `/app/config/` when not explicitly set (so they sit alongside `config.json` in the Docker container's config volume). Existing pre-5.0.0 configs that don't have an `sv2` block at all will pick up these defaults automatically — no hand-editing required.

### Generating the Keys

The recommended (and easiest) way to generate keys is the **Stratum V2 Keys** section at the bottom of the **Global Configuration** page in the Web UI. Two cards appear, one per key type, each with a "Generate" button. Clicking Generate writes the private key to disk owner-read-only (Unix mode `0600`) and immediately displays the resulting authority public key for copy-paste into your miner's NVS.

For a step-by-step walkthrough including screenshots, see the [v5.0.0 Stratum V2 Setup Guide](../../release%20notes/GoSlimStratum/v5.0.0-Stratum-V2-Setup-Guide.md).

> **Headless setups:** A `gssv2-keygen` CLI is also included in the GSS distribution for operators who can't use the Web UI. Run it once on the host with the same paths configured.

### Regeneration Warnings

- **Regenerating the authority keypair is destructive.** Every miner currently configured with the OLD pubkey will fail handshake against the new one until you paste the new pubkey into each miner's NVS. The Web UI gates this behind a typed-confirmation modal — you must type `GENERATE` to proceed.
- **Regenerating a static key is mild.** GSS's cert refresh goroutine re-signs the server certificate every `cert_valid_hours / 2` (per the per-coin `sv2[].cert_valid_hours` field, default 24 hours) using whatever static key is loaded at restart. No miner NVS update is required. Already-connected miners stay connected until they disconnect for unrelated reasons.
- **Restart required.** A freshly generated or regenerated key file is not picked up by running listeners — they hold the old key in memory. Restart GSS to load the new key.

### Behavior

- The `sv2` block only matters if at least one coin has an `enabled: true` V2 listener entry. If no coin uses V2, the block is parsed but unused.
- Key file validation happens at startup: if any enabled V2 listener references a missing or unreadable key file, GSS refuses to start with a clear error message pointing at the offending path.
- Authority key is shared across every coin's V2 listeners — miners only configure one `sv2_auth_pk` value regardless of which coin pool they're connected to.

---

## Notifications Configuration (`notifications.json`)

> [!IMPORTANT]
> Notifications is a licensed feature for GoSlimStratum

Notifications are configured in a separate file, `notifications.json`. This file controls alerts for pool events sent via email, Telegram, Discord webhooks, or any generic HTTP webhook.

> **Note:** The notifications system is optional. If `notifications.json` is not present, no notifications are sent.

### Example Notifications Configuration

```json
{
    "enabled": true,
    "channels": {
        "email": {
            "enabled": false,
            "from_address": "pool@example.com",
            "to_addresses": ["admin@example.com"],
            "smtp_server": "smtp.gmail.com",
            "smtp_port": 587,
            "username": "your_smtp_user",
            "password": "your_smtp_password",
            "use_tls": true
        },
        "telegram": {
            "enabled": false,
            "bot_token": "your_bot_token",
            "chat_id": "your_chat_id",
            "message_prefix": "[GSS] ",
            "parse_mode": "HTML",
            "bot": {
                "enabled": false,
                "poll_timeout_seconds": 30,
                "rate_limit": {
                    "commands_per_minute": 10,
                    "burst_size": 3
                }
            }
        },
        "webhooks": {
            "discord": {
                "enabled": false,
                "type": "discord",
                "url": "https://discord.com/api/webhooks/...",
                "username": "GSS Pool Bot",
                "avatar_url": ""
            }
        }
    },
    "rate_limiting": {
        "miner_events": {
            "enabled": true,
            "batch_window_seconds": 60,
            "max_per_batch": 10
        }
    },
    "events": {
        "blocks": { "enabled": true, "channels": ["telegram", "discord"] },
        "payouts": { "enabled": true, "channels": ["telegram"] },
        "nodes": { "enabled": true, "channels": ["telegram"] },
        "miners": { "enabled": false, "channels": [] },
        "best_share": { "enabled": true, "channels": ["telegram"] },
        "notable_share": { "enabled": false, "channels": [] },
        "rejected_shares": { "enabled": true, "channels": ["telegram"] },
        "network_difficulty": { "enabled": false, "channels": [] },
        "system": {
            "startup": { "enabled": true, "channels": ["telegram"] },
            "shutdown": { "enabled": true, "channels": ["telegram"] },
            "cleanup": { "enabled": false, "channels": [] }
        }
    },
    "coins": {
        "DGB": { "enabled": true },
        "BTC": { "enabled": true }
    }
}
```

---

### Top-Level

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `true` | Master switch for the entire notifications system. Set to `false` to silence all alerts. |

---

### Channels — Email

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable email notifications. |
| `from_address` | `""` | The sender email address. |
| `to_addresses` | `[]` | List of recipient email addresses. |
| `smtp_server` | `""` | SMTP server hostname (e.g., `smtp.gmail.com`). |
| `smtp_port` | `587` | SMTP server port. Common values: `587` (STARTTLS), `465` (SSL), `25` (plain). |
| `username` | `""` | SMTP authentication username. |
| `password` | `""` | SMTP authentication password. |
| `use_tls` | `true` | Use TLS/STARTTLS for the SMTP connection. Recommended for public mail servers. |

---

### Channels — Telegram

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable Telegram notifications. |
| `bot_token` | `""` | Your Telegram bot token from @BotFather. |
| `chat_id` | `""` | The Telegram chat, group, or channel ID to send messages to. |
| `message_prefix` | `"[GSS] "` | Text prepended to all notification messages. |
| `parse_mode` | `"HTML"` | Message formatting mode: `HTML` or `Markdown`. |

#### Telegram Bot (Bidirectional Commands)

The bot can also accept commands from Telegram users, allowing you to query pool status interactively.

| Field | Default | Description |
|-----|-------|-----------|
| `bot.enabled` | `false` | Enable command listening on the Telegram bot. |
| `bot.poll_timeout_seconds` | `30` | Long-poll timeout when checking for new commands. |
| `bot.rate_limit.commands_per_minute` | `10` | Max commands accepted per minute per user. |
| `bot.rate_limit.burst_size` | `3` | Burst allowance above the rate limit. |

---

### Channels — Webhooks

Webhooks are defined as a named map, so you can configure multiple. Each webhook supports the following fields:

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable this webhook. |
| `type` | `""` | Webhook type: `"discord"` for Discord-formatted payloads, `"generic"` for a plain JSON POST. |
| `url` | `""` | The full webhook URL endpoint. |
| `message_prefix` | `""` | Optional prefix prepended to messages. |
| `method` | `"POST"` | HTTP method to use. |
| `headers` | `{}` | Custom HTTP headers to include (e.g., for auth tokens). |
| `timeout_seconds` | `10` | Request timeout in seconds. |
| `username` | `""` | *(Discord only)* Override the bot display name in Discord. |
| `avatar_url` | `""` | *(Discord only)* Override the bot avatar in Discord. |

---

### Rate Limiting

Prevents notification floods for high-frequency events (e.g., many miners connecting and disconnecting rapidly).

| Field | Default | Description |
|-----|-------|-----------|
| `miner_events.enabled` | `true` | Enable rate limiting for miner connection/disconnection events. |
| `miner_events.batch_window_seconds` | `60` | Time window in seconds over which events are batched and counted. |
| `miner_events.max_per_batch` | `10` | Maximum number of miner event notifications sent per batch window. |

---

### Events

Controls which pool events trigger notifications and which channels receive them. Channel names must match keys defined in the `channels` section.

| Event | Description |
|-----|-----------|
| `blocks` | A block was found by the pool. |
| `payouts` | A payment was sent to a miner. |
| `nodes` | A node connection status change (connected, disconnected, error). |
| `miners` | A miner connected or disconnected. High frequency — rate limiting recommended. From v6.0.0 this includes rigs on the Hash Hopper port, listed under the hopper's symbol; a move from one chain to another sends neither message. |
| `best_share` | *(Coin Alerts, v5.1.0+)* A miner set a new pool-best share above the coin's floor. |
| `notable_share` | *(Coin Alerts, v5.1.0+)* A miner submitted a share above the coin's notable floor. |
| `rejected_shares` | *(Coin Alerts, v5.1.0+)* A miner crossed the coin's rejected-share threshold. |
| `network_difficulty` | *(Coin Alerts, v5.1.0+)* A coin's network difficulty crossed a threshold you set, or came back inside it. |
| `system.startup` | GSS pool started successfully. |
| `system.shutdown` | GSS pool is shutting down. |
| `system.cleanup` | A database cleanup task ran. |

Each event takes:
- `enabled` — `true` or `false`
- `channels` — list of channel names to notify (e.g., `["telegram", "discord"]`)

The `blocks` event covers a block found and, from v5.2.8, a block that was later orphaned (**Block ORPHANED**). Orphan checks run for coins with payouts enabled.

The four Coin Alerts events only say where an alert is sent. What triggers each one (the floors and thresholds) is set per coin: see the Alerts section of the [Coin Configuration Guide](gss-coin-config-guide.md). The easiest way to set events and channels is the **Notifications** page in the web UI, which applies changes without a restart.

---

### Per-Coin Notifications

You can enable or disable notifications for specific coins.

```json
"coins": {
    "DGB": { "enabled": true },
    "BTC": { "enabled": false }
}
```

Setting a coin to `false` suppresses all notifications for that coin regardless of event settings.

---

## Configuration Validation

GSS validates the configuration on startup and will fail to start if any of the following are true:

- No coins are configured
- No coins are enabled
- Two or more coins share the same stratum port
- `pool_fee_percent` is outside 0–100%
- A required field (e.g., mining `address`) is missing for an enabled coin

Check the startup logs carefully if GSS fails to start — validation errors are logged with specific field names.
