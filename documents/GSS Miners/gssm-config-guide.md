# GSS Miners (GSSM) Configuration Guide

Complete reference for the `config.json` configuration file used by GSS Miners.

---

## Summary

GSS Miners (GSSM) is a dashboard for monitoring mining devices, GoSlimStratum pool instances, and blockchain nodes. All configuration lives in a single `config.json` file. Changes made through the WebUI are written directly to this file and take effect immediately — no restart required for most settings.

> **Note:** `disableAuthentication`, `webServerPort`, and logging settings require a restart to take effect.

---

## Example Configuration

```json
{
    "webServerPort": 3000,
    "title": "GSS Miners",
    "cookieMaxAge": 3600,
    "disableAuthentication": false,
    "disableSettings": false,
    "disableConfigurations": false,
    "goslimstratumPoolsEnabled": true,
    "cryptNodesEnabled": true,
    "logging": {
        "level": "info",
        "logToFile": true,
        "logFilePath": "/app/logs/gssm.log",
        "maxSizeMb": 20,
        "maxAgeDays": 30,
        "maxBackups": 10,
        "compress": false
    },
    "miners": [ ... ],
    "goslimstratumPools": [ ... ],
    "cryptoNodes": [ ... ],
    "thresholds": { ... },
    "refresh_intervals": {
        "miners": 120,
        "pools": 120,
        "nodes": 120
    }
}
```

---

## Top-Level Fields

General application settings.

| Field | Default | Description |
|---|---|---|
| `webServerPort` | `3000` | Port the GSSM web dashboard is served on. Can also be set via the `PORT` environment variable. |
| `title` | `"GSS Miners"` | Title shown in the browser tab and dashboard header. |
| `cookieMaxAge` | `3600` | Session cookie lifetime in seconds. After this time, users are logged out. Default is 1 hour (3600). |
| `disableAuthentication` | `false` | When `true`, bypasses login entirely. Useful during first-time setup. **Requires TLS (i.e. SSL) for this to work.** |
| `disableSettings` | `false` | When `true`, disables the ability to restart miners or change miner settings from the dashboard. |
| `disableConfigurations` | `false` | When `true`, hides the configuration UI. Useful for read-only deployments. |
| `goslimstratumPoolsEnabled` | `false` | Enables pool monitoring. Must be `true` for the Pools section to be fetched and displayed. |
| `cryptNodesEnabled` | `false` | Enables blockchain node monitoring. Must be `true` for the Nodes section to be fetched and displayed. |

---

## Miners

The `miners` array defines each mining device GSSM monitors. Each entry represents one physical miner.

```json
"miners": [
    {
        "id": "mXk9pQ2r",
        "name": "AxeOS1",
        "address": "http://192.168.1.100",
        "port": 80,
        "addressType": "http",
        "deviceType": "axeos",
        "model": "bitaxe"
    }
]
```

| Field | Required | Description |
|---|---|---|
| `id` | Auto-generated | Unique 8-character identifier, base62. Generated automatically — do not edit manually. |
| `name` | Yes | Display name for this miner in the dashboard. |
| `address` | Yes | IP address or hostname of the miner. Include `http://` prefix for HTTP devices. |
| `port` | Yes | Port to connect to. Typically `80` for HTTP devices and `4028` for TCP devices. |
| `addressType` | Yes | Connection protocol: `"http"` or `"tcp"`. |
| `deviceType` | Yes | The type of miner firmware/API. See device types below. |
| `model` | No | Specific hardware model. Refines display and threshold defaults. See models below. |

### Device Types

| `deviceType` | Description | Protocol |
|---|---|---|
| `axeos` | AxeOS-based miners (Bitaxe, NerdQAxe) | HTTP |
| `cgminer` | CGMiner API-compatible miners (Antminer S-series, etc.) | TCP |
| `canaan` | Canaan-based miners (AvalonQ, Nano3S) | TCP |

### Models

| `model` | Used With | Description |
|---|---|---|
| `bitaxe` | `axeos` | Bitaxe single-chip miners |
| `nerdqaxe` | `axeos` | NerdQAxe miners |
| `avalonq` | `canaan` | Canaan AvalonQ series |
| `nano3s` | `canaan` | Canaan Nano 3S series |

