# GSSM Release Notes
## v2.x Series

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



