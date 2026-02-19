# GSS Miners (GSSM) Notifications Guide

Complete reference for the `notifications.json` configuration file used by GSS Miners.

---

## Summary

GSS Miners supports proactive alerting for mining device events, pool status changes, node outages, and system lifecycle events. Notifications are sent through one or more channels: email, Telegram, Discord webhooks, or any generic HTTP webhook.

Notifications are configured in a separate file, `notifications.json`, which lives alongside `config.json` in the GSSM config directory. If the file does not exist, no notifications are sent.

> **Note:** Notification settings can be edited through the GSSM WebUI. Sensitive values (passwords, tokens, API keys) are masked when viewed through the UI but stored in plaintext in `notifications.json` — secure access to this file accordingly.

---

## Example Configuration

```json
{
    "enabled": false,
    "channels": {
        "email": {
            "enabled": false,
            "smtp_server": "smtp.gmail.com",
            "smtp_port": 587,
            "username": "",
            "password": "",
            "use_tls": true,
            "from_address": "alerts@example.com",
            "to_addresses": ["admin@example.com"]
        },
        "telegram": {
            "enabled": false,
            "bot_token": "[TELEGRAM_BOT_TOKEN]",
            "chat_id": "[YOUR_CHAT_ID]",
            "message_prefix": "[GSS Miners] ",
            "parse_mode": "HTML"
        },
        "webhooks": {
            "discord-alerts": {
                "enabled": false,
                "type": "discord",
                "url": "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
                "message_prefix": "[GSS Miners] ",
                "username": "GSS Miners",
                "avatar_url": ""
            },
            "custom-webhook": {
                "enabled": false,
                "type": "generic",
                "url": "https://api.example.com/webhook",
                "message_prefix": "[GSS Miners] ",
                "method": "POST",
                "headers": {
                    "Authorization": "Bearer YOUR_TOKEN"
                },
                "timeout_seconds": 10
            }
        }
    },
    "polling": {
        "miner_check_interval_seconds": 120,
        "pool_check_interval_seconds": 120,
        "node_check_interval_seconds": 120
    },
    "exclusions": {
        "miners": [],
        "pools": [],
        "nodes": []
    },
    "events": {
        "miners": {
            "enabled": false,
            "channels": ["telegram"],
            "failover": true,
            "offline": true,
            "online": true,
            "zero_hashrate": true,
            "temp_high": true
        },
        "pools": {
            "enabled": false,
            "channels": ["telegram"],
            "offline": true,
            "online": true
        },
        "nodes": {
            "enabled": false,
            "channels": ["telegram"],
            "offline": true,
            "online": true
        },
        "system": {
            "startup": {
                "enabled": false,
                "channels": ["telegram"]
            },
            "shutdown": {
                "enabled": false,
                "channels": ["telegram"]
            }
        }
    },
    "rate_limiting": {
        "miner_events": {
            "enabled": false,
            "batch_window_seconds": 60,
            "max_per_batch": 10
        }
    }
}
```

---

## Top-Level

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Master switch for all notifications. Set to `true` to activate. Individual channels and events must also be enabled. |

---

## Channels

Channels define *how* notifications are delivered. You must configure and enable at least one channel for notifications to be sent.

---

### Email

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable email notifications. |
| `smtp_server` | `""` | SMTP server hostname (e.g., `smtp.gmail.com`). |
| `smtp_port` | `587` | SMTP port. Common values: `587` (STARTTLS), `465` (SSL), `25` (plain). |
| `username` | `""` | SMTP login username. |
| `password` | `""` | SMTP login password. Masked in the UI. |
| `use_tls` | `true` | Use TLS/STARTTLS when connecting to the SMTP server. Recommended for all public email providers. |
| `from_address` | `""` | The sender email address that appears in the "From" field. |
| `to_addresses` | `[]` | List of recipient email addresses. All recipients receive all alert emails. |

---

