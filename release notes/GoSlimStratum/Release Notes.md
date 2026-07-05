# GoSlimStratum — Release Notes
## v5.x Series through v5.1.3

---

## v5.1.3 — DigiByte 9.26.x Mining Fix

GoSlimStratum v5.1.3 is a focused hotfix for **DigiByte mining on DigiByte Core 9.26.x**. If you mine DigiByte (SHA256d) with modern ASICs — Bitaxe, NerdQAxe++, Avalon Nano, and similar — and you've upgraded your DigiByte node to the 9.26.x line, your miners may have started losing work: **rejected "low difficulty" shares**, or your DigiByte **dashboard hashrate reading about half** of what the miner itself reports. v5.1.3 restores full, correct DigiByte mining.

Nothing changes for any other coin, for DigiByte's other algorithms (Scrypt / Skein / Qubit / Odocrypt), or for older DigiByte nodes. This sits entirely on top of 5.1.2.

### ⛏️ What happened — and the fix

DigiByte Core 9.26.x began rolling out **DigiDollar**, and part of that rollout uses one bit of the block **version** field to signal the upgrade across the network. That bit happens to land in the exact region SHA256 mining chips borrow for their own internal speed trick (version rolling, a.k.a. AsicBoost). With both sides writing to the same space, the miner and the pool ended up disagreeing about what each share actually contained — and perfectly valid shares got miscounted.

Depending on the miner, that showed up two different ways:

- **Rejected shares.** Some devices (e.g. Avalon Nano) had good shares bounced by the pool as "low difficulty," even though the miner was working perfectly.
- **Half hashrate, silently.** Others (e.g. NerdQAxe++) discarded the affected shares on the device before sending them — so the miner's own screen showed full speed while GSS credited only about half.

v5.1.3 adjusts how GoSlimStratum builds DigiByte SHA256 jobs so the miner and the pool line up again. Rejected shares go back to accepted, and your dashboard hashrate returns to the miner's true rate.

### Things to know

- **DigiByte SHA256d only.** The fix is scoped precisely to the DigiByte SHA256 pool. Every other coin — and DigiByte's other algorithms (Scrypt, Skein, Qubit, Odocrypt) — is completely untouched.
- **Backward-compatible.** If your DigiByte node is on an older release (8.26.2 or earlier), nothing changes. The fix only engages while the node is actively signaling the DigiDollar upgrade, and does nothing otherwise.
- **Temporary by nature.** Once DigiDollar finishes activating on the DigiByte network, the node stops using that version bit and the fix quietly stands down on its own — no further action, ever.
- **DigiDollar signaling is preserved.** Your pool still contributes to the network's DigiDollar vote normally; this change doesn't slow activation down.

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image, restart your container. Your existing `config.json` works as-is. No database migration, no config changes.
- **Reconnect your DigiByte miners once.** For the fix to take hold on a miner that's already connected, it needs to reconnect and pick up the corrected jobs — so **power-cycle (or reboot) your DigiByte SHA256 miners once** after upgrading.
- **How to confirm.** After reconnecting, your DigiByte miners' rejected-share count should stop climbing, and the DigiByte hashrate on your dashboard should match the number the miner shows on its own screen.
- **Mining DigiByte on an older Core release?** Nothing to do — the fix is a no-op on pre-DigiDollar nodes.

---

## v5.1.2 — CashAddr for Custom Coins

GoSlimStratum v5.1.2 adds one operator-requested capability: **custom coins defined in `coins.json` can now use CashAddr addresses** (the `bitcoincash:q...` / `ecash:q...` style format) directly.

Previously, if you added a Bitcoin Cash-family coin through `coins.json`, GSS only understood the older "legacy" address format (`1...` / `3...`), so you had to convert every CashAddr to legacy before using it. Now you can paste the CashAddr format your wallet shows you — no conversion step — in your pool's mining address, in your miners' usernames, and (in DTM mode) for revenue-share payouts.

No behavior changes to mining, payouts, alerts, or Stratum V2. This sits entirely on top of 5.1.1.

### 🪙 CashAddr support for custom coins

To turn it on for a custom coin, add a `cashaddr` block to that coin's `address` section in `coins.json`, naming the coin's address prefixes:

```json
"address": {
  "base58": {
    "p2pkh": { "mainnet": 0, "testnet": 111 },
    "p2sh":  { "mainnet": 5, "testnet": 196 }
  },
  "cashaddr": {
    "prefix": { "mainnet": "bitcoincash", "testnet": "bchtest" }
  }
}
```

With that block present, the coin accepts **both** address styles:

- **CashAddr** — `bitcoincash:q...` (P2PKH) and `bitcoincash:p...` (P2SH), or the short form without the prefix (`q...` / `p...`)
- **Legacy Base58** — `1...` (P2PKH) and `3...` (P2SH), exactly as before

#### Things to know

- **Nothing changes for existing setups.** If you don't add a `cashaddr` block, your coin works exactly as it did before. If you're already using converted legacy addresses, they keep working — you can switch to CashAddr whenever you like, or never.
- **The prefix must match your coin.** A CashAddr's built-in checksum includes its prefix, so the `mainnet` / `testnet` prefixes you configure must be the exact ones your coin's wallet issues (e.g. `bitcoincash` and `bchtest` for Bitcoin Cash).
- **Built-in coins are unaffected.** BTC, BCH, XEC, DGB, LTC, and DOGE already handle their address formats natively — this change is only for custom coins you define yourself in `coins.json`.
- **Same coins everywhere.** The CashAddr you configure works identically in your `mining.address`, in a miner's stratum username, and in DTM revenue-share — because under the hood CashAddr and legacy addresses point to the exact same destination; only the text format differs.

