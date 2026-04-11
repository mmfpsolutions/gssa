# GoSlimStratum Coin Configuration Guide

Complete reference for configuring coins in your mining pool.

---

## Summary

In GoSlimStratum (GSS), each coin can be configured to uniquely cater to the specific mining properties for that blockchain. Below is a description of each configuration field, and some basic rules on how to adjust them.

Every mining device, every blockchain, every network, every internet connection, every host machine (for GSS) can be different. The beauty of GSS is that those differences can be accommodated by way of configuration thereby allowing the operator to achieve maximum hashrate, stability and efficiency. This also presents opportunity for an operator to configure the system to be suboptimal, so careful consideration should be taken when adjusting coin configurations.

> **Note:** Configuration fields can be edited in the GSS WebUI or via direct edits to the config.json file. It is recommended that edits be done with the WebUI. A restart is required after any changes to a coin configuration!

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
| `coin_type` | The coin implementation to use. | `"digibyte"`, `"bitcoin"`, `"bitcoincash"`, `"ecash"`, `"litecoin"`, `"dogecoin"`, `"bitcoinii"` |
| `algorithm` | Mining algorithm. Set automatically for most coins. DGB supports multiple algorithms on the same instance. | `"sha256d"` (default), `"scrypt"`, `"skein"`, `"qubit"` |
| `display_name` | Human-readable name shown in the web dashboard. | `"DigiByte Mainnet"` |

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
| `zmq_stale_detection_time` | Seconds before falling back to polling if ZMQ silent | 120 default. Adjust to block time for defined coin |
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

### Merged Mining (AuxPoW) - AS OF Version 4.1.0

Merged mining lets your miners simultaneously mine a parent chain and one or more aux (auxiliary) chains using the same hashrate — no extra work, no extra hardware. The classic example is **LTC → DOGE**: scrypt miners hashing for Litecoin can also produce Dogecoin blocks, since DOGE accepts AuxPoW (Auxiliary Proof of Work) blocks proven by LTC's parent chain.

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

If the DOGE address is omitted, GSS falls back to the DOGE pool's `mining.address` config field. Backward compatible — existing miners without pipe syntax continue working unchanged.

**How it works:**

1. The aux chain (DOGE) is polled for new block templates via `getblocktemplate`
2. GSS embeds an AuxPoW commitment (DOGE block hash) in the parent chain's (LTC) coinbase scriptSig
3. Miners hash LTC headers as normal
4. Every accepted LTC share is also checked against the DOGE difficulty target
5. When a share meets the DOGE target, GSS constructs a full DOGE AuxPoW block and submits it via the DOGE node's `submitblock` RPC
6. Block found notifications fire independently for both LTC and DOGE blocks

**Dashboard:**

- **Parent dashboard (LTC):** Orange `Merged → DOGE` badge in the status area. Each connected miner shows an orange `(M)` indicator next to their worker ID.
- **Aux dashboard (DOGE):** Orange `AuxPoW ← LTC` badge in the status area. DOGE blocks found via merged mining appear in the Recent Blocks card with the same display as standalone-mined blocks.

**Graceful degradation:**

- If the aux node (DOGE) goes offline, jobs are built without the AuxPoW commitment and LTC-only mining continues. When the aux node comes back, the commitment resumes automatically.
- If `merged_mining` is not set on either coin, behavior is identical to standalone pools — there is zero performance or correctness impact.

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

## Mining Section

Block construction and coinbase settings.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `address` | **Your Node wallet address for block rewards** | Must be a valid address for this coin. Use legacy format (not bech32) for best compatibility |
| `network` | Which network to validate against | `"mainnet"` or `"testnet"` |
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

BTC and BC2 also accept `bcrt1` regtest addresses when `network` is set to `"testnet"`.

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

**Problem:** Payout fails with "immature coinbase" error

**Solution:** Set `maturity_confirmations` to at least the coin's required maturity (usually 100)

### 6. ZMQ Not Configured on Node

**Problem:** Pool falls back to slower polling, delayed new block detection

**Solution:** Add `zmqpubhashblock=tcp://0.0.0.0:28332` to node config and restart node

### 7. Wallet Locked

**Problem:** Payouts fail with "wallet locked" error

**Solution:** Set `wallet_passphrase` in the coin's node config section. GSS will automatically unlock the wallet for each payout and re-lock it immediately after. The passphrase is auto-encrypted in config.json on first startup. Alternatively, use an unencrypted wallet.

---

## Testing Your Configuration

1. **Validate JSON syntax:** Use a JSON validator before starting
2. **Check node connectivity:** Ensure node is running and RPC is accessible
3. **Test on testnet first:** Use testnet to verify everything works
4. **Monitor logs:** Watch for connection errors or validation failures
5. **Start with one miner:** Verify shares are accepted before adding more

---

*\* Requires license to customize*
