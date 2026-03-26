# GoSlimStratum — Release Notes
## v3.0.15 through v4.0.0

---

## v4.0.0

### Multi-Algorithm Mining Support

GoSlimStratum now supports multiple mining algorithms. Run SHA256d, Scrypt, Skein, and Qubit on the same instance — each with independent share validation, difficulty tracking, and metrics.

| Algorithm | Coins | Typical Miners |
|-----------|-------|----------------|
| SHA256d | BTC, DGB, BCH, XEC, BC2, custom coins | Bitaxe, Antminer, NerdQAxe++, Canaan Nano3S |
| Scrypt | DGB, LTC, DOGE | Antminer L7/L9, Goldshell Mini-DOGE, GPU, CPU |
| Skein | DGB | Baikal BK-G28, GPU |
| Qubit | DGB | Baikal BK-G28, GPU |

**DigiByte Multi-Algorithm**: Run up to 4 algorithm pools for DGB on a single instance sharing one node. Each pool has its own stratum port and difficulty settings. Select the algorithm in the coin configuration page.

**Configuration**: Set `"algorithm": "scrypt"` (or `"skein"`, `"qubit"`) in the coin config. DGB defaults to SHA256d. LTC and DOGE default to scrypt automatically.

### New Built-in Coins

**Litecoin (LTC)** — Full scrypt mining support with MWEB (MimbleWimble Extension Block) block submission. DTM mode and pool mode with payouts. Revenue share available. Address validation for P2PKH (`L`), P2SH (`M`), and Bech32 (`ltc1q`). 100 confirmation maturity.

**Dogecoin (DOGE)** — Scrypt mining support. DTM mode only (pool mode payouts not supported due to DOGE Core legacy RPC). Revenue share available. Address validation for P2PKH (`D` mainnet). 240 confirmation maturity. No SegWit.

**Bitcoin II (BC2)** — SHA256d mining support as a built-in coin with DTM mode and revenue share. If you previously had BC2 configured via `coins.json`, set `"coin_type": "bitcoinii"` in your config — the `coins.json` entry is no longer needed.

### Direct-to-Miner (DTM) Mode

Block rewards go directly to the miner's wallet via the coinbase transaction. No payout system, no waiting. When your pool finds a block, the reward is embedded in the coinbase with your wallet address as the primary output. Spendable after maturity confirmations. Pool operators collect fees as a second coinbase output, automatically deducted from each block.

DTM can be enabled per coin — run some coins in pool mode and others in DTM on the same instance. Works with all algorithms.

**How to enable DTM:**
- **With a license**: Toggle DTM on in the coin's configuration page — done.
- **Without a license**: Toggle DTM on and accept a 0.5% revenue share on block rewards. Available for built-in coins (DGB, BTC, BCH, XEC, LTC, DOGE, BC2) only.
- **Custom coins** (coins.json): DTM requires a license. Revenue share is not available for custom coins.

See the [DTM Best Practices Guide](v4.0.0-Direct-to-Miner-Best-Practices.md) for recommended settings and screenshots.

### API Key Authentication (Port 4004)

Operators can protect the `:4004` API with a simple API key, useful when exposing the API externally for ETL scripts or monitoring.

- Configured via separate `apikey.json` file (never exposed via API)
- Disabled by default. Missing file = disabled
- When enabled, all non-exempt API calls require `X-API-Key` header
- Requires a valid license — the API key is an additional security layer, not a license bypass

```json
{
  "enabled": true,
  "key": "your-secret-api-key"
}
```

```bash
curl -H "X-API-Key: your-secret-api-key" http://host:4004/api/v1/DGB/metrics/pool
```

### Web UI Authentication (Port 3003)

Operators can require username/password login for the web dashboard. Protects all pages and API proxy calls on port 3003.

- Configured via separate `userauth.json` file (not in config.json)
- Disabled by default. Missing file = disabled
- Requires a valid license
- Multiple users supported with bcrypt-hashed passwords
- Session-based with configurable timeout (default 24 hours)
- After login, redirects to the originally requested page

**Security Note:** Credentials are transmitted over HTTP. For internet-facing deployments, place a reverse proxy with HTTPS in front of GSS.