See the updated coin configuration guide and the `coins.example.json` example (the `bitcoincashii` entry) for a full custom-coin definition using CashAddr.

---

## v5.1.1 — Update-Available Badge, Dashboard Polish

GoSlimStratum v5.1.1 is a focused, operator-feedback-driven release. Two themes:

- **You'll now know when there's a new GSS to upgrade to.** A small `update` badge appears in the footer of the dashboard whenever a newer release is published. Click it for current → latest, release date, and a link to the release notes.
- **Dashboard polish.** The SHARES card now shows the pool's best share next to the `% valid` line; the miners-table column that was misleadingly named **Lifetime** now correctly reads `48hrs` (or whatever your `share_retention_hours` is set to); the per-coin HASHRATE card gains a 5-minute hashrate subtitle under the existing 15-minute average.

No behavior changes to mining, payouts, alerts, or Stratum V2 — everything in this release sits on top of 5.1.0's foundation.

### 🔔 Update-Available Check

GSS now knows when a newer version has been published and surfaces it as a small `update` badge in the footer of every page, right next to your version number. Click the badge to see:

- Your current version
- The latest available version
- When it was released
- A link to the release notes

#### Two states

| State | Badge | When |
|---|---|---|
| **Update available** | Small orange `update` | A newer version is published and you're behind |
| **Critical update** | Small red `critical` | We've marked the new version as "you really should upgrade" — reserved for security-relevant fixes or known-broken-behavior corrections |

For the critical case, the modal title also changes to **"Critical Update Available"** so the visual cue lands at a glance.

#### How the check works

On startup, GSS makes one HTTPS call to `https://get.mmfpsolutions.io/versions/gss/latest.json` — a small static file that names the current release. The result is cached for 24 hours; after that, the next page load triggers a fresh check. There's a manual **"Check Now"** button on the `/version` page if you want to force a refresh without waiting.

#### Things to know

- **Fail-silent.** If your install is firewalled or can't reach the internet, nothing appears — no badge, no error toast, no scary log messages. The feature degrades silently and the rest of GSS keeps working normally.
- **No notifications.** GSS never fires a Telegram / email / webhook alert when an update is available. The badge is UI-only — you decide when to upgrade, on your schedule. No new noise on top of your real operational alerts.
- **Dismissible per version.** Click "Don't show again for this version" in the modal and the badge stays hidden until the next release ships. Need to bring it back? The `/version` page has a "Re-enable badge" link whenever a dismissal is active.
- **Enabled by default, off-able if you want.** Add this to your `config.json` to disable entirely:
  ```json
  "updates": {
    "enabled": false
  }
  ```

The `/version` page also gains an **Updates** card with the same status information always visible — so you can check at any time without waiting for the badge to appear.

### 📊 Dashboard Polish

Three small operator-feedback-driven changes to the per-coin dashboard.

#### Pool Best Share on the SHARES card

The SHARES card has always shown total share count plus `X% valid`. Now it also shows the pool-wide best share under the `% valid` line:

```
123,456
75% valid
42.5G best
```

The value is the largest best-share difficulty seen by any miner in your fleet within the share-retention window. Your headline pool record-holder right at the top — no need to scan the miners table to find the max by eye.

#### "Lifetime" and "all-time high" labels now reflect actual retention

Three labels across the dashboards used to say **Lifetime** or **all-time high** when they actually meant "shares within the `share_retention_hours` window" (default 48 hours). They've been corrected to reflect the actual configured window:

| Card / Row | Before | After (default 48h) | If `share_retention_hours: 24` |
|---|---|---|---|
| Per-coin miners-table column header | `Lifetime` | `48hrs` | `24hrs` |
| Per-miner BEST SHARE card subtitle | `all-time high` | `48hrs high` | `24hrs high` |
| Per-miner Performance Stats row label | `Lifetime Shares` | `48hrs Shares` | `24hrs Shares` |

Same data underneath — just labels that match what the numbers actually represent. Operators reading the dashboard quickly often misread "Lifetime" as "all-time" and were surprised when shares older than the retention window dropped off; this fixes it.

#### 5-minute hashrate as a secondary subtitle on the HASHRATE card

The big bold number on the per-coin HASHRATE card is your 15-minute average, with `15m average` underneath. A new secondary subtitle shows the 5-minute value as a recent-trend hint:

```
42.5 TH/s
15m average
38.2 TH/s 5m avg
```

Lets you see at a glance whether hashrate is trending up or down in the recent past without opening the chart. 1m is intentionally skipped — too noisy to be useful in a glance-able stat.

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image, restart your container. Your existing `config.json` and `notifications.json` work as-is. No new database migration. Existing data untouched.
- **Update-Available Check: enabled by default; nothing to configure.** No `updates` block needs to appear in your `config.json` — defaults work for the vast majority of operators. After restart, if there's a newer GSS release published than the one you're running, the badge appears the next time you open a GSS page.
- **Dashboard polish: nothing to configure.** All three changes are automatic. The label changes use your existing `metrics.share_retention_hours` value (default 48). If you've set a custom retention window, every relabeled spot picks it up.
- **Don't see the update badge?** Check `/version` — it shows the current status always. If status is `unknown`, your install couldn't reach `get.mmfpsolutions.io` (firewall, offline, private network, etc.). The feature degrades silently and the rest of GSS keeps working normally.

---

## v5.1.0 — Coin Alerts, SV2 Connection Liveness, Full At-Rest Encryption

