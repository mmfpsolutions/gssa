# GSS Miners (GSSM) Notifications Guide

Complete reference for the `notifications.json` configuration file used by GSS Miners.

*Current for GSS Miners 5.1.0.*

See also the [Configuration Guide](gssm-config-guide.md), the [Miner Control Guide](gssm-miner-control-guide.md) and the [Troubleshooting Guide](gssm-troubleshooting-guide.md).

---

## Summary

GSS Miners can alert you when a miner, a pool or a node changes state, when a schedule or a trigger acts, and when GSSM itself starts or stops. Alerts go out through one or more channels: email, Telegram, Discord webhooks or any HTTP webhook. With Historicals on, they can also be recorded in a searchable alert history.

Notifications need a **Pro or Enterprise** license. Tiers and prices: https://www.mmfpsolutions.io/pricing.html

Notifications are set on the **Notifications** page in the web UI, which writes `notifications.json` next to `config.json` in the GSSM config folder. If the file does not exist, no notifications are sent. A change saved from the page applies straight away.

Three switches must all be on before an alert is sent: the master `enabled`, the channel's own `enabled`, and the event group's `enabled` with that channel in its `channels` list.

> **Secrets are encrypted on disk (v1.1.0+).** The email password, the Telegram bot token and every webhook URL are stored encrypted in `notifications.json` and shown masked in the web UI. A plain value typed into the file by hand is encrypted the next time GSSM starts.

> **The `polling` section is used even when notifications are off.** It sets the pace of GSSM's background checks, which Historicals, Schedules, Triggers and Auto Fan Control also run on. See [Polling](#polling).

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
        "miner_check_interval_seconds": 60,
        "pool_check_interval_seconds": 120,
        "node_check_interval_seconds": 120,
        "fan_control_interval_seconds": 30,
        "schedule_interval_seconds": 60
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
            "temp_high": true,
            "temp_normal": true,
            "schedule": true,
            "triggers": true
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
| `message_prefix` | `"[GSS Miners]"` | Text prepended to every notification message. Useful for identifying the source when multiple bots post to the same chat. |
| `parse_mode` | `"HTML"` | Message formatting: `"HTML"` or `"Markdown"`. Controls how bold, links, and code formatting are rendered in Telegram. |
| `bot` | off | Lets the bot answer commands. See below. |

> **Tip:** To find your `chat_id`, add your bot to the chat, send a message, then call `https://api.telegram.org/bot<token>/getUpdates` and look for the `chat.id` field in the response.

**Send Test Message** on the Notifications page sends a sample so you can confirm it arrives. Email has **Send Test Email**, and each webhook has **Test Webhook**.

#### Telegram bot commands

With `bot.enabled` (**Enable Bot Commands** on the page), the same bot answers questions in the chat. It only answers the chat named in `chat_id`.

| Command | Answer |
|---|---|
| `/help` | The list of commands |
| `/status` | How many miners, pools and nodes are online and offline |
| `/miners` | Every miner with its hashrate and best share |
| `/miner <name>` | One miner in detail: hashrate, best share, shares, pool, temperature |
| `/pools` | Every GoSlimStratum pool with its hashrate and miner count |
| `/nodes` | Every node with its coin, network difficulty, block height and peers |
| `/system` | GSSM's version, uptime and memory use |

| `bot` field | Default | Description |
|---|---|---|
| `enabled` | `false` | Answer commands. |
| `poll_timeout_seconds` | `30` | How long each wait for new commands lasts. Leave it alone. |
| `rate_limit.commands_per_minute` | `10` | The most commands answered in a minute. |
| `rate_limit.burst_size` | `3` | How many commands can be answered back to back. |

The answers come from GSSM's background checks, so a miner the checks skip (disabled, or on the exclusion list) has nothing to report.

---

### Webhooks

Webhooks are defined as a named map — you can have as many as you need. Each key is the webhook's name. In an event's `channels` list a webhook is written as `webhook:<name>` (for example `"webhook:discord-alerts"`), which is what the web UI saves. The name alone also works.

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
| `type` | Must be `"generic"`. Sends a JSON body with these fields: `event_type`, `entity` (the miner, pool or node), `message`, `severity` (`info`, `warning` or `critical`), `category`, `details` and `timestamp`. |
| `url` | The endpoint URL to POST the notification to. |
| `message_prefix` | Optional text prepended to messages. |
| `method` | HTTP method to use. Defaults to `"POST"`. |
| `headers` | Map of custom HTTP headers (e.g., auth tokens, content type). Authorization header values are masked in the UI. |
| `timeout_seconds` | Request timeout in seconds. Requests that exceed this are aborted. |

---

## Polling

GSSM checks your miners, pools and nodes in the background, whether or not anyone has the dashboard open. These settings set how often.

