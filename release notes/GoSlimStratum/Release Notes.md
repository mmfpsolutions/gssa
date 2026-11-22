# GoSlimStratum — Release Notes
## v6.x Series

Earlier releases: [v5.x](release_notes-5.x.md), [v4.x](release_note-4.x.md), [v3.x](release_notes-3.x.md).

---

## v6.0.1

**A second way for a miner to opt in to merged mining, and the Hash Hopper's settings on the Config Summary.** A miner can now give its aux address in the password field, for firmware that won't accept the `|` of a merged-mining username or that limits how long a username can be.

### ⛏️ Merged mining: the aux address in the password field

- Keep the plain username (`ltc1qXXX.workername`) and set the miner's password to `doge=DXXX`: the aux coin's symbol, then the address.
- A difficulty request can go beside it: `d=1024,doge=DXXX`.
- The pipe username (`ltc1qXXX|DXXX.workername`) works exactly as before.
- **Pick one way, not both.** Give the aux address in the username or in the password. The two together make a long pool entry, and some miners can't save it: on one we tested, the miner failed to save its pool settings and dropped the password. If a miner does send both, the address in the username is used.
- Nothing to turn on. The address is checked when the miner connects, and the miner gets the **M** badge on the parent coin's dashboard, as with the pipe format.

See [Merged Mining](../../documents/GoSlimStratum/gss-coin-config-guide.md#merged-mining-auxpow---as-of-version-410) in the Coin Configuration Guide.

### 📋 Config Summary: the Hash Hopper's settings

- **View Summary** (Global Configuration) now has a Hash Hopper section: whether it is on, shadow mode, its ports, the chains and their weights, the hopping rules, the port's stratum and VarDiff settings, each profile with its username and payout addresses, and your saved weight presets.
- A setting you never changed shows the value the hopper is using.
- If the hopper has never been set up, the section says so.

### 🐛 Fixed

- **Help.** The Merged Mining section said a miner with no aux address was paid to the aux pool's mining address. That stopped in v5.2.3: a miner with no aux address mines the parent chain only.

### Upgrading

Nothing to do. There are no configuration or database changes.

---

## v6.0.0 — Hash Hopper

**GoSlimStratum can now move your SHA256d miners between your coins by itself.** Point your rigs at one
new port, and the Hash Hopper keeps each of them on whichever of your coins gives the most blocks for
its hash right now, moving them as difficulties change. Your miners are never reconfigured and never
reconnect when they are moved.

It's off until you turn it on. If you never open the Hash Hopper page, nothing about your pool changes.

The full guide, with every setting, is here:
[Hash Hopper Guide](../../documents/GoSlimStratum/gss-hash-hopper-guide.md).

### 🐇 What it does

Small SHA256d chains change difficulty every block, and their difficulties cross each other all day.
A solo miner who watches them by hand and repoints rigs is doing a job the pool can do.

- **One port for all of them.** Miners connect to the hopper's own port with the username
  `hopper.<profile>` or `hopper.<profile>.<rig>`. No wallet address in the username: your payout
  address for each coin is kept in the profile.
- **It works between coins you already run.** Each coin it uses is one of your own GoSlimStratum coin
  pools, with its own node. It doesn't connect to outside pools.
- **Your coin pools still do the mining.** The hopper only chooses and moves. Each coin builds the jobs,
  checks the shares and builds any block found, exactly as it does for miners on its own port.
- **Rewards go straight to you.** A block found through the hopper pays the address you gave for that
  coin, in the block itself, and shows on that coin's Blocks and Earnings pages.
- **Stratum V1 and Stratum V2.** The hopper can have a V2 port of its own beside its V1 port.

### 🧮 How it chooses

- Each coin's **cost** is the number of hashes it's expected to take to find its next block, read from
  the network difficulty right now.
- The hopper mines the coin with the lowest cost divided by a **weight** you set. A weight of 1 counts
  blocks only. A weight of 50 says one block on that coin is worth 50 blocks on a coin weighted 1.
- It moves when another coin is better by more than the **switch threshold** and your rigs have been
  where they are for at least the **minimum dwell**. A coin whose node goes down is left at once.
- A coin is passed over unless other miners have found blocks on it recently, so the hopper stays off
  a chain that only looks cheap because nobody is mining it. If no coin passes, the best healthy one
  is used, so your miners are never left without work.

**It maximises blocks, adjusted by your weights. It does not maximise value.** It has no price
information. If you want it to follow value, put the value into the weights. You can save sets of
weights as **presets** and switch between them without a single rig reconnecting.

### ✅ What you need

A coin can take hopper miners when it:

- mines SHA256d,
- is running, with a healthy node,
- is in **Direct-to-Miner mode** (a license, or on a built-in coin the 0.5% revenue share accepted),
- isn't a merged-mining parent, and
- uses the same `extranonce_size` as the first coin you select.

You need at least two. There's no separate license for the Hash Hopper: Direct-to-Miner mode on each
coin is the only requirement, and each block pays that coin's usual pool fee and revenue share.
Hopper connections count toward your miner limit once each, whichever coin they're mining.

### 👀 Try it first: shadow mode

Shadow mode is on by default. It scores your coins and logs every switch the hopper **would** make,
without opening a port or moving any hash, and it tells you what hopping would have gained you. It
needs no license and no Direct-to-Miner mode, and it scores any SHA256d coin. Run it for a day, then
turn it off when you like what you see.

### ⚙️ Turning it on

1. Open the Hash Hopper config page from the new **Hash Hopper** card on the Global Configuration page.
2. Select your coins. Leave the weights at 1 to begin with.
3. Add a profile: a short name, and one payout address for each coin.
4. Give the hopper a port no coin uses, turn it on, and save. A **Hash Hopper** tab appears in the
   header.
5. When you're ready, turn Shadow mode off and point your miners at the hopper port.

Saving never needs a GoSlimStratum restart. Weights, rules and addresses apply at once.

### 📊 The Hash Hopper page

- **Chains.** Each coin's cost, weight and weighted cost, which one is best, and how far behind each
  of the others is, in plain words ("WJK is 3.2% better"), with what that means for your rigs.
- **Miners.** Every rig on the hopper port: the coin it's on, hashrate, difficulty and shares. A rig
  that has left stays listed with a red badge, and the red ✕ removes it, as on a coin dashboard. The
  card has the coin dashboard's two buttons as well: remove inactive miners, and reset all miner
  statistics. They clear the hopper's own records only. Blocks, earnings and each coin's records are
  kept.
- **A details page for each rig.** Click a rig's name for its hashrate history, share submissions and
  difficulty adjustments over its one unbroken connection, its best share on any coin, and the blocks
  it has found on every coin.
- **Profiles and Hopping gain.** How long each profile has spent on each coin, and whether hopping is
  paying: "+6.2% over DGB alone" is what hopping earned against a rig left on the one coin that would
  have done best alone. Under it, "+8.7% with perfect switching" shows what your threshold and dwell
  are costing you.
- **Blocks found.** Every block your hopper rigs have found, on all coins together. It opens a
  **Block History** page listing them all, newest first, each with its coin and a link to that coin's
  explorer.
- **Switch Log.** The newest 500 switches, each with why it was made ("WJK was 18.3% better") and how
  long the rigs had been on the previous coin.

### 🔧 Its own stratum settings

The hopper port has its own Stratum Settings and VarDiff Settings, the same ones a coin has, with
defaults chosen for a port that takes anything from a small ESP miner to an ASIC. They follow a rig
from coin to coin: a coin's own stratum and VarDiff settings never apply to hopper miners. Each coin's
mining and payout settings (pool fee, maturity and so on) still apply to the work done on that coin.

### 🔔 Where your rigs show up

- **On the coin they're mining right now.** A hopper rig appears on that coin's dashboard as
  `hopper.<profile>.<rig>` with a rabbit badge, and counts in that coin's miners, hashrate and block
  odds while it's there. When the hopper moves it, it shows as disconnected there and connected on the
  new coin. That's the hopper at work, not a miner dropping.
- **Notifications.** A rig on the hopper port sends the same miner connected and miner disconnected
  messages as any other rig. A move from one coin to another sends neither.
- **Default Pool.** The Hash Hopper page can be the page GoSlimStratum opens on: choose **Hash Hopper**
  under Default Pool on the Global Configuration page.
- **GSS Miners (GSSM) 5.1.0 or later** shows hopping miners with the hopper badge and gives the Hash
  Hopper a card of its own on the Pools tab.

### 🧪 How we tested it

The Hash Hopper has been running on our own fleet on mainnet since November 11: up to 14 miners
hopping between Bitcoin Silver, WojakCoin and DigiByte, on Stratum V1 and V2, with more than 50 blocks
found through it across all three. Revenue share and pool fees were checked end to end on testnet. Over two
day-long runs on that fleet, Hopping gain read about 5% over the best single coin. Yours will depend
on your coins and your weights.

### 🧹 Also in this release: run the database cleanup when you want

GoSlimStratum's cleanup job counts its interval from when GoSlimStratum starts. If you restart more
often than the interval, the cleanup never gets its turn and old rows build up.

- **Run Cleanup Now.** A new button at the foot of the Metrics section on the Global Configuration
  page runs the cleanup straight away. It doesn't change the schedule, and it sends the usual cleanup
  notification if you have that turned on.
- **Difficulty history is now cleaned up too.** Every difficulty change a miner ever had was being kept
  for ever. It's now pruned on the same window as your shares (Share Retention, 48 hours by default).

### 🔧 Improved

- **A miner connected notification shows the miner's IP address without the port** for Stratum V1
  miners (`192.168.1.50`, not `192.168.1.50:54714`), as it already did for Stratum V2.
- **Share counts are separated by "·", not "/"** on the coin dashboard and the miner details page. A
  slash read as a ratio.

### 🐛 Fixed

- **Animated Background on the Global Configuration page.** If you had never chosen a background, the
  page showed Node Mesh while the dashboard was running Hash Drift, and saving the page for any other
  reason switched it. The page now shows the one that's running.
- **Help.** Coin Alerts thresholds apply as soon as you save them. The Help page said a restart was
  needed.

### Good to know

- **Built for a home or solo miner's own rigs.** Every rig of a profile moves together, at once.
- **More database rows for hopper rigs.** A rig on the hopper port has its shares recorded twice, once
  under the hopper and once under the coin it's mining, and the hopper port's default share target is
  10 seconds against a coin port's 15. Together that's about three times the share rows the same rig
  writes on a coin's port. The number of coins you hop makes no difference. The rows are pruned on
  your Share Retention window like any others; to write fewer, shorten Share Retention or raise the
  hopper port's VarDiff target time. Rigs on a coin's own port are not affected.
- **Hopping gain counts expected blocks, not blocks found.** It's worked out from difficulty and your
  weights, so it says nothing about luck, and it's only as right as your weights. It appears after 30
  minutes and starts again when GoSlimStratum restarts or you change the hopper's settings.
- **Kept in memory.** The Switch Log, the time on each coin and the Hopping gain start again when
  GoSlimStratum restarts. Every switch is also written to the GoSlimStratum log. Blocks, shares and
  earnings are in the database as always.
- **Share counts on the Hash Hopper page belong to the connection.** When a rig reconnects, its count
  there starts again.
- **A username starting `hopper.` on a coin's own port is refused,** with a message saying to use the
  hopper port. An address on the hopper port is refused too.


### Upgrading

Nothing to do. The Hash Hopper is off until you set it up, and there are no configuration or database
changes.

**Your first cleanup after upgrading will report a larger number than usual.** It removes the backlog
of old difficulty history in one pass, which takes a moment even on a long-running pool.

---
