# GoSlimStratum — Release Notes
## v4.x Series
## v4.1.2

### Coin Dashboard — Miners Table Column Reorder

The miners table on the coin pool dashboard has been reordered to put the columns you watch most on the left and the column that rarely changes on the right.

- **Before:** Worker, Device, Hashrate, Shares, Best Share, Lifetime
- **After:** Worker, Hashrate, Best Share, Shares, Lifetime, Device

At a glance, what you usually want to see for each worker is what it's producing right now — Hashrate and Best Share — so those now sit immediately next to the Worker name. Device (firmware / user-agent string) rarely changes once a rig is set up, so it has been pushed to the far right.

### Coin Dashboard — Long Device Names Truncated

Long firmware strings (e.g. `NerdQAxe++/v2.x.x/...`) were eating horizontal space in the miners table and pushing the layout around. Device names longer than 10 characters are now truncated to 10 characters in the cell. The full name is preserved as a hover tooltip — point your mouse at any truncated cell to see the complete value. The multi-device case (`N Devices` for workers with more than one active connection) follows the same rule but is typically short enough not to be truncated.

### Notifications — Message Prefix on Its Own Line

If you've configured a Message Prefix (e.g. `[GSS-138]`), it used to share a line with the alert subject:

**Before:**
```
[GSS-138] ✅ Block Matured - DGB #23426904 ✅
```

On narrow viewports — Telegram on mobile especially — this string wraps mid-sentence (sometimes mid-emoji), making the alert harder to read at a glance. The prefix now sits above the subject on its own line:

**After:**
```
[GSS-138]
✅ Block Matured - DGB #23426904 ✅
```

Applied to **Telegram, Discord, and Generic Webhook** alerts. Email subject lines are unchanged because email clients handle long subjects with their own truncation/expansion UX.

### Notifications — Cleaner Reward and Payment Amounts

Block and payment alerts used to repeat the coin name on every amount line:

**Before:**
```
Coin: DGB-Test
Block: #23426904
Hash: abc123…
Reward: 265.20020841 DGB-Test
```

The trailing identifier is the *coin pool key* you configured (often a shortened tag like `DGB-Test`), not a real currency symbol — and the coin is already named in the subject and on the `Coin:` line, so repeating it on every amount line was just noise. The trailing identifier has been removed:

**After:**
```
Coin: DGB-Test
Block: #23426904
Hash: abc123…
Reward: 265.20020841
```

Applies to all event types (Block Found, Block Matured, Block Orphaned, Payment Pending, Payment Completed, Payment Failed) and all channels (Telegram, Discord, Email, Generic Webhook). The `/blocks` Telegram bot command also got the same treatment for consistency.

### Upgrade Notes

- No configuration changes required.
- If you script against the Generic Webhook payload, the **alert body string** now contains a newline between the prefix and subject (previously concatenated). The structured fields and event payload schema are unchanged.

---

## v4.1.1

### Health & Metrics Page

New dedicated **Health & Metrics** page at `/metrics` that visualizes runtime and database health at a glance. Replaces the system-stats and database tables that were previously crowded onto the Version page.

**What it shows:**

- **Runtime tiles** — uptime, goroutines, CPU cores, Go runtime version
- **Memory card** — donut chart of heap usage (in-use / reserved / stack / other) with companion table of memory in-use, memory from OS, heap objects, and log file size
- **Garbage Collection card** — GC cycle count, forced GC count, total pause time, GC CPU fraction
- **Database card** — database size, schema version, table count, plus a horizontal bar chart of row counts per table and a connection pool stats grid (open, in-use, idle, wait counters)

All three main cards are collapsible, with state remembered in your browser between visits.

**Footer changes:**

- The footer "API Health" link is renamed **Health** and now opens the new `/metrics` page
- The footer "Version" label now displays the actual version number (e.g. `v4.1.1`) and links to the Version page (which has been slimmed down to show just version and license info — the system-stats / database / about cards moved to the new Metrics page)

