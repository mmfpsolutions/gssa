# GoSlimStratum Troubleshooting Guide

Symptoms, what they mean, and what to do. Most of them are not faults: they are a setting, a node that is still starting, or a figure that means something other than it seems.

*Current for GoSlimStratum 6.0.0.*

See also the [Coin Configuration Guide](gss-coin-config-guide.md), the [Global Configuration Guide](gss-global-config-guide.md) and the [Hash Hopper Guide](gss-hash-hopper-guide.md).

---

## Start Here

Three tools inside GoSlimStratum answer most questions before you change anything:

- **Diagnostics (v5.2.5+).** On the Global Configuration page, find the coin in the Configured Coins table and click the **pulse icon**, then **Run Diagnostics**. One table covers your node (RPC and ZMQ), your database and the pool itself, each line marked green, amber or red, with anything amber or red explained underneath. It tells a slow node apart from a problem in GSS. Run this first when "GSS is broken".
- **VarDiff Simulator (v5.2.4+).** The **calculator icon** on a coin dashboard. Enter the miners you run and it gives the difficulty settings for that coin as the exact fields on the Coin Config page. Use it for any "what should my difficulty be" question.
- **Config Summary (v5.1.5+).** **View Summary** on the Global Configuration page (`/summary/config`). Your whole configuration on one read-only page with every secret masked. Safe to share when asking for help.

Also check which version you are running (the Version page, or the footer). Several entries below were fixed in a particular release.

> **A note on what kind of software this is.** GoSlimStratum is its own stratum server. Settings, file names and behaviour from other pool software (ckpool, NOMP, yiimp, MiningCore and others) do not apply to it. If advice names a setting that is not in these guides, the setting does not exist in GoSlimStratum.

---

## A Coin Pool Won't Start, or Shows Its Node Offline

### After a reboot, the pool is stopped or the node is offline

The node is still starting up (verifying blocks, loading the wallet). GSS keeps the stratum port closed until the node answers, checks every 5 seconds, and starts the pool by itself the moment the node is ready. Nothing needs restarting. DigiByte nodes can take 10 to 30 minutes or more. See "Node Health Monitoring & Startup Recovery" in the Coin Configuration Guide for how to watch the node's progress.

Worry only if the node itself still reports `initialblockdownload: true` after 30 minutes or more, or if the node is ready and GSS still shows it offline after 2 minutes. In the second case check the coin's node `host`, `port`, `username` and `password`.

### "Port is in use" / "address already in use"

Another program, or another coin, has the port. The error names the port.

- From v5.5.3, GSS retries a failed start by itself and a failed start no longer leaves the port held. Before v5.5.3 a coin could get stuck this way until GSS was restarted: update.
- Ports from 32768 to 60999 are also the ones Linux hands out for outgoing connections. The usual Stratum V2 port, 34254, is in that range, so a coin that starts late can find it taken for a moment. That clears by itself. To avoid it altogether, use a port below 32768.

### A WojakCoin pool shows "not connected"

A WojakCoin node won't hand out work until it is connected to at least one other node. The pool starts by itself once the node has peers. On testnet that means running two nodes connected to each other.

### A Fractal Bitcoin pool gets no work

A Fractal mainnet node won't hand out work while it is still syncing. Wait for it to finish.

### GoSlimStratum itself won't start

GSS checks the configuration at startup and stops with a message naming the field. The checks:

- at least one coin is configured, and at least one is enabled
- every `coin_type` is a built-in coin or an entry in `coins.json`
- each enabled coin has a mining `address` that is valid for that coin and `network`
- each enabled coin has a node `username` and `password`
- each enabled coin has `template_refresh_interval` or `zmq_block_notify` set
- `network` is `mainnet`, `testnet` or `regtest`
- no two coins share a stratum port
- `pool_fee_percent` is from 0 to 100 and `maturity_confirmations` is at least 1
- `odo` is only set on a DigiByte coin
- a coin with an enabled Stratum V2 listener has its key files (generate them on the Global Config page)

### A coin I stopped doesn't come back

A coin you stopped yourself stays stopped. The automatic retry only applies to coins that are meant to be running. Press Start on the coin's Pool Lifecycle card.

---

## A Miner Can't Connect, or Keeps Dropping

### The username

On a coin's own port the username is `<your address for that coin>.<worker name>`, and the password can be anything.

- The address must be valid for that coin and that coin's `network`. A testnet address on a mainnet pool is refused.
- Merged mining: `PARENTADDRESS|AUXADDRESS.worker` (see below).
- **On the Hash Hopper port the username is `hopper.<profile>` or `hopper.<profile>.<rig>`, never an address.** An address on the hopper port is refused, and a `hopper.` username on a coin's port is refused.
- **odo-miner (FPGA):** use `<DGB address>.<worker>`. Don't use the stratum proxy's `--workers` option: it joins the worker name with `_`, which GSS reads as part of the address, so the connection is refused.

