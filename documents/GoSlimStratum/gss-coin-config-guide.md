# GoSlimStratum Coin Configuration Guide

Complete reference for configuring coins in your mining pool.

*Current for GoSlimStratum 6.0.0.* See also the [Global Configuration Guide](gss-global-config-guide.md), the [Hash Hopper Guide](gss-hash-hopper-guide.md) and the [Troubleshooting Guide](gss-troubleshooting-guide.md).

---

## Summary

In GoSlimStratum (GSS), each coin can be configured to uniquely cater to the specific mining properties for that blockchain. Below is a description of each configuration field, and some basic rules on how to adjust them.

Every mining device, every blockchain, every network, every internet connection, every host machine (for GSS) can be different. The beauty of GSS is that those differences can be accommodated by way of configuration thereby allowing the operator to achieve maximum hashrate, stability and efficiency. This also presents opportunity for an operator to configure the system to be suboptimal, so careful consideration should be taken when adjusting coin configurations.

> **Note:** Configuration fields can be edited in the GSS WebUI or via direct edits to the config.json file. It is recommended that edits be done with the WebUI. A saved change to a coin's configuration does not take effect until that coin pool is unloaded and loaded again (see below).
>
> **How to apply a saved change:** a coin pool reads its configuration when it is loaded. After saving on a coin's Configuration page, use the **Pool Lifecycle** card at the top of the page, in this order:
>
> 1. **Stop** (the red square).
> 2. **Unload** (the grey bin, shown once the pool is stopped).
> 3. **Load & Start** (the green triangle marked "Click to load", shown once the pool is not loaded).
>
> This applies to every field on the page, the stratum port included. That coin's miners are disconnected and reconnect once it is running again; other coins are not touched. The page says the same when you save: "Unload and reload the pool to apply changes."
>
> **Restart is not enough.** **Restart** (the blue circular arrow) and **Stop** followed by **Start** bring the pool back with the configuration it was loaded with, so a saved change is not picked up. Restart is for getting a pool going again, not for applying a change.
>
> Two exceptions: Coin Alerts thresholds apply as soon as you save, with nothing to stop or load. And restarting GoSlimStratum itself loads every coin afresh, so it applies saved changes too; that is the way to apply a hand edit to `config.json`.

---

## Example Coin Configuration

Here is a complete example of a coin configuration object in `config.json`:

```json
"DGB": {
    "enabled": true,
    "enable_dtm": false,
    "dtm_revenue_share_accepted": false,
    "coin_type": "digibyte",
    "algorithm": "sha256d",
    "display_name": "DigiByte Mainnet",
    "node": {
        "host": "127.0.0.1",
        "port": 9001,
        "username": "your_rpc_username",
        "password": "your_rpc_password",
        "use_ssl": false,
        "wallet_name": "default",
        "wallet_passphrase": "",
        "zmq_block_notify": "tcp://127.0.0.1:28332",
        "template_refresh_interval": 15,
        "zmq_enabled": true,
        "zmq_stale_detection_time": 120,
        "dual_node_comm": true,
        "alternate_host": "",
        "enable_failover": false
    },
    "stratum": {
        "host": "0.0.0.0",
        "port": 3333,
        "difficulty": 4096,
        "accept_miner_suggested_diff":false,
        "probe_difficulty": 65536,
        "user_agent_difficulty_map": {
          "nerdqaxe": 50000,
          "bitaxe": 9000,
          "nerdoctopus": 24000
        },
        "connection_timeout_seconds": 600,
        "disambiguation_enabled": false,
        "auto_worker_id": true,
        "default_worker_id": "",
        "consolidation_threshold_seconds": 3,
        "ping_enabled": true,
        "ping_interval_seconds": 30
    },
    "sv2": [
        {
            "variant": "bip324",
            "enabled": false,
            "port": 34254,
            "cert_valid_hours": 24
        }
    ],
    "mining": {
        "address": "your_legacy_node_wallet_address",
        "network": "mainnet",
        "coinbase_text": "GoSlimStratum",
        "extranonce_size": 8,
        "max_job_history": 20,
        "job_expiration_time": 300,
        "stale_share_grace_period": 5
    },
    "vardiff": {
        "enabled": true,
        "useFloatDiff":false,
        "floatDiffBelowOne": true,
        "floatDiffPrecision": 4,
        "minDiff": 512,
        "maxDiff": 32768,
        "targetTime": 15,
        "retargetTime": 180,
        "variancePercent": 30,
        "onNewBlock": true,
        "floodProtection": {
            "enabled": false,
            "sharesToCheck": 4,
            "triggerThreshold": 0.25,
            "maxAdjustmentMultiplier": 16
        }
    },
    "payout": {
        "enabled": true,
        "pool_fee_percent": 1.0,
        "maturity_confirmations": 100,
        "payment_interval_seconds": 600,
        "minimum_confirmations": 6,
        "maturity_check_interval_seconds": 60,
        "confirmation_check_interval_seconds": 300,
        "wallet_rpc_timeout_seconds": 30
    },
    "explorer": {
        "use_rest_api": false,
        "use_alternate_host": false
    }
}
```


## Top-Level Fields

| Field | Description | Example |
|-----|-----------|-------|
| `enabled` | Whether this coin is active. Set to `false` to disable without removing config. | `true` |
| `enable_dtm` | Enable Direct-to-Miner mode. Block rewards go directly to the miner's wallet address via the coinbase transaction. | `false` |
| `dtm_revenue_share_accepted` | Accept 0.5% revenue share in lieu of a license for DTM mode. Only applies to built-in coins without a license. | `false` |
| `coin_type` | The coin implementation to use. See the table of built-in coins below. Cannot be changed from the Config page once the coin exists. | `"digibyte"`, `"bitcoin"`, `"bitcoincash"` |
| `algorithm` | Mining algorithm. Set automatically for most coins. DGB supports multiple algorithms on the same instance, each as its own coin entry on its own stratum port. | `"sha256d"` (default), `"scrypt"`, `"skein"`, `"qubit"`, `"odo"` |
| `display_name` | Human-readable name shown in the web dashboard. | `"DigiByte Mainnet"` |

The name you give the coin entry itself (the key under `coins`, such as `"DGB"`) is the coin's symbol in the web UI, in the database and in every other setting that names a coin. Blocks, shares and payment history are stored under it.

### Built-In Coins

| Coin | `coin_type` | Algorithms | Since |
|----|-----------|----------|-----|
| DigiByte (DGB) | `digibyte` | `sha256d`, `scrypt`, `skein`, `qubit`, `odo` (Odocrypt, v5.3.0+) | — |
| Bitcoin (BTC) | `bitcoin` | `sha256d` | — |
| Bitcoin Cash (BCH) | `bitcoincash` | `sha256d` | — |
| eCash (XEC) | `ecash` | `sha256d` | — |
| Litecoin (LTC) | `litecoin` | `scrypt` | — |
| Dogecoin (DOGE) | `dogecoin` | `scrypt` | — |
| Bitcoin II (BC2) | `bitcoinii` | `sha256d` | — |
| Bitcoin Silver (BTCS) | `bitcoinsilver` | `sha256d` | v5.4.0 |
| Bitcoin Cash II (BCH2) | `bitcoincashii` | `sha256d` | v5.4.0 |
| WojakCoin (WJK) | `wojakcoin` | `sha256d` | v5.5.4 |
| Fractal Bitcoin (FB) | `fractalbitcoin` | `sha256d` | v5.5.5 |

