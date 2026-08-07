# GoSlimStratum — Release Notes
## v5.x Series through v5.2.6

---

## v5.2.6 — Merged Mining Survives a Reboot

**If you run merged mining, this release matters.** A bug going back to v4.1.0 meant merged
mining could quietly stop working after a server restart &mdash; and nothing told you.

### 🔁 The reboot problem

Reboot the machine, run `docker compose up -d`, and everything starts at once. GoSlimStratum
usually wins that race: it is up and asking questions before your coin node has finished warming
up. That is normal, and GSS has always recovered from it &mdash; your pool comes online a few
minutes later on its own.

What did **not** recover was merged mining. The parent chain came back and mined perfectly well
on its own, but the aux chain was quietly dropped. No warning, no error you would recognise
&mdash; the only clue was a single line at startup blaming a setting that was, in fact,
correctly configured. Merged mining stayed off until GoSlimStratum itself was restarted, and
restarting just the coin pool did not bring it back.

**Now it recovers automatically.** When your node comes online, merged mining is re-established
*before* the pool starts taking miners &mdash; the right order, so miners get merged work from
their very first job. And the startup message tells the truth:

> Merged mining with DOGE deferred &mdash; node not yet online; will be established
> automatically when it connects

### 🔧 Restarting a coin pool no longer drops merged mining

The same problem in a smaller form: stopping and starting a single coin pool from the UI also
dropped merged mining, on a pool that was working perfectly. Everything still *looked* right
&mdash; the pool reported itself as a merged parent &mdash; while no aux work was being done at
all. Fixed, and a plain stop/start now re-establishes it cleanly.

### 🚨 The dashboard tells you when merged mining is not running

Your coin dashboard has always had a merged mining warning banner, but it only ever checked your
**configuration file**. If your settings were correct &mdash; and in every case above they were
&mdash; it stayed quiet while merged mining was dead.

It now also checks what is actually **running**, and appears on its own within about half a
minute. No page refresh needed.

| What is wrong | What you will see |
|---|---|
| Configured but not running | *Merged mining with DOGE is configured but not active on the running pool. Restart the DGB coin pool to activate it.* |
| Aux coin reloaded underneath it | *Merged mining is bound to a previous instance of DOGE and is using its old configuration.* |
| Aux node not answering | *The DOGE node has not responded for 2m25s &mdash; merged mining is running on a stale aux template and any aux blocks found will be rejected.* |

That last one is worth dwelling on. When your aux node goes down, GoSlimStratum keeps the last
block template it received &mdash; deliberately, so a brief hiccup does not interrupt mining. But
if the node stays down, your pool goes on stamping aux proofs onto a block that no longer exists.
Everything looks healthy: the M badge stays lit, aux job counts look normal. **Any aux block
found in that state is rejected.** Nothing outside the log file ever told you. Now the dashboard
does, with a live count of how long the node has been quiet, and it clears itself the moment the
node answers again.

The banner also stops crying wolf. It used to say "Merged Mining **Misconfigured**" for every
problem &mdash; which was simply wrong when your config was perfect and the pool just needed a
restart. Those now read "Merged Mining **Not Active**".

Note that we check whether your aux node is **answering**, not whether new blocks are arriving.
Block times vary enormously in normal operation &mdash; a chain can easily run far past its
published target between blocks &mdash; so judging health by block arrivals would mean constant
false alarms on a perfectly healthy node.

### 🕐 Timezones now work in Docker

Setting `TZ=America/New_York` in your `docker-compose.yml` had no effect: the container had no
timezone database, so GoSlimStratum silently fell back to UTC and every timestamp on screen was
hours off, with nothing to indicate why. The timezone database is now built into GoSlimStratum
itself, so `TZ=` works with no changes to your setup.

### Upgrading

Nothing to do. No configuration changes, no database changes.

One tip if you are setting up merged mining through the UI: after editing a coin, use
stop &rarr; unload &rarr; start, and **finish with the parent coin**. Reloading the aux coin
while the parent keeps running leaves the parent using the aux coin's *old* settings. That used
to be invisible &mdash; now the dashboard tells you, and restarting the parent fixes it.

---

## v5.2.5 — Diagnostics: "Is It GSS, Or Is It My Node?"

The most common support message we get is *"GSS is broken."* It almost never is &mdash;
usually the node is slow, or ZMQ is off, or a setting quietly cancels out another one. This
release adds a page that can tell the difference, and says so in plain words.