```json
{
  "enabled": true,
  "session_timeout_minutes": 1440,
  "users": [
    {
      "uid": "user1",
      "username": "admin",
      "password": "$2a$10$BCRYPT_HASH_HERE"
    }
  ]
}
```

**Generating a bcrypt password hash:**
```bash
python3 -c "import bcrypt; print(bcrypt.hashpw(b'your-password', bcrypt.gensalt()).decode())"
```

### Earnings Page — Direct Payouts

When running in DTM mode, the earnings page shows a "Direct Payouts" table listing every block your miners found, with the miner's address, worker name, reward amount, and maturity status (Immature → Spendable).

### Dashboard — Block Odds Card

A new "Block Odds" card shows your pool's share of the network hashrate, estimated time to find a block, and projected blocks per day/month. Updates every 30 seconds. Collapsible.

### Wallet Address Mismatch Warning

If the payout address doesn't belong to the node wallet, a red warning banner appears on the dashboard. This catches a common setup mistake. The warning only appears in pool mode — DTM mode intentionally allows external addresses.

### Bug Fixes

- **Early orphan detection** — Orphaned blocks detected immediately on every maturity check, not just at full maturity
- **Version rolling compatibility** — Fixed block submission failure for miners without BIP310 version rolling support. Applied to all coin implementations
- **DTM config warning** — Yellow banner when DTM settings changed but pool not restarted
- **Miner detail page** — DTM blocks now show "Spendable" instead of stuck on "Pending"
- **Payout mode gating** — Fixed payout mode to use runtime DTM state instead of raw config value
- **Time-to-block overflow** — Fixed negative display values for very large estimates (>292 years)
- **Block matured notification** — DTM blocks now show "Spendable" instead of "Ready for payout" in notifications

### UI Improvements

- **Algorithm badge** — Non-SHA256d pools show a purple algorithm badge on the dashboard
- **Algorithm selector** — DGB coin config shows Mining Algorithm dropdown (SHA256d, Scrypt, Skein, Qubit)
- **Best Share on mobile** — tap to see submission details (previously hover-only)
- **Earnings tables on mobile** — horizontal scroll on small screens
- **Network charts** — removed 7-day option, consistent with miner detail charts
- **Better validation feedback** — save errors list specific fields

### Database

This release includes automatic database schema updates. Applied on first start — no manual steps needed. Existing data is unaffected.

### Upgrade Notes

- Existing configurations work without changes. New features (DTM, multi-algo, auth) are all off by default.
- LTC and DOGE coin types automatically default to scrypt algorithm.
- DGB defaults to SHA256d — change via config page or `"algorithm"` field in config.json.
- If you enable DTM, lower `max_job_history` to 5 and `check_interval_seconds` to 120. See the [DTM Best Practices Guide](v4.0.0-Direct-to-Miner-Best-Practices.md).
- DOGE is DTM mode only — pool mode payouts are not supported.
- API key and web UI auth require separate config files (`apikey.json`, `userauth.json`). See examples above.

---

## v3.0.30

**BIP34 Coinbase Height Encoding Fix**

Fixed a bug in `serializeHeight()` where block heights with the high bit set in the most significant byte were encoded incorrectly in the coinbase scriptSig. In Bitcoin's script number encoding, the high bit is the sign bit — a raw `0x80` byte is interpreted as negative zero, not 128. The fix appends a `0x00` padding byte when the high bit is set, keeping the value positive per the BIP34 specification.

Without this fix, blocks found at affected heights are rejected by the node with `bad-cb-height, block height mismatch in coinbase`. On mainnet, the block reward is silently lost (other miners advance the chain past the affected height). On regtest, the chain stalls entirely if the pool is the sole miner.

Affected heights follow the pattern where the MSB of the final encoded byte has bit 7 set: 128–255, 32768–65535, 8,388,608–16,777,215, etc. Current mainnet chains (BTC ~940K, BCH ~942K, DGB ~23M, XEC ~940K) are not at affected heights today. The next affected height for BTC/BCH/XEC is 8,388,608 (~14 years at 10-minute blocks). DGB's next affected height is 2,147,483,648 (~10,900 years at 15-second blocks).

The fix was applied to all five coin implementations: Bitcoin, Bitcoin Cash, DigiByte, eCash, and Generic.

---

## v3.0.29