### Coin Dashboard — Summary Row Refactor

The top summary row on the coin pool dashboard has been redesigned for compactness and at-a-glance scanning, modeled on the GSSM mining dashboard layout.

**Visible changes:**

- **6 cards instead of 5** — a new **Difficulty** card joins Hashrate / Active Miners / Shares / Blocks Found / Node Comm. The bottom-of-page Network Statistics card was removed; its data now lives in the Difficulty card up top.
- **Compact layout** — small icon top-right, bold value taking center stage. The previous oversized icons on the right edge are gone, giving values more visual weight.
- **Consistent value sizing** across all cards. Smaller, less shouty.
- **Difficulty card** — primary value is the network difficulty, with hashrate and block height shown beneath. Click anywhere on the card to open the Network Statistics page with full historical charts.
- **Blocks Found** — entire card is now a clickable link to the Earnings Dashboard. The coin symbol was removed from the "X paid" subtext (it rendered awkwardly for long names like DGB-SCRYPT).
- **Active Miners** — icon swapped from the construction-worker emoji to a hammer-and-pick (⚒️) for a more mining-themed look.
- **Node Comm in DUAL mode** — when running in dual ZMQ-and-polling mode, the card now stacks the mode label, ZMQ status, and polling interval on three separate lines instead of cramming them onto one. Easier to read at a glance.
- **Hide Summary toggle** — small text link above the summary row that collapses the entire card row when you want more screen space for charts and the miners table. Your preference is saved in your browser, so reloads and revisits remember whether you wanted it shown or hidden.

### Animated Background — New "Nonce Hunt" Mode

A fourth animated background option themed around the actual mining process. Hex nonces (`0x3a7f2e1c`) appear at random positions on the page and rapidly mutate their characters — visualizing ASICs cycling through nonce candidates searching for a valid hash. Most nonces fade out after a few seconds (failed attempts), but approximately 1 in 6 "hit" — flashing gold with an expanding ring and spark particles before fading.

- Selectable from the Global Configuration page dropdown alongside Hash Drift, Node Mesh, Share Pulse, and Off
- Mobile-aware: 15 nonces on small screens, 25 on desktop
- Pauses when the tab is hidden, respects the system "reduce motion" preference

### Animated Background — Hot Reload

Changing the animated background no longer requires a GSS restart. Pick a new background in Global Configuration, click Save, and the next page navigation shows the new animation. Previously you had to restart the service for the change to take effect.

### Help Page Expansion

The in-app Help page (`/help`, accessed via the **(?)** icon in the header) gained two big additions in 4.1.1:

- **Coin Dashboard Guide** — a new "Dashboard Guide" sidebar group with a complete walkthrough of the coin pool dashboard. Mockups of the page header (status badges, feature badges, icon links), all summary cards, the collapsible chart sections, the miners table (filter buttons, action icons, columns explained), and the bottom Recent Blocks section. Every badge color, icon, and interactive element is explained.
- **Updated for the dashboard refactor** — the Coin Dashboard guide reflects the new 6-card layout, GSSM-style icons, ⚒️ for Active Miners, the new Difficulty card, the Hide Summary toggle, and the DUAL-mode Node Comm display.

### Upgrade Notes

- No configuration changes required. All changes are visible additions or layout improvements.
- Hide Summary toggle starts in the "shown" state; click it to hide.
- The `/metrics` page does not require a license — available to all users.
- If you'd previously bookmarked the bottom-of-page Network Statistics card, the same data (and a link to the full Network Statistics page) is now in the Difficulty card at the top of the dashboard.

---

## v4.1.0

### Built-in Block Explorer

GSS now includes a built-in block explorer that queries your coin's blockchain node directly. No external block explorer needed — ideal for testnet, regtest, and obscure coins where public explorers don't exist.

