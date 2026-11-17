# GSS Miners (GSSM) Configuration Guide

Complete reference for the `config.json` configuration file used by GSS Miners.

*Current for GSS Miners 5.1.0.*

See also the [Miner Control Guide](gssm-miner-control-guide.md) (Standby, Schedules, Triggers, Auto Fan Control), the [Notifications Guide](gssm-notifications-guide.md) and the [Troubleshooting Guide](gssm-troubleshooting-guide.md).

---

## Summary

GSS Miners (GSSM) is a dashboard for monitoring mining devices, GoSlimStratum pools, litecoinpool.org accounts and blockchain nodes. It reads each device, pool and node directly, on your own network. It is a monitor: it is not a pool, and miners do not connect to it.

Almost everything is set from the **Configuration** page in the web UI, which writes `config.json` for you. Hand-editing the file is only needed for the few settings the page does not show (they are marked below).

### The configuration folder

With the MMFP installer the folder is `/data/gssm/config` on the server (`/app/config` inside the container).

| File or folder | What it holds |
|---|---|
| `config.json` | Everything in this guide: miners, pools, nodes, thresholds, the Coin Map, Historicals. |
| `notifications.json` | Alert channels and events. See the [Notifications Guide](gssm-notifications-guide.md). |
| `coin-icons/` | Logos you upload for your own coins. Created on the first upload. |

GSSM also keeps its own sign-in and license files in this folder. They are managed by GSSM and are not edited by hand.

### When a change takes effect

| Change | Takes effect |
|---|---|
| Anything saved from the web UI, except the items below | Straight away, or on the next refresh. No restart. |
| `webServerPort` and everything under `logging` | After GSSM restarts. |
| A hand edit to `config.json` | After GSSM restarts, or the next time something is saved from the web UI. |
| A license installed on the License page | After GSSM restarts. |

> **GSSM never overwrites a `config.json` it cannot read (v3.0.0+).** If the file has a typo or a permission problem at startup, GSSM stops with a message and leaves the file untouched. Fix the file and start GSSM again.

### First start