- `odo` is DigiByte-only and Stratum V1 only. GSS won't start if `odo` is set on another coin.
- Fractal Bitcoin: GSS mines Fractal's regular (permissionless) blocks. Merged mining with Bitcoin is not supported.
- WojakCoin pays part of every block to its development fund. GSS builds those payments into the block for you; that is why WJK cannot be added through `coins.json`.

### Other Coins (`coins.json`)

A SHA256d coin that is not built in can be defined in `coins.json`, in the same directory as `config.json`. Each entry is keyed by a lowercase name, and that name is what you put in `coin_type`. An entry gives the coin's name, symbol, address formats and explorer links; see [coins.example.json](../examples/GoSlimStratum/coins.example.json) and [coins.schema.json](../examples/GoSlimStratum/coins.schema.json).

- SHA256d coins only.
- Direct-to-Miner mode on a `coins.json` coin needs a license. Revenue share in lieu of a license applies to built-in coins only.
- Coin Value shows no price for a `coins.json` coin.
- If an entry has the same name as a built-in coin, the built-in coin is used.

---

## Node Section

Connection settings for your coin's node (full or pruned).

| Field | Description | Guidelines |
|-----|-----------|----------|
| `host` | IP address of your node | `"127.0.0.1"` for local, or remote IP |
| `port` | RPC port of your node | Check your node's config (e.g., rpcport=X) |
| `username` | RPC username from node's config file | Must match `rpcuser` in node config |
| `password` | RPC password from node's config file | Must match `rpcpassword` in node config |
| `use_ssl` | Use HTTPS for RPC connection | `false` for local, `true` if node requires SSL |
| `wallet_name` | Name of the wallet to use for payouts | `"default"` unless you created a named wallet |
| `wallet_passphrase` | Passphrase for encrypted (password-protected) node wallets | Leave empty (`""`) if wallet is not encrypted. On first startup, GSS auto-encrypts the plaintext value in config.json using AES-256-GCM |
| `zmq_block_notify` | ZMQ endpoint for instant block notifications | Format: `"tcp://IP:PORT"`. Requires node ZMQ config. |
| `template_refresh_interval` | Seconds between block template polls | 15-30 seconds typical. Lower = more network traffic |
| `zmq_enabled` | Use ZMQ for instant new block detection | `true` recommended if node supports ZMQ |
| `zmq_stale_detection_time` | Seconds before falling back to polling if ZMQ silent | Leave it unset to get the default for the coin: DGB `120`, DOGE `180`, FB `180`, WJK `360`, BTC / BCH / BCH2 / BC2 / BTCS / XEC / LTC `900`, any other coin `300`. `0` disables the check |
| `dual_node_comm` | Enable ZMQ + Polling, recommended | Default set to `false` if not defined |
| `alternate_host` | Optional alternate node for block explorer queries and node failover | `"10.0.0.50"` or `"10.0.0.50:14022"`. If no port specified, uses the primary node's port |
| `enable_failover` | Enable automatic failover to `alternate_host` when the primary node goes down (v4.1.0+) | `false` default. Requires `alternate_host` to be set and a license with the node failover scope. See **Node Failover** below |

### ZMQ Setup

Add this to your node's config file (e.g., `digibyte.conf`):

```
zmqpubhashblock=tcp://0.0.0.0:28332
```

Then set `zmq_block_notify` to match: `"tcp://127.0.0.1:28332"`

### Node Failover - AS OF Version 4.1.0

When `enable_failover` is `true` and `alternate_host` is set, GSS will automatically switch to the backup node if the primary becomes unreachable. Mining continues without interruption — miners stay connected, no reconnection required. Once the primary recovers, GSS fails back on the next natural block boundary.

```json
"node": {
    "host": "192.168.1.100",
    "port": 14022,
    "username": "rpc_user",
    "password": "rpc_password",
    "alternate_host": "192.168.1.101",
    "enable_failover": true
}
```

**Behavior:**

- **Failover trigger:** 3 consecutive health check failures on the primary node
- **Failback trigger:** 5 consecutive successful primary checks, then waits for the next block boundary to switch back (avoids disruption mid-work)
- **Anti-flapping:** An unstable primary resets the recovery counter, preventing premature failback
- **ZMQ dual subscription:** GSS subscribes to ZMQ on both primary and backup simultaneously from startup, so block detection on the backup is instant — no polling lag during failover. If the backup doesn't have ZMQ configured, it falls back to polling-only on the backup node.
- **Both nodes down:** If the backup is also unreachable when failover is attempted, GSS falls through to standard offline behavior (stop stratum, wait for reconnect).
- **Dashboard banner:** The coin pool dashboard shows an orange "mining on backup node" banner while failover is active. The banner updates to "failback pending" when the primary recovers and is waiting for the next block.
- **Notifications:** Failover and failback events are sent via the existing `nodes` notification channel (Telegram, Discord, email, webhook).

**Requirements:**

- Both nodes must use the **same RPC username, password, and port**
- Both nodes must be on the **same chain tip** (this is automatic in normal operation — the failover relies on chain validity being node-agnostic, so in-flight work from the primary remains valid on the backup)
- Wallet must be loaded on the backup node for payouts to continue
- Requires a license with the **node failover scope**. The Config UI checkbox is disabled without the license, and the engine silently ignores the setting if the license is missing.
- `alternate_host` is required when `enable_failover` is `true` — config save is rejected otherwise.

> **Tip:** If you only need an alternate host for explorer queries (not mining failover), set `alternate_host` and leave `enable_failover` as `false`. The two settings are independent.

### Node Health Monitoring & Startup Recovery

GSS continuously monitors each coin's node health and **automatically starts the stratum server** as soon as the node finishes its startup process. There is no need to restart GSS after a node restart, server reboot, or `apt upgrade`. This section explains the timing so you know what to expect.

**The most common question:** *"I rebooted my server / restarted Docker, GSS shows my pool stopped or node offline. Is something broken?"*

Almost always, no. The node is still starting up (verifying blocks, loading the wallet, opening the RPC port). GSS sees the node as not yet ready, refuses to open the stratum port (so miners don't connect to a pool that can't yet build jobs), and keeps polling on a tight cadence until the node responds. The moment it does, GSS opens the stratum port automatically.

**Three-tier health-check polling cadence:**

| Phase | Polling interval | When it applies |
|---|---|---|
| **Warmup** | every **5 seconds** | Node is responding with RPC error `-28` ("Loading block index", "Verifying blocks", "Loading wallet"). GSS polls aggressively so it detects the transition to ready ASAP. |
| **Initial** | every **20 seconds** | First **5 minutes** after the node accepts RPC normally. Tight cadence in case the node flakes during early operation. |
| **Long-term** | every **120 seconds** | After 5 minutes of clean responses. Steady-state polling for the lifetime of the pool. |