Open **Global Configuration**, find your coin in the **Configured Coins** table, and click the
**pulse icon** in its Actions column (next to the new gear icon, which replaces the old
"Configure →" link). Press **Run Diagnostics** and you get **one table** &mdash; your node, your database and the
pool itself, one line per measurement, each marked good, marginal or bad:

| Group | Component | Measurement | Result | Endpoint |
|---|---|---|---|---|
| Node | RPC | Get Block Template | 3ms | 192.168.7.149:14022 |
| Node | ZMQ | ZMQ Last Received | 2s ago | tcp://192.168.7.149:28332 |
| Database | SQL | DB Query | 1ms | 192.168.7.138:5432 |
| GSS | DTM | Total Job Queue | 25 | |
| GSS | Routines | SV1 Miners | 24 | |
| GSS | Stratum | SV1 Port | 3333 | |

Each result is **green when it is fine, amber when it is worth a look, red when it needs
attention** &mdash; so the whole table is one glance. Anything amber or red is explained
underneath by name. Everything else stays a single line, so the page can be scanned rather
than read.

Note the ZMQ row carries **your ZMQ address**, not your RPC one &mdash; different port, and
often a different machine. A ZMQ feed pointed at the wrong node is invisible everywhere else
in GSS.

### 🩺 It can tell your node apart from your pool

The clever part is how simple it is. Diagnostics asks your node three questions back to
back &mdash; one that takes it almost no effort, one slightly harder, and one that makes it
build a full block template. Because all three travel the same path, comparing them cancels
out everything the network adds:

- **The easy question is slow too?** Then it is the connection or the machine your node runs
  on &mdash; not the chain, and not GSS. Nothing else on the page can be trusted until that
  is fixed, and the page says so rather than burying you in numbers.
- **Easy questions fast, template slow?** Then it is your node's template building
  specifically &mdash; a big mempool, a slow disk, or a block it is busy checking.
- **Everything answers except the template?** That one has always been invisible. Your node
  reads as perfectly "online" everywhere else in GSS while miners get nothing new to work
  on. It now has its own line.

### 🧭 Mining the chain you think you are

Three checks come straight from your node's own account of itself:

- **Are you on the network you configured?** If your coin is set to mainnet and the node is
  actually on testnet or regtest &mdash; or the other way round &mdash; everything downstream
  belongs to the node's chain, not the one your config names. Both look perfectly normal on
  the dashboard. This is the one check on the page that can save you a very bad afternoon.
- **Is your node actually caught up?** Not from the "verification progress" figure, which
  reads 0.99999997 on a perfectly synced node and never quite reaches 100%, but from the gap
  between the blocks it has validated and the headers it knows about. A node quietly behind
  the tip builds work on a stale block, and anything you find on it is orphaned.
- **Is the node trying to tell you something?** Bitcoin-family nodes carry a warnings field
  &mdash; unknown consensus rules activating, unrecognised block versions &mdash; that nothing
  in GSS has ever shown you. On a mining pool that is worth reading.

### 🔍 Settings that cancel each other out

Two configurations look completely reasonable and do precisely nothing:

- **A grace period that can never apply.** If your stale share grace period is longer than
  your job expiration time, the extra is wasted &mdash; by the time the grace would help, the
  job is already gone and the share is refused for a different reason entirely. You think you
  configured forgiveness; you configured nothing.
- **A keep-alive that can never fire.** If the ping interval is longer than the connection
  timeout, the keep-alive is switched on but the timeout always wins first. On, and inert.

### 📏 Settings sized wrong for your coin, or for your mode

These are not broken, just wrong for your particular setup &mdash; which is exactly the kind
of thing you would never go looking for:

- **A job history sized for the wrong mode.** The setting means two different things. In
  **pool mode** there is one shared queue, so depth is nearly free &mdash; sitting below the
  default of 20 costs you late shares for no saving. In **DTM** every miner gets its own
  queue, so the same 20 becomes 20 &times; your miner count, and the page suggests coming down
  to 5. It shows the actual entry count, so the number is not abstract.
- **A stale grace period pulling the wrong way.** Too long and it forgives practically every
  stale share, so the setting stops protecting anything and miners are credited for work that
  cannot find a block &mdash; the page shows the actual percentage being forgiven at your
  setting, worked out from your coin's block interval. Too short (under 5 seconds) and a share
  that was simply in flight when a block landed gets rejected, putting an error on the miner's
  screen it had no way to avoid.
- **Difficulty changes held for a block that never comes.** Whether VarDiff waits for the next
  block before changing difficulty is right or wrong depending on how long your blocks take
  &mdash; on a ten-minute chain a miner can sit at the wrong difficulty for most of a block,
  while on a fifteen-second chain the next block is already here. The page knows your coin's
  block time and says which way round yours should be.
