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
    "coin_type": "digibyte",
    "display_name": "DigiByte Mainnet",
    "node": {
        "host": "127.0.0.1",
        "port": 9001,
        "username": "your_rpc_username",
        "password": "your_rpc_password",
        "use_ssl": false,
        "wallet_name": "default",
        "zmq_block_notify": "tcp://127.0.0.1:28332",
        "template_refresh_interval": 15,
        "zmq_enabled": true,
        "zmq_stale_detection_time": 120,
        "dual_node_comm": true
    },
    "stratum": {
        "host": "0.0.0.0",
        "port": 3333,
        "difficulty": 4096,
        "accept_miner_suggested_diff":false,
        "connection_timeout_seconds": 600,
        "ping_enabled": true
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
        "minDiff": 512,
        "maxDiff": 32768,
        "targetTime": 15,
        "retargetTime": 180,
        "variancePercent": 30
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
    }
}
```


## Top-Level Fields

| Field | Description | Example |
|-----|-----------|-------|
| `enabled` | Whether this coin is active. Set to `false` to disable without removing config. | `true` |
| `coin_type` | The coin implementation to use. | `"digibyte"`, `"bitcoin"`, `"bitcoincash"`, `"ecash"` |
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
| `zmq_block_notify` | ZMQ endpoint for instant block notifications | Format: `"tcp://IP:PORT"`. Requires node ZMQ config. |
| `template_refresh_interval` | Seconds between block template polls | 15-30 seconds typical. Lower = more network traffic |
| `zmq_enabled` | Use ZMQ for instant new block detection | `true` recommended if node supports ZMQ |
| `zmq_stale_detection_time` | Seconds before falling back to polling if ZMQ silent | 120 default. Adjust to block time for defined coin |
| `dual_node_comm` | Enable ZMQ + Polling, recommended | Default set to `false` if not defined |

### ZMQ Setup

Add this to your node's config file (e.g., `digibyte.conf`):

```
zmqpubhashblock=tcp://0.0.0.0:28332
```

Then set `zmq_block_notify` to match: `"tcp://127.0.0.1:28332"`

---

## Stratum Section

Settings for miners connecting to your pool.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `host` | IP to listen on | `"0.0.0.0"` to accept all connections |
| `port` | Port miners connect to | Pick unique port per coin (3333, 3334, etc.) |
| `difficulty` | Starting difficulty for new miners | **See table below** |
| `accept_miner_suggested_diff`| Accept starting diff value sent from miner | Default set to `false` if not defined |
| `connection_timeout_seconds` | Disconnect idle miners after this many seconds | 600 (10 min) typical. No change recommended |
| `ping_enabled` | Attempt to use mining.ping with miners | Default set to `true` if not defined |

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

- **DGB:** Use legacy `D...` address (not `dgb1...` bech32)
- **BTC:** Use legacy `1...` or `3...` address (not `bc1...` bech32)
- **BCH:** Use CashAddr format `bitcoincash:q...`
- **XEC:** Use eCash format `ecash:q...`

---

## VarDiff Section

Automatic difficulty adjustment per miner. Adjusts difficulty so each miner submits shares at a consistent rate.

| Field | Description | Guidelines |
|-----|-----------|----------|
| `enabled` | Turn on automatic difficulty adjustment | `true` recommended for mixed miner sizes |
| `useFloatDiff` | Allow GSS to use float64 diff values (i.e. 0.0001) | Default set to `false` if not defined |
| `minDiff` | Lowest difficulty allowed | 256-512 for small miners (Bitaxe) |
| `maxDiff` | Highest difficulty allowed | 32768-65536 typical. Use `-1` for unlimited, caution -1 could set a pool diff higher than network diff - resulting in lost blocks! |
| `targetTime` | Target seconds between shares | 10-15 for responsive feedback, 30 for less traffic |
| `retargetTime` | Seconds between difficulty adjustments | 90-180 typical. Lower = faster response |
| `variancePercent` | Acceptable deviation before adjusting | 30 typical. Higher = less frequent changes |

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

### Understanding Satoshis

All amounts are in satoshis (the smallest unit):

- `100000000` satoshis = 1 coin (for 8-decimal coins like BTC, DGB, BCH)
- `100` satoshis = 1 XEC (XEC uses 2 decimals, so 100 satoshis = 1 XEC)

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

**Solution:** Increase starting difficulty or lower vardiff `minDiff`

### 5. Maturity Too Low

**Problem:** Payout fails with "immature coinbase" error

**Solution:** Set `maturity_confirmations` to at least the coin's required maturity (usually 100)

### 6. ZMQ Not Configured on Node

**Problem:** Pool falls back to slower polling, delayed new block detection

**Solution:** Add `zmqpubhashblock=tcp://0.0.0.0:28332` to node config and restart node

### 7. Wallet Locked

**Problem:** Payouts fail with "wallet locked" error

**Solution:** Unlock wallet with `walletpassphrase` command before starting pool, or use unencrypted wallet

---

## Testing Your Configuration

1. **Validate JSON syntax:** Use a JSON validator before starting
2. **Check node connectivity:** Ensure node is running and RPC is accessible
3. **Test on testnet first:** Use testnet to verify everything works
4. **Monitor logs:** Watch for connection errors or validation failures
5. **Start with one miner:** Verify shares are accepted before adding more

---

*\* Requires license to customize*
