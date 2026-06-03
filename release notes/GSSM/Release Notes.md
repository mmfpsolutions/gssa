# GSSM Release Notes

## v2.0.2

A focused UX-quality release. The Nodes tab no longer hangs when a node is unresponsive, and the "Partial Results" error banner across the Nodes, Miners, and Pools tabs is now short, readable, and one-entity-per-line.

### Improvements

- **Nodes tab no longer hangs on a down or restarting node** — Loading the Nodes tab with any single offline or late-initializing crypto node used to lock the entire page for **roughly 90 seconds** before rendering anything. A stopped DigiByte daemon, a DGB node that was still loading blocks after restart, or a network partition mid-fetch could each trigger this. GSSM now gives up on an unresponsive node within **5 seconds** and renders the page with the working nodes showing live data and the offline one marked as Error. The 18× faster ceiling also flows through to the **Test Connection button** on the Configuration page so a wrong RPC address or stopped daemon fails fast instead of making you wait 30+ seconds. **No operator action required** — the change is automatic on upgrade.

- **Cleaner Partial Results banner** — When something on the dashboard can't be reached (a stopped node, a powered-off Bitaxe, a pool whose API isn't responding), the yellow "Partial Results" banner used to render long technical chains of repeated error wrapping that buried the useful information. The banner now shows one short line per affected entity in this shape:

  ```
  Partial Results
  DGBT-149 (192.168.7.149:9010): unreachable — connection refused
  BCH-149 (192.168.7.149:9002): RPC error -28: Loading blocks... 0%
  bitaxe-1 (http://192.168.1.100): not responding (timeout)
  ```

  Each line carries the entity's name, its address (so you know exactly which one is having trouble without cross-referencing the card below), and a short classified reason: **unreachable** (refused / no route / DNS), **not responding** (timeout), **authentication failed**, or **RPC error N: …** (with the actual code and message from the node — so a DigiByte daemon's `-28: Loading blocks... 0%` is shown verbatim). Multiple failed entities each get their own line, no more 280-character single-line walls.

- **Faster detection of cycling / unstable nodes** — A side benefit of the timeout work. If you have a node that's repeatedly restarting, getting OOM-killed, or flapping due to network issues, the faster offline detection means each cycle that hits a polling tick produces a clean offline → online notification pair instead of often being masked by the long timeout swallowing the down-window. The signal you want for "this node is unhealthy and worth investigating" now reliably reaches your notification channels.

### Bug Fixes