**What happens on a server reboot / Docker restart:**

1. GSS starts up and tries to initialize each coin's pool by calling `getblockchaininfo` on its node.
2. The node is still loading blocks → RPC returns error `-28`. GSS marks the node as "warmup" state and the pool stays uninitialized (stratum port stays closed).
3. GSS health monitor polls every **5 seconds** while the node is in warmup.
4. The node finishes its startup process and starts responding normally to RPC.
5. The next 5-second poll succeeds → GSS initializes the pool and **starts the stratum server automatically**. Dashboard updates to show node = Online and pool = Running.
6. For the next 5 minutes GSS polls every 20 seconds (initial mode). After that, it settles into 120-second long-term polling.

**Node startup time depends on total block count and disk speed.** It is roughly proportional to how many blocks the node has to verify on startup, not to the chain's "weight" or popularity:

- **DGB tends to be the longest.** DigiByte has 15-second block times since 2014 → millions of blocks, each requiring signature verification on startup. On slower SSDs or HDDs this can easily run 10–30+ minutes. **This is normal.**
- **BTC and BCH typically come up faster** despite their reputation, because 10-minute blocks means far fewer blocks to verify on startup, even though the chain weight is heavier per block.
- **XEC and other smaller chains** are usually fastest.

**The right way to check progress:** don't watch GSS — Couple of ways:

- Watch in your dozzle logs viewer : http:{YOUR_IP_ADDRESS}:8080
- Watch the node directly. Run the coin's CLI from a shell on the node host:

> **Note:**
> - $USER=Your RPC Username
> - $PASSWORD=Your RPC Password
> - $PORT=Your RPC Port

```bash
# DigiByte
sudo docker exec dgb digibyte-cli -rpcuser=$USER -rpcpassword=$PASSWORD -rpcport=$PORT getblockchaininfo | grep -E "blocks|headers|verificationprogress|initialblockdownload"

# Bitcoin
sudo docker exec btc bitcoin-cli -rpcuser=$USER -rpcpassword=$PASSWORD -rpcport=$PORT getblockchaininfo | grep -E "blocks|headers|verificationprogress|initialblockdownload"

# Bitcoin Cash
sudo docker exec bch bitcoin-cli -rpcuser=$USER -rpcpassword=$PASSWORD -rpcport=$PORT getblockchaininfo | grep -E "blocks|headers|verificationprogress|initialblockdownload"
```

When you see:
- `"initialblockdownload": false`
- `"verificationprogress": 0.9999...` (very close to 1.0)
- `"blocks"` matches (or nearly matches) `"headers"`

…the node is ready, and GSS will detect it on the next health poll — **within 5 seconds** (warmup) or **within 20 seconds** (initial). No GSS restart required.

**Notifications:** A `node_online` notification fires the moment GSS detects the node is ready. If you have Telegram, Discord, email, or webhook notifications configured for the `nodes` channel, you'll get a ping the instant the pool comes back up — even if you're not watching the dashboard.

**When to actually worry:**

If 30+ minutes pass and the node CLI still shows `initialblockdownload: true` or `verificationprogress` not approaching 1.0, the node itself is the issue, not GSS. Check the node's own log (e.g. `~/.digibyte/debug.log`) for errors. Common causes: full disk, corrupted chain state (rare, usually requires `-reindex`), or insufficient RAM during verification.

If `getblockchaininfo` reports the node IS ready but GSS still shows it offline after 2 minutes, check that GSS's configured `host`, `port`, `username`, and `password` actually work from GSS's perspective:

> **Note:**
> You must have rest=1 in your node configuration file (e.g. digitbyte.conf) for this to work

```bash
curl --user rpc_user:rpc_password -d '{"jsonrpc":"1.0","method":"getblockchaininfo","params":[]}' http://NODE_HOST:NODE_PORT/
```

A 200 OK with JSON content = GSS should be detecting it. A 401, connection refused, or timeout = network/auth misconfiguration, not a GSS bug.

### Starting After a Failed Start - AS OF Version 5.5.3

If a coin fails to start once its node is up (for example because one of its ports was briefly in use), GSS tries again by itself on its regular health check and carries on until the coin is running. A coin you stopped yourself stays stopped. The error for a port that is in use says which port and what to do about it.

### Merged Mining (AuxPoW) - AS OF Version 4.1.0

Merged mining lets your miners simultaneously mine a parent chain and one or more aux (auxiliary) chains using the same hashrate — no extra work, no extra hardware. The classic example is **LTC → DOGE**: scrypt miners hashing for Litecoin can also produce Dogecoin blocks, since DOGE accepts AuxPoW (Auxiliary Proof of Work) blocks proven by LTC's parent chain.

**Supported pairs:** Litecoin + Dogecoin, and from v5.2.3 DigiByte-Scrypt + Dogecoin (a DGB coin entry with `"algorithm": "scrypt"` as the parent). Stratum V2 is not involved: V2 runs on SHA256d coins and merged mining runs on Scrypt.

GSS implements full AuxPoW merged mining with **per-miner DTM coinbases on both chains**, including pool fee splits — most stratum pool implementations limit the aux chain coinbase to a single address. GSS uses the aux node's `submitblock` RPC with a fully constructed block, giving complete control over the aux chain's coinbase outputs.

**Configuration:**

Merged mining is configured per-coin via a `merged_mining` block. The parent chain declares its aux chains, and each aux chain points back to its parent.

```json
"coins": {
    "LTC": {
        "enabled": true,
        "enable_dtm": true,
        "coin_type": "litecoin",
        "algorithm": "scrypt",
        "merged_mining": {
            "role": "parent",
            "aux_chains": ["DOGE"]
        },
        "node": { "...": "..." },
        "stratum": { "port": 4335, "...": "..." },
        "mining": { "...": "..." }
    },
    "DOGE": {
        "enabled": true,
        "enable_dtm": true,
        "coin_type": "dogecoin",
        "algorithm": "scrypt",
        "merged_mining": {
            "role": "aux",
            "aux_of": "LTC"
        },
        "node": { "...": "..." },
        "stratum": { "port": 4336, "...": "..." },
        "mining": { "...": "..." }
    }
}
```

**Fields:**

| Field | Description | Required When |
|-----|-----------|----------|
| `role` | The chain's role in the merged mining relationship: `"parent"` or `"aux"` | Always (when `merged_mining` is set) |
| `aux_chains` | List of aux chain config keys this parent embeds AuxPoW commitments for | `role` is `"parent"` |
| `aux_of` | Config key of the parent chain this aux is mined alongside | `role` is `"aux"` |

**Validation rules:**