- **A keep-alive that is off, or slower than it needs to be.** With the ping keep-alive
  disabled, a miner that has gone away keeps its slot until the connection timeout expires
  &mdash; and keeps showing on your dashboard. The same goes for a connection timeout set well
  past the default: miners without ping support linger for that whole window.
- **VarDiff switched off**, so every miner sits at your fixed starting difficulty &mdash; on a
  mixed fleet, wrong for all of them at once. The page links to the VarDiff Simulator for this
  coin, which works out what to set.
- **Flood protection off**, which is what stops a powerful miner swamping the pool in the
  seconds after it connects, before an ordinary retarget can catch up.
- **A miner asking for a difficulty and being ignored.** With suggested difficulty turned off,
  a device that knows its own hashrate starts wherever the pool puts it instead. Requests stay
  clamped to your bounds either way, so there is little reason to refuse them.

It also flags a poll interval too coarse for your coin's block time, a ZMQ feed that has gone
quiet, a slow database round trip, and &mdash; if it applies &mdash; that you are currently
running on your **backup node**, which explains a lot of otherwise baffling behaviour.

### 🧵 Goroutine counts, so a leak has somewhere to show up

Three more lines: how many internal routines GSS is running for your **SV1 miners**, for your
**SV2 miners**, and across the whole process. In normal running each connected miner accounts
for two, so the numbers should track your miner count and come back down when miners leave.

If a count keeps climbing while your miner count does not, something is not letting go. The
page flags that and tells you to re-run in a minute &mdash; a number that stays high is a real
leak, one that settles was just miners disconnecting. The per-protocol counts are measured
directly rather than estimated, so they stay honest.

### 🤐 And it tells you what it cannot know

Every diagnostics tool is tempted to show a wall of green ticks. This one lists its own
blind spots on the page:

- It **cannot** tell you whether your stratum ports are reachable from the internet. It can
  only see that it is listening. Ports are listed as *configured and listening* &mdash;
  never as a tick that implies more.
- It **cannot** measure your miners' own latency. A pool cannot ping a miner.
- If you have not pressed the button, it says the node was not checked rather than showing
  you a clean-looking page.

A check that always passes is worse than no check, so the ones that would always pass were
left out.

### 🖱️ Runs once, only when you ask

The page never refreshes on its own. Building a block template is real work for your node,
so it happens on a button press and nowhere else &mdash; never on a timer. There is also a
**Run Diagnostics** shortcut on the *Node Offline* and *Node Failover* banners &mdash; they
only appear when something is actually wrong, which is exactly when you want it.

Nothing on this page changes your configuration.

### 🔧 Also fixed: cloning a coin that uses Stratum V2

Cloning a coin gave the copy a new V1 stratum port but left its **V2 listener ports
unchanged** &mdash; so the clone quietly claimed ports that were already taken. The clone
reported success and the problem only appeared later, when the configuration refused to load.

The clone dialog now asks for a new port for each V2 listener, pre-filled with a free one,
and checks every port you enter against every port already in use &mdash; V1 and V2 together,
which is how GSS has always enforced it internally. Coins without V2 listeners are unaffected
and the dialog looks exactly as it did.

### 🧹 Also in this release: the `miner_accounts` table is gone

GoSlimStratum has been writing to a database table called `miner_accounts` on every miner
connection and every matured block — and **nothing has ever read it**. Not a page, not an
endpoint, not the payout system. It was noticed twice over the years and half-cleaned up
both times; this release finishes the job.

It also had a quiet flaw: miners that connect **without a `.worker` suffix** were recorded
under their connection ID rather than a worker name, so every reconnect created another
row. On busy pools it grew without limit, and it was skipped by the normal retention
cleanup. If you've been pruning it by hand, you can stop.

### ⬆️ What happens when you upgrade

The database moves to **schema v19** automatically on first startup, and the table is
dropped. Nothing else in the schema changes.

**No action is needed.** Nothing reads the table, so nothing loses a number — the block
counts on your dashboard come from a different table and are unaffected. The drop is
permanent, so if you're curious about the rows, `pg_dump` them before you upgrade.

---

## v5.2.4 — VarDiff Simulator: "What Should My Difficulty Settings Be?"

It's the question we get more than any other, and until now the honest answer was
*"run it and see what vardiff settles on."* This release replaces that with arithmetic.

Open the **calculator icon** on any coin dashboard, type in the miners you run, and get the
settings for that coin — bounds, starting difficulty, and a per-device mapping — shown as
the exact fields on the Coin Config page, ready to type in.

