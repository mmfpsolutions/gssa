# GoSlimStratum Global Configuration Guide

Complete reference for the global configuration settings in GoSlimStratum (GSS).

---

## Summary
> **Note:** Most of these settings can be changed in the WebUI.

GoSlimStratum uses two configuration files:

- **`config.json`** — The main configuration file. Contains global settings that apply to the entire pool (logging, metrics, web UI) as well as all per-coin configurations.
- **`notifications.json`** — Optional. Controls alert notifications via email, Telegram, Discord, or custom webhooks.

This guide covers the global sections of `config.json` and the full `notifications.json`. For per-coin configuration settings, see the [Coin Configuration Guide](coin-config-guide.md).

> **Note:** Configuration changes require a restart of GoSlimStratum to take effect. It is recommended to use the WebUI for edits where possible.

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
        "cleanup_interval_hours": 24,
        "hashrate_windows": [60, 300, 900],
        "log_interval_seconds": 30,
        "enable_http_api": true,
        "http_api_port": 4004
    },
    "web": {
        "enabled": true,
        "host": "0.0.0.0",
        "port": 3003,
        "api_base_url": "http://your.ip.address:4004/api/v1",
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
    "coins": {
        "...": "see coin-config-guide.md"
    }
}
```

---

## Global Section

Top-level pool identity settings.

| Field | Default | Description |
|-----|-------|-----------|
| `pool_name` | `"GoSlimStratum Pool"` | The display name of your pool. Shown in the web dashboard and used in notifications. |

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

> **Tip:** Lower `flush_interval_seconds` means more real-time data but more frequent DB writes. Higher values reduce load but delay dashboard updates.

### Data Retention & Cleanup

| Field | Default | Description |
|-----|-------|-----------|
| `share_retention_hours` | `48` | How many hours of share data to keep in the database. Older shares are pruned. |
| `cleanup_interval_hours` | `24` | How often (in hours) the cleanup job runs to remove expired data. |

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
| `api_base_url` | `"http://localhost:4004/api/v1"` | URL the web frontend uses to fetch data from the HTTP API. Must be reachable from the browser — use your server's public IP or hostname, not `localhost`, if accessing remotely. |

### Block Explorer URLs

Configures external block explorer links in the dashboard. Use the coin ticker symbol as the key. Use `{hash}` as a placeholder for the block hash.

```json
"block_explorer_urls": {
    "DGB": "https://chainz.cryptoid.info/dgb/block.dws?{hash}",
    "BTC": "https://chainz.cryptoid.info/btc/block.dws?{hash}",
    "BCH": "https://blockchair.com/bitcoin-cash/block/{hash}"
}
```

### Transaction Explorer URLs

Links to transaction details on an external explorer. Use `{txid}` as the placeholder.

```json
"tx_explorer_urls": {
    "DGB": "https://chainz.cryptoid.info/dgb/tx.dws?{txid}",
    "BTC": "https://chainz.cryptoid.info/btc/tx.dws?{txid}",
    "BCH": "https://blockchair.com/bitcoin-cash/transaction/{txid}"
}
```

### Address Explorer URLs

Links to address lookups on an external explorer. Use `{address}` as the placeholder.

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
| `miners` | A miner connected or disconnected. High frequency — rate limiting recommended. |
| `system.startup` | GSS pool started successfully. |
| `system.shutdown` | GSS pool is shutting down. |
| `system.cleanup` | A database cleanup task ran. |

Each event takes:
- `enabled` — `true` or `false`
- `channels` — list of channel names to notify (e.g., `["telegram", "discord"]`)

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