- Both the parent and every aux chain must have **DTM enabled** (license or revenue share)
- The parent and aux chains must use the **same mining algorithm** (scrypt for LTC → DOGE)
- Each aux chain referenced in `aux_chains` must exist, be enabled, and have its own `merged_mining` block declaring `role: "aux"` with `aux_of` pointing back to the parent
- The coin pool dashboard shows an orange warning banner if any of these rules are violated, with a list of specific misconfigurations
- Both LTC and DOGE remain fully functional **standalone** pools — merged mining is an additive layer, not a replacement. Removing the `merged_mining` config field leaves both pools running exactly as before.

**Username format:**

Miners point at the **parent chain's stratum port only** (no changes to miner hardware or firmware). To mine both chains, use a **pipe-delimited** username with both addresses:

```
ltc1qXXX|DXXX.workername    — LTC address + DOGE address + worker name
ltc1qXXX.workername         — LTC only (no merged mining for this miner)
```

**Merged mining is opt-in per miner (v5.2.3+).** A miner earns aux rewards only when its username carries its own aux payout address in the pipe format above. The password field is not read for the aux address. A miner without one keeps mining the parent chain normally; it just doesn't merge-mine, and the log says so when it connects. Before v5.2.3, a miner with no aux address was merge-mined anyway and its DOGE rewards went to the pool's configured DOGE address. That fallback is gone.

- A mistyped aux address is caught when the miner connects: one warning in the log, and the miner keeps mining the parent chain.
- **One wallet address, one decision.** Miners that share a parent wallet address share one coinbase, so they share one merged-mining decision. If any worker on an address opts in, every worker on that address contributes to the aux chain. If two workers on one address give different aux addresses, the most recent one wins and the log warns you. For separate aux payouts, use separate parent addresses.
- **Revenue share (v5.2.3+):** without a license, the 0.5% revenue share you accepted on each coin applies on the aux chain too.

**How it works:**

1. The aux chain (DOGE) is polled for new block templates via `getblocktemplate`
2. GSS embeds an AuxPoW commitment (DOGE block hash) in the parent chain's (LTC) coinbase scriptSig
3. Miners hash LTC headers as normal
4. Every accepted LTC share is also checked against the DOGE difficulty target
5. When a share meets the DOGE target, GSS constructs a full DOGE AuxPoW block and submits it via the DOGE node's `submitblock` RPC
6. Block found notifications fire independently for both LTC and DOGE blocks

**Dashboard:**

- **Parent dashboard (LTC):** Orange `Merged → DOGE` badge in the status area. A worker shows an **M** badge only while it is actually merge-mining (connected, authorized, with a valid aux address); hover it to see the aux address its rewards pay to. No badge means that miner is not merge-mining. The Block Odds card gains an **Aux Odds** row, worked out from only the miners that are merge-mining.
- **Aux dashboard (DOGE):** Orange `AuxPoW ← LTC` badge in the status area. DOGE blocks found via merged mining appear in the Recent Blocks card with the same display as standalone-mined blocks.
- **Miners are listed on the parent dashboard only.** A merge-mining miner is connected to the parent's port, so it never appears in the aux coin's miner list, and the aux coin's log line `DTM: Dispatched per-miner jobs to 0 miners` is normal. Neither means merged mining is not working.
- **The aux address is not part of the name shown.** A miner that logged in as `ltc1qXXX|DXXX.workername` is listed as `ltc1qXXX.workername`.

**How to confirm a miner is merge-mining:**

- The **M** badge beside the worker on the parent (LTC) dashboard.
- The parent's log when the miner connects: `Merged mining: aux payout registered — DOGE → <address>`. If it says `no aux address supplied` or `invalid DOGE address`, the miner is mining the parent chain only.

**Graceful degradation:**

- If the aux node (DOGE) goes offline, jobs are built without the AuxPoW commitment and LTC-only mining continues. When the aux node comes back, the commitment resumes automatically.
- If `merged_mining` is not set on either coin, behavior is identical to standalone pools — there is zero performance or correctness impact.
- From v5.2.6, merged mining is re-established automatically when the node comes online after a reboot, and after a coin pool is stopped and started. The dashboard banner also checks what is actually running, not just the configuration: "Merged Mining **Not Active**" with the reason (configured but not running, the aux coin was reloaded, or the aux node has stopped answering). While the aux node is not answering, any aux block found is rejected, so act on that banner.

> **Note:** Merged mining requires DTM mode on both chains. If you don't have a license, you can use revenue share (0.5%) on built-in coins. LTC and DOGE are both built-in coins.

---

## Stratum Section

Settings for miners connecting to your pool.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `host` | IP to listen on | `"0.0.0.0"` to accept all connections |
| `port` | Port miners connect to | Pick unique port per coin (3333, 3334, etc.) |
| `difficulty` | Starting difficulty for new miners | **See table below** |
| `accept_miner_suggested_diff`| Accept starting diff value sent from miner | Default set to `false` if not defined |
| `probe_difficulty`| High difficulty sent with the initial mining.subscribe response before miner identity is known | `65536` typical. Set to `0` to disable. See Smart Initial Difficulty below |
| `user_agent_difficulty_map` | Map of user agent substring to starting difficulty | Case-insensitive substring match. e.g., `{"bitaxe": 9000, "nerdqaxe": 50000}` |
| `connection_timeout_seconds` | Disconnect idle miners after this many seconds | 600 (10 min) typical. No change recommended |
| `disambiguation_enabled` | Append `-1`, `-2`, etc. when multiple connections share the same worker name | Default `false`. Enable if multiple physical miners use the same worker name and you want unique identifiers per connection |
| `auto_worker_id` | Auto-assign a workerID when a miner connects with just a wallet address (no `.workerID` suffix) | Default `true`. When `false`, miners with no suffix use the bare wallet address as their worker name |
| `default_worker_id` | Custom workerID to assign to no-suffix miners (only used when `auto_worker_id` is `true`) | Default `""` (empty = use unique connection ID). Set to a string like `"default"` to group all no-suffix miners under the same name |
| `consolidation_threshold_seconds` | Grace period (seconds) for consolidating rapid reconnects under the same worker name | Default `3`. Set to `0` to disable. Only applies when `disambiguation_enabled` is `true` |
| `ping_enabled` | Attempt to use mining.ping with miners | Default set to `true` if not defined |
| `ping_interval_seconds` | Seconds between `mining.ping` keep-alive messages | Default `30`. Set to `0` to use legacy behavior (half of `connection_timeout_seconds`) |
| `tcp_keepalive_idle_seconds`, `tcp_keepalive_interval_seconds`, `tcp_keepalive_count`, `tcp_user_timeout_ms` | Advanced (v5.1.0+). Per-coin overrides of the global TCP keepalive settings | Leave unset to use the global values. Editable in `config.json` only. See the [Global Configuration Guide](gss-global-config-guide.md) |

> **Note:** These settings apply to miners on this coin's own stratum port. Miners on the Hash Hopper port (v6.0.0+) use the Hash Hopper's own Stratum and VarDiff settings on every coin they mine, never a coin's. See the [Hash Hopper Guide](gss-hash-hopper-guide.md).

> [!TIP]
> - use d=xxx or diff=xxx in the password field for miner suggested difficulty if your miner does not have a specific way to send mining.suggest_difficulty
> - AxeOS devices have this as Suggested Difficulty in settings for some devices

