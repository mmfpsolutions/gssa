# GSSM Release Notes
## v3.x Series

## v3.0.1

A focused follow-up to 3.0.0 that hardens how GSSM watches your miners and nodes: accurate failover status on AxeOS devices, far fewer false offline/online alerts, faster alert checks for larger setups, and a greatly expanded in-app Help page.

> **No operator action required on upgrade.** These are reliability fixes and improvements — nothing in your configuration changes.

### Bug Fixes

- **Accurate failover status on AxeOS miners (NerdQAxe++ & Bitaxe).** The miner card now correctly shows when a device is mining on its **backup pool** — previously a NerdQAxe++ always read *Failover: false* even after it had switched over. And the pool-switch notification now fires in **both** directions: when a miner fails over to its backup **and** when it moves back to its primary (it used to only alert on the way out).

  > **Who this affects:** anyone running AxeOS miners (Bitaxe / NerdQAxe++) with a primary + fallback pool configured.

- **Far fewer false "miner offline / online" alerts.** Some miners — NerdQAxe++ especially — occasionally answer slowly or briefly hang their API, which could make GSSM think a perfectly healthy miner had dropped and fire an offline-then-online alert pair. Two changes fix this:
  - **A longer response window for AxeOS miners** — 5 seconds (up from 3) before a check counts as a miss.
  - **A confirmation step** — a miner must now miss **two checks in a row** before an offline alert is sent. A single slow or hung check is absorbed silently, so one blip no longer pages you.

### Improvements

- **Faster, more reliable alert checks on larger setups.** GSSM now checks your **miners and crypto nodes in parallel** instead of one at a time. Previously, on a fleet of 20+ devices, a handful of slow or unresponsive ones could stretch a check cycle past its interval. Now a cycle is bounded by your *slowest* device, not the sum of all of them — so big fleets stay comfortably within their check window even when some devices are misbehaving. (Pools were already fast and are unchanged.)

- **Expanded Help & Reference page.** The in-app **Help** page (linked in the footer) is now a full visual guide: sample miner, pool, and crypto-node cards, plus field-by-field references for every Configuration, Notifications, and Historicals setting — all styled to match your dashboard, with a quick sidebar to jump around.

- **Consistent crypto-node logging.** Node checks now appear in the debug log — cycle start, per-node status, and event dispatch — matching what miners and pools already logged. If you ever turn on debug logging to troubleshoot a node, it now tells the same story as the rest of the dashboard.

### Good to know

- **Offline alerts are now confirmed over two check cycles.** That's the trade-off for killing the false alerts: a genuine outage is reported one check interval later than before (about a minute at default settings). Your **history and trends are unaffected** — the raw offline reading is still recorded; only the *alert* waits for confirmation.

---

## v3.0.0

Our biggest release yet. The headline is **Historicals** — an optional, Pro/Enterprise history database that gives your live dashboard a memory: trend charts, all-time best shares that survive reboots, and a searchable alert history. Alongside it: a new **Health** page, support for **two new coins** (Bitcoin Cash II and Bitcoin Silver), a richer pool and crypto-node detail experience (new charts, sortable tables, more of what your node actually knows), and a top-to-bottom **consistency and accuracy pass** across every miner, pool, and node — the card, the detail page, and your alerts now all read from one source, so they can't disagree, and details some devices reported all along but GSSM used to quietly drop now show up. There's a good round of bug fixes too, including one that stops a healthy node from spamming you with false offline alerts.

> **No operator action required on upgrade.** GSSM stays exactly as it is unless you choose to turn something on. Historicals is **off by default**, and with it off GSSM remains fully stateless and in-memory — behaving just like the 2.x series. Nothing in your `config.json` is rewritten when you upgrade.

### New Features

