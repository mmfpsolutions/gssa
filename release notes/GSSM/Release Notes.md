# GSSM Release Notes
## v2.x Series

## v2.0.4

First-class dashboard support for NerdQAxe++ devices running in **dual-pool mode** — mining two different coins concurrently with a configurable hashrate split (e.g. 80% to your DGB pool, 20% to your BCH pool). On prior releases, GSSM only showed you the primary pool's stats and silently hid everything about the second pool. This release surfaces both pools in every view: dashboard card, list view, and miner detail page. Plus one small improvement — the network difficulty for the coin you're mining now shows on single-pool AxeOS cards too (Bitaxe and NerdQAxe++ in failover mode).

### New Features

- **NerdQAxe++ dual-pool mode is now first-class** — If your NerdQAxe++ is configured to mine two coins at once, GSSM now shows you both. **No operator action required** — the dashboard detects dual mode automatically from the device's existing API and surfaces the per-pool information without any config changes.

  - **Two coin icons in the card header** — instead of just the primary coin, you'll see both coins side-by-side in the gallery card header and in the list view's Coin column (e.g. DGB icon next to BCH icon).

  - **A cyan "DUAL" badge in the expanded card** — a banner row at the top of the expanded card body reads `DUAL · 80/20` (or whatever your configured split is), so the dual-mode status is unmistakable when you open a card. The same badge appears in the top header of the miner detail page next to the coin icons.

  - **Per-pool stats in the card body** — the expanded card now has a "Pools" section showing each pool individually, with its own Best Diff, Shares, Net Diff, Pool Diff, and Ping. Each pool's section is labeled with the pool's coin icon and your configured split percentage (e.g. "Pool 1 · [DGB icon] · SV2 · 80%"). Rejected shares render in red per-pool, so you can see at a glance which pool — if either — has a problem.

  - **Both pools' best-diff shown in collapsed view** — when the gallery card is collapsed, the best-diff stat shows both values separated by a middle dot (e.g. `5.71 M · 560.45 K`) on desktop. On mobile (where the collapsed row is tight), only the higher of the two values shows, with the per-pool breakdown still available in the tooltip.

  - **Same treatment in list view** — the Diff column shows both values (e.g. `5.71 M / 560.45 K`) with a tooltip naming each pool by coin, and the same "Pools" section appears when you expand a row.

  - **Dedicated Pools card on the miner detail page** — when you open a dual-mode miner's detail page, a new "Pools" card appears between the device's diagnostic cards and the Device Details section. Same per-pool layout as the gallery card body.

  - **Single-pool devices are unchanged** — every other miner on your dashboard (Bitaxe, regular NerdQAxe++ in failover mode, AxeOS3, AvalonNano, NerdMiner, Antminer, ElphaPex, Whatsminer) renders exactly the same as it did in 2.0.3. The dual-pool surface only activates when a device actually reports dual mode.

### Improvements