### Starting Difficulty Guidelines

| Miner Type | Hashrate | Recommended Difficulty |
|----------|--------|----------------------|
| Bitaxe (single) | ~500 GH/s | `256-512` |
| Bitaxe (multiple) | 1-5 TH/s | `1024-4096` |
| Small ASIC | 5-20 TH/s | `4096-8192` |
| Large ASIC | 50+ TH/s | `16384-65536` |

> **Note:** If vardiff is enabled, this is just the starting point - it will auto-adjust based on miner performance.

### Smart Initial Difficulty - AS OF Version 3.0.18

When a miner connects, GSS uses a cascade to determine the best starting difficulty:

1. **Probe difficulty** — A high difficulty (e.g., 65536) is sent immediately with the `mining.subscribe` response, before the miner's identity is known. This prevents a share flood from powerful miners during the brief window before authorization completes.
2. **Password `d=` / `mining.suggest_difficulty`** — If the miner sends a suggested difficulty (via `mining.suggest_difficulty` or `d=XXX`/`diff=XXX` in the password field), and `accept_miner_suggested_diff` is `true`, GSS uses that value.
3. **Historical difficulty** — If the miner (identified by worker name) has connected before during this GSS session, GSS remembers its last vardiff-settled difficulty and uses that. This avoids ramp-up on reconnects.
4. **User agent map** — If the miner's user agent string contains a substring matching a key in `user_agent_difficulty_map`, GSS uses the mapped difficulty. The match is case-insensitive.
5. **Stratum default** — Falls back to the `difficulty` value in the stratum section.

The cascade stops at the first match. After the resolved difficulty is applied, the probe difficulty is replaced with the real starting difficulty and a new job is sent with `clean_jobs: true` so the miner immediately begins working at the correct difficulty.

> **Note:** Historical difficulty is stored in memory and is lost when GSS restarts. Miners that always send `mining.suggest_difficulty` (e.g., Bitaxe, NerdQAxe++) will override historical difficulty — this is by design.

### Worker Name Disambiguation & Consolidation - AS OF Version 3.0.24

When multiple physical miners connect with the same worker name (e.g., two Bitaxes both configured as `wallet.worker1`), disambiguation controls whether GSS appends a numeric suffix to distinguish them.

**Disambiguation (`disambiguation_enabled`):**
- When `true`, GSS appends `-1`, `-2`, etc. to duplicate worker names so each connection gets a unique identity (e.g., `worker1-1`, `worker1-2`).
- When `false` (default), all connections keep the original worker name. Hashrate, shares, and stats are aggregated under the shared name on the dashboard and miner detail page.

**Consolidation (`consolidation_threshold_seconds`):**
- Only applies when `disambiguation_enabled` is `true`.
- When a miner disconnects and reconnects within the threshold (default 3 seconds), GSS reuses the same disambiguated name instead of assigning a new suffix. This prevents suffix churn from brief network interruptions.
- Set to `0` to disable consolidation — every new connection always gets a fresh suffix.

**Auto Worker ID (`auto_worker_id` and `default_worker_id`) - AS OF Version 3.0.27:**
- When a miner connects with just a wallet address (no `.workerID` suffix), GSS can auto-assign a workerID.
- When `auto_worker_id` is `true` (default), GSS assigns a workerID: the `default_worker_id` value if set, otherwise a unique connection ID.
- When `auto_worker_id` is `false`, no workerID is assigned — the bare wallet address becomes the worker name. All miners connecting with the same address are automatically aggregated.
- Setting `default_worker_id` to a custom value like `"default"` means all no-suffix miners for the same address share the same worker name and aggregate (when disambiguation is off).

**Behavior Matrix** — how these three settings interact for miners connecting with just a wallet address (no `.workerID` suffix):

| `auto_worker_id` | `default_worker_id` | `disambiguation_enabled` | Worker Name Result | Behavior |
|:-:|:-:|:-:|---|---|
| `true` | `""` | any | `address.0001A1B2C3D4` | **Default** — each connection gets a unique 12-char hex ID |
| `true` | `"dgb"` | `true` | `address.dgb`, `address.dgb-1`, `address.dgb-2` | Named but disambiguated — each connection is individually tracked |
| `true` | `"dgb"` | `false` | `address.dgb` | **Aggregated** — all no-suffix miners share one logical miner |
| `false` | *(ignored)* | `true` | `address`, `address-1`, `address-2` | Bare address, disambiguated per connection |
| `false` | *(ignored)* | `false` | `address` | **Aggregated** — all same-address miners merge under the bare address |

> [!TIP]
> - Most operators should leave `disambiguation_enabled` at `false` (the default). The dashboard and miner detail page will show combined hashrate and stats for all connections sharing a worker name.
> - Enable disambiguation if you need to track each physical miner individually even when they share a worker name.
> - If disambiguation is enabled, the default 3-second consolidation window is usually sufficient. Increase it only if your miners experience longer reconnect cycles.
> - Set `auto_worker_id` to `false` if you want miners connecting with just a wallet address to be grouped together under the bare address.
> - Use `default_worker_id` with a custom name (e.g., `"miner"`) to give all no-suffix connections a readable shared name instead of individual connection IDs.

---

## Stratum V2 Section - AS OF Version 5.0.0

Stratum V2 is the next-generation mining protocol — a binary, encrypted, authenticated successor to the classic JSON-based Stratum V1. GSS supports **both protocols simultaneously** on different ports per coin, so V1 miners and V2 miners can mine the same pool concurrently with no firmware changes required for V1 devices.

**Important — what V2 is and isn't:**

- **Only `sha256d` algorithm coins** can run V2 (any SHA256d coin, built in or from `coins.json`). Scrypt, Skein, Qubit and Odo coins are Stratum V1 only.
- **Only firmware that supports V2** can use a V2 listener. Tested: NerdQAxe++ (Extended channel), Bitaxe (Extended and Standard channels) and, from v5.2.7, Braiins-based miners such as an S19 on BraiinsOS. V1-only firmware ignores the V2 listener and continues using the V1 port — no breaking changes for existing setups.
- **If you ran V2 in Standard channel mode before v5.2.7,** update: blocks found on a Standard channel were rejected by the node before that release. Extended channel was never affected.
- **V2 requires a one-time key generation step** on the Global Config page. See the [v5.0.0 Stratum V2 Setup Guide](../../release%20notes/GoSlimStratum/v5.0.0-Stratum-V2-Setup-Guide.md) for the walkthrough.
- **V2 is opt-in** — every existing coin pool starts up with V2 disabled. Nothing changes for existing operators until they explicitly enable a V2 listener.

### The `sv2` Array

The per-coin `sv2` field is an **array** of listener entries. Each entry binds one V2 port to one crypto variant. The array form is forward-looking — when additional variants (like SRI) ship in future versions, an operator can add a second entry on a different port without disrupting the first.

```json
"sv2": [
    {
        "variant": "bip324",
        "enabled": true,
        "port": 34254,
        "cert_valid_hours": 24
    }
]
```