### Telegram

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable Telegram notifications. |
| `bot_token` | `""` | Your Telegram bot token. Obtain from [@BotFather](https://t.me/BotFather). Masked in the UI. |
| `chat_id` | `""` | The Telegram chat, group, or channel ID to send messages to. The bot must be a member of the target chat. |
| `message_prefix` | `"[GSS Miners] "` | Text prepended to every notification message. Useful for identifying the source when multiple bots post to the same chat. |
| `parse_mode` | `"HTML"` | Message formatting: `"HTML"` or `"Markdown"`. Controls how bold, links, and code formatting are rendered in Telegram. |

> **Tip:** To find your `chat_id`, add your bot to the chat, send a message, then call `https://api.telegram.org/bot<token>/getUpdates` and look for the `chat.id` field in the response.

---

### Webhooks

Webhooks are defined as a named map — you can have as many as you need. Each key is the name you reference in event `channels` lists.

Two webhook types are supported:

#### Discord Webhook

```json
"discord-alerts": {
    "enabled": false,
    "type": "discord",
    "url": "https://discord.com/api/webhooks/...",
    "message_prefix": "[GSS Miners] ",
    "username": "GSS Miners",
    "avatar_url": ""
}
```

| Field | Description |
|-----|-----------|
| `enabled` | Enable this webhook. |
| `type` | Must be `"discord"`. Sends a Discord-formatted embed payload. |
| `url` | The full Discord webhook URL. Created in Discord Server Settings → Integrations → Webhooks. |
| `message_prefix` | Optional text prepended to messages. |
| `username` | Overrides the bot's display name in Discord. Leave blank to use the webhook's default. |
| `avatar_url` | Overrides the bot's avatar in Discord. Leave blank to use the webhook's default. |

#### Generic HTTP Webhook

```json
"custom-webhook": {
    "enabled": false,
    "type": "generic",
    "url": "https://api.example.com/webhook",
    "message_prefix": "[GSS Miners] ",
    "method": "POST",
    "headers": {
        "Authorization": "Bearer YOUR_TOKEN"
    },
    "timeout_seconds": 10
}
```

| Field | Description |
|-----|-----------|
| `enabled` | Enable this webhook. |
| `type` | Must be `"generic"`. Sends a plain JSON POST body. |
| `url` | The endpoint URL to POST the notification to. |
| `message_prefix` | Optional text prepended to messages. |
| `method` | HTTP method to use. Defaults to `"POST"`. |
| `headers` | Map of custom HTTP headers (e.g., auth tokens, content type). Authorization header values are masked in the UI. |
| `timeout_seconds` | Request timeout in seconds. Requests that exceed this are aborted. |

---

## Polling

The notifications system runs its own background checks independently from the dashboard UI polling. These intervals control how often GSSM actively checks each resource type for alert conditions.

```json
"polling": {
    "miner_check_interval_seconds": 120,
    "pool_check_interval_seconds": 120,
    "node_check_interval_seconds": 120
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `miner_check_interval_seconds` | `120` | How often (in seconds) GSSM polls miners to detect alert conditions. |
| `pool_check_interval_seconds` | `120` | How often GSSM polls GoSlimStratum pools for status changes. |
| `node_check_interval_seconds` | `120` | How often GSSM polls blockchain nodes for status changes. |

> **Note:** These intervals are separate from the `refresh_intervals` in `config.json`. Dashboard UI polling and notification polling are independent. Setting these lower increases alert responsiveness but also increases network traffic to your devices.

---

## Exclusions

Suppresses all notifications for specific miners, pools, or nodes by their ID. Useful for known-offline devices, test equipment, or devices undergoing maintenance.

```json
"exclusions": {
    "miners": ["mXk9pQ2r", "jW5vT9yC"],
    "pools": [],
    "nodes": []
}
```

| Field | Description |
|-----|-----------|
| `miners` | List of miner IDs to exclude from all alerts. IDs are found in `config.json` or the GSSM device list. |
| `pools` | List of pool IDs to exclude from all alerts. |
| `nodes` | List of node IDs to exclude from all alerts. |

> **Tip:** To temporarily silence alerts for a device without removing it from your config, add its ID to the appropriate exclusions list.

---

## Events

Events define *what* triggers a notification and *which channels* receive it. Each event section can be independently enabled or disabled, and directed to any combination of configured channels.

Channel names in the `channels` list must exactly match keys defined in the `channels` section (e.g., `"telegram"`, `"discord-alerts"`, `"email"`).

---

### Miner Events

Alerts for individual mining device state changes.

```json
"miners": {
    "enabled": false,
    "channels": ["telegram"],
    "failover": true,
    "offline": true,
    "online": true,
    "zero_hashrate": true,
    "temp_high": true,
    "temp_normal": true
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable miner event notifications. |
| `channels` | `[]` | Which channels to notify. Must match channel keys. |
| `offline` | `true` | Alert when a miner stops responding to polls. |
| `online` | `true` | Alert when a previously offline miner comes back online. |
| `zero_hashrate` | `true` | Alert when a miner is reachable but reporting 0 hashrate. Indicates a mining issue without a full outage. |
| `temp_high` | `true` | Alert when a miner's temperature exceeds the critical threshold defined in `thresholds`. |
|  `temp_normal` | `true` | Alert when a miner's temperature falls below the critical threshold defined in `thresholds`. |
| `failover` | `true` | Alert when a miner switches to a backup/failover pool. |

> **Note:** Miner events can be noisy on fleets with many devices or unstable network connections. Use `rate_limiting` (below) to prevent alert floods.

---

### Pool Events

Alerts for GoSlimStratum pool availability. Requires `goslimstratumPoolsEnabled: true` in `config.json`.

```json
"pools": {
    "enabled": false,
    "channels": ["telegram"],
    "offline": true,
    "online": true
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable pool event notifications. |
| `channels` | `[]` | Which channels to notify. |
| `offline` | `true` | Alert when a pool's API becomes unreachable. |
| `online` | `true` | Alert when a previously unreachable pool comes back online. |

---

### Node Events

Alerts for blockchain node availability. Requires `cryptNodesEnabled: true` in `config.json`.

```json
"nodes": {
    "enabled": false,
    "channels": ["telegram"],
    "offline": true,
    "online": true
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable node event notifications. |
| `channels` | `[]` | Which channels to notify. |
| `offline` | `true` | Alert when a blockchain node's RPC becomes unreachable. |
| `online` | `true` | Alert when a previously unreachable node comes back online. |

---

### System Events

Alerts for GSSM application lifecycle events.

```json
"system": {
    "startup": {
        "enabled": false,
        "channels": ["telegram"]
    },
    "shutdown": {
        "enabled": false,
        "channels": ["telegram"]
    }
}
```

| Event | Description |
|-----|-----------|
| `startup` | Sent when the GSSM application starts successfully. Useful for confirming a restart completed. |
| `shutdown` | Sent when GSSM is shutting down gracefully. |

Each takes:
- `enabled` — `true` or `false`
- `channels` — list of channel names to notify

---

## Rate Limiting

Prevents notification floods when many miner events fire in a short window (e.g., a network switch reboot causes all miners to briefly appear offline).

```json
"rate_limiting": {
    "miner_events": {
        "enabled": false,
        "batch_window_seconds": 60,
        "max_per_batch": 10
    }
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `miner_events.enabled` | `false` | Enable rate limiting for miner events. |
| `miner_events.batch_window_seconds` | `60` | Time window in seconds. Events within this window are counted together. |
| `miner_events.max_per_batch` | `10` | Maximum number of miner event notifications sent within one batch window. Events beyond this limit are suppressed until the next window. |

> **Example:** With `batch_window_seconds: 60` and `max_per_batch: 10`, if 50 miners go offline at once, only 10 notifications are sent in the first 60 seconds, preventing an alert flood.

> **Tip:** For large fleets, enable rate limiting with a generous `batch_window_seconds` and keep `max_per_batch` low. For small setups (under 10 miners), rate limiting may not be necessary.
