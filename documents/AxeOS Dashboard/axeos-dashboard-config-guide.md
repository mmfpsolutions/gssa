# AxeOS Dashboard Configuration Guide

Complete reference for all configuration files used by AxeOS Dashboard.

> [!TIP]
> Configuration can be done via the Web UI for most settings.


---

## Summary

AxeOS Dashboard uses multiple configuration files stored in the `config/` directory. Together they control which mining devices and pools are monitored, how authentication works, and how notifications are delivered.

| File | Purpose | Required |
|----|-------|--------|
| `config.json` | Main application configuration — devices, pools, nodes, UI settings | Yes |
| `access.json` | Admin login credentials (hashed password) | Yes |
| `jsonWebTokenKey.json` | JWT session token configuration | Yes |
| `rpcConfig.json` | Blockchain node RPC credentials | Only if nodes enabled |
| `notifications.json` | Alert notification channels and events | Auto-generated if missing |

> **Note:** If `config.json`, `access.json`, or `jsonWebTokenKey.json` are missing, the dashboard enters first-time setup mode. Notifications config is auto-generated with defaults if absent.

---

## config.json

The main configuration file. Controls device lists, pool integrations, UI behavior, and session settings.

### Example

```json
{
    "axeos_dashboard_version": 3,
    "web_server_port": 3000,
    "title": "AxeOS Dashboard",
    "disable_authentication": false,
    "disable_settings": false,
    "disable_configurations": false,
    "cookie_max_age": 3600,
    "axeos_instances": [
        { "AxeOS1": "http://192.168.1.100" },
        { "NerdQAxe1": "http://192.168.1.102" }
    ],
    "cgminer_instances": [
        { "AntminerS9": "192.168.1.101:4028" }
    ],
    "avalonq_instances": [
        { "AvalonQ-1": "192.168.1.103:4028" }
    ],
    "mining_core_enabled": false,
    "mining_core_url": [{}],
    "goslimstratum_enabled": true,
    "goslimstratum_instances": [
        {
            "name": "DigiByte",
            "host": "192.168.1.104",
            "api_port": "4004",
            "webui_port": "3003",
            "coin_type": "dgb"
        }
    ],
    "cryptNodesEnabled": true,
    "cryptoNodes": [
        {
            "Nodes": [
                {
                    "NodeType": "dgb",
                    "NodeName": "Digibyte",
                    "NodeId": "dgb1",
                    "NodeAlgo": "sha256d"
                }
            ]
        }
    ]
}
```

---

### Application Settings

| Field | Default | Description |
|-----|-------|-----------|
| `axeos_dashboard_version` | `3` | Internal version marker. Do not change — used by the app to detect config migrations. |
| `web_server_port` | `3000` | Port the dashboard web server listens on. Can also be set via the `PORT` environment variable. |
| `title` | `"AxeOS Dashboard"` | Title displayed in the browser tab and dashboard header. |
| `disable_authentication` | `false` | When `true`, bypasses the login screen entirely. **Requires TLS (i.e. SSL) if set to false**  |
| `disable_settings` | `false` | When `true`, hides the device settings controls. Prevents restarting or reconfiguring miners from the UI. |
| `disable_configurations` | `false` | When `true`, hides the configuration page. Useful for read-only or shared deployments. |
| `cookie_max_age` | `3600` | Session cookie lifetime in seconds. After this time the user is logged out. Default is 1 hour (3600). |


---

### Mining Devices

Each device type uses its own array. Devices are defined as key-value pairs where the key is the display name and the value is the connection address.

#### AxeOS Devices (`axeos_instances`)

AxeOS-based devices (Bitaxe, NerdQAxe) communicate over HTTP. Include the `http://` prefix in the address.

```json
"axeos_instances": [
    { "AxeOS1": "http://192.168.1.100" },
    { "NerdQAxe1": "http://192.168.1.102" }
]
```

| Part | Description |
|----|-----------|
| Key (e.g., `"AxeOS1"`) | Display name shown in the dashboard. |
| Value (e.g., `"http://192.168.1.100"`) | Full HTTP address of the device. Port 80 is assumed by default — include a port if different (e.g., `http://192.168.1.100:8080`). |

#### CGMiner Devices (`cgminer_instances`)

CGMiner API-compatible devices (Antminer S-series and similar) communicate over TCP. Do **not** include `http://`.

```json
"cgminer_instances": [
    { "AntminerS9": "192.168.1.101:4028" }
]
```

| Part | Description |
|----|-----------|
| Key | Display name. |
| Value | `host:port` in TCP format. Default CGMiner port is `4028`. |

#### AvalonQ Devices (`avalonq_instances`)

Canaan AvalonQ devices also use the CGMiner TCP API.

```json
"avalonq_instances": [
    { "AvalonQ-1": "192.168.1.160:4028" }
]
```

| Part | Description |
|----|-----------|
| Key | Display name. |
| Value | `host:port` in TCP format. Default port is `4028`. |