GoSlimStratum v5.1.0 is a substantial release built around three independent features that each solve a real-world operator problem.

- **Coin Alerts** — a new per-coin notification system that fires on noteworthy share events and network difficulty swings. Tell me when any miner submits a new pool-best share, when chronic rejections start piling up on a miner, or when a chain's difficulty crosses a threshold I care about. Configured per coin, routed to your existing Telegram / email / webhook channels.
- **Stratum V2 Connection Liveness** — fixes a class of false-positive disconnects on SV2 miners that GSS v5.0.x couldn't catch on its own. Kernel-level TCP keepalive + `TCP_USER_TIMEOUT` replace the app-level read deadline that didn't fit V2's "quiet between shares" traffic pattern.
- **Full at-rest encryption** — every secret in your config files (node RPC passwords, metrics database password, Telegram bot token, webhook URLs and Authorization headers) is now encrypted on disk and masked in API responses. Previously only your wallet passphrase was encrypted; v5.1.0 brings the same treatment to everything else.

Plus polish: orphaned per-coin notification entries self-clean, "Reset All Statistics" also resets the alerts pipeline's pool-best record, the Notifications config link is now always visible (with a clear "license required" page if you don't have one), and the in-app Help reference has been updated for every new feature.

### Coin Alerts

A new **Coin Alerts** panel appears on every per-coin Configuration page. Master switch at the top, then four independent alert types, each with their own thresholds.

> Coin Alerts require both **notifications enabled** (GSS license) and **metrics enabled** (Postgres). Without both, the panel is dormant. The page shows a callout pointing to MMFP pricing if you need a license.

#### 🏆 Best Share Alert

Fires **once** when any miner submits a new pool-wide best share above your floor. The "new record" alert — useful for celebrating when your fleet hits something noteworthy and for tracking the long-tail of "luckiest share ever" outcomes.

- **Minimum Value**: floor below which the alert won't fire, in the same units the miner card on the dashboard shows. Accepts SI suffixes — type `1G`, `1.5G`, or `1000000000` interchangeably.
- The pool's best-share record is loaded from your shares history at startup so a restart doesn't replay history. **"Reset All Statistics"** on the dashboard now also resets this — clean slate for testing.
- Alerts include a "% of block difficulty" line so you can see how close that share was to actually finding a block.

#### 💎 Notable Share Alert

Fires **every time** any miner submits a share above your floor (not just records). Use this for "tell me when ANY miner hits something good." Rate-limited per miner to keep volume sane.

- **Minimum Value**: same units / SI suffixes as Best Share.
- **Max Alerts/hour (per miner)**: rate cap. `10` = at most one alert every 6 minutes per miner; `0` = unlimited.
- **Breakthrough rule**: even when the rate limit is suppressing alerts, a share **at or above 2× the last fired value** breaks through. So if a miner just hit a notable 10K share and now hits a 25K share inside the rate window, you'll still see it — the bigger jump is worth surfacing even when the smaller stream is being throttled.

Tip: set the Notable floor a bit above your "typical noteworthy" value so the rate cap stays loose for genuinely high shares.

#### ⚠️ Rejected Shares Alert

Fires when a specific miner crosses a rejection threshold within a rolling window. Leading indicator that something has gone wrong with that miner's infrastructure (firmware glitch, network instability, voltage problem).

- **Threshold Count**: rejections needed within the window to fire.
- **Window (minutes)**: how far back to count. Default 10.
- **Max Alerts/hour (per miner)**: optional cap for chronic flaky miners that would otherwise re-fire every window. `0` = no cap.
- Per-miner counter — one noisy device doesn't bury alerts for the rest of the fleet.
- Counter resets to zero on fire, so the next alert requires another full threshold's worth of rejections.
- **Stale shares count as rejections** — they're functionally the same thing from the operator's perspective.

#### 📉📈 Network Difficulty Alert

Fires when the chain's network difficulty moves above or below a threshold you set. Useful for "tell me when difficulty jumps" (chain about to get hard) or "tell me when it drops" (window of opportunity for solo / small-pool mining).

- **Below Threshold**: fires when difficulty drops below this value.
- **Above Threshold**: fires when difficulty rises above this value.
- Either side can be set independently — leave the other at `0` to disable it.
- Both can be set together for a band — but the form prevents you from saving `below ≥ above` so a fat-finger doesn't break the pool's startup.
- Thresholds are in **raw units** — the same number mining.info shows for the chain, the same number the main dashboard's "Network Difficulty" tile shows. Accepts SI suffixes (`535G`, `218K`, etc.).
- Fires on **transitions only**. Sustained breach fires once; if the chain recovers and breaches again, you get another alert.

✅ **Recovery alerts.** When difficulty climbs back into the OK band (out of an above-breach, or up across the below threshold), GSS fires a recovery alert too — "things have stabilized." Less noise than constantly checking the dashboard to see if the alert state has resolved.

#### Hot reload — thresholds apply immediately on save

Coin Alerts thresholds are **hot-reloadable**: edit floors, rate caps, or band thresholds in the UI, hit Save, and the running pool picks up the new values on the very next share or template. No pool restart, no GSS restart. The pool-best record, rejection counters, and rate-limiter state all survive the reload — you're tightening or loosening your rules, not resetting history.

Other coin config sections (node password, stratum port, mining address, VarDiff, etc.) still require a pool reload or full GSS restart to take effect. The Web UI's existing "restart required" warning persists for those; the Coin Alerts panel has its own small green callout noting that changes apply immediately on save.

#### Routing — Notifications page