> **Note:** `model` is optional but recommended. It allows GSSM to apply the correct threshold defaults and display the proper device icon.

---

## GoSlimStratum Pools

The `goslimstratumPools` array defines GoSlimStratum pool instances to monitor. Requires `goslimstratumPoolsEnabled: true`.

```json
"goslimstratumPools": [
    {
        "id": "qA6wV9yM",
        "name": "Digibyte",
        "host": "192.168.7.138",
        "apiPort": "4004",
        "webuiPort": "3003",
        "coinType": "DGB",
        "gssCoinKey": "DGB"
    }
]
```

| Field | Required | Description |
|---|---|---|
| `id` | Auto-generated | Unique 8-character identifier, base62. Generated automatically. |
| `name` | Yes | Display name for this pool in the dashboard. |
| `host` | Yes | IP address or hostname of the GoSlimStratum server. |
| `apiPort` | Yes | Port for the GSS HTTP API (typically `"4004"`). Must match `http_api_port` in the GSS config. |
| `webuiPort` | Yes | Port for the GSS web UI (typically `"3003"`). Must match `port` in the GSS web config. |
| `coinType` | No | Coin ticker (e.g., `"DGB"`, `"BTC"`). Used for display purposes. |
| `gssCoinKey` | No | The coin key as it appears in the GSS config (usually matches `coinType`). Used to fetch per-coin stats from the GSS API. |

---

## Crypto Nodes

The `cryptoNodes` array defines blockchain nodes GSSM connects to for network statistics. Requires `cryptNodesEnabled: true`.

```json
"cryptoNodes": [
    {
        "id": "rB7xW0zK",
        "nodeName": "Digibyte",
        "nodeType": "DGB",
        "nodeAlgo": "sha256d",
        "rpcAddress": "192.168.1.110",
        "rpcPort": 9001,
        "rpcAuth": "yourrpcuser:yourrpcpassword"
    }
]
```

| Field | Required | Description |
|---|---|---|
| `id` | Auto-generated | Unique 8-character identifier, base62. Generated automatically. |
| `nodeName` | Yes | Display name for this node in the dashboard. |
| `nodeType` | Yes | Blockchain ticker symbol: `"DGB"`, `"BTC"`, `"BCH"`, `"XEC"`, etc. |
| `nodeAlgo` | Yes | Mining algorithm used by this blockchain. See algorithms below. |
| `rpcAddress` | Yes | IP address or hostname of the node running the RPC server. |
| `rpcPort` | Yes | RPC port of the node. Must match `rpcport` in the node's config file. |
| `rpcAuth` | Yes | RPC credentials in `"username:password"` format. Must match `rpcuser`/`rpcpassword` in the node config. |

> [!TIP]
> Use BTC for Nodes that are not listed in the drop down if they follow standard bitcoin.

### Supported Node Algorithms

| `nodeAlgo` | Coins |
|---|---|
| `sha256d` | BTC, DGB (SHA256d algo), BCH, XEC, other SHA256d Nodes |


> **Note:** RPC credentials are masked to `"****:****"` when viewed through the GSSM API. They are only readable from the raw `config.json` file.

---

## Logging

Controls how GSSM writes log output.

```json
"logging": {
    "level": "info",
    "logToFile": true,
    "logFilePath": "/app/logs/gssm.log",
    "maxSizeMb": 20,
    "maxAgeDays": 30,
    "maxBackups": 10,
    "compress": false
}
```

| Field | Default | Description |
|---|---|---|
| `level` | `"info"` | Log verbosity. See levels below. |
| `logToFile` | `false` | Set to `true` to write logs to a file in addition to console output. |
| `logFilePath` | `"/app/logs/gssm.log"` | Path to the log file. Required if `logToFile` is `true`. |
| `maxSizeMb` | `20` | Maximum log file size in MB before rotation. |
| `maxAgeDays` | `30` | Number of days to retain old log files. |
| `maxBackups` | `10` | Number of rotated log file backups to keep. |
| `compress` | `false` | Compress rotated log files with gzip. |

### Log Levels