- **Historicals — optional mining history and trends** *(Pro/Enterprise)* — GSSM has always been live-only, showing you the current moment and nothing more. Historicals adds an optional history layer, backed by your own PostgreSQL database, that persists miner telemetry and lifetime records so you can look *back*, not just *now*.

  > **Who this affects:** only Pro/Enterprise users who choose to connect a database. If you don't turn Historicals on, nothing changes — GSSM stays stateless and in-memory, exactly as before.

  - **Turn it on from a config page** — a new **Historicals** configuration page (with a matching card on the main Configuration page). Enter your database connection details, use the **Test Connection** button to verify them, and — if you'd like — let the one-time first-run helper create the database for you. Enabling, disabling, or re-pointing the database applies live, with no restart.

  - **Fleet trend charts** — a new **Historicals → Miners** page with per-miner line charts for hashrate, temperature, fan RPM, assigned difficulty, and session best-share. Filter by device type and model, and pick the time range you want to see.

  - **All-time best share that survives reboots** — the miner detail page now shows a **Best (lifetime)** value. For miners that don't track their own all-time best, GSSM remembers it for them (shown in an emerald "tracked" color). A nice side effect: an offline miner keeps showing its last known best instead of going blank, then hands back to the device when it returns.

  - **Searchable alert history** — a new **Historicals → Notifications** timeline records every notification (offline, failover, temperature, and so on) so you can filter and review exactly what happened and when — per miner, pool, or node. Each detail page deep-links to its own history via a 🔔 link.

  - **You stay in control of the data** — the Historicals config page lists per-miner record counts and lets you reset a best or remove a miner's data. History is automatically trimmed to a retention window you set (default 7 days for detailed metrics, 90 days for alert history).

- **Health page** — a new **Health** page, linked in the footer next to the version, shows GSSM's own vitals at a glance: uptime, memory use, which services are running, how many miners/pools/nodes are online, and — when Historicals is connected — database size and statistics.

- **Pool detail page — charts** — the pool detail page now graphs **Blocks Found per day** and daily **Earnings**. For litecoinpool, LTC and DOGE earnings render as two separate charts so one currency doesn't dwarf the other.

- **Pool detail page — sortable tables** — **Workers**, **Blocks**, and **Payments** are now full tables with every column sortable and Prev/Next paging. Values a given pool doesn't provide show as **N/A** rather than blank.

- **Crypto node detail — more of what your node knows** — several new sections surface information your daemon reports:
  - **Mempool** — pending transaction count and size, as a node-health signal.
  - **Upload Target** — bandwidth-budget tracking (target, reached, bytes and time left), or **"Unlimited"** when no limit is set.
  - **Per-wallet balances** — each wallet listed by name and balance, instead of a single lumped total.
  - **Deployments** — a table tracking soft-fork activation status (the future home for DigiByte **DigiDollar** tracking).
  - **Peer Analysis** — a new card with four charts (Version Distribution, Connection Types, Peer Latency, Bandwidth) plus a richer peers table.
  - **Sortable tables** — Algorithms, Peers, Transactions, and Deployments are all sortable, with sensible default sorts.

- **litecoinpool card details** — litecoinpool cards now show the PPS ratio and fee, whole-pool miners and hashrate, dual LTC/DOGE earnings, and a **"Last Payment"** line.

- **Two new coins — Bitcoin Cash II (BCH2) and Bitcoin Silver (BTCS)** — both are now selectable as a GoSlimStratum pool and as a crypto node in the configuration dropdowns, each with its own coin icon across the card, detail, and list views. For miners, GSSM auto-detects these coins from the wallet address — BCH2 from its `bitcoincashii:` prefix, and BTCS from its `bs1…` / `tbs1…` format.

### Improvements

- **One consistent source for every miner, pool, and node** — under the hood, GSSM now reads each device through a single shared path, so the **dashboard card, the detail page, and your alerts always agree**. Two things you'll notice: values that used to occasionally disagree between the card and the detail page now match, and details a device reported all along but GSSM used to silently drop — like found-blocks on the Avalon Nano3s — now appear.