### 🧮 One number in, a whole configuration out

The simulator already knows your coin, so there's almost nothing to enter:

- **Algorithm is worked out for you.** Open it from a Scrypt pool and it does Scrypt maths;
  from a SHA256d pool, SHA256d. No dropdown to get wrong — and getting that wrong puts you
  off by a factor of 65,536.
- **Your current settings are the baseline**, so the output is a *difference*, not an
  abstract number. Anything already correct is marked **no change** in green; only genuine
  edits stand out.
- **Target time and retarget window are pre-filled** from that coin, and both are editable
  so you can try "what if" without touching your pool.

Everything is calculated from standard proof-of-work probability and the hashrate **you**
state — never from the pool's own share-derived estimate, which moves with the very
difficulty you're choosing.

### 👀 It catches things you cannot see

A wrong difficulty setting never errors. The pool runs, shares arrive, and nothing tells
you anything is off. The simulator names thirteen of these, with the numbers attached:

- **A ceiling that's too low.** An Antminer S19 on stock settings needs around 384,000 but
  the default `maxDiff` is 32,768 — so it sits pinned at the ceiling submitting a share
  every **1.3 seconds** instead of every 15. Twelve times the intended load, silently.
- **A miner you configured correctly that still doesn't work.** Set `d=384000` on the device
  itself and the pool clamps it right back to your `maxDiff`. Device right, pool wrong, no
  error anywhere. The simulator shows both together so the interaction is visible.
- **Small miners that look dead.** Anything needing below difficulty 1 gets rounded up to 1
  unless **Use Float Difficulty** is ticked — a NerdMiner ends up thousands of times too
  hard and simply stops reporting.
- **A ceiling being touched by chance.** VarDiff measures each miner from its last ten
  shares, so its estimate naturally wanders. If your `maxDiff` sits too close to a miner's
  natural difficulty, ordinary luck lands it on the ceiling — the simulator tells you
  roughly **how many times a day** to expect that, and what headroom stops it.

### 🎯 Built for mixed fleets

An Antminer S21 and a NerdMiner are about **four billion times apart** in difficulty. Set
your bounds for one and you break the other.

So per-device difficulties go in the **User Agent Difficulty Map**, where each device class
starts exactly where it belongs — no compromise — while the min/max bounds simply *span*
the fleet. Add every miner class you run, and if the suggested ceiling comes out lower than
what you have today, the simulator says so, because that usually means you left a miner out.

### 🔭 Where it earns its keep

Beyond fixing what is already wrong:

- **Planning ahead.** Work out the settings for a new rig before it arrives, or before a
  hashrate rental drops a few PH/s on your pool for a weekend. You cannot measure
  hardware you do not own yet, but you can calculate for it.
- **Predictable load.** A difficulty set too low means a miner submitting many times more
  often than intended — more shares to validate, store and retain, and more network work
  for a device that would rather be hashing. The simulator projects the daily share volume
  for your whole fleet before you commit to a target time.
- **Sharper numbers.** A miner reporting twice a minute gives the 1-minute hashrate column
  almost nothing to work with. Six or twelve times a minute makes it a figure you can
  actually trust — and spot problems in.

**Why the advice is worth following.** The arithmetic itself is standard proof-of-work
probability; there is nothing exotic about it. What is specific to GoSlimStratum is the
model behind the recommendations: how our VarDiff samples share times, how far it will move
in a single step, the deadband it waits for before acting at all, and when it applies a
change. The simulator mirrors every one of those, so what it tells you describes what
*your pool* will actually do — not what a generic calculator assumes.

A few practical notes:

- The simulator is **read-only** — it never changes your configuration. It shows you the
  fields and the values; you decide and type them in.
- Suggestions are a **starting point**, not gospel. Nameplate hashrate isn't what a device
  always delivers, and a week of watching your own pool beats any calculator.
- Nothing about mining behaviour changed in this release. If you never open the page,
  GoSlimStratum works exactly as it did in v5.2.3.

Drop-in upgrade — no config changes, nothing to do.

---

## v5.2.3 — Merged Mining, Round Two: DigiByte Joins, and the Feature Grows Up

Merged mining has been part of GoSlimStratum since the LTC + DOGE days. This release is its
coming-of-age: **DigiByte-Scrypt pools can now be merged-mining parents too**, the whole
feature moves to **explicit per-miner opt-in with honest dashboards**, and it's been
hardened by a real production soak — including multiple DigiByte-Scrypt blocks found live in merged
mode.