Each Coin Alert type has its own toggle and channel selection on the Notifications page, alongside the existing Block / Payout / Node / Miner event types:

- **Best Share (Coin Alerts)**
- **Notable Share (Coin Alerts)**
- **Rejected Shares (Coin Alerts)**
- **Network Difficulty (Coin Alerts)**

Pick which channels (Telegram, email, your webhooks) each alert type goes to. The notifications page reloads live without restart — you can opt in and out of channels mid-run.

#### Quick start

1. Open a coin's Configuration page → scroll to the **Coin Alerts** section.
2. Tick **Coin Alerts Enabled** (master switch).
3. Set thresholds for whichever alert types you want — start conservative (high floors / low rate caps) and tune down as you see how often they fire.
4. **Save.** Thresholds apply immediately. No restart.
5. Open the Notifications page → scroll to **Event Types** → tick the four new "(Coin Alerts)" rows and pick channels for each. Save.

You'll see your first alerts on the next qualifying share or template fetch.

### Stratum V2 Connection Liveness

If you've been running miners on a Stratum V2 listener since v5.0.0, you may have seen the occasional false-positive disconnect — GSS dropping a miner's session even though the miner was online and healthy. v5.1.0 fixes the root cause.

**What was happening:** GSS V2 used the same application-level read deadline (`connection_timeout_seconds`, default 600) that V1 uses. On V1 that works because V1 traffic is chatty — `mining.ping`, `mining.submit`, periodic difficulty adjustments all flow back to the pool, naturally refreshing the deadline. SV2 is a different protocol: idle miners on low-rate coins can go 10+ minutes between share submissions, with no other application-layer chatter in either direction. The 600-second deadline tripped on miners who were perfectly healthy, just quiet.

**The fix:** SV2 sessions now use kernel-level **TCP keepalive** (probe packets sent by the OS on idle connections) plus **`TCP_USER_TIMEOUT`** (bounds how long the kernel will keep retrying an unACKed packet before giving up). This is the same liveness mechanism Linux servers use for any long-lived idle TCP connection. The application-level `connection_timeout_seconds` field is now **V1-only** — V2 no longer uses it.