**Float Diff Below One — Firmware-Safe Float Difficulty**

When `useFloatDiff` is enabled, the pool can now restrict float precision to sub-1 difficulty values only, sending integer difficulty for values >= 1. This is controlled by the new `floatDiffBelowOne` setting (default: `true`).

This resolves a firmware compatibility issue discovered on Canaan Nano3S (and potentially other ASIC devices) where float difficulty at high magnitudes (100K+) caused CRC/COM_CRC errors on the chip data bus. The root cause is that embedded miner firmware typically uses float32 internally, which only supports ~7 significant digits. A difficulty like `103297.0000` (10+ significant digits) exceeds float32 precision, causing the firmware to misinterpret the value and produce hardware errors.

With `floatDiffBelowOne` enabled:
- Difficulty < 1 (e.g., `0.0038`, `0.022`) — sent as float with configured precision. Ideal for tiny miners like NerdMiner and ESP32 devices.
- Difficulty >= 1 (e.g., `4096`, `103297`) — rounded to integer. Safe for all ASIC firmware including Canaan and AxeOS devices that truncate or can't process float difficulty.

This gives operators the best of both worlds: precise sub-1 difficulty for low-hashrate hobby miners, and clean integers for everything else.

The setting is available in the vardiff config, the Web UI config page, and the Add Coin form.

---

## v3.0.28

**Bech32 Coinbase Output Script Support**

The pool now supports Bech32 (SegWit) mining addresses for coinbase outputs. Previously, only legacy and P2SH addresses were supported for the `mining.address` field. Starting in v3.0.28, operators can use native SegWit addresses — both P2WPKH (`bc1q...`, `dgb1q...`) and P2WSH (`bc1q...` 62-char, `dgb1q...` 62-char) — as their payout address. The pool detects the address type automatically and constructs the correct coinbase output script. This applies to the DigiByte and Generic coin handlers. Bitcoin and Bitcoin Cash handlers already supported SegWit via their existing implementations.

**Password-Protected Node Wallet Support**

Operators whose node wallets are encrypted (password-protected) can now configure the wallet passphrase in `config.json`. Previously, the payout system would fail with a "wallet locked" error because `signrawtransactionwithwallet` requires an unlocked wallet.

How it works:
- Add the wallet passphrase to the `wallet_passphrase` field in the coin's node section.
- On first startup, GSS automatically encrypts the plaintext passphrase in-place using AES-256-GCM. The config file is rewritten with the encrypted value (prefixed with `ENC:`), so the plaintext passphrase never persists on disk after the first run.
- During payouts, GSS decrypts the passphrase, unlocks the wallet for the minimum time needed (fund + sign + broadcast), then immediately re-locks it.
- If a passphrase is configured but the wallet is not actually encrypted, GSS logs a warning and proceeds normally.

The `wallet_passphrase` field is also available in the Web UI configuration page and the Add Coin form.

**Configurable Ping Interval with Dead Connection Detection**

The `ping_interval_seconds` setting allows operators to control how frequently `mining.ping` keep-alive messages are sent to miners. Previously, the interval was always half the connection timeout. Now it can be set explicitly per coin. Default: 30 seconds. Set to `0` to use the legacy behavior (half the connection timeout).

Ping is also now used for dead connection detection. If a miner that previously responded to pings fails to reply (no PONG) before the next ping interval, GSS closes the connection automatically. This means ghost connections from miners that disconnect without a clean TCP close (e.g., power loss, network failure, unplugged devices) are detected within 1-2 ping intervals (~30-60 seconds at default settings) instead of waiting for the full connection timeout (default: 600 seconds).

**Adaptive Share Acceptance for Ultra-Low Hashrate Devices**

Miners operating below 1 difficulty (e.g., NerdMiners, ESP32-based hobby miners) now benefit from adaptive share validation. The pool's share handler recognizes when a miner's assigned difficulty is sub-1 and applies a streamlined acceptance path that eliminates unnecessary rejection overhead. These devices contribute negligible hashrate relative to the pool, and their shares are accepted without the standard difficulty comparison — reducing log noise and improving the mining experience for hobbyist devices. Block candidate evaluation remains fully intact regardless of share difficulty, so any share that meets the network target is still submitted normally.

