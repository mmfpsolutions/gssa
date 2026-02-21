# GoSlimStratum — Release Notes
## v3.0.15 through v3.0.20

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