- **Net Diff row on single-pool AxeOS cards** — The expanded card body for Bitaxe and single-pool NerdQAxe++ devices now shows a "Net Diff" row right after "Pool Difficulty," reading the current network difficulty for the coin you're mining (auto-formatted with K/M/G/T scaling). The data was always in the device's API response — it just wasn't being surfaced. Older AxeOS firmware that doesn't report the field simply omits the row, no error. (Dual-pool devices don't get this row — they already show Net Diff per-pool in the dual-pool section.)

- **Tighter card header on the Miners dashboard** — The Details / Restart / Disable buttons in the top-right of each gallery card are now icon-only on every screen size (desktop previously showed text labels next to the icons; mobile was already icon-only). Same buttons, same behavior, just compact enough that the new dual-coin icons + DUAL badge fit on the same line at every breakpoint.

---

## v2.0.3

GSSM now tells you when there's a newer version available, so you stop finding out about updates months later from a Telegram message. A small badge appears next to the version link in the footer when a new release ships, the `/version` page picks up a new Updates card, and you can dismiss the badge per-version or turn the check off entirely if you'd rather not have it. The release also picks up a few polish improvements on the crypto node card and detail page.

### New Features

- **Update-available check** — GSSM fetches a small JSON file from `get.mmfpsolutions.io` on startup that describes the latest GSSM release. When your running version is behind, a small orange **update** badge appears next to the version link in the footer of every page. Click the badge for a modal showing your current version, the latest version, the release date, and a link to the release notes. If the new release is also above the minimum-recommended threshold (e.g. a security-relevant fix), the badge turns red and reads **critical** instead — same modal, different urgency.

  The check runs once on startup and caches the result for 24 hours; there's no background polling or periodic phone-home. You can force an immediate refresh from the new Updates card on the `/version` page via the **Check Now** button.

- **Updates card on the `/version` page** — A new section below Runtime Status shows your current version, the latest version, when the latest was released, a link to the release notes, and when GSSM last checked. The **Check Now** button bypasses the 24-hour cache and re-fetches immediately. If you've dismissed the badge for the current version (see below), a "Re-enable update badge for this version" link appears here so you can change your mind.

- **Per-version dismiss** — Inside the modal, **"Don't show again for this version"** hides the badge across all pages until a newer version is published. Once a new release ships, the badge reappears with the new version's details — your dismissal is per-version, not permanent. The dismissed state lives in your browser's local storage (it doesn't sync across browsers).

- **Opt-out via config** — If you don't want GSSM checking at all (running on an isolated network, behind a strict outbound firewall, or just personal preference), add `"updates": { "enabled": false }` to your `config.json`. The check never runs, no badge ever appears, and the `/version` Updates card shows the status as Unknown.

  **Privacy note** — the check is a one-way pull only. GSSM downloads the JSON file from `get.mmfpsolutions.io` (which announces the latest version) and compares against your installed version locally. **No data about your install is sent.** No hostname, no machine ID, no version-ping, no telemetry. 

  **No operator action required on upgrade** — defaults to enabled with the right URL. If you'd previously set `"updates": { "enabled": false }` in your config (manually adding the block on a prior install), that opt-out is preserved. If your `config.json` has no `updates` block — which is what every existing install will look like on first upgrade to 2.0.3 — defaults are applied in memory only; your file on disk is not rewritten.

- **Fails silently if offline** — If `get.mmfpsolutions.io` is unreachable for any reason (your internet is down, your firewall blocks it, the CDN is having a bad day), GSSM simply shows no badge and the `/version` Updates card displays Unknown. No error notifications, no log noise — the update check is best-effort and never gets in the way of your dashboard working.

### Improvements

- **Network hashrate on the crypto node card** — The Blockchain section of each crypto node card now shows the network hashrate fetched from your node, auto-formatted from MH/s up to EH/s (Bitcoin's network sits at ~600 EH/s today and now reads as "600.00 EH/s" instead of "600000.00 PH/s"). For multi-algo coins like DigiByte, the card shows hashrate for **all five algos** (Odo, Qubit, Scrypt, SHA256d, Skein) — and the Difficulty row now reflects the algo you've configured for that node instead of always reading SHA256d. The same algo-aware Difficulty is also used in the collapsed card header, so a DGB-Scrypt operator sees their Scrypt difficulty at a glance. Older daemons that don't implement `getmininginfo` simply omit the hashrate row — no error, no awkward "--".

- **Transport column on the Connected Peers table** — The peers table on the Node Detail page gained a "Transport" column showing whether each peer connection is using **V1** (the original unencrypted Bitcoin protocol) or **V2** (BIP324 — the encrypted transport that shipped in Bitcoin Core 26.x and is enabled in our DGB daemon templates via `v2transport=1`). Sortable like every other column. Nodes whose daemons don't report the field default to V1 — historically that's what every connection was, and any daemon old enough to omit the field is by definition still on V1.

- **License badge in the header** — The header gained a license-tier badge between the right-side icon group and the username block, matching the badge that's already in GSS. **Free-tier** installs see a clickable orange "Unlock Features ↗" badge that opens the pricing page in a new tab when clicked. **Professional** installs see a green "Professional" badge; **Enterprise** installs see a purple "Enterprise" badge. (Both Pro and Enterprise badges hide a small easter egg if you click them, but you'll have to find that one yourself.) Mobile abbreviates the labels (Unlock ↗ / Pro / Ent) so the badge stays compact on narrow screens.

- **Tighter top-right icon group** — To make room for the license badge, the Refresh / Config / Help buttons in the header are now icon-only on desktop too. Same refresh arrow, gear, and question-mark icons, just without the text labels next to them — and slightly larger SVGs to match the new icon-first treatment. Mobile already showed icon-only so nothing changes there.

### Bug Fixes

- **NerdMiner difficulty was being silently rounded down by a factor of 1000** — In list mode on the Miners dashboard (and in the gallery card's collapsed header, and in the expanded card body), a NerdMiner reporting a best-ever difficulty of `2.1941k` was displaying as `2.19` instead — same digits, but the `k` scale suffix was getting stripped during parsing so a value that's actually ~2,194 was rendering as if it were ~2.19. NerdMiners now display the device's reported value with its scale suffix intact, so the diff column reads `2.1941k / 39.148` instead of the misleading `2.19 / 39.148`. Other miner types (AxeOS, CGMiner, Canaan, Whatsminer, ElphaPex) were unaffected — the bug only triggered on devices that send difficulty as a string with a scale suffix.

- **Miner list-mode action buttons drifted toward the middle of the row instead of pinning to the right edge** — In list mode on the Miners dashboard, the action buttons (Details / Restart / Disable) used to sit tight against the perf-percentage cell, leaving empty space between them and the row's right edge — the row outline extended to the right edge but the buttons floated mid-row. The Pools and Nodes list-mode rows didn't have this issue: their action buttons pinned to the row's right edge correctly. Now the Miners rows match — action buttons sit at the right edge of the row outline, both for online and disabled miners. Purely visual; no behavior change.

---

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