**Mid-Block VarDiff Adjustments**

A new `onNewBlock` setting in the vardiff config controls when difficulty changes are delivered to miners. When `true` (the default, matching previous behavior), difficulty adjustments are queued and sent alongside the next new block job. When `false`, difficulty changes are sent immediately — `mining.set_difficulty` followed by a `mining.notify` with the same block template and `clean_jobs=false`. The miner applies the new difficulty without discarding work. No hash power is wasted in either mode.

This is useful on slow blockchains (e.g., BTC at ~10 minute blocks) where waiting for a new block before adjusting difficulty means miners can be at the wrong difficulty for minutes. The job resend ensures compatibility with ASIC miners (e.g., bitaxe) that only apply difficulty changes when they receive a new job. The existing `previousDifficulty` grace period handles any in-flight shares at the old difficulty, so no shares are rejected during the transition.

---

## v3.0.27

**Auto Worker ID and Default Worker ID**

Two new stratum settings give operators control over how miners connecting without a `.workerID` suffix are identified:

- `auto_worker_id` (default: `true`) — When enabled, GSS auto-assigns a workerID to miners that connect with just a wallet address. When disabled, the bare wallet address becomes the worker name.
- `default_worker_id` (default: `""`) — When `auto_worker_id` is `true` and this is set to a custom value (e.g., `"default"`), all no-suffix miners for the same address share that worker name and aggregate under it. When empty, each connection gets a unique 12-character hex ID.

**Disambiguation Default Changed**

`disambiguation_enabled` now defaults to `false`. Previously it defaulted to `true`, meaning duplicate worker names were automatically suffixed with `-1`, `-2`, etc. With the new default, all connections sharing a worker name are treated as one logical miner with aggregated hashrate and stats. Operators who need per-connection tracking can re-enable it.

---

## v3.0.26

**Duplicate Worker Name Aggregation**

When multiple physical miners connect with the same worker name (e.g., two Bitaxes both configured as `wallet.worker1`), the pool now aggregates their data under a single identity by default. Previously, disambiguation was enabled by default and appended `-1`, `-2` suffixes to create unique names per connection. Starting in v3.0.26, disambiguation is disabled by default and the pool treats all connections sharing a worker name as one logical miner.

With disambiguation disabled:
- **Hashrate** — The dashboard and miner detail page show the combined hashrate across all connections sharing the worker name. The hashrate chart on the miner detail page aggregates per-timestamp snapshots so the chart line represents total output, not interleaved per-connection values.
- **Shares** — Valid, invalid, and stale share counts are summed across all connections. Efficiency percentage reflects the combined totals.
- **Device display** — When multiple connections share a worker name, the dashboard miners table shows "N Devices" instead of a single user agent string. The miner detail page shows "N connections" under the worker name.
- **Per-connection charts** — The share submission and difficulty adjustment charts on the miner detail page are per-connection by nature. When more than one connection shares the worker name, these charts display a message explaining the data is not available in aggregated mode.

Operators who need per-connection tracking can re-enable disambiguation by setting `disambiguation_enabled` to `true` in the coin's stratum config.

---

## v3.0.25

**Dashboard — Miner Table Pagination and Filtering**

The miners table on the coin pool dashboard now supports server-side pagination and active/inactive filtering. Previously, the table loaded all miners at once — which became unmanageable beyond about 20 miners and would time out entirely at 100+.

- **Active / Inactive / All filter** — Three toggle buttons above the miners table let you switch between viewing active miners only, inactive miners only, or all miners. The default is Active only, so inactive miners no longer clutter the table. Each button shows its count (e.g., "Active (5)"). The selected filter is remembered across page reloads.
- **Pagination controls** — Previous / Next buttons below the table, with a configurable page size selector (5, 10, 20, 30, 50, or 100 per page). Page size preference is remembered across page reloads.
- **Server-side sorting** — Active miners are sorted by hashrate (highest first), inactive miners by last seen time (most recent first). Sorting is handled server-side for consistent pagination order.
- **Remove Inactive Miners button** — A new trash icon button in the miners card header lets you permanently remove all inactive miners and their data in one action, with a confirmation modal matching the existing reset modal style.

The 10-second auto-refresh continues to work with pagination — it stays on your current page and filter selection, and automatically adjusts if the page count changes (e.g., a miner goes offline).