| Field | Description | Guidelines |
|-----|-----------|----------|
| `variant` | The SV2 crypto stack. Today only `bip324` is supported (`Noise_NX_Secp256k1+EllSwift_ChaChaPoly_SHA256` with BIP-340 Schnorr cert). | `"bip324"` |
| `enabled` | Whether this listener actually starts. A disabled entry is parsed and validated but the port is not bound. | `true` to enable; `false` to keep the config in place without binding |
| `port` | TCP port miners connect to. Must be unique across this coin's V1 stratum port and all other V2 listeners. Default convention: `34254` (BTC), `34255` (BCH), `34256` (other SHA256d coins). | Any free TCP port. Ports from 32768 to 60999 are also the ones Linux hands out for outgoing connections, so a coin that starts late can find its port taken for a moment ("port is in use"). From v5.5.3 that clears by itself; to avoid it altogether, use a port below 32768 |
| `cert_valid_hours` | Validity window of the server certificate. GSS auto-renews the cert every `cert_valid_hours / 2`, so newly-connecting miners always see a fresh cert. Already-connected miners are unaffected. | `24` (default) |

### Key Files

V2 uses cryptographic keys for the encrypted handshake — but these are configured **globally**, not per-coin (see the [Global Configuration Guide](gss-global-config-guide.md) for the `sv2` section at the top level of `config.json`). The reasoning: one authority public key per pool is what miners paste into their `sv2_auth_pk` NVS field, regardless of which coin they're mining. Per-variant static keys are shared across all coins using that variant.

### Behavior

- **V1 + V2 coexistence:** Both servers fan out from the same job-management pipeline, so block templates, share validation, vardiff, license enforcement, and (when applicable) DTM revenue share all "just work" for V2 miners with no special configuration.
- **Multiple variants per coin:** Add additional entries to the `sv2` array with distinct `variant` values when more variants become available. Each entry uses its own static key (from the global config) but shares the single pool-wide authority key.
- **Non-SHA256d coins:** If the coin's algorithm isn't `sha256d`, the V2 array is silently ignored at startup. The Web UI shows a polite "Stratum V2 is not available for this coin" message instead of the listener editor.
- **Validation:**
  - Each enabled listener requires the global `sv2.authority_key_path` and `sv2.variants.<variant>.static_key_path` to be configured (and the corresponding key files to exist).
  - Port uniqueness is enforced across V1 and all V2 listeners on the same coin AND across coins (no two listeners can share a port).
  - Variant uniqueness within a coin's `sv2` array is enforced (you cannot have two `bip324` listeners on the same coin).

> **Tip:** Start with V2 disabled (`"enabled": false`) on your existing coin configs after upgrading to v5.0.0. Generate keys on the Global Config page, then come back to the coin config, set `enabled: true`, save, and restart GSS. V1 miners continue working throughout — they don't even notice.

---

## Mining Section

Block construction and coinbase settings.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `address` | **Your Node wallet address for block rewards** | Must be a valid address for this coin. Use legacy format (not bech32) for best compatibility |
| `network` | Which network to validate against | `"mainnet"`, `"testnet"` or `"regtest"` |
| `coinbase_text` | Text embedded in blocks you mine | Max ~20 chars. Your pool name/signature - default GoSlimStratum* |
| `extranonce_size` | Bytes reserved for miner nonce space | 8 recommended. Don't change unless you know why |
| `max_job_history` | Number of old jobs to keep for stale share validation | 20 typical. Higher uses more memory |
| `job_expiration_time` | Seconds before a job is considered too old | 300 (5 min) typical |
| `stale_share_grace_period` | Seconds to accept shares after new block | 3-5 typical. Higher = more accepted stales |

### Address Format Notes

All standard address types are supported for each coin:

| Coin | P2PKH (Legacy) | P2SH | Bech32 (SegWit) | Bech32m (Taproot) | CashAddr |
|------|---------------|------|-----------------|-------------------|----------|
| **BTC** | `1...` | `3...` | `bc1q...` | `bc1p...` | — |
| **DGB** | `D...` | `S...` | `dgb1q...` | `dgb1p...` | — |
| **LTC** | `L...` | `M...` | `ltc1q...` | `ltc1p...` | — |
| **DOGE** | `D...` | `9/A...` | — | — | — |
| **BCH** | `1...` | `3...` | — | — | `bitcoincash:q/p...` |
| **XEC** | `1...` | `3...` | — | — | `ecash:q/p...` |
| **BC2** | `1...` | `3...` | `bc1q...` | `bc1p...` | — |
| **BTCS** | `B...` | `3...` | `bs1q...` | `bs1p...` | — |
| **BCH2** | `1...` | `3...` | — | — | `bitcoincashii:q...` (the prefix is optional) |
| **WJK** | `W...` | `3...` | — | — | — |
| **FB** | `1...` | `3...` | `bc1q...` | `bc1p...` | — |

> **Addresses that look like another coin's.** GSS can only check that an address has the right form, and some coins share a form with Bitcoin:
> - **Fractal Bitcoin** addresses look exactly like Bitcoin's, so any Bitcoin address passes the check.
> - **WojakCoin** `3...` addresses start the same way as Bitcoin's, and a Bitcoin `3...` address is accepted. Use a `W...` address where you can.
>
> Use an address from your own wallet for that coin. Never use an exchange's Bitcoin deposit address: coins sent there are most likely lost.

**Testnet and regtest notes:**

- **Fractal Bitcoin's testnet uses mainnet-style addresses** (`1...`, `3...`, `bc1...`), unlike Bitcoin's testnet. Set `network` to `"testnet"` and use the same kind of address you would on mainnet. Fractal regtest uses `m...`, `n...`, `2...` and `bcrt1...` with `network` set to `"regtest"`.
- **WojakCoin** uses `m...`, `n...` and `2...` on testnet and regtest. It has no `wj1...` addresses on mainnet or testnet.

BTC and BC2 also accept `bcrt1` regtest addresses when `network` is set to `"testnet"`.

**Generic coins (coins.json) and CashAddr:** A user-defined coin can opt into CashAddr by adding a `cashaddr` block to its `address` config with the coin's mainnet/testnet prefixes:

```json
"address": {
  "base58": {
    "p2pkh": { "mainnet": 0, "testnet": 111 },
    "p2sh":  { "mainnet": 5, "testnet": 196 }
  },
  "cashaddr": {
    "prefix": { "mainnet": "bitcoincash", "testnet": "bchtest" }
  }
}
```

With the block present, the coin accepts both the CashAddr form (`bitcoincash:q/p...`, or the bare `q.../p...` shorthand) and legacy Base58 (`base58` stays required). The prefix is folded into the CashAddr checksum, so it must exactly match the prefix the coin's wallet issues. Without a `cashaddr` block, a generic coin accepts Base58 (and Bech32 if `segwit` is true) only.

---

## VarDiff Section