### The miner connects but never submits a share, then disconnects

The starting difficulty is too high for the miner. Lower the coin's `difficulty`, or map the device in `user_agent_difficulty_map`, and let VarDiff adjust upward. The VarDiff Simulator gives the figures.

### The pool is flooded with shares from one miner

The starting difficulty is too low for that miner. Raise it, or turn on `floodProtection` in the coin's VarDiff settings.

### DigiByte SHA256d: "low difficulty" rejects, or the dashboard shows half the miner's hashrate

This appeared when DigiByte Core 9.26.x began signalling DigiDollar, on GSS versions before v5.1.3. Update GoSlimStratum, then power-cycle the DigiByte SHA256d miners once.

### Stratum V2 miner won't connect

- The miner needs the pool's **authority public key** (shown on the Global Config page, under Stratum V2 Keys) in its settings. If the authority key was regenerated, every miner needs the new one.
- Only SHA256d coins have a V2 port, and only if a V2 listener is enabled for that coin.
- **BraiinsOS** (for example an S19): connects, shows the pool as active, sits idle and reboots, on GSS before v5.2.7. Update.

### Every miner is refused

If you are over your license's miner or coin limit, the web UI shows a license violation and stratum is disabled. See [pricing](https://www.mmfpsolutions.io/pricing.html) for the limits. Connections on the Hash Hopper port count toward the miner limit too.

---

## Hashrate and Shares

### The 1-minute hashrate is low, or jumps around

GoSlimStratum does not read hashrate from the miner. It works it out from the shares the miner submits. Over one minute that is a handful of shares, so the figure swings widely even when the miner is perfectly steady. It is noise in the estimate, not a sign of a sick device. Judge a miner by the 5-minute and 15-minute figures and by its own screen.

### The share count went back to zero

Share totals on a coin dashboard reset when that coin pool restarts.

### A few rejected or stale shares

99% or more valid is healthy. A rejected share or two straight after a GSS restart or a miner reconnect is normal: the miner submitted work for a job the pool no longer has. A steady stream of stale shares points to network latency between the miner and the pool, or slow block notification from the node (check that ZMQ is set up; the Diagnostics page shows when ZMQ last delivered).

### Hashrate looks doubled with the Hash Hopper

A hopper rig is listed on the Hash Hopper page and also on the dashboard of the coin it is mining right now. It is the same hash shown in two places, not twice the hash.

---

## Blocks

### A block was found and then marked orphaned

An orphan is a block you found that lost out to another miner's block at the same height. It is part of mining, not a fault. From v5.2.8 an orphan sends a **Block ORPHANED** notification. Orphans of eCash blocks rejected by Avalanche do not send one.

### Stratum V2, Standard channel: blocks found but rejected by the node

Before v5.2.7, a block found on a Stratum V2 **Standard** channel was refused by the node (`Failed to submit block` in the log). Extended channel was never affected. Update.

### WojakCoin: shares rejected with "ntime too far in the future"

A WojakCoin node rejects a block timed more than 15 minutes ahead of its clock, so GSS rejects shares that are. Check the clock on the miner and on the server.

### Fractal Bitcoin: the difficulty GSS shows is far below what an explorer shows

Fractal has three kinds of blocks, each with its own difficulty. GSS mines at the difficulty in your node's block template, which is the right one for the blocks it mines.

### Merged mining: no aux (DOGE) blocks, or no M badge on a miner

- **Look on the parent coin, not the aux coin.** Miners connect to the parent's port, so they are listed on the parent (LTC) dashboard only. No miners on the DOGE dashboard, and the DOGE log line `DTM: Dispatched per-miner jobs to 0 miners`, are both normal.
- A miner is merge-mining when it has the **M** badge on the parent's dashboard. The parent's log says so when the miner connects: `Merged mining: aux payout registered — DOGE → <address>`.
- Since v5.2.3, each miner opts in with its own aux address: `PARENTADDRESS|DOGEADDRESS.worker`. No pipe address, no merged mining for that miner. The password field is not read for the aux address.
- The miner is listed as `PARENTADDRESS.worker`. The aux address is not part of the name shown.
- An orange **Merged Mining Not Active** banner on the parent's dashboard gives the reason. "Configured but not running": restart the parent coin pool. "The DOGE node has not responded": the aux node is down, and any aux block found meanwhile is rejected.
- Before v5.2.6, merged mining could stop silently after a server reboot. Update.

---

## Payouts and Wallet

### Payout fails with "insufficient funds"

`maturity_confirmations` is lower than the coin really needs, so GSS tries to pay rewards that cannot be spent yet. Bitcoin Silver needs **200**; most coins need 100. A coin added through `coins.json` may need more than the default of 100.

### Payout fails with "wallet locked"

The node's wallet is encrypted. Set `wallet_passphrase` in the coin's node section. GSS unlocks the wallet for each payout and locks it again.