**Pages:**
- **Explorer Dashboard** — chain info, mempool summary, recent blocks, search by height or hash
- **Block Detail** — full block header info, all transactions with clickable txids, previous/next navigation
- **Transaction Detail** — inputs, outputs (address, value, type), coinbase hex-to-ASCII decoding
- **Blocks List** — recent blocks with "Load More" pagination, DGB multi-algo column when applicable
- **Mempool** — dynamic stat cards for all fields the node returns

**Configuration (per coin):**
- `alternate_host` — optional secondary node for explorer queries (avoids load on the mining-critical primary node)
- `use_rest_api` — use REST API instead of JSON-RPC (requires `rest=1` on the node)
- `use_alternate_host` — route explorer calls to the alternate host

Block hash and height links on the Blocks and Earnings dashboards now navigate to the internal explorer. Transaction and address links remain external. No license required — available to all users.

### Pool Topology Visualization

New animated canvas page showing the live pool data flow: miners → GSS hub → coin node. Access via the lightning bolt icon on the dashboard header.

- **Miners** — displayed as colored nodes sized by relative hashrate, color-coded by tier
- **GSS Hub** — center circle with concentric pulsing rings, showing pool hashrate, active miners, shares, and blocks found
- **Coin Node** — circle showing block height, difficulty, network hashrate, and ZMQ connection state
- **Animated particles** — shares (blue, miner → hub), jobs (amber, hub → miner), ZMQ notifications (green, node → hub), GBT polls (gray, hub → node)
- **Block found burst** — gold rings emanate from the hub with a victory chime sound when a new block is detected
- **Hover tooltips** — miner device type, hashrate, shares, best difficulty
- Top 20 miners by hashrate displayed; larger pools show "... and N more miners"


### Animated Background

Three configurable animated canvas backgrounds themed around mining concepts. Selectable from the Global Configuration page.

- **Hash Drift** (default) — hex string fragments drift upward, characters mutate to simulate live computation
- **Node Mesh** — floating nodes with connecting lines evoking a network topology
- **Share Pulse** — radial rings expand outward simulating share submissions
- **Off** — no animation

Respects `prefers-reduced-motion` and pauses when the tab is hidden. Set via `animated_background` in the `web` section of config.json.

### LTC / DOGE Scrypt Support

Fixed hashrate calculation and difficulty display for Litecoin and Dogecoin. These single-algo scrypt coins report difficulty differently than DGB-SCRYPT, which caused hashrate to be inflated by 65,536x and difficulty values to display incorrectly.

- **Hashrate** — now uses the correct scrypt multiplier for all scrypt coins including LTC and DOGE
- **Best share** — correctly scaled on both dashboard and miner detail page
- **Block difficulty** — no longer incorrectly scaled for LTC and DOGE
- **Recent Blocks** — share difficulty and block difficulty display correctly for all scrypt coins

### Node Failover

When a blockchain node goes down, GSS now automatically fails over to the configured `alternate_host` and continues mining without interruption. No stratum disconnect, no miner reconnection needed. Once the primary node recovers, GSS fails back on the next natural block boundary.

- **Automatic detection** — 3 consecutive health check failures trigger failover
- **Seamless mining** — miners receive `cleanJobs=true` and continue working on the backup node's templates
- **Smart failback** — requires 5 consecutive successful primary checks before switching back, then waits for the next block to avoid disruption mid-work
- **ZMQ dual subscription** — GSS subscribes to ZMQ on both nodes simultaneously for near-instant block detection on the backup, no polling lag
- **Dashboard banner** — orange banner appears during failover showing the active backup host, updates to "failback pending" when primary recovers
- **Notifications** — failover and failback events sent to configured notification channels (Telegram, Discord, email, webhook)
- **Payouts continue** — metrics and payout RPC clients are updated automatically (requires wallet loaded on backup node)

**Configuration (per coin, node section):**
```json
{
    "alternate_host": "192.168.1.100",
    "enable_failover": true
}
```