- **Pool partial-results banner used to show internal IDs instead of pool names** — A pre-existing bug surfaced during the error-banner cleanup. When 1, 2, or 3 of the 4 GoSlimStratum API endpoints for a pool failed to respond (e.g. metrics came back but blocks-by-date didn't), the banner showed something like `qK8mNz3p: 2 of 4 endpoints failed` instead of `pool-main (192.168.1.50:4004): 2 of 4 endpoints failed`. The 8-character string was GSSM's internal pool identifier — meaningful only to the database, useless to operators. Now shows the pool's name and address in the same shape as the rest of the new error banner. Affects both the Pools dashboard banner and the Pool Detail page banner.

---

## v2.0.1

A new device family added (Whatsminer), plus a round of polish across the configuration and auto-discovery flows.

### New Features

- **Whatsminer support** — GSSM now supports MicroBT Whatsminer devices (M30S / M50 / M60 series running BTMiner firmware). Add them manually from the Configuration page or let Auto-Discovery find them on TCP port 4433. Dashboard card, detail page (with per-board diagnostic charts and a Power Supply info card), notifications, and threshold editor all support Whatsminer end-to-end.

- **Multiple-fan support for NerdQAxe++** — NerdQAxe++ firmware 1.0.37+ reports both fans on dual-fan models. The miner card now shows Fan 1 + Fan 1 RPM and Fan 2 + Fan 2 RPM separately, each color-coded against your fan-speed thresholds. Single-fan boards (Bitaxe, older NerdQAxe firmware) still show one fan with no label change.

### Improvements

- **Auto-Discovery enables sections automatically on bulk-add** — When you discover pools or crypto nodes and add them, GSSM now flips the "Enable GoSlimStratum Pools" and "Enable Crypto Nodes" master switches to on for you. Previously, a fresh-install operator could add a dozen pools via discovery and wonder why none of them showed data — the section-level toggles still defaulted to off on a clean config. Adding entries now turns the corresponding section on, the way you'd expect.

- **Configuration page polished** — Several fields that almost nobody changes have been hidden from the Configuration page UI. They still live in `config.json` and can be hand-edited by anyone running a non-default setup, but they're no longer cluttering the form:
  - **Web Server Port** and **Cookie Max Age** dropped from Application Settings — defaults (3000 and 3600) work for the vast majority of operators.
  - **API Port** dropped from the GoSlimStratum Pool list and add/edit form — GSS runs on port 4004 by default for everyone; new pools save with that value automatically, existing pools keep their hand-edited port, and the Lookup Keys button uses 4004 internally.
  - **RPC User** column dropped from the Crypto Node list — the value was already masked to `****` everywhere (credentials are encrypted at rest since 1.1.0), so the column never carried useful information. The form still collects the RPC username on add/edit.

---

## v1.1.0

A milestone release. Three big new operator features (Auto-Discovery, encrypted credentials at rest, Disable for pools and nodes), plus a quieter pass on the parts of the UI that no longer made sense once those features landed.

### New Features

- **Auto-Discovery — find your fleet in one click** — A new Discover page (reachable from the Configuration page's new "Auto-Discover Miners" action card, or directly during first-time setup) scans your LAN and surfaces everything GSSM can manage. Three tabs share the same scan controls and results layout but each looks for a different kind of thing:
  - **Miners** — probes every IP in your subnet for the five GSSM-supported miner families: AxeOS (Bitaxe / NerdQAxe++), NerdMiner v1 and v2, ElphaPex DG Home 1, CGMiner-family (Antminer, vnish), and Canaan (Avalon Q / Nano3S). Identifies each device by what its firmware reports, then bulk-adds your selection to `config.json` with one click.
  - **GoSlimStratum Pools** — finds every GSS instance on your network and lists each coin pool loaded inside it. Pick the coins you want, give each a name, and add them all in one shot.
  - **Crypto Nodes** — finds the underlying RPC nodes behind your GSS pools, deduplicates across multiple GSS instances pointing at the same node (so you don't get duplicate rows for the same physical daemon), and lets you bulk-add the new ones. A **Pick coin type** dropdown on each row lets you tell GSSM exactly which coin to label the node as — operators sometimes name their GSS coin keys in ways GSSM can't infer (e.g. `DGB-prod-mainnet-01`), so you get the final word.
  - **Already-configured devices are hidden** — each tab silently deduplicates against your current `config.json` and stashes already-known items behind a "Show N already-configured" reveal so the results list shows only what's new.
  - **Subnet auto-detect** — GSSM proposes a sensible default subnet based on the network interface it's running on. Override it freely (any CIDR up to /16) if you want to scan a different range.

- **Credentials encrypted at rest** — Every sensitive value GSSM stores in `config.json` and `notifications.json` is now encrypted on disk. The Configuration API still masks these fields the way it always did, and your settings forms still show `****`. The difference is what's on disk: open `config.json` directly and you'll see encrypted blobs in place of the plaintext passwords, tokens, and webhook URLs that used to be there.
  - **No operator action required.** The first time you start GSSM 1.1.0, it detects any plaintext credentials and encrypts them in place. Restart again and nothing changes — the file is already encrypted and stays that way. Hand-edit `config.json` to set a new plaintext value? The next start encrypts it.
  - **What this protects against**: config backups, screenshots of your config file, Docker volume snapshots, anything captured without the running binary. An attacker who grabs your config file alone gets ciphertext, not working credentials.
  - **What this doesn't claim to protect against**: someone with full access to the host running GSSM. The encryption is defense in depth, not an isolation boundary.
  - **Fields covered**: every node RPC credential, every notification channel password / token (email, Telegram bot), and every webhook URL and header value (Discord, Slack, generic).

- **Disable individual pools and nodes** — You could already disable a miner (`config.json: miners[].disabled = true`) to suspend its polling and silence its alerts without deleting the entry — useful for hardware swaps, summer shutdowns, or any "this device is intentionally offline" moment. The same affordance is now available for **GoSlimStratum pools** and **crypto nodes**:
  - **Disable button** on each pool / node card on the Pools and Nodes dashboards, with a confirmation modal so an accidental click doesn't suspend a production component.
  - **Status column on the Configuration page** — see at a glance which pools and nodes are enabled vs. disabled, alongside the same column for miners.
  - **Disabled checkbox** in each pool's / node's edit form on the Config page for the same toggle from the editor.
  - While disabled, GSSM stops polling the entry and **no offline alerts fire** for it — exactly the same semantics as disabled miners. Stratum keeps running on the GSS side (GSSM doesn't touch GSS state); GSSM just stops watching the entry.
  - Re-enable from the same button — polling resumes on the next cycle.

### Improvements

- **Compatible with GoSlimStratum's new at-rest encryption** — GoSlimStratum 5.1.0 adds encryption to every credential it stores. GSSM 1.1.0's Auto-Discovery flow knows how to read both formats: when it finds a GSS 5.1.0+ instance with encrypted credentials, it understands them transparently and stores the discovered node with GSSM's own encryption. When it finds a GSS instance on an older version with plaintext credentials, it handles those too. No setup, no flags — just upgrade and Auto-Discovery keeps working across mixed-version fleets.

- **Header navigation tidied** — The three status dots beside the Miners / Pools / Nodes tabs in the top nav have been removed. They were a holdover from before disabled pools / nodes and optional notifications, and could no longer represent the dashboards accurately — a "green dot" on Pools didn't tell you anything useful once some pools could be intentionally disabled. The dashboards themselves remain the canonical source for status, and they're one click away.

- **Test Connection on the node configuration page now reports actual results** — previously the "Test" button always returned "Connection Successful" even when the node was unreachable or the credentials were wrong. Test now exercises a real RPC call and surfaces the actual outcome (success, auth failure, network unreachable, etc.) so you can fix configuration issues without guessing.

- **Editing only the RPC password no longer clears the username** — when you opened a node's config edit form and changed just the password field, leaving the username untouched, the save sometimes lost the username. Fixed: a password-only edit now correctly preserves the existing username.

### Behind the scenes

- Internal refactoring across the configuration loading and saving paths so every entry point treats sensitive values identically. The Auto-Discovery feature and the at-rest encryption layer share the same plumbing.
- Test coverage substantially expanded around configuration handling and the new encryption layer.

---

## v1.0.26

### New Features

- **List View on the Miners, Pools, and Nodes dashboards** — Each dashboard now has a desktop alternative to the card grid: a dense table view where every miner / pool / node is one row of column-aligned values. Click any row to expand it inline with the same body content the card would show.
  - **View toggle** sits in the page header next to Hide summary. The icon shows what you'll switch *to* — `☰ List` in card view, `▦ Gallery` in list view. Hidden on mobile (the existing card view already reads as a list at narrow widths).
  - **Column headers** above the table with values vertically aligned across all rows — read down any column to spot the outlier.
  - **Expand all / Collapse all** button appears next to the view toggle in list mode.
  - **Compact summary row** — the four stat cards at the top of each dashboard (Total Miners / Online / Total Hashrate / Avg Temp, and equivalents for pools and nodes) collapse to a tighter inline row in list view, giving the table more vertical real estate.
  - Your choice (gallery vs list) is remembered per dashboard and survives page reloads. Switching between modes is instant — no waiting for the next poll.
  - Per dashboard, the columns are:
    - **Miners**: Status · Block-found · Coin · Name · Hashrate · Best Difficulty · Shares · Pool Diff · Performance % · Actions. The Pool Diff column reads from each miner's reported value across all supported device types (AxeOS, CGMiner, Canaan/Nano3s, NerdMiner v1/v2, ElphaPex).
    - **Pools**: Status · Coin · Name · Network Hashrate · Network Difficulty · Block · Active Miners · Pool Hashrate · Details
    - **Nodes**: Status · Coin · Name · Chain · Blocks · Difficulty · Verification % · Version · Connections · Details
  - At narrower desktop widths (under 1024px), the lower-priority columns drop automatically so the table stays inside the viewport. Expand any row to see the full detail.

- **Drag-to-Reorder on the Configuration page** — Miners, GoSlimStratum pools, and crypto nodes can now be reordered with the mouse. The new order persists to `config.json` and propagates to every other page in the app on the next poll.
  - **Drag handle** (the `⋮⋮` glyph in a new "Order" column) on each row. Grab and drop where you want it. A blue indicator line shows whether the row will land above or below the target.
  - **Up / Down arrow buttons** on each row for mobile and keyboard users (HTML5 drag doesn't work on touch). Arrows are the only reorder path on phones; on desktop the drag handle takes over.
  - Race-aware: if another browser tab modifies the section between when you loaded the page and when you drop, the server detects the mismatch, the page silently refetches, and you see the fresh state.

- **NerdQAxe++ Settings Page** — NerdQAxe++ devices now get a full settings editor in GSSM, matching what Bitaxe devices have had. Six sections cover Device (hostname, screen options), WiFi (SSID/password), Pool Strategy (Failover / Dual Pool / Stratum keepalive), Primary Pool, Fallback Pool, and Performance (frequency, voltage, fan control mode).
  - **Stratum V2 fields** included — Stratum Protocol (V1/V2 select), SV2 Authority Pubkey, SV2 Channel Type (Extended/Standard), with fallback equivalents. NerdQAxe++ is the first GSS-supported miner with SV2 capability and operators can now configure it from GSSM.
  - **OTP/TOTP aware** — when the device's `GET /api/system/info` reports `otp: true`, a one-line note appears at the top of the form explaining that saves will return a 401 from the device until OTP is disabled in the device's own web UI. v1 doesn't negotiate OTP sessions; the note pre-explains the failure mode so a bare 401 in the save status is interpretable.
  - **Coinbase verification fields are intentionally not exposed yet** — the device's own UI doesn't surface them either, so GSSM holds the line on parity for now.
  - Click the Settings link on any NerdQAxe++ miner detail page to access it (same place Bitaxe settings live).

- **Stratum Protocol indicator built into the status pill** — Every miner's status indicator across the app (dashboard cards, miner detail hero, settings page header, bulk-restart rows, and the new list view) is now a single rounded pill that combines status color with the protocol label inside. Green pill = online, red = offline, etc., with `v1` or `v2` text inside. NerdQAxe++ on Stratum V2 and Bitaxe v2.14+ on Stratum V2 show as `v2`; everything else shows as `v1`. Devices that are offline / error / timeout / disabled show the colored pill with no label since the protocol can't be determined. Hover the pill for a tooltip with the full status + protocol name.

### Improvements

- **Wider text inputs on the Settings page (desktop)** — Long stratum URLs, full `address.worker` wallet usernames, and 51-character SV2 authority public keys were getting clipped inside the settings form's input fields, forcing horizontal scrolling inside each field to see the whole value. On desktop (≥768px width), text and password fields and selects are now twice as wide (28rem instead of 14rem) so addresses and pubkeys fit comfortably. Number inputs (port, frequency, difficulty, etc.) are unchanged — they have short content that doesn't benefit from extra width. Mobile is also unchanged — narrow fields work better with the on-screen keyboard.

- **Configuration page mobile experience** — Several visual fixes for the Config page on phones:
  - **Action buttons render as icons** on mobile (✓ Test, ✎ Edit, ✕ Delete) instead of text labels, saving horizontal space.
  - **The IP-address column drops on mobile** — operators can identify each entry by name; tap ✎ to see the full address when needed.
  - **Long values fit cleanly** — addresses, hostnames, and pool keys no longer push table columns past the screen edge.
  - **Tighter padding** so every pixel of width goes to the values that matter.
  - Each section's column widths re-tuned for the new layout. Pool Type chips (GSS / LTC) no longer clip at the column edge.

- **Cleaner node version display** — Bitcoin Core sub-version strings (used by all the BTC family node implementations) wrap themselves in forward slashes by convention — `/Satoshi:27.0.0/`. The leading and trailing slashes are now stripped for display, so it reads as `Satoshi:27.0.0`. Multi-component versions like Knots's `/Satoshi:29.3.0/Knots:20260508/` become `Satoshi:29.3.0/Knots:20260508` — the internal slash between Satoshi and Knots is informative so it stays.

### Bug Fixes

- **Statistics chart now shows on Bitaxe devices running beta firmware** — When ESP-Miner 2.14.0b3 (an SV2 test build) was installed on a Bitaxe, the device-detail page's statistics chart vanished. Cause: GSSM's internal version parser rejected the `b3` pre-release suffix, so the device was incorrectly classified as older than the version that introduced the new statistics endpoint, and the chart never activated. The parser now tolerates pre-release suffixes from ESP-Miner (`Nb3`, `Nrc1`, `Nalpha`, `Nbeta`) and standard SemVer pre-release / build-metadata forms (`-beta.3`, `+build123`). A beta of `X.Y.Z` is treated as equal to stable `X.Y.Z` for capability gating, so operators running beta firmware see all the same features stable firmware operators do.

---

## v1.0.25

### Bug Fixes

- **Zero Hashrate alerts now fire on Canaan miners (Avalon Q, Nano3S)** — GSSM was silently dropping every field after the first from the response sent by Canaan-firmware miners, leaving the internal hashrate value stuck at zero. Combined with the alert reading the wrong field (lifetime average instead of recent 5-second average), the Zero Hashrate event could never fire on these devices — even when a fan died and the hashboards stopped producing shares while the control board kept the stratum connection alive. Fixed both issues:
  - The parser now correctly extracts every field from the response (hashrate, accepted/rejected shares, best share, temperature)
  - Hashrate is now read from the 5-second average, matching how the dashboard already reads it — so a sudden hardware failure triggers a Zero Hashrate alert within one polling cycle
- **No change to the dashboard miner card** — the miner card on the Miners page was always reading from a different (and correct) code path, so your displayed hashrate, share counts, and best share have been right all along. The fix is entirely on the notification/alerting side.
- **No change to temperature alerts or automatic fan control** — both run on independent code paths that were never affected by this bug, and they continue to work exactly as before.

If you have Zero Hashrate alerts enabled on a Canaan-firmware miner, you'll start receiving Discord / Telegram / email / webhook notifications within ~1 minute of the miner stopping share submission, even if the device remains TCP-connected to the pool.

### Improvements

None this cycle.

---

## v1.0.24

### Improvements

- **Footer version label tidied up** — The version string in the GSSM footer used to display with a leading `v` (e.g. `v1.0.24`). Removed the `v` so the version reads as just the number, matching the version files on disk and the rest of the GSSM ecosystem (GSS, GSBE, MIM).

### Bug Fixes

None this cycle.

### Behind the scenes

- CI/CD workflows bumped to Node.js 24 (replaces the deprecated Node 20). No user-facing impact — builds continue to publish the same Docker images to the same registry.

---

## v1.0.23

### Improvements

- **Cleaner notification messages** — Several readability tweaks across Telegram, Discord, Email, and Generic Webhook alerts:
  - **Prefix on its own line** — The configured Message Prefix (e.g. `[GSSM-138]`) used to share a line with the alert subject, which wrapped awkwardly on phones. The prefix now sits above the subject on its own line, so the alert reads cleanly at every screen width.
  - **Hashrate in human units** — Miner Online and Pool Online alerts no longer show `1.0434260000000001e+06` — they show `1.04 MH/s`, auto-scaled through KH / MH / GH / TH as needed.
  - **Cleaner timestamps** — Last-seen times like `2026-05-06 05:30:05.287506172 +0000 UTC m=+376803.723714515` (Go's internal monotonic-clock reading) now render as `2026-05-06 05:30:05 UTC`.
  - **Title-cased detail labels** — `last_seen`, `previous_hashrate`, `block_height`, etc. now appear as `Last Seen`, `Previous Hashrate`, `Block Height` in the alert body.
  - All four changes apply to the human-readable channels. The Generic Webhook payload keeps raw values and snake_case keys so any custom automation you've wired up against the webhook still works unchanged.

### Bug Fixes

None this cycle.

---

## v1.0.22

### New Features

- **NerdMiner 2.0 Support** — GSSM now supports both classic NerdMiner devices and the new NMMiner 2.x firmware family side by side. Pick the model from a new dropdown when you add or edit a miner. Configured v2 devices unlock:
  - **Richer card data** on the dashboard — accurate hashrate, accepted/rejected shares, VCore temperature, and pool URL straight from the device
  - **Detail page** with hostname, firmware version, Wi-Fi signal strength bars, session vs lifetime stats, network/pool/last-share difficulty, temperatures, free heap, storage usage, and pool info
  - **Restart button** with confirmation — same UX as Bitaxe restart
  - **Six-section Settings editor** — Mining (pools/address/password), Network (hostname/Wi-Fi), Display & LED (brightness/rotation/screensaver), Time & Date (timezone/format), Market (coin watch-list), and Weather (city/coordinates). Each section saves independently.

- **Litecoinpool.org Pool Type** — Add your litecoinpool.org account as a pool entry and watch your account performance from the GSSM dashboard. Just enter a name and your API key:
  - **LTC + DOGE dual-currency cards** showing pool stats, your account stats (hashrate, blocks found, past 24h, unpaid balance, total paid — all dual currency), and LTC network stats
  - **Detail page** with summary tiles, an Earnings Breakdown table (Paid / Unpaid / Total / Past 24h / Expected 24h for both LTC and DOGE), a Workers table (status, hashrate, 24h average, valid/stale/invalid shares, last share time), and recent payouts charts for both currencies
  - **Smart rate-limit protection** — GSSM caches the upstream response for 60 seconds (matching the pool's own update cadence), so refresh-spam and multiple browser tabs never trip litecoinpool's 10-requests-per-minute limit on your API key
  - Add it from the Config page just like you'd add a GoSlimStratum pool — pick "Litecoinpool.org" from the new pool type dropdown

- **Bulk Restart** — Restarting a fleet one rig at a time was painful. New **Bulk Restart** link sits between Fleet View and Collapse all on the Miners page. Opens a dedicated page where you:
  - See every restart-capable miner in a checklist (AxeOS, Canaan, NerdMiner v2 — devices that don't support remote restart aren't listed)
  - Pick which ones to restart with checkboxes, or hit **All** to select everything
  - Confirm and watch — each miner's row animates Ready → In Progress → Success / Fail, with a live progress bar and success/fail counters at the top
  - Restarts run sequentially with a 1-second pause between each, so you don't flood your network or your rigs
  - Failures show with hover-tooltip error messages so you know which rigs need attention; the rest of the fleet still gets restarted
  - URL pattern is `/miners/bulk/restart` so future bulk operations have somewhere to live

### Improvements

- **Faster-feeling Miners page** — The Miners dashboard used to show a single full-page spinner until every rig in the fleet had responded. With 11 miners, one slow rig could stall the whole page render for several seconds. Now the page lights up instantly with a placeholder card per miner (showing the name, device type, and a small loading indicator), and each card fills in with live data as the response arrives. Same data, same backend, just stops feeling sluggish.

- **Cleaner summary card sizing** — Total Miners / Online / Total Hashrate / Avg Temperature on the Miners page (and the equivalent cards on Pools and Nodes) had numbers that jumped from medium to extra-large at desktop breakpoints. Now they're consistently sized across screen sizes, matching the look of the GoSlimStratum coin dashboard.

- **Status dots on Bulk Restart match the Miners page** — Same colors for online (green), offline (red), error (yellow), timeout (gray), and the purple dot for "online but rejecting shares".

### Bug Fixes

None this cycle.

---

## v1.0.21

Consolidated release rolling up changes from v1.0.17 through v1.0.21 (intermediate point releases were never publicly distributed).

### New Features

- **Disable Miner Flag** — Pause individual miners without removing them from your config. Built for seasonal shutdowns (summer heat, winter storage), repair downtime, or any scenario where a miner is intentionally offline:
  - **One-click disable** from the miner card on the dashboard (gray ⏻ icon next to the existing Restart button)
  - **One-click enable** to resume — disabled cards show a muted appearance with a single Enable button
  - Disabled miners **skip the polling loop entirely** — no health checks, no offline alerts, no temperature warnings, no hashrate-drop notifications
  - **Auto fan control is paused** for disabled miners — no fan commands sent to a Nano3s in summer storage
  - **Telegram bot** shows Disabled state distinctly (⚫) instead of misleading 🔴 Offline; `/miner <name>` includes a re-enable hint
  - **Status column** in the config page miners table shows Enabled/Disabled at a glance
  - **Edit form** has a Disabled checkbox with an explanatory hint
  - Disabled miners stay visible on the dashboard (muted card) so you remember they exist
  - Backend short-circuits the network fetch entirely — zero RPC noise for unreachable disabled devices

- **Animated Background Canvas** — Subtle animated canvas behind the dashboard. Pure cosmetic, zero backend impact, **hot-reloads on next page navigation** without restarting GSSM:
  - **Nonce Hunt** (default) — hex nonces rapidly mutate then occasionally flash gold and burst on a "hit" — visualizes the actual ASIC nonce search
  - **Hash Drift** — hex string fragments drift upward at low opacity
  - **Node Mesh** — floating nodes connect via faint lines forming a network topology
  - **Share Pulse** — radial rings expand outward simulating share submissions
  - **Off** — no animation
  - Configurable from Application Settings on the Config page
  - Pauses automatically when the browser tab is hidden
  - Respects OS `prefers-reduced-motion` setting
  - Mobile-aware: fewer particles on small screens

- **ElphaPex DG Home 1 Support** (Scrypt Miner) — Full integration for ElphaPex DG Home Scrypt ASIC:
  - New device type added to the multi-miner support roster
  - Dedicated miner card with Scrypt-specific metrics (hashrate, ASIC health chart, fan stats, pool details)
  - CGI API normalization layer (~466 lines) handling the device's HTTP CGI endpoints
  - Polling integration with the notification service
  - Detail page with ASIC health chart visualization
  - Config wizard support — selectable from the Add Miner Device Type dropdown
  - Comprehensive integration documentation in `design-documents/`

- **DOGE & LTC Coin Support** — Visual badges for Litecoin (LTC) and Dogecoin (DOGE) miners:
  - LTC coin icon and dropdown option
  - DOGE coin icon and dropdown option
  - Auto-detection from miner pool addresses

### Improvements

- **Better Address Detection** — `DetectCoinFromAddress` now recognizes more address formats:
  - **LTC** — Bech32 (`ltc1`, `tltc1`), P2PKH (`L...`), P2SH (`M...`)
  - **XEC** — Explicit CashAddr prefixes (`ecash:`, `ectest:`)
  - Documented known ambiguities (DGB vs DOGE share version byte, BTC vs BC2 share format, bare CashAddr defaults to BCH)
  - 93 new unit tests covering the recognition logic
  - Fixes "Unknown coin" badges on miners pointing at LTC/DOGE/XEC pools

- **Algorithm Options on Add Miner** — Device Type dropdown now distinguishes algorithm where it matters (Scrypt vs SHA256d) so users pick the right card for their hardware

### Bug Fixes

- **DTM Pool Confirmed Block Count** — Fixed an off-by-one in the GoSlimStratum DTM pool stats where confirmed block counts were being counted incorrectly under certain pool configurations

- **DOGE Icon Routing** — Coin icon for Dogecoin was being requested at `dog.png` due to an existing 3-character symbol-truncation pattern; added matching asset filename so the icon renders correctly across cards, dropdowns, and badges

---

## v1.0.16

### New Features

- **GSSM Auto Fan Control (Pro/Enterprise)** - Automatic fan speed adjustment for Nano3s based on target temperature:
  - Proportional controller with dead band algorithm — adjusts fan speed based on average chip temperature (TAvg)
  - Emergency override using max chip temperature (TMax) — forces fan to 100% if threshold exceeded
  - Configurable per-miner: target temperature (40-95°C, default 90°C), minimum fan speed (30-80%), emergency temperature (85-110°C, default 100°C)
  - Independent polling loop (default 30s interval), runs regardless of notification service state
  - Toggle on/off with confirmation modals warning about multi-instance conflicts and firmware auto fallback
  - Live status display showing current TAvg, TMax, fan speed, and last adjustment time
  - Styled slider controls for all settings (target temp, min fan speed, emergency temp)
  - Emergency temperature notifications via existing miner notification channels (tied to High Temperature toggle)
 

- **Per-Device TCP Connection Lock** - Serialized TCP connections to Canaan devices to prevent connection timeouts when multiple subsystems (dashboard, notifications, fan control) query the same miner simultaneously

### Improvements

- **Mobile Collapsible Settings** - Fixed collapse/expand sections not responding to taps on mobile devices (added touch-action, pointer-events fix)
- **Reduced Miner Load** - Fan control uses lightweight `stats` command (~8KB) instead of `estats` (~64KB) for temperature reads

---

## v1.0.15

### New Features

- **Nano3s Fan Control** - Added fan speed controls to the Nano3s settings page:
  - Slider to set manual fan speed (30%-100%)
  - "Reset to Automatic" button to restore firmware automatic fan control (sends command immediately)
  - Current fan speed percentage displayed on the slider

- **Rejected Shares Status Indicator** - Miner dashboard status dot now shows purple when a miner is online but has rejected shares, providing at-a-glance visibility even with cards collapsed

### Improvements

- **Collapsible Settings Sections** - Work Mode, LED Control, and Fan Control sections on the Nano3s settings page are now individually collapsible with persistent state (remembered across page loads)

