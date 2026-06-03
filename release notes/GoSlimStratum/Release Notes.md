# GoSlimStratum — Release Notes
## v3.0.15 through v5.1.0

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
- On first startup, GSS automatically encrypts the plaintext passphrase in-place. The config file is rewritten with the encrypted value (prefixed with `ENC:`), so the plaintext passphrase never persists on disk after the first run.
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