RPC username, password, and port must be the same on both nodes. Requires a license with node failover scope. The checkbox is disabled in the config UI without the license, and the engine silently ignores the setting if the license is missing.

### Merged Mining (AuxPoW) — LTC → DOGE

GSS now supports AuxPoW (Auxiliary Proof of Work) merged mining. Miners hashing for a parent chain like Litecoin can simultaneously produce blocks on aux chains like Dogecoin — the same hashrate, no extra hardware, no extra electricity. GSS handles the AuxPoW block construction and submission entirely on the pool side.

**How it works:**

- Miners connect to the **parent chain's stratum port only** — no firmware or hardware changes
- A **pipe-delimited username** provides addresses for both chains: `ltc1qXXX|DXXX.workername`
- GSS embeds an AuxPoW commitment in every parent chain coinbase
- Every accepted parent share is checked against the aux chain's difficulty target — if it meets it, GSS constructs and submits a full AuxPoW block to the aux node
- LTC and DOGE block found events fire independently
- DTM mode is required on both the parent and aux chains (via license or revenue share). LTC and DOGE are both built-in coins.

**Per-Miner DTM on Both Chains:**

GSS submits AuxPoW blocks via the aux node's `submitblock` RPC with a fully constructed block, giving full control over the aux chain's coinbase outputs — per-miner DTM addresses, pool fee splits, and revenue share outputs all work on the aux chain. Most stratum pool implementations limit the aux chain coinbase to a single address.

**Configuration:**

```json
"coins": {
    "LTC": {
        "enabled": true,
        "enable_dtm": true,
        "merged_mining": { "role": "parent", "aux_chains": ["DOGE"] }
    },
    "DOGE": {
        "enabled": true,
        "enable_dtm": true,
        "merged_mining": { "role": "aux", "aux_of": "LTC" }
    }
}
```

**Validation:**

- Both parent and aux must have DTM enabled
- Parent and aux must use the same mining algorithm (scrypt for LTC → DOGE)
- Each aux must declare itself with `role: "aux"` and `aux_of` pointing to the parent
- The coin pool dashboard shows an orange warning banner if any of these rules are violated, with specific misconfigurations listed

**Graceful degradation:**

- If the aux node goes offline, jobs are built without the AuxPoW commitment and parent-chain mining continues
- When the aux node comes back, the commitment resumes automatically
- Both coins remain fully functional standalone pools — merged mining is an additive layer. Removing the `merged_mining` config field leaves both pools running exactly as before.

**Dashboard indicators:**

- Parent dashboard shows an orange `Merged → DOGE` badge
- Aux dashboard shows an orange `AuxPoW ← LTC` badge
- Each connected miner on the parent shows an `(M)` indicator next to its worker ID