| Level | What Gets Logged |
|---|---|
| `debug` | Everything — API calls, polling details, full request/response data |
| `info` | Normal operational events — startup, connections, polling results |
| `warn` | Recoverable issues — failed polls, retries |
| `error` | Failures only — connection errors, config errors |

---

## Thresholds

Thresholds define the warning and critical levels for each metric on each device type. The dashboard uses these to color-code values (green / yellow / red). Each device type has its own thresholds since their normal operating ranges differ significantly.

```json
"thresholds": {
    "miners": {
        "axeos": { ... },
        "cgminer": { ... },
        "canaan": { ... },
        "avalonq": { ... },
        "nano3s": { ... }
    }
}
```

Each threshold entry uses the same `warning` / `critical` structure:

```json
"temperature": {
    "warning": 65,
    "critical": 80
}
```

> **Note on Performance thresholds:** Performance is measured as a percentage of the device's expected hashrate. The logic is inverted — `warning` is the lower bound where performance is considered degraded, and `critical` is the point of serious underperformance. A reading *below* the warning level triggers a warning; below critical triggers a critical alert.

### AxeOS (`axeos`) — Bitaxe, NerdQAxe

| Metric | `warning` | `critical` | Description |
|---|:---:|:---:|---|
| `temperature` | `65` | `80` | Chip temperature in °C |
| `performance` | `95` | `80` | Hashrate as % of expected. Below warning = degraded; below critical = critical |
| `chipError` | `2` | `5` | Chip error rate as a percentage |
| `fanSpeed` | `90` | `100` | Fan speed as a percentage of max |

> **Fan Speed Note:** Warning at `90%` flags fans running near maximum (possible cooling issue). Critical at `100%` means fans are maxed out.

### CGMiner (`cgminer`) — Antminer S-series and other CGMiner-compatible ASICs

| Metric | `warning` | `critical` | Description |
|---|:---:|:---:|---|
| `temperature` | `70` | `85` | Board/chip temperature in °C |
| `performance` | `95` | `80` | Hashrate as % of expected |
| `hwErrorRate` | `0.01` | `1` | Hardware error rate as a percentage |
| `rejectRate` | `0.01` | `1` | Share reject rate as a percentage |

### AvalonQ (`avalonq`) — Canaan AvalonQ series

| Metric | `warning` | `critical` | Description |
|---|:---:|:---:|---|
| `temperature` | `70` | `85` | Temperature in °C |
| `performance` | `95` | `80` | Hashrate as % of expected |
| `rejectRate` | `0.01` | `1` | Share reject rate as a percentage |

### Nano3S (`nano3s`) — Canaan Nano 3S

| Metric | `warning` | `critical` | Description |
|---|:---:|:---:|---|
| `temperature` | `110` | `100` | Temperature in °C — Note: Nano3S runs hot by design; thresholds are higher |
| `performance` | `95` | `80` | Hashrate as % of expected |
| `rejectRate` | `0.01` | `1` | Share reject rate as a percentage |
| `hwErrorRate` | `2` | `5` | Hardware error rate as a percentage |

### Canaan (`canaan`) — Legacy Canaan fallback

| Metric | `warning` | `critical` | Description |
|---|:---:|:---:|---|
| `temperature` | `70` | `85` | Temperature in °C |
| `performance` | `95` | `80` | Hashrate as % of expected |
| `rejectRate` | `0.01` | `1` | Share reject rate as a percentage |

> **Tip:** Thresholds can be customized per deployment. For example, if your Bitaxe runs passively cooled, you may want to lower the temperature warning threshold.

---

## Refresh Intervals

Controls how often the GSSM dashboard polls each category for updated data (in seconds).

```json
"refresh_intervals": {
    "miners": 120,
    "pools": 120,
    "nodes": 120
}
```

| Field | Default | Description |
|---|---|---|
| `miners` | `120` | How often (in seconds) the dashboard polls all miners for updated stats. |
| `pools` | `120` | How often the dashboard polls GoSlimStratum pools for updated stats. |
| `nodes` | `120` | How often the dashboard polls blockchain nodes for updated stats. |

> **Tip:** Lower values give more real-time data but increase network traffic to your miners and nodes. 60 seconds is a reasonable minimum for most setups. Very low values (under 30s) on large fleets can cause network congestion.