One Scrypt share now works two chains: your miners mine DGB (or LTC) exactly as before, and
every share also gets checked against the Dogecoin network. When one clears the DOGE
target, the DOGE block reward pays **directly from the DOGE coinbase to the miner's own
DOGE address** — Direct-to-Miner on both chains, zero pool custody, nothing to distribute.

### ⚠️ Action needed if you already run merged mining

**Merged mining is now opt-in per miner.** A miner earns aux rewards only when its username
carries its own aux payout address in pipe format:

```
PARENTADDRESS|DOGEADDRESS.workername
```

Previously, miners connecting *without* an aux address were silently merge-mined anyway,
with their DOGE rewards paid to the pool's configured DOGE address. That undocumented
fallback is gone — it could send rewards somewhere the miner never chose. Miners without a
pipe address keep mining the parent chain completely normally; they just don't merge-mine,
and the log says so plainly at connect. **If your miners relied on the old fallback, add
the pipe address to their usernames — that's the whole migration.**

A mistyped DOGE address is caught the moment the miner connects: one clear warning in the
log, the miner keeps mining the parent chain, and nothing is silently misdirected.

### 🐕 Setting up a DigiByte + Dogecoin pair

Same configuration shape as LTC + DOGE — a `merged_mining` block on each side:

```jsonc
"DGB":  { "algorithm": "scrypt", "enable_dtm": true,
          "merged_mining": { "role": "parent", "aux_chains": ["DOGE"] } },
"DOGE": { "algorithm": "scrypt", "enable_dtm": true,
          "merged_mining": { "role": "aux", "aux_of": "DGB" } }
```

Parent and aux must share an algorithm (Scrypt with Scrypt), and both sides run
Direct-to-Miner. The aux pool keeps running as a normal standalone pool throughout.

### 🏷️ The dashboard tells the truth

- **Per-miner M badge.** Each worker on the miners card shows an **M** badge only while it
  is *actually* merge-mining — connected, authorized, valid aux address registered. Hover
  it and you see the exact DOGE address its aux rewards pay to. No badge = not
  merge-mining, and that absence is now your diagnostic.
- **Aux Odds on the Block Odds card.** Merged-parent dashboards gain an **Aux Odds** row —
  pool share, estimated time to block, blocks/day and blocks/month against the *Dogecoin*
  network, computed from only the miners actually merge-mining (`2 of 3 miners
  merge-mining → DOGE`). DOGE's network is orders of magnitude larger than DGB-Scrypt's,
  and this row is where that reality lives — think of it as the odds printed on the
  lottery ticket.

### 👛 One wallet address, one decision

Miners that share a parent wallet address share one coinbase — so they share one
merged-mining decision. If any worker on an address opts in, every worker on that address
contributes to the aux chain (and shows the M badge with the real payout address). If two
workers on one address supply *different* DOGE addresses, the most recent one wins and the
log warns you loudly, naming both. Want genuinely separate aux payouts? Use separate
parent wallet addresses — every wallet in the world will happily give you another one.

### 🤝 Revenue share now applies on the aux chain

Unlicensed operators run merged mining under the same terms as everything else in
Direct-to-Miner mode: the 0.5% revenue share you accepted on each coin now applies on the
aux chain too, collected directly in the DOGE coinbase alongside the miner's payout —
previously it was only collected on the parent side. Licensed operators are unaffected:
no revenue share on either chain, as always.

### 🛡️ Hardened by soak

Running this on our own mainnet pool before releasing it surfaced three issues you'll
never meet:

- **A memory leak in long-running merged pools** — aux job data accumulated for the life
  of the process (a fast parent chain could add ~170 MB/day). Now strictly bounded; a
  once-per-aux-block log line (`aux_jobs=N, parent_jobs=N`) lets you watch the bound hold.
- **Aux node down at GSS startup no longer disables merged mining.** Previously, if the
  Dogecoin node wasn't answering the moment GSS started, merged mining stayed dead until a
  restart. Now GSS warns, keeps retrying, and merged mining starts by itself the moment
  the node responds — same as it always did for a node that dropped mid-run.
- **A database housekeeping fix** — the internal schema version record now correctly reads
  18 on upgraded installs. Purely cosmetic; no action, no data change.

### ⚡ Job delivery rebuilt — for every pool, merged or not

This one's for everyone. Digging through the dispatch path for the work above, we found a
long-standing structural weakness in how Stratum V1 delivers jobs: new work went out to
miners **one socket at a time**, and a single miner whose connection had genuinely wedged
(a dying NAT, a collapsed Wi-Fi link, a device that stopped reading) could hold up job
delivery to *every other miner on that coin* — V1 and V2 alike — for up to ten seconds
per new block. Worse, the delay landed on the same internal path that watches the
blockchain for new blocks, so fresh work itself arrived late. The victims were random
each time, which made it look like ordinary network flakiness: scattered, unexplainable
stale shares.

