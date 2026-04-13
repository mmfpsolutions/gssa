# GSSM Release Notes

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

### Technical Details

- **Disabled Miner:**
  - New `Disabled bool` field on `config.Miner` (JSON: `disabled`, omitempty)
  - New `Disabled bool` and `Status: "disabled"` on `MinerSummary` API response
  - New `Disabled int` count on `MinersSummary` (separate from offline)
  - PUT `/api/v1/config/miners/{id}` accepts `disabled` as `*bool` for explicit true/false/unchanged semantics
  - `fetchMiner()` short-circuits to a zero-cost summary when `Disabled == true`
  - `notifications.Service.checkMiners()` skips disabled miners before state tracking
  - `notifications.Service.checkFanControl()` and the loop-spawn check both honor the disabled flag
  - Telegram `/miners` and `/miner <name>` commands surface the Disabled state with a distinct ⚫ marker
  - New CSS: `.status-disabled` (slate gray dot, no glow) and `.device-card-disabled` (muted opacity 0.55)
  - JS: new `renderDisabledMinerCard()`, `confirmDisableMiner()`, `enableMiner()`, `setMinerDisabled()` helpers in `miners.js`
- **Animated Background:**
  - New `AnimatedBackground string` field on `config.Config`
  - Whitelisted in PATCH `/api/v1/config` allowed-fields map
  - Surfaced via `MetaData.AnimatedBackground` on `GET /api/v1/meta` (no auth required, called early on every page)
  - New file: `internal/web/static/js/background-canvas.js` (~360 lines, four animation modes, pure canvas 2D, no external dependencies)
  - Canvas element `<canvas id="gssm-bg-canvas">` injected via `base.html` (excluded on login page)
  - Init script in `base.html` calls `api.getMeta()` and passes the resolved mode into `window.initGSSMBackground()`; defaults to `nonce-hunt` when no value is set
- **ElphaPex:**
  - New file: `internal/handlers/v1/normalize_elphapex.go` (CGI response normalization)
  - New file: `internal/handlers/v1/cgi-calls.md` (CGI endpoint reference)
  - Polling loop extension in `internal/notifications/polling.go` for ElphaPex devices
  - Coin/algorithm wiring in `config.go`, `meta.go`, `miners.go`
  - Frontend: ElphaPex card renderer in `miners.js`, detail page in `miner-detail.js`
- **Address Detection:**
  - LTC and XEC branches added to `DetectCoinFromAddress`
  - 93 new test cases in `coin_detect_test.go`

### Files Changed/Added

**New files (8):**
- `internal/handlers/v1/normalize_elphapex.go` — ElphaPex CGI normalization
- `internal/handlers/v1/coin_detect_test.go` — 93 address-detection tests
- `internal/web/static/js/background-canvas.js` — animated background canvas
- `internal/web/static/img/coins/ltc.png` — LTC icon
- `internal/web/static/img/coins/doge.png` + `dog.png` — DOGE icon
- `design-documents/ElphaPexMiner-Scrypt-Miner/cgi-calls.md` — ElphaPex CGI reference
- `design-documents/elphapex-dg-home-1-support-plan.md` — implementation plan
- `design-documents/ElphaPexMiner-Scrypt-Miner/asic-health.png` + `chart.png` — reference assets

**Modified files (~14):**
- `internal/config/config.go` — `Disabled` on Miner, `AnimatedBackground` on Config, ElphaPex device type
- `internal/notifications/service.go` — skip disabled miners in poll loop
- `internal/notifications/fan_control.go` — skip disabled miners (loop + spawn check)
- `internal/notifications/polling.go` — ElphaPex polling
- `internal/notifications/telegram_commands.go` — Disabled state in `/miners` and `/miner <name>`
- `internal/handlers/v1/config_crud.go` — accept `disabled` field, whitelist `animatedBackground`
- `internal/handlers/v1/miners.go` — short-circuit `fetchMiner` for disabled, ElphaPex switch case
- `internal/handlers/v1/meta.go` — return `animatedBackground`, ElphaPex thresholds
- `internal/handlers/v1/coin_detect.go` — LTC, XEC support, documented ambiguities
- `internal/handlers/v1/pools.go` — DTM confirmed block count fix
- `internal/types/v1/miners.go` — `Disabled` field on summary, `AnimatedBackground` on meta
- `internal/web/templates/layout/base.html` — canvas element, init script
- `internal/web/static/js/miners.js` — disabled miner card, ElphaPex card renderer, action handlers
- `internal/web/static/js/config.js` — Status column, disable checkbox, animated background dropdown, LTC/DOGE icon support, algorithm options
- `internal/web/static/js/miner-detail.js` — ElphaPex detail view
- `internal/web/static/js/utils.js` — `'disabled'` in `getStatusClass`
- `internal/web/static/css/custom.css` — disabled status/card styles, miner table grid update for new Status column

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

### Technical Details

- New package: `internal/devicelock` — singleton per-device mutex manager for TCP connection serialization
- New file: `internal/notifications/fan_control.go` — P-controller algorithm, fan control loop, state management
- New file: `internal/handlers/v1/fan_control.go` — API handlers for fan status and configuration
- Config: `FanControlConfig` struct added to `Miner` in `config.json` (enabled, targetTemp, minFanSpeed, emergencyTemp)
- Notifications: `fanControlIntervalSeconds` added to polling config (default 30s)
- Events: `miner_fan_emergency` / `miner_fan_emergency_off` event types
- Design documents: `design-documents/auto-fan-control.md`

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

### Technical Details

- Backend: New `fanspeed` command in Canaan command handler (`ascset|0,fan-spd,<SPEED>`)
- Frontend: New `.status-rejected` CSS class (purple `#a855f7`)
- Fan speed range enforced at 30-100 (manual) or -1 (automatic) on both frontend and backend