### "Fee estimation failed. Fallbackfee is disabled"

The node has seen too few recent transactions to estimate a fee. Common on WojakCoin, Fractal Bitcoin, testnet and regtest. Add `fallbackfee=0.001` to the node's `.conf` and restart the node.

### Wallet Sweep: "Transaction too large"

The wallet holds a very large number of small rewards. Sweep in parts using **Amount** mode.

### A red banner says the mining address doesn't belong to the node wallet, and the pool is stopped

In pool mode the coin's mining `address` must be an address of the node's own wallet, because the pool is paid first and then pays the miners. If it isn't, the dashboard shows a red warning and GSS stops that coin pool. Set an address from the node's wallet and start the pool again. In Direct-to-Miner mode outside addresses are allowed and this check does not apply.

### No rewards or earnings figures

With `payout.enabled` set to `false`, the payout system and its reward figures are off.

---

## Notifications

### Nothing arrives

Check, in order:

1. Notifications are a licensed feature.
2. `notifications.json` exists and its top-level `enabled` is `true`.
3. The event is enabled and lists a channel (the Notifications page shows this).
4. That channel is enabled and its details are right.
5. The coin is not turned off under Per-Coin Notifications.

### Coin Alerts never fire

Coin Alerts need notifications and metrics (PostgreSQL) both enabled, the coin's **Coin Alerts** master switch on, a threshold above `0` for that alert, and the alert's event enabled on the Notifications page.

### Some miner connect or disconnect messages are missing

Miner events are rate limited (by default 10 in each 60 seconds) so that a flapping miner cannot flood you.

### No message when the Hash Hopper moves a rig

By design. A rig stays connected to the hopper port while it is moved, so there is nothing to report. It sends miner connected and miner disconnected only when it joins or leaves the hopper port.

---

## Settings and the Web UI

### I changed a setting and nothing happened

| Changed | Takes effect |
|---|---|
| Any field on a coin's Configuration page, the stratum port included | After **Stop**, then **Unload**, then **Load & Start** on that coin's Pool Lifecycle card. **Restart** alone does not apply it: Restart brings the pool back with the configuration it was loaded with |
| Coin Alerts thresholds | On save |
| Notifications page | On save |
| Animated Background, Default Pool, Show Coin Price and Value | On save |
| Log levels on the Log Stream page | On save |
| Log levels and most other fields on the Global Config page | After a GoSlimStratum restart |
| Hash Hopper config | On save (a change to its port, chains or stratum settings restarts the hopper port only) |
| `config.json` edited by hand | After a GoSlimStratum restart |

### The dashboard doesn't open on my Default Pool

The chosen pool isn't loaded, so the automatic choice is used until it is. Your choice is kept. If the pool was removed, the setting goes back to Automatic.

### Coin price and value don't show

Coin Value is off by default (Global Config, Web Server Settings). It also shows nothing for testnet or regtest pools, for coins added in `coins.json`, for WojakCoin, and whenever a price can't be fetched.

### Timestamps are in UTC in Docker

Set `TZ` (for example `TZ=America/New_York`) in `docker-compose.yml`. From v5.2.6 this works with no other change.

### The database keeps growing / the cleanup never seems to run

The cleanup interval is counted from when GoSlimStratum starts, so every restart puts the first cleanup one full interval away. If you restart more often than `cleanup_interval_hours`, it never runs. From v6.0.0, press **Run Cleanup Now** at the foot of the Metrics section on the Global Config page. Share data is kept for `share_retention_hours`; lowering it shrinks the database.

### The dashboard and API are empty or unreachable

The web UI and API need metrics: `metrics.enabled` must be `true` with a working PostgreSQL connection, and `enable_http_api` and `web.enabled` must be `true`.

### TCP keepalive settings went back to 0

Before v5.4.1, saving the Global Config page wrote the four TCP keepalive settings back as `0` ("use the default"). If you had set your own values, set them again in `config.json` after updating.

---

## Hash Hopper

The [Hash Hopper Guide](gss-hash-hopper-guide.md) has its own Common Questions. The ones that come up most:

- **A miner is refused on the hopper port:** its username must be `hopper.<profile>[.<rig>]`, not an address.
- **A chain shows "Can't take part":** the reason is under the icon; usually the coin is not in Direct-to-Miner mode, is a merged-mining parent, is stopped, or has a different `extranonce_size`.
- **A chain shows "Not live":** other miners found too few blocks on it in the liveness window, so the hopper is passing it over.
- **A rig shows as disconnected on a coin dashboard:** the hopper moved it to another coin. Look on the Hash Hopper page.
- **The hopper port is not open (red dot on the Hash Hopper tab):** no selected chain can take miners yet. The Hash Hopper page gives the reason for each chain. The port is also closed, by design, while the hopper is off or in shadow mode.
- **The Switch Log is empty:** with shadow mode off, switches are logged only for profiles with a rig connected.