Now every V1 connection gets its own outbound queue with a dedicated writer, the same
design Stratum V2 has used since day one. A wedged miner delays only itself; everyone
else gets their work in microseconds, every block.

You also get the receipts in the log:

- Every job dispatch now reports how long it took (`elapsed=`) — healthy pools sit in
  the low milliseconds, flat.
- Any single miner socket that stalls a write for over a second gets a **Warn naming the
  worker** — so if you've been chasing phantom stale shares, the culprit now signs its
  work.

A few practical notes:

- Merged mining requires Direct-to-Miner mode on both coins, and matching algorithms.
- For merged parents we recommend `"max_job_history": 5` (already the DTM recommendation)
  — it directly bounds merged-mining memory on large fleets.
- SHA256d pools are unaffected by all of this unless you configure them as merged parents
  with a SHA256d aux chain — nothing here touches ordinary solo pools.

Drop-in upgrade — **existing merged-mining operators, see the action-needed note above**;
everyone else has no config changes and nothing to do.

---

## v5.2.0 — DigiDollar Stats for DigiByte Pools

DigiDollar — the US-dollar stablecoin built into the DigiByte blockchain — is now live on mainnet, and GoSlimStratum is the first pool software* to put it on your dashboard.

<sub>*That we know of — show us another! 👀</sub>

If you run a DigiByte pool, you'll see a new **DigiDollar** badge on the coin dashboard and a new page at **`/coin/{your-coin}/digidollar`** showing, straight from your own node:

- **System health** — the chain-wide collateralization ratio and status
- **DigiDollar supply** and active collateral positions
- **Locked collateral** — total DGB backing the system, with its USD value
- **DGB oracle price** — the decentralized price feed, its 24-hour range, freshness, and how many oracles are reporting
- **Deployment details** — activation status and the oracle signing session
- **A collateral calculator** — pick an amount ($100–$100K) and a lock period (30 days to 10 years) and see exactly how much DGB collateral minting would require at the current oracle price

Everything is **read-only and free on every tier** — no license needed. GSS displays what your node reports; it never mints, redeems, or holds anyone's coins. Your node, your coins, your DigiDollars.

**New Oracles page.** From the DigiDollar page, open **Oracle Network** to see the decentralized DGB/USD price-feed network in full — the current consensus price, how many oracles signed the latest on-chain price, and a live roster of every oracle: who's reporting, who's signing, heartbeat freshness, software version, and endpoint. It's the same public data every DigiByte node sees, presented clearly — and if you happen to run an oracle yourself, yours is flagged.

**Refined look.** The DigiDollar page got a visual polish — a collateralization bar, health and tier indicators, and clearer cards — while staying consistent with the rest of your dashboard. Both DigiDollar pages load their data once and include a **Refresh** button that shows when the figures were last read from your node, so they stay light on your node.

A few practical notes:

- The page appears only on DigiByte coin pools. Nothing changes for any other coin.
- If your DigiByte node predates DigiDollar, the page simply says so — no errors, no log noise. Upgrade the node and the stats appear within a minute, no GSS restart needed.
- The calculator is exactly that — a calculator. It tells you what minting *would* require; actually minting DigiDollar is done from your own wallet, not from GSS.

Drop-in upgrade — no config changes, nothing to do.

---

## v5.1.6 — Maintenance Release

Internal improvements to share validation and minor code cleanup. Some miners may notice a small reduction in rejected shares.

**Merged mining fix:** if you run merged mining (e.g. LTC + DOGE) and disable one of the coins, your pool now starts normally. Previously, disabling one side of a merged-mining pair could block *other*, unrelated coins from starting. When an aux coin is disabled, the parent simply mines on its own.

**Blocks page fix (Scrypt coins):** on the Blocks dashboard, the difficulty of the share that found a block now displays at the correct scale for Scrypt coins (LTC, DOGE, DGB-Scrypt). It was previously shown 65,536× too large. This was a display-only issue — your mining, blocks, and rewards were never affected.

Drop-in upgrade — no config changes, nothing to do.

---

## v5.1.5 — Config Summary Page, Clearer Coin Table & a Wallet-Timeout Fix

GoSlimStratum v5.1.5 adds one new feature and a set of configuration-visibility improvements:

