# GSSM Release Notes

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