Automatic difficulty adjustment per miner. Adjusts difficulty so each miner submits shares at a consistent rate.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `enabled` | Turn on automatic difficulty adjustment | `true` recommended for mixed miner sizes |
| `useFloatDiff` | Allow GSS to use float64 diff values (i.e. 0.0001) | Default set to `false` if not defined |
| `floatDiffBelowOne` | Only use float difficulty for sub-1 values, integer for >= 1 | Default `true`. Prevents firmware precision issues on Canaan/AxeOS devices at high difficulty magnitudes. Only applies when `useFloatDiff` is `true` |
| `floatDiffPrecision` | Decimal places for float difficulty values | `4` default. Range: 0-15. Only applies when `useFloatDiff` is `true`. Some firmware (e.g., Canaan Nano3S) can't handle more than ~4-5 decimal places |
| `minDiff` | Lowest difficulty allowed | 256-512 for small miners (Bitaxe) |
| `maxDiff` | Highest difficulty allowed | 32768-65536 typical. Use `-1` for unlimited, caution -1 could set a pool diff higher than network diff - resulting in lost blocks! |
| `targetTime` | Target seconds between shares | 10-15 for responsive feedback, 30 for less traffic |
| `retargetTime` | Seconds between difficulty adjustments | 90-180 typical. Lower = faster response |
| `variancePercent` | Acceptable deviation before adjusting | 30 typical. Higher = less frequent changes |
| `onNewBlock` | Only apply vardiff changes on new block/job boundaries | Default `true`. Set to `false` to send difficulty changes immediately without waiting for a new block (useful on slow blockchains like BTC). No hash power is wasted — miner keeps working on the same block template |

### Flood Protection (Sub-Section) - AS OF Version 3.0.15

Flood protection addresses a specific problem: when a powerful miner connects at a low starting difficulty, varDiff can only adjust difficulty at job boundaries (when a new block is found). With a 4x max increase per retarget, ramping from a very low difficulty to an appropriate level can take a long time — during which the miner floods the pool with trivial shares.

When enabled, flood protection monitors share submission rate during initial connection ramp-up. If shares arrive significantly faster than `targetTime`, it sends an emergency `mining.set_difficulty` immediately (out-of-band, without waiting for a new block) and re-sends the current job so the miner begins working at the new difficulty right away.

Flood protection automatically deactivates after the miner's first normal varDiff retarget, meaning the miner has settled into a normal share rate. If the miner reconnects, flood protection re-enables.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `enabled` | Enable flood protection during initial ramp-up | `false` by default. Enable for pools with wide difficulty ranges or low starting difficulty |
| `sharesToCheck` | Minimum shares to analyze before triggering | `4` default. Lower values trigger faster but with less data |
| `triggerThreshold` | Trigger when avg share time < `targetTime * triggerThreshold` | `0.25` default (triggers when shares arrive 4x faster than target). Range: 0.01-1.0 |
| `maxAdjustmentMultiplier` | Maximum difficulty multiplier per emergency adjustment | `16` default. Emergency diff is capped at `currentDiff * multiplier` and also by `maxDiff` |

> [!TIP]
> - Flood protection is most useful when `useFloatDiff` is `true` and starting difficulty is very low (e.g., 0.001 for BTC/BCH). In this scenario, ramp-up from 0.001 to an appropriate difficulty happens in seconds instead of hours.
> - For pools where all miners are similar size and starting difficulty is close to optimal, flood protection can be left disabled.
> - The `maxAdjustmentMultiplier` of 16 means each emergency adjustment can jump up to 16x. Starting at 0.001: 0.001 → 0.016 → 0.256 → 4.096 → 65.5 → 1048 (5 iterations, seconds).

### Quick Presets

> **Note:**  Tuning VarDiff takes experiementation, each operator has their own preferences

| Scenario | minDiff | maxDiff | targetTime | retargetTime |
|--------|:-----:|:-----:|:--------:|:----------:|
| Bitaxe only | 256 | 32768 | 15 | 90 |
| Mixed miners | 512 | 65536 | 15 | 180 |
| Large ASICs only | 4096 | -1 * | 10 | 120 |

### How VarDiff Works

1. Pool measures how often each miner submits shares
2. If shares come faster than `targetTime`, difficulty increases
3. If shares come slower than `targetTime`, difficulty decreases
4. Adjustments happen every `retargetTime` seconds
5. Difficulty stays within `minDiff` and `maxDiff` bounds
6. **CAUTION** setting `maxDiff` to -1 can lead to lost blocks!

---

## Alerts Section (Coin Alerts) - AS OF Version 5.1.0

Per-coin alerts on noteworthy shares, rejected shares and network difficulty. They are set in the **Coin Alerts** panel on the coin's Configuration page, and sent through your notification channels.

> **Requires** notifications (a licensed feature) and metrics (PostgreSQL) to be enabled. Without both, the panel does nothing.

```json
"alerts": {
    "enabled_coin_alerts": true,
    "best_share_minimum_value": 1000000000,
    "notable_share_minimum_value": 0,
    "notable_share_max_alert_rate": 10,
    "share_rejection_threshold_count": 20,
    "share_rejection_window_minutes": 10,
    "share_rejection_max_alert_rate": 0,
    "network_difficulty": {
        "enabled": false,
        "below_threshold": 0,
        "above_threshold": 0
    }
}
```

| Field | Description | Guidelines |
|-----|-----------|----------|
| `enabled_coin_alerts` | Master switch for this coin's alerts | `false` default |
| `best_share_minimum_value` | **Best Share alert.** Fires once when any miner sets a new pool-wide best share at or above this value | In the units the miner card's Best Share shows. `0` = off |
| `notable_share_minimum_value` | **Notable Share alert.** Fires every time any miner submits a share at or above this value, record or not | Same units. `0` = off |
| `notable_share_max_alert_rate` | Most Notable Share alerts per miner per hour | `10` = at most one every 6 minutes per miner. `0` = unlimited. A share at least twice the last one alerted on breaks through the limit |
| `share_rejection_threshold_count` | **Rejected Shares alert.** Rejections by one miner, inside the window, that fire the alert | `0` = off. Stale shares count as rejections. The count starts again after the alert fires |
| `share_rejection_window_minutes` | How far back rejections are counted | `10` default |
| `share_rejection_max_alert_rate` | Most Rejected Shares alerts per miner per hour | `0` = no cap |
| `network_difficulty.enabled` | Turn the **Network Difficulty alert** on | `false` default |
| `network_difficulty.below_threshold` | Fires when network difficulty drops below this value | Raw units, the number the dashboard's Network Difficulty tile shows. `0` = off |
| `network_difficulty.above_threshold` | Fires when network difficulty rises above this value | Raw units. `0` = off. If both are set, below must be less than above |

- In the web UI the value fields accept SI suffixes: `1G`, `1.5G` or `1000000000`.
- The Network Difficulty alert fires when a threshold is crossed, once, and again when difficulty comes back inside the band (a recovery alert).
- **Thresholds apply as soon as you save.** No pool restart is needed, and the pool-best record and rejection counts are kept.
- **Where each alert is sent** (which channels) is chosen on the Notifications page, under Best Share, Notable Share, Rejected Shares and Network Difficulty (Coin Alerts). See the Events section of the [Global Configuration Guide](gss-global-config-guide.md).