With no `config.json`, GSSM writes a baseline file, opens the Configuration page and waits for you to add devices, by hand or with **Auto-Discover** (see [Adding Devices](#adding-devices)).

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
    "animatedBackground": "nonce-hunt",
    "goslimstratumPoolsEnabled": true,
    "litecoinpoolPoolsEnabled": false,
    "cryptNodesEnabled": true,
    "logging": { ... },
    "miners": [ ... ],
    "goslimstratumPools": [ ... ],
    "litecoinpoolPools": [ ... ],
    "cryptoNodes": [ ... ],
    "coinMap": { ... },
    "thresholds": { ... },
    "refresh_intervals": { ... },
    "electricity": { ... },
    "updates": { ... },
    "historicals": { ... }
}
```

A complete example is in [config.example.json](../examples/GSS%20Miners/config.example.json).

---

## Top-Level Fields

| Field | Default | Description |
|-----|-------|-----------|
| `webServerPort` | `3000` | Port the dashboard is served on. The `PORT` environment variable, if set, wins over this. Not shown on the Configuration page: edit the file. Needs a restart. |
| `title` | `"GSS Miners"` | Title shown in the browser tab and the header. |
| `cookieMaxAge` | `3600` | How long a sign-in lasts, in seconds. Not shown on the Configuration page: edit the file. |
| `disableAuthentication` | `true` on a new install | When `true`, the dashboard has no sign-in. Signing in needs the dashboard to be served over HTTPS, because the browser only does its part of the sign-in on a secure connection. On plain HTTP, leave this `true` and keep GSSM on a network you trust. |
| `disableSettings` | `false` | When `true`, nothing can be changed on a miner from the web UI: no restart, no device settings, no Standby or Wake, no fan control, and schedules and triggers cannot be edited. Ones that are already set up keep running. |
| `disableConfigurations` | `false` | When `true`, the configuration pages are read-only. |
| `animatedBackground` | `"nonce-hunt"` | The moving background behind the dashboard: `none`, `hash-drift`, `node-mesh`, `share-pulse` or `nonce-hunt`. Applies on the next page load. |
| `goslimstratumPoolsEnabled` | `false` | Turns GoSlimStratum pool monitoring on. Adding a pool from the web UI turns it on for you. |
| `litecoinpoolPoolsEnabled` | `false` | Turns litecoinpool.org monitoring on. |
| `cryptNodesEnabled` | `false` | Turns node monitoring on. Adding a node from the web UI turns it on for you. |
| `serverId` | generated | An ID GSSM gives itself on first start, stamped on every row it stores in the Historicals database. Do not edit it: history is tied to it. |

---

## Miners

The `miners` array lists each mining device. GSSM talks to each device directly, over the device's own API.

```json
"miners": [
    {
        "id": "mXk9pQ2r",
        "name": "AxeOS1",
        "address": "http://192.168.1.100",
        "port": 80,
        "addressType": "http",
        "deviceType": "axeos"
    }
]
```

| Field | Required | Description |
|-----|--------|-----------|
| `id` | Auto-generated | Unique 8-character identifier. Generated for you. Do not edit it. |
| `name` | Yes | The name shown on the dashboard. It does not have to match the device's hostname. Notification exclusions go by this name. |
| `address` | Yes | IP address or hostname of the miner. HTTP devices take a full URL (`http://192.168.1.100`); TCP devices take a bare IP. |
| `port` | Yes | The device's API port. See the table below. |
| `addressType` | Yes | `"http"` or `"tcp"`. See the table below. |
| `deviceType` | Yes | The firmware family. See the table below. |
| `disabled` | No | `true` pauses the miner: GSSM stops checking it and sends no alerts for it, and its schedule, triggers and auto fan control stop. The entry is kept. Set from the miner's card or its edit form. |
| `fanControl`, `schedule`, `triggers` | No | Written by GSSM when you use Auto Fan Control, Schedules or Triggers. See the [Miner Control Guide](gssm-miner-control-guide.md). |

### Device Types

| `deviceType` | Devices | `addressType` | Usual `port` |
|------------|-----------|--------|------|
| `axeos` | Bitaxe and NerdQAxe-firmware boards (NerdQAxe++, NerdOCTAXE and others) | `http` | `80` |
| `nerdminer` | NerdMiner on NMMiner firmware 2.0 or newer | `http` | `80` |
| `elphapex` | ElphaPex DG-Home1 (Scrypt) | `http` | `80` |
| `cgminer` | CGMiner-compatible ASICs (Antminer S-series, including vnish firmware) | `tcp` | `4028` |
| `canaan` | Canaan Avalon Q and Avalon Nano3s | `tcp` | `4028` |
| `whatsminer` | MicroBT Whatsminer M30S, M50 and M60 series (BTMiner firmware) | `tcp` | `4433` |

What GSSM can do on each family:

| `deviceType` | Monitor | Restart | Settings page | Standby / Wake | Schedules | Triggers |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `axeos` | Yes | Yes | Yes | Yes | Yes (power) | Yes |
| `canaan` Avalon Q | Yes | Yes | Yes | Yes | Yes (power, work mode) | Yes |
| `canaan` Avalon Nano3s | Yes | Yes | Yes | No | Yes (work mode) | Yes (alert or restart only) |
| `elphapex` | Yes | Yes | Yes (work mode) | Through Sleep work mode | Yes (work mode) | Yes |
| `nerdminer` | Yes | Yes | Yes | No | No | Yes (alert or restart only) |
| `cgminer` | Yes | No | No | No | No | Yes (alert only) |
| `whatsminer` | Yes | No | No | No | No | Yes (alert only) |

Standby, Schedules, Triggers and Auto Fan Control need a Pro or Enterprise license. The [Miner Control Guide](gssm-miner-control-guide.md) covers them.

### No model to set (v4.0.0+)

Every miner names itself: GSSM reads the model from the device on every check (for example **Gamma 601**, **NerdQAxe++**, **Avalon Q**, **DG-Home1**, **M30S++_VH70** or **NMMiner**) and picks the matching thresholds and settings. There is no `model` field to configure. A `model` value left in a configuration from an earlier version is ignored.

> **NerdMiner firmware older than 2.0 is not supported (v4.0.0+).** Such a miner shows as offline with the message "NerdMiner firmware older than 2.0 isn't supported — update the firmware". Update the miner and it reappears by itself.

---

## GoSlimStratum Pools

The `goslimstratumPools` array lists the GoSlimStratum (GSS) pools to monitor. Needs `goslimstratumPoolsEnabled: true`. One entry is one coin's pool on a GSS server, or that server's Hash Hopper.

```json
"goslimstratumPools": [
    {
        "id": "qA6wV9yM",
        "name": "Digibyte",
        "host": "192.168.7.138",
        "apiPort": "4004",
        "coinType": "DGB",
        "gssCoinKey": "DGB"
    },
    {
        "id": "hK2pL8sD",
        "name": "Hash Hopper",
        "host": "192.168.7.138",
        "apiPort": "4004",
        "hashHopper": true
    }
]
```

| Field | Required | Description |
|-----|--------|-----------|
| `id` | Auto-generated | Unique 8-character identifier. Generated for you. |
| `name` | Yes | The name shown on the dashboard. |
| `host` | Yes | IP address or hostname of the GoSlimStratum server. Use `127.0.0.1` when GSS runs on the same machine as GSSM. |
| `apiPort` | Yes | The GSS API port, as text. `"4004"` unless you changed it in GSS. The web UI saves `"4004"` for you and does not show this field; edit the file for another port. |
| `gssCoinKey` | Yes, for a coin pool | The coin's key exactly as GSS has it (`DGB`, `DGBT`, `DGB-DD`). The **Lookup Keys** button on the pool form asks GSS and lists them. |
| `coinType` | No | The coin whose badge the card shows. **Optional since v5.1.0:** GSSM takes the coin from GSS itself, and GSS's answer wins over this field. Set it only for a GSS custom coin GSSM does not know (or give that coin its GSS coin type in the [Coin Map](#coin-map)). |
| `hashHopper` | No | `true` makes this entry the GSS server's **Hash Hopper** (GSS 6.0.0 or later) and not a coin pool. `coinType` and `gssCoinKey` are not used and GSSM clears them. (v5.1.0+) |
| `disabled` | No | `true` pauses the pool: no checks, no alerts. Set from the pool's card or its edit form. |

Notes:

- **A pool with no miners on it still reads online.** That is a standby pool, not an outage.
- **The Hash Hopper card (v5.1.0+)** shows whether the hopper is hopping or in shadow mode, the best chain now, which chain each profile's rigs are on, the switch rules, the rigs connected and their hashrate. Blocks found through the hopper show on each coin's own pool card. On a GSS older than 6.0.0 the card reads offline and says so.
- **There is no web UI port setting.** Older versions of this guide listed `webuiPort`; GSSM does not use it.

---

## Litecoinpool Pools

The `litecoinpoolPools` array lists litecoinpool.org accounts. Needs `litecoinpoolPoolsEnabled: true`. On the pool form, choose the pool type **Litecoinpool.org**.

```json
"litecoinpoolPools": [
    {
        "id": "tR4mN7xQ",
        "name": "My LTC Account",
        "apiKey": "your-litecoinpool-api-key"
    }
]
```

| Field | Required | Description |
|-----|--------|-----------|
| `id` | Auto-generated | Unique 8-character identifier. Generated for you. |
| `name` | Yes | The name shown on the dashboard. |
| `apiKey` | Yes | The API key from your litecoinpool.org account settings. Stored encrypted (see [Secrets](#secrets)). |

GSSM asks litecoinpool.org at most once a minute for each account, whatever the refresh interval. Litecoinpool pools send no offline or online alerts.

---

## Crypto Nodes

The `cryptoNodes` array lists blockchain nodes. Needs `cryptNodesEnabled: true`. GSSM talks to Bitcoin Core-family daemons over JSON-RPC.

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
|-----|--------|-----------|
| `id` | Auto-generated | Unique 8-character identifier. Generated for you. |
| `nodeName` | Yes | The name shown on the dashboard. Notification exclusions go by this name. |
| `nodeType` | Yes | The coin the node runs. It is a label that picks the badge: a built-in coin (below) or one you added in the Coin Map. |
| `nodeAlgo` | No | For a coin with more than one algorithm (DigiByte), the algorithm whose difficulty and hashrate lead the card: `sha256d`, `scrypt`, `skein`, `qubit` or `odo`. Coins with one algorithm ignore it. Default `sha256d`. |
| `rpcAddress` | Yes | IP address or hostname of the node. Use `127.0.0.1` when it runs on the same machine as GSSM. |
| `rpcPort` | Yes | The node's RPC port. Must match `rpcport` in the node's own config file. |
| `rpcAuth` | Yes | The node's RPC credentials as `"username:password"`, matching `rpcuser` and `rpcpassword` in the node's config. Stored encrypted (see [Secrets](#secrets)). The web UI asks for the username and password separately. |
| `disabled` | No | `true` pauses the node: no checks, no alerts. |

**Test Connection** on the node form checks the address, port and credentials against the live node before you save.

### Built-in coins

GSSM ships badges for: BC2, BCH, BCH2, BSV, BTC, BTCS, CRW, DGB, DOGE, EMC, FB, LTC, PPC, WJK, XEC, XMY, XRO. These are the choices for a node's type and a pool's coin, together with any coin you add in the Coin Map.

> [!TIP]
> A Bitcoin Core-family node for a coin that is not listed can be added two ways: add the coin in the Coin Map and pick it, or pick BTC and accept the Bitcoin badge.

---

## Coin Map

*v5.0.0+. Its own page, **Coin Map**, opened from the Configuration page.*

The Coin Map lets you add coins GSSM does not ship, with your own logos, and tell GSSM which coin a miner is mining when it cannot work that out. It only changes what is displayed: a coin symbol has no effect on how GSSM talks to a miner, pool or node. Nothing changes until you add something, and changes apply on the next refresh.

```json
"coinMap": {
    "customCoins": [
        { "symbol": "VTX", "gssCoinType": "vertexcoin" }
    ],
    "addressRules": [
        { "id": "aB3dE6gH", "coin": "VTX", "prefix": "vtx1" }
    ],
    "minerPoolMappings": [
        { "id": "jK9mN2pQ", "host": "192.168.7.10", "port": 3334, "coin": "FB" }
    ]
}
```

Use the Coin Map page for this section. The page checks every entry, which a hand edit skips; an entry GSSM cannot use is ignored and named in the log.

### Custom coins (`customCoins`)

| Field | Description |
|---|---|
| `symbol` | The coin's symbol: 1 to 16 letters and digits, starting with a letter. Stored in capitals. It cannot be renamed later, and it cannot be a built-in coin's symbol or `HOPPER`. |
| `gssCoinType` | Optional (v5.1.0+). What GoSlimStratum calls this coin: its key in GSS's `coins.json`, such as `vertexcoin`. Lowercase letters and digits, starting with a letter. GSS lets a coin's pool be named anything (`VTX-New`), so this is how GSSM knows a GSS pool or Hash Hopper chain of that type is this coin. Not needed for GSS's built-in coins, which GSSM already knows. Set it when you add the coin, or later with **Edit**. |

A custom coin appears in the pool and node coin lists straight away. A coin that is in use cannot be deleted; GSSM says what is using it.

**Logos.** Upload a PNG of up to 256 KB for a coin you added; square works best. Logos are kept in the `coin-icons` folder next to `config.json`, and you can also put `<symbol>.png` there by hand. Built-in coins, and the Hash Hopper's badge, always keep the logo they ship with. A dashboard that is already open shows a new logo within a minute.

### Which coin a miner shows

A miner's badge comes from what the miner itself reports: its pool address and the username it mines with. GSSM never asks the pool. For each pool a miner reports, GSSM checks in this order:

1. **Address rule** (`addressRules`). The wallet address has a form you taught GSSM, such as its own Bech32 prefix.
2. **Pool mapping** (`minerPoolMappings`). The pool's host and port are mapped to a coin. This beats the built-in rules on purpose: it is how a Bitcoin-style address on a Fractal Bitcoin port shows FB.
3. **Built-in rules.** What GSSM recognises by itself from the address, plus two special cases: a litecoinpool.org pool shows LTC, and a GoSlimStratum Hash Hopper login (`hopper.<profile>.<rig>`) shows the Hash Hopper badge, whichever chain the hopper has the rig on (v5.1.0+).
4. **Nothing matched.** The default badge.

### Address rules (`addressRules`)

| Field | Description |
|---|---|
| `id` | Generated for you. |
| `coin` | The coin this address form belongs to. |
| `prefix` | The start of the address, in lowercase, such as `vtx1` or `vexta:`. |
| `base58Version` | For a legacy (Base58) address, its version byte as a number. A rule has a `prefix` or a `base58Version`, never both. |

You do not type these. On the Coin Map page, paste one real address and GSSM works out the rule, or says why it cannot. GSSM refuses a rule for an address a built-in coin already claims, which covers most legacy addresses starting with `1`, `3`, `L`, `M`, `X`, `W`, `D`, `S`, `A`, `9` or `n`. Use a pool mapping for those.

### Pool mappings (`minerPoolMappings`)

| Field | Description |
|---|---|
| `id` | Generated for you. |
| `host` | The pool's host exactly as the miner reports it. |
| `port` | The pool's port. |
| `coin` | The coin every miner on that pool shows. |

A mapping matches exactly what the miner reports. A mapping for `192.168.7.10:3334` does not match a miner set to `gss.local:3334`; add a second mapping for that. The Coin Map page lists every pool your miners report ("What your miners report"), and **Map** on a row fills in the right value. If a coin moves to another port, update its mapping.

### Coins GSSM cannot tell apart by address

Some coins share address formats, so a miner's address cannot say which one it is. This only affects the badge.

- **Fractal Bitcoin (FB)** uses Bitcoin's address formats on every network: FB miners show the Bitcoin badge.
- **Bitcoin II (BC2)** addresses look like Bitcoin's.
- **WojakCoin (WJK)** is recognised only from its standard addresses starting with **W**. Its addresses starting with **3**, and all of its testnet addresses, look like Bitcoin's.
- **Bitcoin Cash II (BCH2)** is recognised only with its `bitcoincashii:` prefix; without it the address shows as BCH.
- **Bitcoin Silver (BTCS)** is recognised from its `bs1` / `tbs1` addresses; a legacy BTCS address shows as BTC.
- **DigiByte and Dogecoin** legacy addresses starting with **D** look the same: they show as DGB.
- **eCash (XEC)** is recognised only with its `ecash:` prefix; without it the address shows as BCH.

A pool mapping fixes any of these.

---

## Thresholds

Thresholds decide when a value on a miner card turns amber (warning) or red (critical). Each device family has its own set, edited under **Thresholds** on the Configuration page.

```json
"thresholds": {
    "miners": {
        "axeos": {
            "temperature": { "warning": 60, "critical": 80 },
            "performance": { "warning": 95, "critical": 80 }
        }
    }
}
```

Which set a miner uses:

| Set | Used by |
|---|---|
| `axeos` | Every `axeos` miner |
| `cgminer` | Every `cgminer` miner |
| `avalonq` | A `canaan` miner that names itself Avalon Q |
| `nano3s` | A `canaan` miner that names itself a Nano |
| `canaan` | A `canaan` miner GSSM has not been able to name yet |
| `elphapex` | Every `elphapex` miner |
| `whatsminer` | Every `whatsminer` miner |

NerdMiner has no threshold set.

Metrics (a set only uses the ones its devices report):

| Metric | Meaning |
|---|---|
| `temperature` | Temperature in °C. Reaching `critical` is also what sends the High Temperature alert. |
| `performance` | Hashrate as a percentage of what the device expects. **Works the other way round:** a reading below `warning` is amber, below `critical` is red. |
| `chipError` | Hardware error rate, in percent (AxeOS). |
| `hwErrorRate` | Hardware error rate, in percent (other families). |
| `rejectRate` | Rejected shares, in percent. |
| `fanSpeed` | Fan speed as a percentage of full. |
| `powerUtilization` | Power draw as a percentage of the most the device declares. Default `100` / `110` for every family. Not shown on the Configuration page. |

Defaults, as `warning` / `critical`:

| Set | `temperature` | `performance` | error rate | `rejectRate` | `fanSpeed` |
|---|:-:|:-:|:-:|:-:|:-:|
| `axeos` | 60 / 80 | 95 / 80 | `chipError` 0.01 / 5 | none | 90 / 100 |
| `cgminer` | 70 / 85 | 95 / 80 | `hwErrorRate` 0.01 / 1 | 0.01 / 1 | 90 / 100 |
| `avalonq` | 70 / 85 | 95 / 80 | none | 0.01 / 1 | 90 / 100 |
| `nano3s` | 85 / 95 | 95 / 80 | `hwErrorRate` 2 / 5 | 0.01 / 1 | 90 / 100 |
| `canaan` | 70 / 85 | 95 / 80 | none | 0.01 / 1 | 90 / 100 |
| `elphapex` | 70 / 85 | 95 / 80 | `hwErrorRate` 0.01 / 1 | 0.01 / 1 | 90 / 100 |
| `whatsminer` | 85 / 95 | 95 / 80 | `hwErrorRate` 1 / 5 | 1 / 5 | 80 / 95 |

A value you leave out takes its default.

> **Thresholds colour the cards and drive the High Temperature alert. They do not act on a miner.** The temperature at which a trigger idles a miner is set on the trigger itself, separately, so that changing what turns a card amber never changes when a miner shuts down. See the [Miner Control Guide](gssm-miner-control-guide.md).

---

## Refresh Intervals

How often the dashboard pages re-read your devices, in seconds.

```json
"refresh_intervals": {
    "miners": 120,
    "pools": 120,
    "nodes": 120
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `miners` | `120` | How often the Miners page reads every miner. |
| `pools` | `120` | How often the Pools page reads every pool. |
| `nodes` | `120` | How often the Nodes page reads every node. |

The Configuration page asks for at least 5 seconds.

> **These only control the page you are looking at.** Alerts, Historicals, schedules and triggers run on a separate background check, set under Polling in the [Notifications Guide](gssm-notifications-guide.md).

> **Tip:** Every read is a request to the device. Small miners have small web servers, so a short interval on a large fleet can make them slow to answer. 60 seconds or more suits most setups.

---

## Logging

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
|-----|-------|-----------|
| `level` | `"info"` | How much is logged: `debug`, `info`, `warn` or `error`. |
| `logToFile` | `false` (`true` on a new install) | Also write the log to a file. |
| `logFilePath` | `"/app/logs/gssm.log"` on a new install | Where the log file goes. Needed when `logToFile` is `true`. |
| `maxSizeMb` | `20` | Size at which the log file is rotated, in MB. |
| `maxAgeDays` | `30` | Days to keep rotated log files. |
| `maxBackups` | `10` | How many rotated log files to keep. |
| `compress` | `false` | Compress rotated log files with gzip. |

Logging changes need a restart. The **Logs** page (linked in the footer) shows the log live.

| Level | What is logged |
|-----|----------------|
| `debug` | Everything, including each check of each device |
| `info` | Normal events: startup, connections, results |
| `warn` | Problems GSSM recovered from: failed checks, retries |
| `error` | Failures only |

---

## Electricity

*v3.0.11+. Under Application Settings on the Configuration page. Free on every license.*

```json
"electricity": {
    "ratePerKWh": 0.12,
    "currency": "USD"
}
```

| Field | Description |
|---|---|
| `ratePerKWh` | What one kWh costs you. Leave it out, or `0`, and no cost is shown anywhere. |
| `currency` | A label for the figure, such as `USD` or `CAD`. GSSM does not convert currencies. |

With a rate set, the **Fleet** page shows an estimated running cost for the fleet and for each miner. It is an estimate from what the miners are drawing right now, not a bill. A miner that does not report its power draw (NerdMiner) is listed as "not reported" and left out of the total. For recorded energy use over time, see `trackPowerConsumption` under [Historicals](#historicals).

---

## Updates

*v2.0.3+.*

```json
"updates": {
    "enabled": false
}
```

| Field | Default | Description |
|---|---|---|
| `enabled` | `true` | Check for a newer GSSM release. Set `false` to turn the check off. Not shown on the Configuration page: edit the file. |
| `url` | the MMFP version file | Where the check looks. Leave it alone. |

GSSM downloads one small file from `get.mmfpsolutions.io` when it starts, keeps the answer for 24 hours, and compares it with its own version. There is no background checking. Nothing about your install is sent. When a newer release exists, a badge appears beside the version in the footer. If the site cannot be reached, nothing happens: no badge and no error.

---

## Historicals

*v3.0.0+. Pro or Enterprise. Off by default. Its own page, **Historicals**, opened from the Configuration page.*

Historicals gives GSSM a memory: trend charts for each miner, all-time best shares that survive a reboot, a searchable alert history and, optionally, recorded energy use. It needs a PostgreSQL database that you provide. With it off, GSSM keeps no history at all and works exactly as it does without a database.

```json
"historicals": {
    "enabled": true,
    "database": {
        "host": "127.0.0.1",
        "port": 5432,
        "dbName": "gssm",
        "user": "gssm",
        "password": "your-password",
        "sslMode": "disable",
        "maxConnections": 10,
        "connectionTimeout": 30
    },
    "retentionDays": 7,
    "notificationRetentionDays": 90,
    "batchSize": 100,
    "flushIntervalSeconds": 10,
    "trackPowerConsumption": false
}
```

| Field | Default | Description |
|---|---|---|
| `enabled` | `false` | Turns Historicals on. Turning it on or off, or pointing it at another database, applies without a restart. |
| `retentionDays` | `7` | Days of detailed miner readings to keep. Older readings are removed. Roughly 0.5 MB per miner per day. |
| `notificationRetentionDays` | `90` | Days of alert history to keep. |
| `batchSize` | `100` | How many readings are grouped into one write. |
| `flushIntervalSeconds` | `10` | How often stored-up readings are written. |
| `trackPowerConsumption` | `false` | Record each miner's energy use, in kWh per day (v3.0.12+). See below. |

`database`:

| Field | Default | Description |
|---|---|---|
| `host` | `"localhost"` | The PostgreSQL server. Use `127.0.0.1` when it runs on the same machine as GSSM. |
| `port` | `5432` | PostgreSQL port. |
| `dbName` | `"gssm"` | The database GSSM stores into. |
| `user` | `"gssm"` | The account GSSM connects with. |
| `password` | none | That account's password. Stored encrypted (see [Secrets](#secrets)). |
| `sslMode` | `"disable"` | `disable`, `require`, `verify-ca` or `verify-full`. |
| `maxConnections` | `10` | The most connections GSSM opens. |
| `connectionTimeout` | `30` | Seconds to wait when connecting. |

Setting it up:

- **Test Connection** checks the details against the live database before you save.
- **Create database & user** makes the database and the account for you. It asks for a PostgreSQL admin account, uses it once and does not store it. With the MMFP installer, the admin username and password are in `/data/docker-compose/.env`.
- **You can use the same PostgreSQL server as GoSlimStratum.** GSSM uses its own tables and does not touch GoSlimStratum's.
- **Several GSSM installs can share one database.** Each stamps its rows with its own `serverId`.

What you get:

- **Historicals → Miners:** trend charts per miner for hashrate, temperature, fan speed, assigned difficulty and best share.
- **Best (lifetime)** on a miner's detail page. For a miner that only tracks its best share since it last started, GSSM remembers the all-time best.
- **Historicals → Notifications:** every alert, searchable. An event group is recorded when `historicals` is one of its channels (see the [Notifications Guide](gssm-notifications-guide.md)).
- **Historicals → Energy** (with `trackPowerConsumption`): kWh per miner for any date range, with a CSV download.
- **Data Management** on the Historicals page: see what is stored for each miner, reset a best share, or remove a miner's data.

### Energy tracking (`trackPowerConsumption`)

When on, GSSM adds up each miner's real power draw at every background check and keeps a daily total.

- **Energy records are never removed by retention.** Only you can delete them, under Data Management. They cannot be rebuilt later, so the months before you turn this on stay empty.
- **GSSM records what it measured and nothing else.** While GSSM is stopped, while a miner is disabled, or for a device that does not report its power draw (NerdMiner), nothing is recorded. Every total comes with the percentage of the period that was measured.
- **Energy is stored, cost is not.** The report multiplies by your electricity rate as a convenience. For a rate that changed during the period, download the CSV and apply your own rates.

> **A miner excluded from notifications is not recorded.** Historicals and energy tracking use the same background check as alerts, and that check skips disabled miners and miners on the notification exclusion list. See Exclusions in the [Notifications Guide](gssm-notifications-guide.md).

---

## Secrets

*v1.1.0+.*

Passwords and keys in `config.json` are encrypted on disk: each node's `rpcAuth`, each litecoinpool `apiKey` and the Historicals database `password`. In the web UI they are shown masked.

You can still type a plain value into the file by hand. GSSM encrypts it the next time it starts.

---

## Adding Devices

Two ways, both from the Configuration page.

**Auto-Discover (v1.1.0+).** Scans your network and lists the miners, GoSlimStratum pools and nodes it finds; tick the ones you want and add them.

- Enter your subnet in CIDR form, such as `192.168.1.0/24`.
- Miners are found over HTTP (AxeOS, NerdMiner, ElphaPex) and TCP (CGMiner and Canaan on port 4028, Whatsminer on port 4433).
- Pools and nodes are found by asking each GoSlimStratum server. A GoSlimStratum on the same machine as GSSM is found without a scan.
- A discovered pool comes with its coin already chosen, read from GSS (v5.1.0+). A GSS server's Hash Hopper is offered as its own entry.
- Adding pools or nodes this way turns their section on for you.
- **Lower the concurrency** if the scan misses devices you know are there. Networks that translate addresses (Docker's bridge network, for one) can drop packets when many checks run at once.

**By hand.** Each section has an **Add** button and a short form. Miners, pools and nodes can be dragged into the order you want; the order is used on every page.

---

## Timezone

Schedules, time-of-day triggers and the daily energy totals use the server's clock. Set the `TZ` environment variable for the GSSM container to your zone, such as `TZ=America/Toronto`, and restart it. With no `TZ`, GSSM runs on UTC, and a "21:00" schedule window runs at 9 PM UTC.

The MMFP installer's compose file sets `TZ=America/New_York`. Change it if that is not your zone. The Schedule and Triggers pages show the zone GSSM is using and warn when `TZ` is not set or cannot be loaded.

---

## Licensing

GSSM monitors miners, pools and nodes on every license. Notifications, Historicals, Standby and Wake, Schedules, Triggers and Auto Fan Control need a Pro or Enterprise license. Tiers and prices: https://www.mmfpsolutions.io/pricing.html

A license key is pasted into the **License** page (opened from the Version page, which is linked in the footer). Restart GSSM after installing one.

---

## Common Mistakes to Avoid

- **Editing `config.json` while GSSM is running and expecting it to apply at once.** A hand edit is read at the next restart, or at the next save from the web UI. A save from the web UI to the same section (the miners list, for example) before then writes over your edit. Safest: stop GSSM, edit, start it.
- **A bare IP for an HTTP miner.** AxeOS, NerdMiner and ElphaPex miners need the `http://` in front; CGMiner, Canaan and Whatsminer take the IP alone.
- **The wrong port for a Whatsminer.** It is `4433`, not `4028`.
- **Adding one GoSlimStratum entry and expecting every coin.** Each coin's pool is its own entry, with its own `gssCoinKey`. Auto-Discover adds them all for you.
- **Guessing the `gssCoinKey`.** It must be the key exactly as GSS has it. Use **Lookup Keys**.
- **Expecting thresholds to protect a miner.** They colour the card and send an alert. To idle a miner that gets too hot, use a protective trigger.
- **Leaving `TZ` unset and then scheduling.** The schedule runs at the right times in UTC.
- **Running two GSSM installs that both schedule, trigger or fan-control the same miner.** They will fight over it. Monitor from as many installs as you like; control a miner from one.