---

## v3.0.24

**Duplicate Worker Name Disambiguation**

When multiple miners connect with the same wallet address and worker ID (e.g., `address.worker1`), the pool now disambiguates them automatically. Previously, duplicate worker names could cause metrics to be merged or misattributed across different physical miners. Each connection now maintains its own distinct identity in the miner table.

**VarDiff — Miner Suggest Difficulty Limited to Initial Connection**

The pool now only honors a miner's suggested difficulty (`mining.suggest_difficulty` or `d=` password field) on initial connection, before the first VarDiff adjustment. Once VarDiff has begun managing the miner's difficulty, further suggest difficulty requests from the miner are ignored. This prevents miners from overriding the pool's difficulty management after VarDiff has already found the optimal level.

---

## v3.0.23

**Improved Miner Device Identification**

The dashboard now correctly identifies miners that report their device information in non-standard formats. Previously, some firmware — such as Braiins OS — would display as a long unreadable string instead of a friendly device name. These miners are now recognized and labeled properly in the miner table.

**Cleaner Hashrate and Difficulty Display**

Hashrate and difficulty values throughout the dashboard now use a consistent, streamlined formatting system. Large values scale cleanly across all magnitudes (kH/s through ZH/s), and very small difficulty values for low-hashrate miners continue to display with full precision.

**API Security Improvements**

Hardened security controls across API endpoints to strengthen protection against unauthorized access.

---

## v3.0.20

**Dashboard — Faster Miner Table Updates After Delete**

When deleting an individual inactive worker or resetting all miner statistics, the dashboard now immediately clears the coin's metrics cache before refreshing the miner table. Previously there was a lag where the deleted worker could still appear in the table until the next cache refresh cycle.

Both confirmation modals also now include an optional "Re-prime cache after delete/reset" checkbox (unchecked by default). When checked, the cache is repopulated immediately after clearing so the table refresh reflects fresh database data rather than waiting for the next snapshot interval.

**Bug Fix — Telegram Bot Token Not Saving**

Changing the Telegram bot token on the Notifications configuration page was silently discarded — the old token was always kept regardless of what was typed. The issue was that the hidden raw field (used to preserve the masked token when no changes are made) was never cleared when the user edited the visible field, causing the backend to always pick up the old value. This is now fixed — editing the token field clears the raw field so the newly typed value is saved correctly. The same fix applies to the email password field.

---

## v3.0.19

**Float Difficulty Precision Control**

When using float difficulty for low-hashrate miners (e.g., NerdMiner, tiny ASIC devices), the pool now lets you control exactly how many decimal places are used in the difficulty value sent to the miner. Some miner firmware — particularly Canaan devices — can't handle long decimal difficulty values and will produce stale shares if given more precision than they expect. The new `floatDiffPrecision` setting (default: 4 decimal places, range: 0–15) keeps things compatible across different hardware without having to turn float difficulty off entirely.

This setting is available in the coin config and on the Web UI config page.

---

## v3.0.18

**Smart Initial Difficulty**

Previously, every miner started at the same fixed pool difficulty and relied entirely on VarDiff to ramp up or down. v3.0.18 introduces a smarter startup process that gets miners working at the right difficulty much faster:

- **Probe difficulty** — A high difficulty is sent the instant a miner connects, before the pool even knows what miner it is. This prevents a share flood from powerful miners during the brief authorization window. Defaults to `0` (disabled) — set `probe_difficulty` to a value like `65536` to enable it.
- **Historical difficulty** — If a miner has connected before during this pool session, the pool remembers where VarDiff settled and starts it there on reconnect. No ramp-up needed.
- **Device-based difficulty** — Operators can map known device types (by user agent substring) to a starting difficulty. For example, all Bitaxe miners can start at 9,000 and all NerdQAxe miners at 50,000 automatically.
- **Miner-suggested difficulty** — When a miner sends its own suggested difficulty (via `mining.suggest_difficulty` or the `d=` password field), the pool now immediately sends a fresh job at that difficulty with `clean_jobs`, so the miner starts working at the right level right away instead of wasting time on the wrong difficulty.

**Web UI — Small Miner Display Fix**