---

### Pool Integrations

#### MiningCore

> [!IMPORTANT]
> Support for Mining Core has been deprecated, do not use these settings.

```json
"mining_core_enabled": true,
"mining_core_url": [
    { "My Pool": "http://192.168.1.200:4000" }
]
```

#### GoSlimStratum

| Field | Default | Description |
|-----|-------|-----------|
| `goslimstratum_enabled` | `false` | Enable GoSlimStratum pool monitoring. |
| `goslimstratum_instances` | `[]` | Array of GoSlimStratum pool instances. |

Each instance in `goslimstratum_instances`:

| Field | Required | Description |
|-----|--------|-----------|
| `name` | Yes | Display name for the pool. |
| `host` | Yes | IP address or hostname of the GoSlimStratum server. |
| `api_port` | Yes | Port for the GSS HTTP API (typically `"4004"`). |
| `webui_port` | Yes | Port for the GSS web dashboard (typically `"3003"`). |
| `coin_type` | No | Coin ticker in lowercase (e.g., `"dgb"`, `"btc"`, `"bch"`). Used when the pool runs multiple coins. |

---

### Blockchain Nodes

| Field | Default | Description |
|-----|-------|-----------|
| `cryptNodesEnabled` | `false` | Enable blockchain node monitoring and network stats. |
| `cryptoNodes` | `[]` | Array of node configuration objects. |

Each entry in `cryptoNodes` contains a `Nodes` array. Each node in that array:

| Field | Description |
|-----|-----------|
| `NodeType` | Coin ticker (e.g., `"dgb"`, `"btc"`, `"bch"`). Determines display icon and formatting. |
| `NodeName` | Display name for this node (e.g., `"Digibyte"`). |
| `NodeId` | Unique identifier that links this node to its RPC credentials in `rpcConfig.json`. Must match a `NodeId` in `rpcConfig.json`. |
| `NodeAlgo` | Mining algorithm (e.g., `"sha256d"`). Used for display purposes. |

> **Note:** Node display config lives in `config.json`, but connection credentials (IP, port, username, password) live in the separate `rpcConfig.json` file. The `NodeId` field is the link between them.

---

## access.json

Stores the admin login credentials for the dashboard. Passwords are stored as SHA256 hashes — never in plaintext.

### Example

```json
{
    "admin": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
}
```

| Field | Description |
|-----|-----------|
| `admin` | SHA256 hash of the admin password. The key `"admin"` is the username. |

The hash shown above is SHA256 of the string `"admin"` — **change this before deploying**.

### Generating a Password Hash

```bash
echo -n "yourpassword" | sha256sum
```

Use the 64-character hex string output as the value in `access.json`.

> **Security:** Protect this file with appropriate filesystem permissions. Anyone with read access to this file can attempt to crack the hash offline.

---

## jsonWebTokenKey.json

Configures the JWT tokens used to maintain login sessions.

### Example

```json
{
    "jsonWebTokenKey": "Some_Super_Secret_Key",
    "expiresIn": "1h"
}
```

| Field | Description |
|-----|-----------|
| `jsonWebTokenKey` | Secret key used to sign and verify JWT tokens. Use a long, random string in production. If this key changes, all existing sessions are invalidated. |
| `expiresIn` | Token expiration duration in Go time format. Examples: `"1h"` (1 hour), `"30m"` (30 minutes), `"24h"` (24 hours). |

> **Security:** Use a strong, unique random key. A short or guessable key allows attackers to forge session tokens.

### Generating a Secure Key

```bash
openssl rand -base64 32
```

---

## rpcConfig.json

Stores connection credentials for blockchain nodes. This file is kept separate from `config.json` so that sensitive RPC credentials are not exposed through the dashboard API.

### Example

```json
{
    "cryptoNodes": [
        {
            "NodeId": "dgb1",
            "NodeRPCAddress": "192.168.1.106",
            "NodeRPCPort": 9001,
            "NodeRPAuth": "yourrpcuser:yourrpcpassword"
        }
    ]
}
```

Each entry in the `cryptoNodes` array:

| Field | Description |
|-----|-----------|
| `NodeId` | Must exactly match the `NodeId` in the corresponding node entry in `config.json`. This is how the dashboard links display config to credentials. |
| `NodeRPCAddress` | IP address or hostname of the blockchain node. |
| `NodeRPCPort` | RPC port. Must match `rpcport` in the node's configuration file. Common defaults: DGB `9001`, BTC `8332`, BCH `8332`. |
| `NodeRPAuth` | RPC credentials in `"username:password"` format. Must match `rpcuser`/`rpcpassword` in the node config. |

> **Security:** RPC credentials are never served through the dashboard API. Protect this file with appropriate filesystem permissions.

---

## notifications.json

> [!IIMPORTANT]
> Notifications are a licensed feature, an MMFP License is required to enable this.