**Default behavior:** TCP keepalive sends a probe every 30 seconds after 30 seconds of idle, gives up after 4 failed probes — meaning a quietly-dead miner is detected within roughly 90 seconds (vs the prior 600s best-case, or 13–30 minutes in the death-during-push case on V2's push-heavy protocol). Production validation across V1 and V2 mixed fleets confirmed zero false disconnects across 72+ hours of real miner traffic.

**Tunable per-pool.** New fields in the Global Configuration's Stratum section let you tune the keepalive math for unusual network conditions:

- `tcp_keepalive_idle_seconds` (default 30)
- `tcp_keepalive_interval_seconds` (default 15)
- `tcp_keepalive_count` (default 4)
- `tcp_user_timeout_ms` (default 0 = auto-compute from the above)

Most operators won't need to touch these. They're per-coin override-able if a single coin has unusual network conditions, but in practice you set them once at the global level and forget about them.

> Linux-only for `TCP_USER_TIMEOUT`. On macOS / Windows dev environments the second-layer protection falls back to TCP keepalive alone — sufficient for development, not relevant for production since GSS deploys on Linux.

### Full At-Rest Encryption for All Sensitive Config Values

GSS v3.0.28 introduced encryption for the wallet passphrase. v5.1.0 extends the same treatment to **every other secret** in your config files. After upgrade, your `config.json` and `notifications.json` no longer hold any plaintext secret values — they all migrate to the same `ENC:` ciphertext format the wallet passphrase already used.

**What gets encrypted (newly in 5.1.0):**

- **Node RPC password** (each coin's `node.password`)
- **Metrics database password** (`metrics.database_password`)
- **Telegram bot token** (`channels.telegram.bot_token`)
- **Webhook URL** (each entry in `channels.webhooks[].url`)
- **Webhook headers** (each value in `channels.webhooks[].headers` — covers `Authorization`, `X-API-Key`, and any other auth-header pattern you may have configured)

**What stays plaintext** (unchanged): non-secret fields like usernames, host/port pairs, addresses, every other config field. Only actual secrets get the encryption treatment.

**What you see in the Web UI:**

Every password / token / URL field on the Config and Notifications pages now displays `****` instead of the actual value. The eye-toggle icon on edit forms still reveals what you're typing in real time, but the saved value is masked in display rows. If you don't touch a field, it stays exactly as it was — the form treats the `****` you see as "don't change."


**Migration:**

On first startup with v5.1.0, GSS rewrites your `config.json` and `notifications.json` files, converting every newly-covered plaintext secret to `ENC:` ciphertext. The conversion is automatic and one-time per field — subsequent startups read the encrypted value, decrypt it in memory for use, and the on-disk file stays encrypted.

> **Threat model.** This protects against accidental disclosure — config files in support bundles, screenshares, log dumps, third-party API consumers, browser DevTools, tcpdump on localhost. Same threat model as the v3.0.28 wallet passphrase encryption — defense in depth, not isolation.

**GSSM operators:** if you run GSSM autodiscovery pointed at this GSS instance, you'll need to be on GSSM version 2.0.0 or better before autodiscover can read GSS-encrypted values. See the upgrade notes below. 

### Other Improvements

#### Notifications — Per-coin list now self-cleans

The "Per-Coin Settings" panel on the Notifications page used to be **add-only**: when you added a coin to your pool, an entry appeared; when you removed a coin, the orphaned entry stayed forever. On a long-running install with churn, the list could accumulate clutter.

v5.1.0 turns this into a true bidirectional reconcile. At startup, GSS adds entries for newly-configured coins (default opt-in) AND removes entries for coins no longer in your config. Disabling a coin temporarily keeps the entry (so your opt-out preference is preserved for when you re-enable). Only **removing** a coin from `config.json` triggers cleanup.

You'll see stale entries disappear on your first 5.1.0 startup — that's expected.

#### Notifications Config link — always visible on Global Config

Previously the Notifications panel link on the Global Configuration page was hidden if your license didn't include notifications. Now it's **always visible**. Clicking it lands you on a clean "Feature Not Available" page with a "Manage License" button — better discoverability than hiding the feature entirely.

#### "Reset All Statistics" also resets the Best Share alert prime

If you hit "Reset All Statistics" on the dashboard expecting a clean slate, that now includes the Coin Alerts pipeline. The watcher's in-memory pool-best record drops to zero, so the very next noteworthy share fires a Best Share alert if you've got one configured. Matches the operator-intent meaning of "clear stats." Single-worker delete deliberately does NOT re-prime — other workers' historical shares could still legitimately be the pool record.

#### In-app Help reference — updated

The in-app Help reference (the **(?)** icon in the page header) gained a new **Coin Alerts** section under the **Coin Pool Configurations** sidebar group, with a visual mock of the configuration panel and a numbered field reference for every threshold and rate-cap input. The **Notifications** section was updated to document the four new event types.

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image, restart your container. Your existing `config.json` and `notifications.json` work as-is. No new database migration. Existing data untouched.
- **First-startup migration.** On the first 5.1.0 startup, GSS rewrites both config files to convert newly-covered plaintext secrets (node passwords, metrics DB password, Telegram bot token, webhook URLs and headers) to `ENC:` ciphertext. The migration is one-time per field, idempotent on subsequent startups, and logged at INFO level so you can confirm it happened. Wallet passphrases (already encrypted since v3.0.28) are untouched.
- **Coin Alerts: nothing to do unless you want them.** The new `alerts` block on each coin defaults to fully disabled. A config file from before 5.1.0 (no `alerts` block at all) loads cleanly. To enable: open a coin's Configuration page, scroll to **Coin Alerts**, tick **Coin Alerts Enabled**, set whatever thresholds you want, Save. Then on the Notifications page, tick the four new event types and pick channels. **Thresholds apply immediately on save** — no restart needed for Coin Alerts.
- **SV2 connection liveness: nothing to do.** Defaults are sensible. If you've been seeing false-positive V2 disconnects, the next dead-miner event in your log should resolve within ~90 seconds instead of the prior 600s+ pattern.
- **Stale notification entries will self-clean.** If your `notifications.json` has accumulated entries for coins you've removed over time, the first 5.1.0 startup drops them automatically. Coins that are merely disabled (not removed) keep their preferences.
- **Hit "Reset All Statistics" recently?** That now also resets the Best Share alerts watcher to zero. If you were relying on the old behavior of historical-best persisting across resets, plan accordingly — the new behavior matches operator intent more than the old one did.
- **GSSM autodiscovery coordination.** Until your GSSM instance ships a matching 5.1.x release that knows how to read GSS's new `ENC:` values, autodiscover-fetched fields will look opaque. Make sure you are on GSSM 2.0.0 or better before using autodiscovery after upgrading to GSS 5.1.0 for node discovery.

---

## v5.0.1 — Node Wallet Sweep + Stratum V2 Polish

GoSlimStratum v5.0.1 is a focused follow-up to v5.0.0's big Stratum V2 release. The headline addition is the **Node Wallet Sweep** feature — a one-click, PIN-protected way to move your accumulated node wallet balance to cold storage (or anywhere else) directly from the Web UI, without ever opening a terminal. Plus polish around the Stratum V2 Standard Channel codebase to validate compatibility with the freshly-released Bitaxe SV2 2.14.0b3 Beta firmware.

### Node Wallet Sweep

In pool mode (or DTM mode with a non-zero pool fee), your node wallet accumulates a balance over time — pool-fee outputs from every coinbase transaction land in your configured mining address. Until v5.0.1, the only way to move that balance to cold storage was through your coin's command-line interface (`bitcoin-cli sendall ...`, `digibyte-cli sendtoaddress ...`, etc.) executed from a terminal on the node host. That works for power users, but it's a meaningful friction point for prosumer and home-pool operators.

v5.0.1 adds a guided **Sweep Wallet** flow to each supported coin's Earnings page.

**What you get:**

- **Node Wallet card** on each per-coin Earnings page, showing the live node wallet balance with a **Sweep Wallet** button, refreshes automatically every 60 seconds. Collapsible like every other card on the page, with the collapse state remembered across reloads.
- **PIN-protected sweep flow.** Before any sweep can fire, you set a **4–8 digit numeric PIN** on the new **Security** panel of the Global Configuration page. The PIN is stored as a bcrypt hash on disk (file permissions 0600); the plaintext PIN never persists and never appears in any API response. Wrong PIN entries are logged at WARN level with the remote IP for basic brute-force visibility.
- **Two sweep modes:**
  - **Send All** — sweeps the entire wallet balance to your destination address. The destination receives `balance − network fee`.
  - **Specific Amount** — sweeps exactly the amount you choose. The recipient receives `amount − network fee`; your wallet loses exactly the amount entered.
- **Concurrency safety.** If a regular payout transaction is currently broadcast but not yet confirmed, the sweep refuses to fire and asks you to wait for the payout to confirm. Prevents accidental UTXO collisions between a sweep and an in-flight payout.
- **Coin-aware address validation.** Your destination address is checked against the coin's address validators before any RPC fires. Wrong address format (e.g., a Bitcoin address when sweeping DigiByte, or a malformed CashAddr for BCH) is caught immediately with a clear error — no wasted RPC round-trip.
- **Wallet Sweep History card** appears beneath your payment tables once you've performed at least one sweep. Lists every attempt (success or failure) with timestamp, mode, destination, amount, status badge, and either the on-chain txid (clickable to the block explorer) or the error message on failed attempts.
- **Encrypted-wallet support.** If your node wallet is password-protected (the same setup you configured for the existing payout system in v3.0.28), sweeps use the same `wallet_passphrase` field — unlock for the minimum window needed, then re-lock automatically.

**Supported coins:**

The Node Wallet Sweep feature is available on **SHA256d coins**: BTC, BC2, DGB, BCH, XEC. Non-SHA256d coins (LTC, DOGE, generic coins from `coins.json`) do not see the Node Wallet card on their Earnings pages.

### ⚠️ Recommended — Keep a Working Balance in Your Node Wallet

If you're running in **pool mode with a low pool fee percentage** (especially below 1%), be careful not to sweep your entire node wallet balance to zero. The pool's payout system relies on UTXOs in the node wallet to fund miner payouts. Sweeping too aggressively can leave the wallet in a state where the next scheduled payout fails until pool-fee outputs from subsequent blocks refill it.

**Suggested rule of thumb:** Leave enough balance in the node wallet to cover several payout cycles' worth of miner distributions plus typical network fees. The exact amount depends on your hashrate, block frequency, and miner count, but **a few days of expected payout volume** is a safe target. You can sweep more frequently if you're closer to that threshold, less frequently if you have a larger buffer.

In **DTM mode** the consideration is smaller — block rewards go directly to miners via the coinbase, so your node wallet only accumulates pool-fee outputs. Sweeping more aggressively in DTM is fine. You may still want a small buffer if you occasionally run any coins in pool mode alongside DTM.

### Stratum V2 — Bitaxe v2.14.0b3 Validation

Shortly after v5.0.0 shipped, the Bitaxe ecosystem released firmware **v2.14.0b3** with first-class Stratum V2 support (PR #1553) — covering both Extended Channel and Standard Channel modes. v5.0.1 includes the polish work needed to fully validate GoSlimStratum's SV2 server against this brand-new client implementation.

**What was validated:**

- **Extended channel mode** on Bitaxe v2.14.0b3 — works cleanly end-to-end. Same hashrate the device delivers on V1, just over the encrypted V2 transport. Confirmed live on BTC mainnet through one ~54-minute outlier block (well into Bitcoin's long-tail block-time distribution): 217 shares accepted, 0 rejected.
- **Standard channel mode** on Bitaxe v2.14.0b3 — also works cleanly after a small protocol-handling refinement on the GSS side related to how Standard-channel jobs are activated at the moment a new block lands. The change brings Standard-channel handling into alignment with how Extended channel has worked since v5.0.0. Validated against both BTC mainnet and DGB (rapid-fire block transitions every ~15 seconds, exercising the new-block activation path many times in a short window with zero rejects).

**What this means for you:**

If you're running a Bitaxe with firmware v2.14.0b3 (or any newer SV2-capable firmware), you can connect it to your GoSlimStratum pool over Stratum V2 today. The setup is identical to v5.0.0: enable a V2 listener on the coin's Configuration page, paste your pool's authority public key into the Bitaxe's `sv2_auth_pk` NVS field, and connect.

**Channel mode recommendation:** For most operators, **Extended channel is the recommended default**. It gives the miner full visibility into the coinbase transaction — block height, transactions, rewards — which the on-device dashboard uses to display the contextual mining stats Bitaxe owners expect. Standard channel also works, but the on-device dashboard will show less context because the SV2 protocol intentionally doesn't transmit the coinbase to the miner in Standard mode.

### Other Improvements

- **Cleaner amount displays throughout the Web UI.** Numbers no longer trail with your coin pool's config key (e.g., the earnings page now shows `85,681.57000000` instead of `85,681.57000000 DGBT`). Operator-chosen pool keys like `DGBT` or `BCH-Test` read as currency units next to a number but aren't actual denominations — they were visual noise. The coin context is already named by the page header or card title, so the trailing label was redundant. Kept in places where the symbol genuinely *identifies* which pool you're operating on (modal titles like "Sweep Wallet — DGBT") or what address format is expected ("Enter DGBT address" placeholders).

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image, restart your container. Your existing `config.json` works as-is. Database auto-migration adds one new audit table (`wallet_sweeps`) on first startup; existing data is untouched.
- **No new config required to keep existing behavior.** Until you visit Global Configuration → Security and set a Sweep PIN, the Node Wallet Sweep feature is dormant. The Sweep Wallet card on the Earnings page will display the balance, but clicking the button points you at Configuration to set up the PIN first.
- **Setting your Sweep PIN:** Global Configuration → Security panel (above the Restart Warning) → enter a 4–8 digit PIN and confirm. Done. To change the PIN later, the form requires you to enter the current PIN first.
- **Bitaxe SV2 operators:** If you're using firmware v2.14.0b3 or newer, your pool benefits from the validation work — no config changes required. Use whichever channel mode (Extended or Standard) you prefer, though Extended is recommended for the richer on-device dashboard experience.
- **Pool-mode operators with low pool fees:** Read the "⚠️ Keep a Working Balance" callout above before performing your first sweep. Don't drain the wallet to zero — your payout system needs a working balance to fund miner distributions.

---

## v5.0.0 — Stratum V2 Support

GoSlimStratum v5.0.0 is the **Stratum V2** release. GSS now speaks the next-generation mining protocol alongside the classic Stratum V1 — both protocols run side-by-side on the same pool, on different ports, with no breaking changes for existing miners.

### What's Stratum V2 and Why Should I Care?

Stratum V2 (often called "SV2") is the modernized mining protocol that the Bitcoin protocol community has been building over the last several years. Compared to the original Stratum protocol from 2012, V2 brings three things that matter to a pool operator:

- **Encryption.** Every message between miner and pool is encrypted with a Noise-protocol handshake (the same crypto family used by WireGuard, Lightning Network, and Signal). On hostile networks (public WiFi, shared hosting, ISPs that throttle Bitcoin traffic), nobody between your miner and your pool can read or tamper with shares.
- **Authentication.** The miner verifies it's talking to *your* pool — not an attacker doing a "share hijack" man-in-the-middle. You generate a pool-wide authority key once; every miner verifies it during the handshake.
- **Efficiency.** Binary frames instead of JSON, smaller packets, less CPU on both ends. On constrained ESP-based miners (Bitaxe, NerdQAxe), this means a little more cycles for hashing and a little less for protocol bookkeeping.

### What You Get in v5.0.0

- **One pool, two protocols.** Existing V1 miners (Bitaxe, NerdMiner, Antminer, Avalon, anything speaking classic Stratum) continue to work exactly as before, on exactly the same ports as before. No firmware updates required.
- **Per-coin V2 listener.** Each SHA256d coin in your config (DGB, BTC, BCH, XEC) gets a new optional Stratum V2 listener that you can enable on its own port. V1 stays where it is; V2 binds to a new port (`34254` is the convention; you can change it).
- **One-click key generation.** A new **Stratum V2 Keys** card at the bottom of the **Global Configuration** page generates your pool's keys with a single button click. The authority public key — the value your miners paste into their firmware — appears immediately on screen, ready to copy.
- **Mixed-fleet support.** Run a Bitaxe (V1) and a NerdQAxe++ (V2) at the same time on the same coin pool. GSS tracks both, shows both in the dashboard with a `v1`/`v2` badge next to each worker name, and pays out (in pool mode) or routes rewards directly (in DTM mode) identically for both.
- **Full vardiff, license, DTM, and revenue-share parity.** Every existing feature works for V2 miners exactly as it does for V1 — same difficulty algorithm, same flood protection, same license enforcement, same Direct-to-Miner mode with optional revenue share for built-in coins.

### What Doesn't Change

- **Nothing for existing operators by default.** v5.0.0 ships with V2 disabled on every coin. Until you go to the Coin Configuration page and explicitly add a Stratum V2 listener, your pool behaves exactly as v4.1.2 did. Upgrade with zero risk.
- **No firmware required.** V1 miners ignore the V2 port. V2 miners (NerdQAxe++ firmware shipping today; Bitaxe SV2 firmware once their PR lands) can connect when you're ready.
- **No protocol re-encoding inside GSS.** Block templates, share validation, vardiff, and block submission all use the same pipeline regardless of which protocol delivered the share. If V1 mines a block today, V2 mines blocks the same way.

### Supported Coins

Stratum V2 is currently available on **SHA256d coins only** — that's BTC, BCH, DGB (SHA256d algorithm), XEC and coins.json (SHA256d) coins. Scrypt-based coins (LTC, DOGE) are not in scope for this release.

### Setup Walkthrough

For a step-by-step walkthrough with screenshots covering the global key generation and per-coin listener configuration, see the dedicated guide:

📘 **[v5.0.0 — Stratum V2 Setup Guide](v5.0.0-Stratum-V2-Setup-Guide.md)**

### Miner Dashboard — Total Rewards Now Correct in DTM Mode

If you've been running a coin in **Direct-to-Miner (DTM)** mode, you may have noticed the **Total Rewards** card on each miner's detail page always showed `0.0000`, even when that miner had matured blocks in the **Blocks Found** list below it. This was a long-standing bug.

**Cause:** The miner dashboard's reward summary only looked at the pool's `payments` table — which is populated when the pool distributes a matured block's reward across miners in pool mode. In DTM mode there's no pool distribution step; the miner's wallet receives the reward directly via the coinbase, so nothing ever lands in `payments` for DTM workers.

**Fix:** The per-miner reward query now also sums matured DTM block rewards from the blocks history (filtered by the same wallet address + worker name + coin, and only counted after the block reaches maturity). Pool-mode users see no change — their numbers were already correct. DTM-mode users with matured blocks now see their actual on-chain rewards reflected on the dashboard.

> **Note:** Pre-maturity DTM blocks still show as 0 until they reach the maturity confirmation count — same semantics as pool-mode pre-maturity payments. This is intentional: rewards aren't spendable until the block matures, so showing them as 0 keeps the dashboard honest.

### Miner Dashboard — Blocks Found Pagination (and a Bug Fix)

The **Blocks Found** panel on each miner's detail page got two improvements that fix a subtle bug along the way.

**The bug:** previously, the panel fetched the **50 most recent blocks pool-wide**, then filtered client-side to keep only those belonging to the current worker. On a busy pool, a low-output miner whose blocks fell outside that 50-block window would see "No blocks found yet" — even with a non-zero Total Rewards card and obvious block-found history. The miner's blocks weren't lost; they just weren't being fetched in the first place.

**The fix:** the panel now does a proper server-side worker-scoped query. Every block that miner has found shows up, regardless of how many pool-wide blocks have come and gone since.

**Pagination on top:** since worker-scoped block history can grow indefinitely, the panel also gained:
- **Per-page dropdown** (5 / 10 / 20) — your choice is remembered across page loads.
- **"Showing X-Y of Z" indicator** at the bottom-left.
- **Prev / Next buttons** at the bottom-right, auto-disabled at the first and last page.

The collapse toggle and section header are unchanged.

### Miner Dashboard — Summary Cards Match the Coin Pool Dashboard

The four summary cards on the **Miner Dashboard** (Current Hashrate, Efficiency, Best Share, Total Rewards) used to have a different visual treatment than the matching cards on the Coin Pool Dashboard — bigger numbers, a large icon floated to the right of the value. The inconsistency was distracting when bouncing between the two pages.

The Miner Dashboard cards now share the Coin Pool Dashboard's compact layout: title and icon sit side-by-side at the top of the card, value and subtext stack underneath. Both pages now feel like a unified set.

### In-App Help — New Miner Dashboard Guide

The in-app Help page (the **(?)** icon in the page header) gained a new **Miner Dashboard** entry under the existing **Dashboard Guide** sidebar group, mirroring the Coin Dashboard guide that's been there for a while.

What it covers:
- **Identity Header** — status indicator, worker name, device firmware, payment address, session time
- **Summary Cards** — the four cards in their new (matched-to-coin-dashboard) layout. The Total Rewards reference explicitly notes that pool-mode payouts AND matured DTM block rewards are both summed (the fix above).
- **Charts** — Hashrate History with 1H/2H/4H/6H selector, Share Submissions, Difficulty Adjustments
- **Performance Stats** — Average Share Rate, Session / Lifetime Shares, Valid / Invalid / Stale rate, Current Difficulty
- **Blocks Found** — the new pagination UI, with a footnote about the pre-5.0.0 client-side filtering behavior so anyone reading older screenshots/issues understands the change.

### Other Improvements in v5.0.0

Beyond Stratum V2 itself, this release rolls in a number of polish items:

- **Header coin tooltips show all ports.** Hovering a coin chip in the page header now shows a multi-line tooltip with the coin name, the V1 port, and every running V2 listener (`SV2 (bip324) <port>`). Makes it obvious at a glance which ports each coin is serving.
- **Dashboard v1/v2 protocol pill.** Each worker in the miners table and on the miner detail page is now labeled with a small rounded pill showing the protocol it's connected with — `v1` or `v2`. Color preserves the familiar green = online, red = offline.
- **Node health monitoring documentation.** The most common "why does GSS say my pool is stopped after a server reboot" question is now answered in the [Coin Configuration Guide](../../documents/GoSlimStratum/gss-coin-config-guide.md#node-health-monitoring--startup-recovery) with a clear explanation of the 3-tier polling cadence and what to expect during node startup.
- **Cleaner Telegram bot warnings.** Transient Telegram API timeouts (network-side, not GSS-side) no longer spam ERROR-level log entries — they were already demoted to WARN in v3.1.0 but several configuration patterns still surfaced them frequently. Recovery middleware also now filters benign client-disconnect events out of the panic logs.

### Breaking Change — Legacy Single-Coin API Removed

> ⚠️ **This affects external API consumers only — not the GSS Web UI, GSSM, or MIM.** If you've never written your own scripts against GSS's HTTP API, you can skip this section.

When GoSlimStratum was originally single-coin (DGB-only), all metrics endpoints lived at paths like `/api/v1/metrics/pool`. When multi-coin support landed, a parallel set of coin-aware endpoints was added at `/api/v1/{coin}/metrics/pool`, and the legacy paths silently defaulted to DGB. Every internal client (Web UI, GSSM dashboard, MIM) migrated to the coin-aware paths long ago. The legacy paths have been carrying duplicate handler logic with no internal consumers ever since.

**In v5.0.0, the legacy paths are removed entirely.** Hitting `/api/v1/metrics/pool` (or any of the other legacy endpoints) now returns a `404 Not Found`.

**Migration is a simple find-and-replace:**

```
s|/api/v1/metrics/|/api/v1/DGB/metrics/|
```

…where `DGB` becomes whatever coin symbol you're actually querying (`BTC`, `BCH`, `XEC`, etc.). Every legacy endpoint has a direct multi-coin equivalent at the corresponding `/api/v1/{coin}/metrics/...` path. No data schema or response format changes — just add the coin symbol into the URL path.

For the full updated endpoint catalog, see the GoSlimStratum API Documentation.

### Upgrade Notes

- **Drop-in upgrade for the Web UI and GSSM.** Pull the new image, restart your container. Your existing config.json works as-is. No dashboard or notification changes required.
- **Breaking change for external API scripts.** If you've written your own scripts that query GSS's metrics API directly (not through the Web UI or GSSM), update them to use the coin-aware paths — see the "Breaking Change" section above.
- **No mandatory config changes.** A new top-level `sv2` block and per-coin `sv2: []` array are documented and supported, but if you don't add them GSS uses sensible defaults — and with no V2 listeners enabled, those defaults are never read.
- **Want to try V2 today?** Pick up a NerdQAxe++ (current firmware ships with SV2 support) or wait for the Bitaxe SV2 firmware PR to merge upstream. Follow the [Setup Guide](v5.0.0-Stratum-V2-Setup-Guide.md) to enable a V2 listener on one coin, generate keys, paste the authority public key into the miner, and you're mining over V2.

---