- **Offline devices explain themselves** — an offline miner, pool, or node now shows a short, plain reason for being down (unreachable, timeout, authentication failed, still loading, and so on) right on its card, instead of a wall of "--". Because each card is now its own error surface, the old yellow "Partial Results" banner is gone.

- **Cleaner, unified pool and node cards** — pools now share one card design regardless of source, and nodes share one design regardless of coin (the old DigiByte-specific special-casing is gone). Rows that don't apply to a given device simply don't appear. Enabling or disabling a pool or node updates the card **in place, without a full page reload**.

- **Cleaner detail summaries** — the pool detail page leads with 4 focused summary cards (Active Miners, Hashrate, Blocks Found, Total Paid); the node detail page leads with 6 (Block Height, Difficulty, Connections, Balance, Disk Size, Version). The old raw-JSON dump card on the node detail page is gone in favor of the readable, typed view.

- **Safer miner settings saves** — saving settings to AxeOS devices (Bitaxe / NerdQAxe++) is now hardened so a mistyped value can't accidentally reset the device, and renaming a device's hostname no longer looks like a failed save while the device re-registers on the network.

- **Accepted vs rejected shares are color-coded** — accepted in green, rejected in red — everywhere shares appear: the miners list, every expanded card, the detail page, and per-pool rows.

- **A cleaner separator for paired values** — two-value readouts (such as accepted·rejected shares or a best-diff pair) now use a middle dot (`·`) instead of a slash, so they're easier to read at a glance.

- **Feature discovery on the Configuration page** — the Notifications and Historicals cards now show for everyone, with a small **"PRO"** tag when unlicensed, so you can see what's available. The feature pages themselves stay license-gated.

- **Clearer pool labels** — a matured, spendable block now reads **"SPENDABLE"** instead of an internal status code, and the payments count now reflects the real number of payments.

### Bug Fixes

- **Healthy nodes no longer flap between online and offline** — some nodes (worst on Bitcoin Cash) were toggling offline → online roughly every 30 seconds and firing a stream of false alerts. A healthy node now stays steady, and only reports a transition when something real happens.

- **Idle pools now show as online** — a configured pool with no miners on it (for example, a standby BCH pool) was being mislabeled as offline and could fire false alerts. It now correctly reads online.

- **Correct difficulty on multi-algo coins** — on coins like DigiByte that mine with multiple algorithms, the card and alerts now always read the difficulty for the algorithm you configured (a subtle case-sensitivity slip could previously make it read the wrong one).

- **Correct block timing on the pool detail page** — the detail page no longer mixes up "time since the last block" with "expected time between blocks." Each pool now shows the right one.

- **Node warnings show on modern daemons** — warning messages from newer daemons (Bitcoin Core 29+) now display correctly, alongside older ones.

- **GSSM never overwrites a config it can't read** — if your `config.json` has a typo or a permission problem at startup, GSSM now stops with a clear message and leaves your file **untouched**, instead of quietly replacing it with a blank default. Previously, a single typo could wipe your whole configuration.

### Good to know

- **Historicals is entirely optional and Pro/Enterprise.** With it off (the default), GSSM is fully stateless — no database, no history, no behavior change from 2.x. Turning it on requires a PostgreSQL database that you provide.

- **Pool alerts are GoSlimStratum-only for now** — offline/online alerts for litecoinpool pools aren't wired up yet.

- **New node details are shown, not yet alerted on** — mempool, deployments, and the rest now appear on the dashboard, but new alert types (such as block-height-stuck or DigiDollar activation) are a follow-up.

- **Detail tables show the most recent 100 rows** — the Workers / Blocks / Payments tables and the node tables page through the latest 100 entries.

- **A few miner wallet formats can't be auto-detected.** A bare BCH2 address (no prefix) falls back to showing as **BCH**, and a legacy BTCS address falls back to **BTC**, because those older formats carry no distinguishing marker. The common prefixed / Bech32 forms detect correctly — and this only affects miners, since pools and nodes select their coin explicitly.

---