- **Config Summary page.** A new read-only, printable page that gathers your entire configuration into one clean document — ideal for documentation, review, or attaching to a support ticket. Every secret is masked; nothing sensitive ever leaves the server.
- **Clearer Configured Coins table.** The coins table on the Global Configuration page now shows each coin's **mining algorithm**, and the old single "Stratum Port" column is split into **SV1 Port** and **SV2 Port** — so you can see V1 and V2 listener ports (and which crypto variant) at a glance.
- **The Wallet RPC Timeout setting now actually works.** A payout setting that was present in the UI but never wired up now takes effect — useful if you run a large or slow-to-respond encrypted node wallet.

Everything sits on top of 5.1.4. No config changes required.

### 📄 Config Summary — your whole setup on one printable page

A new **View Summary** button in the Global Configuration header opens a read-only summary of your entire GoSlimStratum configuration at `/summary/config`. It's built for **documentation, review, and support tickets** — one page you can read top-to-bottom or **Print / Save as PDF** straight from your browser (no downloader, no separate export step).

- **Everything in one place.** Global settings (metrics, web, logging), a security overview (which keys and PINs are configured), and — per coin — node, stratum, SV2 listeners, mining, VarDiff, payout, coin alerts, explorer, and merged-mining settings, plus your full notifications setup (channels, event matrix, per-coin overrides).
- **Secrets never leave the server.** Every password, token, passphrase, and webhook URL renders as `[configured]` or `[not set]` — the real values are never sent to your browser, so the page is safe to screenshot or hand to support. SV2 binary keys show as a simple "configured?" flag.
- **Compact and readable.** A clean multi-column document layout (not the big editable forms), with difficulty-scale numbers shown using friendly K / M / G / T / P suffixes instead of scientific notation.
- **Opens in a new tab**, so you keep your place in the config editor.

### 🪙 Configured Coins table — algorithm + SV1 / SV2 ports

The **Configured Coins** table on the Global Configuration page picked up two readability improvements:

- **New "Algo" column.** Each coin now shows its mining algorithm (`sha256d` / `scrypt`) at a glance, between Coin and Display Name.
- **Separate SV1 and SV2 port columns.** The old single "Stratum Port" column only showed the V1 port, hiding your Stratum V2 listeners. It's now split into **SV1 Port** and **SV2 Port**. The SV2 column lists each configured listener as `port - variant` (e.g. `34254 - bip324`), stacking vertically when a coin runs more than one — so you can tell which port serves which SV2 implementation. Coins with no SV2 listener, and non-SHA256d coins (Scrypt — LTC / DOGE — which can't run SV2), show `--`.

Display-only — nothing about your configuration or mining changes.

### ⏱️ Wallet RPC Timeout setting now works

**Fixed:** the **Wallet RPC Timeout** field on the payout configuration (`wallet_rpc_timeout_seconds`) has always been present in the UI — and documented as "increase if your wallet is slow to respond" — but it wasn't actually connected to anything. The pool used a fixed 30-second window internally, no matter what you set.

v5.1.5 wires it up. The value now controls how long GSS keeps an encrypted node wallet unlocked while a payout (or a wallet sweep) completes — so operators with a large or slow-to-respond encrypted wallet can raise it and have it take effect.

- **Default is unchanged (30 seconds).** If the default has been working for you, nothing changes.
- **Only relevant for encrypted wallets.** The setting governs the wallet-unlock window used during payouts and sweeps; if your node wallet isn't password-protected, it has no effect.
- **Safe by design.** It never interrupts a payment that's already broadcasting — it only governs the unlock window, so there's no risk to in-flight transactions.

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image and restart your container. Your existing `config.json` works as-is — no database migration, no config changes.
- **Config Summary: nothing to configure.** Click **View Summary** on the Global Configuration page (or visit `/summary/config`). It's read-only and every secret is masked. Print or Save-as-PDF from your browser.
- **Coin table columns: automatic.** The new **Algo** column and the **SV1 Port** / **SV2 Port** split appear on their own — display-only, no action needed.
- **Wallet RPC Timeout: default unchanged (30s).** If you'd previously raised this for a slow or encrypted node wallet and wondered why nothing changed, it now takes effect. No action needed otherwise.

---

## v5.1.4 — DigiDollar-Ready DigiByte, Custom Coin Badges & Alert Reliability

GoSlimStratum v5.1.4 bundles two new capabilities and two reliability fixes:

- **DigiByte is ready for DigiDollar.** When DigiByte's DigiDollar upgrade activates on the network, GSS will automatically carry the required oracle commitment in the blocks it mines — no operator action, and nothing changes until activation actually happens.
- **Coin badge icons, fixed and customizable.** Badge icons now match by **coin type** instead of guessing from the first three letters of the symbol, so custom coins finally show the right icon (or a clean default) — and you can supply your own artwork for any coin.
- **Coin alerts survive a pool stop/start**, and a **Stratum V2 connection fix** ensures rejected connections report their reason.