Share difficulty values for low-hashrate miners (sub-1 difficulty) were displaying as long raw decimals like `2.1985060522527893`. These are now rounded and formatted cleanly in the dashboard.

**Miner API Stability Fix**

Querying the API for a miner that had disconnected could produce a repeating error in the pool logs. This is now handled cleanly with no log spam.

**Global Config — New Fields**

Two new fields are available in the global config section and Web UI:

- `connection_timeout_seconds` — Set a global default connection timeout for all coins.
- Minimum difficulty floor lowered — `difficulty` and `minDiff` values below 1 are now allowed, enabling proper support for very low-hashrate devices.

---

## v3.0.17

**API Cache Layer**

The pool dashboard makes frequent API calls to display live pool stats, miner lists, and network data. Under load, these calls were hitting the database directly on every refresh. v3.0.17 adds a cache layer in front of the heaviest API endpoints, significantly reducing database load and improving dashboard responsiveness — especially for pools with many connected miners.

The cache refreshes on the same schedule as the pool's snapshot interval, so dashboard data stays current without hitting the database on every request. Cache can be enabled or disabled via `enable_api_cache` in the config.

**Pool Metrics API Optimization**

The pool-level metrics API endpoint was rewritten to run more efficiently against the database, reducing query time and resource usage.

**Flood Protection Fixes**

Flood protection (introduced in v3.0.15) had incorrect default values showing in the Web UI config page. These are now correct. The flood protection difficulty tracking was also improved to properly record and log difficulty changes driven by flood protection events.

**Connection Event Batching**

Miner connection and disconnection events are now written to the database in batches rather than one at a time, reducing write pressure on high-connection pools.

---

## v3.0.16

**Database Optimization — Network Stats**

The network stats table now has a configurable retention period (`network_stats_retention_days`, default: 7 days). Old network data is automatically cleaned up on a schedule, keeping the database lean over time. This was paired with schema improvements (V16) to make network stats queries more efficient.

---

## v3.0.15

**Flood Protection**

New feature to handle miners that connect and immediately submit shares far faster than the pool's target share rate. When a miner's share rate exceeds the threshold, the pool automatically bumps their difficulty — up to a configurable multiplier — to bring them back in line. This prevents log spam, unnecessary database writes, and inflated share counts from misconfigured or very high-hashrate miners hitting a too-low starting difficulty.

Configurable per coin:
- `enabled` — on/off
- `sharesToCheck` — how many recent shares to evaluate
- `triggerThreshold` — how far below target share time triggers protection
- `maxAdjustmentMultiplier` — maximum difficulty multiplier applied

**Miner Metrics Database Optimization**

The per-miner metrics API endpoint was significantly optimized. Snapshot write routines were also refactored to reduce database round-trips, lowering CPU and I/O usage during high-share-volume periods.

**Database Cleanup — Connections Table**

The connections table is now included in the automated database cleanup routine, preventing it from growing unbounded over time.

---

## Upgrade Notes

- v3.0.16 includes a database schema update (V16). The pool will apply this automatically on first start.
- All new config fields have safe defaults — existing `config.json` files do not need to be updated to upgrade. New fields will use defaults until explicitly configured.
- Float difficulty precision (`floatDiffPrecision`) defaults to 4 decimal places. If you are running Canaan ASIC miners with `useFloatDiff: true`, this default is recommended. If you were previously seeing stale shares on those miners, this is the fix.
- v3.0.27 changes `disambiguation_enabled` default from `true` to `false`. If you relied on the old default behavior (per-connection `-1`, `-2` suffixes), add `"disambiguation_enabled": true` to your stratum config.
- v3.0.28: If you add a `wallet_passphrase` value to config.json, it will be auto-encrypted on the next startup. The original plaintext is replaced with an `ENC:` prefixed encrypted value. This is a one-way config rewrite — back up your config before testing if desired.
- v3.0.29: `floatDiffBelowOne` defaults to `true`. If you have `useFloatDiff` enabled and want float difficulty at all magnitudes (previous behavior), set `"floatDiffBelowOne": false` in your vardiff config. Most operators should leave it at `true` — it prevents firmware issues on Canaan and AxeOS devices.
- v3.0.30: No config changes required. This is a bug fix to coinbase transaction construction. Rebuild and redeploy to apply.