See the [Coin Configuration Guide](../documents/GoSlimStratum/gss-coin-config-guide.md#merged-mining-auxpow---as-of-version-410) for full configuration details and the username format.

### Dashboard Improvements

- **Recent Blocks pagination** — dropdown selector (5, 10, 20) on the Recent Blocks card. Preference saved to browser storage.
- **Coin icon badge fix** — coin symbols longer than 3 characters (e.g., DGBT, DGB-SCRYPT) now correctly display the coin icon using the first 3 characters
- **Sticky footer** — footer now stays at the bottom of the viewport on all pages, even with short content

### Web UI Polish

A round of mobile and usability improvements across the web dashboard:

- **Mobile-friendly status badges** — On phones (`< 640px`), the coin pool dashboard status badges collapse to short abbreviations (e.g., `Running` → `R`, `Revenue Share` → `RS`, `Merged → DOGE` → `M`) while keeping full text on tablets and desktop. Same colors and indicators on both — only the text changes.
- **Configured Coins table — mobile card layout** — On the Global Configuration page, the Configured Coins table was unreadable on phones (six columns crammed horizontally). It now renders as one labeled card per row on small screens, with each field shown next to its column name. Desktop view unchanged.
- **Mobile coin selector — last-selection persistence** — The mobile coin dropdown now remembers your last-picked coin across navigation. Previously, navigating to a global page (Global Configuration, Notifications, License, etc.) reset the dropdown to the first option. Your selection is restored when the page loads, so you don't have to re-pick every time you switch between a coin page and a global one.
- **Mobile free-tier badge label** — The free-tier "Unlock Features ↗" badge in the header now shows a shorter "Unlock ↗" on phones to save space. Hyperlink and behavior unchanged.
- **Coin pool dashboard header** — Removed "Pool Dashboard" from the title — now just shows the coin symbol (e.g., `DOGE`) next to the coin icon. Saves header real estate on both desktop and mobile, page context already makes the dashboard purpose obvious.
- **Removed "Last updated" wall clock** — The "Last updated: HH:MM:SS" indicator in the dashboard header was a system clock that ticked regardless of actual data refresh state, which made it actively misleading. Removed entirely. The refresh button (which actually does refresh) stays.

### In-App Help &amp; Configuration Reference

Added a built-in help page at `/help` that visually documents every configurable field across the entire GSS UI — a single in-app source of truth for "what does this field do?". Accessible from a new **(?)** icon in the header, placed to the immediate left of the Global Configuration gear icon and visible on every page.

**Format:** Two-pane layout with a sticky left sidebar (grouped into "Global Configurations" and "Coin Pool Configurations") and a right pane that shows one documentation section at a time. Each section reproduces the actual live config form — same look-and-feel, same layout — but with inputs pre-populated with example values and a numbered blue badge next to each field, paired with a numbered explanation list below.

**19 sections covering ~140 fields, including:**

- **Configured Coins table** — Shows all 5 coin-state combinations (Enabled+Running, Enabled+Stopped, Enabled+Not Loaded, Disabled+Not Loaded) so you can recognize each status badge on sight.
- **Pool Lifecycle** — Mockups of the Running / Stopped / Not Loaded states with the real action buttons, explaining when each appears and what it does (Stop, Restart, Start, Unload, Load & Start).
- **Every field** on the Global Configuration page (Pool Settings, Web Server, Metrics & Database, Logging, Notifications), the Add Coin wizard, the Clone Coin modal, the Remove Coin modal, and every section of the per-coin Configuration page (Status & DTM, Node Settings, Block Explorer, Node Failover, Merged Mining, Stratum, Mining, VarDiff, Payout).
- **Contextual tips** — e.g., the Mining section now recommends `max_job_history: 5` when DTM is enabled (instead of the default 20), because DTM creates per-miner jobs and history grows fast.

**URL deep-linking:** Every section has a hash anchor — `/help#merged-mining`, `/help#pool-lifecycle`, `/help#node-failover`, etc. — so you can bookmark a specific section or share a link to it. Browser back/forward navigation works as expected.

**Header spacing fix:** The new (?) icon ships grouped with the gear icon in a shared inline container, and both icons use tighter padding — on mobile this frees up horizontal space so the free-tier / Pro / Enterprise badge is no longer pushed off-screen.

No configuration required — the help page is available immediately after upgrading and works offline (no API calls, no backend dependencies).

### Upgrade Notes

- No configuration changes required. All new features are backward compatible.
- The `alternate_host`, `enable_failover`, `explorer`, and `merged_mining` fields are all optional — pools without them behave exactly as before.
- `animated_background` defaults to `"hash-drift"` if not set.
- Block explorer links in the Blocks and Earnings pages now navigate to the internal explorer. External `block_explorer_urls` in config are no longer used for block lookups but can remain for reference.
- Transaction and address external links (`tx_explorer_urls`, `address_explorer_urls`) are still used.
- **Merged mining miners** — Existing miners without pipe-delimited usernames continue working unchanged. To enable merged mining, update the miner's stratum username to `parentaddress|auxaddress.workername`. If only the parent address is provided, the aux pool's `mining.address` is used as the fallback DOGE payout address.

---

## v4.0.2

### Scrypt Display Scaling Fixes

Fixed display formatting for scrypt coins (e.g., DGB-SCRYPT) across the dashboard and miner detail pages. Scrypt and SHA256d use different difficulty scales (ratio of 2^16 = 65536), so raw values needed UI-side conversion for consistent display.

- **Best share** — divided by 65536 for scrypt coins on both dashboard miners table and miner detail page
- **Block difficulty** — multiplied by 65536 for scrypt coins on both dashboard miners table and miner detail page
- **Recent Blocks card** — share difficulty divided by 65536, block difficulty multiplied by 65536 for scrypt coins on both dashboard and miner detail page

All changes are display-only — backend values are unchanged.

### Bug Fix: Blocks Found Card Missing DTM Rewards

The "Blocks Found" card on the coin pool dashboard showed the correct block count but displayed incorrect for the paid rewards amount when running in DTM (Direct-to-Miner) mode. DTM block rewards are now included in the total alongside pool-mode payouts. Previously was only showing non-DTM rewards amount.

---

## v4.0.1

### P2SH / P2TR / Taproot (Bech32m) Address Support

Added P2SH (Pay-to-Script-Hash) and Taproot (P2TR / Bech32m) address support across all coin implementations. Miners can now use any standard address type as their mining or payout address in both pool mode and DTM mode.

**Complete address type support by coin:**

| Address Type | BTC | DGB | BCH | XEC | BC2 | LTC | DOGE |
|---|---|---|---|---|---|---|---|
| P2PKH (legacy) | `1...` | `D...` | CashAddr `q...` | CashAddr `q...` | `1...` | `L...` | `D...` |
| P2SH | `3...` | `S...` | CashAddr `p...` | CashAddr `p...` | `3...` | `M...` | `9/A...` |
| P2WPKH (Bech32) | `bc1q...` | `dgb1q...` | — | — | `bc1q...` | `ltc1q...` | — |
| P2WSH (Bech32) | `bc1q...` | `dgb1q...` | — | — | `bc1q...` | `ltc1q...` | — |
| P2TR (Bech32m) | `bc1p...` | `dgb1p...` | — | — | `bc1p...` | `ltc1p...` | — |

Generic coins (`coins.json`) support all of the above based on configuration — P2PKH and P2SH are always available, and P2WPKH/P2WSH/P2TR are available when `segwit: true` with a Bech32 HRP configured.

**What changed:**
- Bech32m encoding/decoding added alongside existing Bech32 (BIP350 compliant)
- Address validators accept witness version 1 (Taproot) with 32-byte programs
- Coinbase output script generation for P2TR: `OP_1 <32-byte tweaked public key>`
- BTC and BC2 accept `bcrt1` regtest addresses under testnet config

### Pool Violation Shutdown — Wallet Address Mismatch Enforcement

In pool mode (non-DTM), the health monitor now enforces wallet address ownership. If the configured payout address does not belong to the node wallet, the coin pool is automatically stopped to prevent misconfiguration issues.

- **Pool mode + external address** — pool is stopped, miners disconnected, dashboard shows "Pool Stopped — Wallet Address Mismatch"
- **Pool mode + node wallet address** — pool runs normally
- **DTM mode** — completely unaffected, external addresses are expected
- **Recovery** — fix the payout address in `config.json` and restart the pool

### Upgrade Notes

- No configuration changes required. All changes are backward compatible.
- P2SH and P2TR address support is automatic — miners can start using these address types immediately after upgrading.
- Pool violation shutdown is automatic in pool mode. If you are running pool mode with an external address (not in the node wallet), the pool will stop on the next health check. Switch to DTM mode or fix the payout address before upgrading.

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