Everything sits on top of 5.1.3. No config changes required.

### 🟢 DigiByte — ready for DigiDollar activation

DigiByte's **DigiDollar** upgrade introduces an *oracle commitment* that pools must include in the coinbase once the feature goes live (similar in spirit to the SegWit commitment already there). GSS now includes it automatically whenever your DigiByte node provides one.

- **Automatic, and invisible until activation.** Before DigiDollar activates — and on older DigiByte nodes — the node doesn't hand out an oracle commitment, so GSS builds blocks exactly as it does today. When activation happens, GSS starts including the commitment on its own. No flag to flip, no restart to time to activation.
- **Nothing for your miners to do.** The commitment rides inside the coinbase, which miners already treat as opaque. Bitaxe, NerdQAxe++, Avalon, and every other device need no firmware or setting changes.
- **DigiByte-only, all algorithms.** Verified end-to-end on the DigiDollar test network across **SHA256d, Skein, and Scrypt**, over both **Stratum V1 and V2**. No other coin is affected.

### 🎨 Coin badge icons — correct matching, and bring your own

The coin icons on the dashboard header used to be chosen by the **first three letters of the coin symbol**. That worked for built-in coins but broke for custom (`coins.json`) coins: a coin named `BCH2` would wrongly show the Bitcoin Cash badge, and a coin with no matching image showed **no badge at all**.

Badges now resolve by **coin type** — the stable identifier from your config — so:

- **Custom coins show the right badge.** Icons match a coin's `coin_type`, not a 3-letter guess, so `BCH2`, `DGB-Scrypt`, and similar all resolve correctly.
- **Upload your own badge — right from the dashboard.** Open **Global Config → Configured Coins** and click a coin's icon. A dialog lets you **upload a PNG** or **reset to the default** — no shell access, no rebuild, no restart. The new badge appears immediately.
- **Or drop a file.** Prefer the filesystem? Drop a `<coin_type>.png` (or `.svg`) into a **`coin-icons`** folder next to your configuration and GSS serves it. Works for custom coins *and* overrides built-in badges.
- **Never blank.** Any coin without a matching image now shows a neutral default badge rather than empty space.

#### Things to know

- **One badge per coin *type*.** Badges key off `coin_type`, so a badge applies to every pool of that type — if you run `DGB` and a cloned `DGB2` (both DigiByte), they share one badge. The upload dialog tells you which coin type you're changing.
- **The folder is optional.** If you never upload or create `coin-icons`, everything works as before — built-in coins keep their shipped badges. The folder is created automatically on your first upload.
- **Uploads are PNG, up to 256 KB.** The dashboard accepts PNG images; the filesystem drop-in also accepts SVG. Both name the file by `coin_type` (e.g. `bitcoincashii.png`), lowercase.
- **Live pickup.** Uploaded, replaced, or dropped-in badges appear on the next page load — no restart needed.

### 🔔 Coin alerts now survive a coin pool stop/start

**Fixed:** if you **stopped and then started an individual coin pool** from the dashboard, that coin's alerts (best share, notable share, rejected-share, network-difficulty) went **silently quiet** until you restarted the whole GSS process — with nothing in the logs to explain it. Other coins kept alerting normally, which made it easy to miss.

v5.1.4 re-wires each coin's alert watcher whenever its pool restarts, so alerts keep firing after a stop/start. A log line now records the re-wire, so the event is visible instead of silent.

### 🔌 Stratum V2 connection fix

**Fixed:** a Stratum V2 connection rejected at setup could close before its rejection reason was delivered, leaving the miner to see a bare disconnect instead of the "why." The shutdown path now flushes that final message before closing.

### Upgrade Notes

- **Drop-in upgrade.** Pull the new image and restart your container. Your existing `config.json` works as-is — no database migration, no config changes.
- **DigiByte + DigiDollar: nothing to do.** Readiness is automatic and stays dormant until DigiDollar activates on the network — you don't need to time anything to activation.
- **Custom coin badges (optional).** Upload a PNG from **Global Config → Configured Coins** (click a coin's icon), or drop `<coin_type>.png` / `.svg` into a `coin-icons` folder next to your config. Skip it and nothing changes.
- **Coin alerts.** No action — the stop/start fix applies automatically. If you'd previously worked around it by fully restarting GSS after a pool stop/start, you no longer need to.

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