---

## Payout Section

Automatic payment processing settings.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `enabled` | Enable automatic payouts | `true` for automatic, *`false` for manual payouts |
| `pool_fee_percent` | Your pool's fee percentage | `1.0` = 1% fee. Range: 0-100 |
| `maturity_confirmations` | Blocks before reward is spendable | **Coin-specific** - see table below |
| `payment_interval_seconds` | How often to process pending payments | 600 (10 min) typical |
| `minimum_confirmations` | Confirmations needed before payment considered complete | 6 typical for most coins |
| `maturity_check_interval_seconds` | How often to check if blocks matured | 60 typical |
| `confirmation_check_interval_seconds` | How often to check payment confirmations | 300 (5 min) typical |
| `wallet_rpc_timeout_seconds` | Timeout for wallet RPC calls | 30 typical. Increase if wallet is slow |

> **\*CAUTION** Setting payout to `false` will disable payout system and associated metrics for rewards.

### Maturity Confirmations by Coin

| Coin | Typical Maturity | Notes |
|----|:--------------:|-----|
| DGB (DigiByte) | 100 | Standard coinbase maturity |
| BTC (Bitcoin) | 100 | Standard coinbase maturity |
| BCH (Bitcoin Cash) | 100 | Standard coinbase maturity |
| XEC (eCash) | 10 | Uses Avalanche finalization (faster) |
| LTC (Litecoin) | 100 | Standard coinbase maturity |
| DOGE (Dogecoin) | 240 | Higher maturity requirement |
| BC2 (Bitcoin II) | 100 | Standard coinbase maturity |
| BTCS (Bitcoin Silver) | **200** | Twice the usual. Lower than 200 and payouts fail with "insufficient funds" |
| BCH2 (Bitcoin Cash II) | 100 | Standard coinbase maturity |
| WJK (WojakCoin) | 20 | The default of 100 is safe but pays out later |
| FB (Fractal Bitcoin) | 100 | Standard coinbase maturity |

> **Note:** `maturity_confirmations` defaults to `100`. For a coin whose rewards mature later than that (BTCS), you must raise it yourself. A coin added in `coins.json` may also need more than 100: check that coin's own rules.

### Understanding Satoshis

All amounts are in satoshis (the smallest unit):

- `100000000` satoshis = 1 coin (for 8-decimal coins like BTC, DGB, BCH)
- `100` satoshis = 1 XEC (XEC uses 2 decimals, so 100 satoshis = 1 XEC)

---

## Explorer Section

Settings for the built-in block explorer (v4.1.0+). The explorer queries the coin's blockchain node to display block details, block lists, mempool info, and transaction details within the GSS web UI — no external block explorer required.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `use_rest_api` | Use the node's REST API instead of JSON-RPC for explorer calls | `false` default (uses RPC). Set to `true` if your node has `rest=1` enabled — REST is simpler and requires no authentication |
| `use_alternate_host` | Route explorer calls to the alternate host instead of the primary node | `false` default. Set to `true` to offload explorer queries to a secondary node, keeping the primary node dedicated to mining |

> **Note:** The explorer feature is available to all users — no license required. Data is fetched live from the node on each page hit (no polling, no database). Explorer pages are accessible at `/coin/{COIN}/explorer`.

> **Tip:** For operators running high-hashrate pools, configure an alternate host for explorer calls to avoid adding load to the mining-critical primary node.

---

## Common Mistakes to Avoid

### 1. Wrong RPC Credentials

**Problem:** Pool can't connect to node

**Solution:** Credentials must exactly match your node's config file (`rpcuser` and `rpcpassword`)

### 2. Address/Network Mismatch

**Problem:** Address validation fails on startup

**Solution:** Testnet addresses only work with `"network": "testnet"`. Mainnet addresses require `"network": "mainnet"`

### 3. Starting Difficulty Too High

**Problem:** Miners connect but never find shares, eventually disconnect

**Solution:** Start with lower difficulty (512-1024) and let vardiff adjust upward

### 4. Starting Difficulty Too Low

**Problem:** Pool flooded with shares, high CPU/bandwidth usage

**Solution:** Increase starting difficulty or lower vardiff `minDiff`. If you need low starting difficulty for small miners, enable `floodProtection` to handle powerful miners that connect at the low difficulty

### 5. Maturity Too Low

**Problem:** Payout fails with "immature coinbase" or "insufficient funds"

**Solution:** Set `maturity_confirmations` to at least the coin's required maturity (usually 100; **200 for Bitcoin Silver**). See the table in the Payout section

### 6. ZMQ Not Configured on Node

**Problem:** Pool falls back to slower polling, delayed new block detection

**Solution:** Add `zmqpubhashblock=tcp://0.0.0.0:28332` to node config and restart node

### 7. Wallet Locked

**Problem:** Payouts fail with "wallet locked" error

**Solution:** Set `wallet_passphrase` in the coin's node config section. GSS will automatically unlock the wallet for each payout and re-lock it immediately after. The passphrase is auto-encrypted in config.json on first startup. Alternatively, use an unencrypted wallet.

### 8. Merged Mining Without an Aux Address

**Problem:** A miner on a merged-mining parent finds no aux (DOGE) blocks and shows no **M** badge

**Solution:** Since v5.2.3 each miner opts in with its own aux address in the username: `PARENTADDRESS|DOGEADDRESS.workername`

### 9. A Wallet Address on the Hash Hopper Port

**Problem:** A miner pointed at the Hash Hopper port with `address.worker` as its username is refused

**Solution:** The Hash Hopper port takes `hopper.<profile>` or `hopper.<profile>.<rig>`, never an address. Payout addresses are set in the profile. See the [Hash Hopper Guide](gss-hash-hopper-guide.md)

For more symptoms and what they mean, see the [Troubleshooting Guide](gss-troubleshooting-guide.md).

---

## Using a Coin with the Hash Hopper - AS OF Version 6.0.0

The Hash Hopper moves SHA256d miners between your coins on a port of its own. Nothing in a coin's configuration turns it on, but a coin can only take hopper miners when it:

- uses the `sha256d` algorithm,
- is running,
- is in Direct-to-Miner mode (`enable_dtm`, with a license or accepted revenue share),
- is not a merged-mining parent, and
- has the same `extranonce_size` as the other coins the hopper uses.

A block found by a hopper miner is built by that coin exactly as for its own Direct-to-Miner miners, so the coin's pool fee, revenue share and maturity settings apply. Everything else is in the [Hash Hopper Guide](gss-hash-hopper-guide.md).

---

## Testing Your Configuration

1. **Validate JSON syntax:** Use a JSON validator before starting
2. **Check node connectivity:** Ensure node is running and RPC is accessible
3. **Test on testnet first:** Use testnet to verify everything works
4. **Monitor logs:** Watch for connection errors or validation failures
5. **Start with one miner:** Verify shares are accepted before adding more

---

*\* Requires license to customize*