```json
"polling": {
    "miner_check_interval_seconds": 60,
    "pool_check_interval_seconds": 120,
    "node_check_interval_seconds": 120,
    "fan_control_interval_seconds": 30,
    "schedule_interval_seconds": 60
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `miner_check_interval_seconds` | `60` | Seconds between checks of every miner. The Notifications page asks for at least 30. |
| `pool_check_interval_seconds` | `120` | Seconds between checks of every GoSlimStratum pool. At least 30. |
| `node_check_interval_seconds` | `120` | Seconds between checks of every node. At least 30. |
| `fan_control_interval_seconds` | `30` | How often Auto Fan Control adjusts a fan. Not shown on the page: edit the file. |
| `schedule_interval_seconds` | `60` | How often the scheduler looks for a window edge. Window times are in whole minutes, so leave it at 60. Not shown on the page. |

What runs on the miner check:

- **Miner alerts.**
- **Historicals:** each check is one stored reading for each miner.
- **Energy tracking.**
- **Triggers:** the miner check interval is the fastest a rule can react.

So a shorter miner check interval means quicker alerts and triggers, and more requests to your miners.

> **Note:** These are separate from `refresh_intervals` in `config.json`, which only control how often an open dashboard page re-reads your devices.

> **These checks run with notifications off too.** With `enabled: false` no alerts are sent, but Historicals, Schedules, Triggers and Auto Fan Control still run, at the pace set here.

---

## Exclusions

Silences all alerts for particular miners, pools or nodes. On the Notifications page, tick the ones to exclude.

```json
"exclusions": {
    "miners": ["garage-bitaxe", "bench-unit"],
    "pools": [],
    "nodes": []
}
```

| Field | Description |
|-----|-----------|
| `miners` | Miner **names** to exclude, exactly as in `config.json` (`miners[].name`). |
| `pools` | GoSlimStratum pool names to exclude (`goslimstratumPools[].name`). |
| `nodes` | Node names to exclude (`cryptoNodes[].nodeName`). |

Exclusions go by **name**, not by ID. If you rename a miner, pool or node, tick it again.

> **Excluding a miner does more than silence it.** GSSM's background check skips an excluded miner entirely. That also stops its **Historicals** readings, its **energy tracking** and its **triggers**. Its schedule and Auto Fan Control keep running, and it still shows on the dashboard. To silence one kind of alert for every miner, turn that event off under Events.

To pause a miner altogether (no checks, no alerts, no schedule, no triggers), disable it; see `disabled` in the [Configuration Guide](gssm-config-guide.md).

---

## Events

Events define *what* triggers a notification and *which channels* receive it. Each event section can be independently enabled or disabled, and directed to any combination of configured channels.

Names in a `channels` list:

| Name | Sends to |
|---|---|
| `"email"` | The email channel |
| `"telegram"` | The Telegram channel |
| `"webhook:<name>"` | The webhook with that name (the name alone also works) |
| `"historicals"` | The alert history in the Historicals database (v3.0.0+). Offered when Historicals is licensed; it does nothing while the database is not connected. |

### How alerts behave

- **The first check after GSSM starts sends nothing.** GSSM learns the state of everything first, then alerts on changes.
- **An offline alert waits for two missed checks in a row (v3.0.1+).** One slow answer from a miner is ignored. A real outage is reported one check interval later than it happened.
- **A miner idled on purpose does not alert (v3.0.6+).** While a miner reports itself in standby or sleep, its Zero Hashrate and Offline alerts are held back, however it was idled.
- **Every alert has a severity:** critical, warning or info. Generic webhooks receive it as `severity`.
- **The Details lines in a message are in alphabetical order**, the same every time.

---

### Miner Events

Alerts for individual miners.

```json
"miners": {
    "enabled": false,
    "channels": ["telegram"],
    "failover": true,
    "offline": true,
    "online": true,
    "zero_hashrate": true,
    "temp_high": true,
    "temp_normal": true,
    "schedule": true,
    "triggers": true
}
```

| Field | On the page | Default | Severity | Description |
|-----|-----|-------|-----|-----------|
| `enabled` | Enable Miner Notifications | `false` | | Turns miner alerts on. |
| `channels` | Send to Channels | `[]` | | Where miner alerts go. |
| `offline` | Offline | `true` | critical | A miner missed two checks in a row. |
| `online` | Online (recovery) | `true` | info | A miner that was offline answers again. |
| `failover` | Pool Failover | `true` | warning | A miner moved to its backup pool, or back to its primary. |
| `zero_hashrate` | Zero Hashrate | `true` | warning | A miner is reachable but hashing at 0, and has not reported itself idled. |
| `temp_high` | High Temperature | `true` | critical | A miner's temperature reached the `critical` threshold for its device family. Also covers the Auto Fan Control emergency alert and its all-clear. |
| `temp_normal` | Temp Recovered | `true` | info | The temperature dropped back below `critical`. |
| `schedule` | Schedule Applied | `true` | info, or warning when it fails | A schedule changed a miner, or could not (one message when it starts failing). (v3.0.6+) |
| `triggers` | Trigger Fired | `true` | critical for a protective rule, info for a routine restart, warning when a rule is parked | A trigger rule fired, or was parked after firing five times in 24 hours. (v3.0.8+) |

> **Note:** Miner events can be noisy on fleets with many devices or unstable network connections. To cut the noise, turn off the event types you do not need, or lengthen the miner check interval.

---

### Pool Events

Alerts for GoSlimStratum pools, including a Hash Hopper entry (v5.1.0+). Requires `goslimstratumPoolsEnabled: true` in `config.json`. Litecoinpool pools send no alerts.

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
| `offline` | `true` | Critical. The pool cannot be reached, or the coin is no longer on that GoSlimStratum. For a Hash Hopper: it is turned off, or its port is closed. A pool with no miners on it is still online. |
| `online` | `true` | Info. A pool that was offline is back. |

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
| `offline` | `true` | Critical. The node's RPC cannot be reached. |
| `online` | `true` | Info. A node that was offline is back. |

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
| `startup` | Info. Sent when GSSM starts. Useful for confirming a restart completed. |
| `shutdown` | Critical. Sent when GSSM is shutting down normally. A crash or a power cut sends nothing. |

Each takes:
- `enabled` — `true` or `false`
- `channels` — list of channel names to notify

---

## Rate Limiting

> **As of v5.1.0 these settings are saved but not applied.** The Notifications page stores them, and every miner alert is still sent. They are documented here so the file can be read.

Intended to prevent notification floods when many miner events fire in a short window (e.g., a network switch reboot causes all miners to briefly appear offline).

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
| `miner_events.max_per_batch` | `10` | Maximum number of miner event notifications in one batch window. |