Controls alert notifications for device, pool, and node events. Auto-generated with defaults if the file does not exist.

### Example

```json
{
    "enabled": false,
    "channels": {
        "email": { ... },
        "telegram": { ... },
        "webhooks": {
            "discord-alerts": { ... },
            "custom-webhook": { ... }
        }
    },
    "polling": { ... },
    "exclusions": { ... },
    "events": { ... },
    "rate_limiting": { ... }
}
```

### Top-Level

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Master switch. Set to `true` to enable all notifications. Individual channels and events must also be enabled. |

---

### Channels — Email

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable email notifications. |
| `smtp_server` | `""` | SMTP server hostname. |
| `smtp_port` | `587` | SMTP port. Common values: `587` (STARTTLS), `465` (SSL), `25` (plain). |
| `username` | `""` | SMTP login username. |
| `password` | `""` | SMTP password. Masked in the UI. |
| `use_tls` | `true` | Use TLS/STARTTLS for the connection. |
| `from_address` | `""` | Sender email address. |
| `to_addresses` | `[]` | List of recipient email addresses. |

---

### Channels — Telegram

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable Telegram notifications. |
| `bot_token` | `""` | Bot token from @BotFather. Masked in the UI. |
| `chat_id` | `""` | Target chat, group, or channel ID. |
| `message_prefix` | `"[AxeOS Dashboard] "` | Text prepended to all messages. |
| `parse_mode` | `"HTML"` | Message formatting: `"HTML"` or `"Markdown"`. |

---

### Channels — Webhooks

Webhooks are named — the key is the name referenced in event `channels` lists.

#### Discord Webhook

| Field | Description |
|-----|-----------|
| `enabled` | Enable this webhook. |
| `type` | Must be `"discord"`. |
| `url` | Discord webhook URL. |
| `message_prefix` | Optional message prefix. |
| `username` | Override the bot display name in Discord. |
| `avatar_url` | Override the bot avatar in Discord. |

#### Generic HTTP Webhook

| Field | Description |
|-----|-----------|
| `enabled` | Enable this webhook. |
| `type` | Must be `"generic"`. |
| `url` | Endpoint URL to POST to. |
| `message_prefix` | Optional message prefix. |
| `method` | HTTP method. Default is `"POST"`. |
| `headers` | Map of custom headers (e.g., `Authorization`). Auth headers masked in the UI. |
| `timeout_seconds` | Request timeout in seconds. |

---

### Polling

The notifications system checks devices on its own schedule, independent of the dashboard UI refresh.

| Field | Default | Description |
|-----|-------|-----------|
| `miner_check_interval_seconds` | `120` | How often (seconds) to poll miners for alert conditions. |
| `pool_check_interval_seconds` | `120` | How often to poll pools. |
| `node_check_interval_seconds` | `120` | How often to poll nodes. |

---

### Exclusions

Suppress all notifications for specific devices by name. Useful for test devices or known-offline hardware.

| Field | Description |
|-----|-----------|
| `miners` | List of miner display names to exclude. |
| `pools` | List of pool names to exclude. |
| `nodes` | List of node IDs to exclude. |

---

### Events

Controls which events trigger notifications and which channels receive them. Channel names must exactly match keys in the `channels` section.

#### Miner Events

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable miner event notifications. |
| `channels` | `[]` | Channels to notify (e.g., `["telegram", "discord-alerts"]`). |
| `offline` | `true` | Alert when a miner stops responding. |
| `online` | `true` | Alert when a previously offline miner comes back. |
| `zero_hashrate` | `true` | Alert when a miner is reachable but reporting 0 hashrate. |
| `temp_high` | `true` | Alert when temperature exceeds the critical threshold. |
| `failover` | `true` | Alert when a miner switches to a backup pool. |

#### Pool Events

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable pool event notifications. |
| `channels` | `[]` | Channels to notify. |
| `offline` | `true` | Alert when a pool becomes unreachable. |
| `online` | `true` | Alert when a pool comes back online. |

#### Node Events

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Enable node event notifications. |
| `channels` | `[]` | Channels to notify. |
| `offline` | `true` | Alert when a node's RPC becomes unreachable. |
| `online` | `true` | Alert when a node comes back online. |

#### System Events

| Event | Description |
|-----|-----------|
| `system.startup` | Sent when the dashboard starts. Confirms a successful restart. |
| `system.shutdown` | Sent when the dashboard shuts down gracefully. |

Each takes `enabled` (bool) and `channels` (list of channel names).

---

### Rate Limiting

Prevents alert floods when many devices go offline simultaneously (e.g., network outage).

| Field | Default | Description |
|-----|-------|-----------|
| `miner_events.enabled` | `false` | Enable rate limiting for miner events. |
| `miner_events.batch_window_seconds` | `60` | Time window in seconds for grouping events. |
| `miner_events.max_per_batch` | `10` | Max notifications sent per batch window. Events beyond this are suppressed until the next window. |
