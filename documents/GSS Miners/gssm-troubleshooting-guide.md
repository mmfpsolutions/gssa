# GSS Miners (GSSM) Troubleshooting Guide

Symptoms, what they mean, and what to do. Many of them are not faults: they are a setting, a device that cannot report something, or a figure that means something other than it seems.

*Current for GSS Miners 5.1.0.*

See also the [Configuration Guide](gssm-config-guide.md), the [Miner Control Guide](gssm-miner-control-guide.md) and the [Notifications Guide](gssm-notifications-guide.md).

---

## Start Here

Four places inside GSSM answer most questions before you change anything:

- **The card itself.** An offline miner, pool or node says why on its card: unreachable, not responding, authentication failed, and so on. The reasons are listed below.
- **The Health page** (linked in the footer). GSSM's own state: uptime, memory, which services are running, how many miners, pools and nodes are online and, with Historicals on, the database's size.
- **The Logs page** (linked in the footer). The log, live. For more detail, set the log level to `debug` under Logging on the Configuration page and restart GSSM.
- **The Help page** (linked in the footer). Every card and every setting explained, inside the product.

Also check which version you are running: it is in the footer and on the Version page. Several entries below were fixed in a particular release.

> **A note on what kind of software this is.** GSS Miners is a monitoring dashboard. It reads your miners, pools and nodes; miners do not connect to it and it is not a pool. Settings, file names and behaviour from other monitoring or pool software do not apply to it. If advice names a setting that is not in these guides, the setting does not exist in GSSM.

---

## GSSM Won't Start, or You Can't Get In

### GSSM stops at startup with a message about `config.json`

The file has a typo or cannot be read. GSSM leaves it untouched and stops, so that a mistake cannot wipe your configuration (v3.0.0+). Fix the file (a missing comma or quote is the usual cause) and start GSSM again. Before v3.0.0, GSSM replaced an unreadable file with a blank one: update.

### The dashboard opens on the Configuration page with nothing in it

That is a first start: there was no `config.json`. Add devices by hand or with Auto-Discover. If you expected your configuration to be there, check that the container's config folder is the one that holds your files (`/data/gssm/config` with the MMFP installer).

### The sign-in page does not let you in over plain HTTP

Signing in needs the dashboard to be served over HTTPS, because the browser only does its part of the sign-in on a secure connection. If you reach GSSM by plain HTTP, set `"disableAuthentication": true` in `config.json`, restart GSSM, and keep it on a network you trust.

### The dashboard does not load on port 3000

Check `webServerPort` in `config.json` and the `PORT` environment variable, which wins over it. Both are read at startup.

---

## A Miner Shows Offline

The card gives the reason:

| On the card | Meaning |
|---|---|
| unreachable — connection refused | Something answered at that address but nothing is listening on that port. Wrong port, or the miner's API is off. |
| unreachable — no route to host / host down / network down | The address cannot be reached from the GSSM server. |
| unreachable — DNS lookup failed | The hostname does not resolve. Use the IP address. |
| not responding (timeout) | The device did not answer in time. It may be busy, restarting or off. |
| NerdMiner firmware older than 2.0 isn't supported — update the firmware | See below. |

### A miner never comes online after you add it

Check its entry against the Device Types table in the Configuration Guide:

- **HTTP devices need the `http://`.** AxeOS, NerdMiner and ElphaPex take `http://192.168.1.100`; CGMiner, Canaan and Whatsminer take the bare IP.
- **The port must match the family.** `80` for HTTP devices, `4028` for CGMiner and Canaan, `4433` for Whatsminer.
- **The device type must be the firmware family.** A NerdQAxe is `axeos`; an Avalon Q or Nano3s is `canaan`; an Antminer is `cgminer`.
- **The GSSM server must be able to reach the miner's network.** Try the miner's own web page from the same machine.

Auto-Discover fills all of this in for you.

### A NerdMiner went offline after updating GSSM to 4.0

GSSM 4.0 supports NerdMiner firmware 2.0 and newer. Update the miner's firmware and it reappears by itself.

### Bitaxe or NerdQAxe miners flick offline and back while they are mining fine

Two fixes cover this: v3.0.1 (a longer wait for AxeOS miners, and an offline alert only after two missed checks) and v3.0.2 (GSSM closes each connection after reading the miner, so it no longer ties up the miner's small web server). Update to v3.0.2 or newer. If it still happens on a large fleet, lengthen the miners refresh interval: every dashboard read is a request to each miner.

### A miner you disabled shows a muted card

That is what disabled means: GSSM does not check it and sends no alerts for it. Enable it from the card.

---

## A Pool Shows Offline

### "pool not configured or offline" on a GoSlimStratum pool

GSSM reached GoSlimStratum, but that coin is not one of its pools. The `gssCoinKey` does not match a coin on that server, or the coin was removed or disabled there. Open the pool's edit form and use **Lookup Keys** to see the keys GoSlimStratum has.

### "unreachable" or "not responding" on a GoSlimStratum pool

GSSM cannot reach the GoSlimStratum API. Check `host`, and that the API port (`4004` unless you changed it in GoSlimStratum) is reachable from the GSSM server. Use `127.0.0.1` as the host when both run on the same machine.

### A pool with no miners shows online

That is correct (v3.0.0+). A pool that is set up and waiting is online. It was shown as offline before v3.0.0.

### A Hash Hopper card shows offline

The card says why:

| On the card | Meaning |
|---|---|
| this GSS has no Hash Hopper (needs GSS 6.0.0 or later) | That GoSlimStratum is older than 6.0.0. |
| Hash Hopper isn't set up on this GSS | The hopper has not been configured in GoSlimStratum. |
| Hash Hopper is turned off | It is configured and switched off. |
| hopper port is closed | The hopper is on but its port could not be opened. The reason from GoSlimStratum follows. |
| couldn't load hopper.json | GoSlimStratum could not read the hopper's configuration. |

A hopper in **shadow mode** is online: its port is closed on purpose and it still scores the chains. Fix any of these in GoSlimStratum; see its Hash Hopper guide.

### A litecoinpool card shows offline or stale figures

Check the API key against your litecoinpool.org account. GSSM asks litecoinpool.org at most once a minute for each account, so figures can be up to a minute old whatever the refresh interval.

---

## A Node Shows Offline

| On the card | Meaning |
|---|---|
| authentication failed | The RPC username or password is wrong. They must match `rpcuser` and `rpcpassword` in the node's own config file. |
| unreachable — connection refused | Wrong `rpcPort`, the node is not running, or the node does not accept RPC from the GSSM server's address (`rpcallowip` / `rpcbind` in the node's config). |
| RPC error -28: Loading blocks… (or similar) | The node is still starting. It comes online by itself when it has finished. |
| not responding (timeout) | The node did not answer within 5 seconds. A node that is very busy can do this for a while. |

**Test Connection** on the node's edit form checks the address, port and credentials against the live node and reports the real result.

### A node flips between online and offline every half minute

Fixed in v3.0.0 (it was worst on Bitcoin Cash nodes). Update.

### The node card shows the wrong difficulty on DigiByte

Set the node's **Algorithm** to the one you mine. On a coin with several algorithms the card leads with the difficulty and hashrate for that algorithm.

---

## Coin Badges

A badge only labels a card. Nothing else depends on it.

### A miner shows the wrong coin, or the default badge

A miner's coin is worked out from what the miner reports: its pool's address and the username it mines with. Some coins cannot be told apart that way:

- **Fractal Bitcoin** miners show the Bitcoin badge. Fractal uses Bitcoin's address formats.
- **WojakCoin** addresses starting with **3**, and all its testnet addresses, look like Bitcoin's.
- **Bitcoin Cash II** without its `bitcoincashii:` prefix shows as BCH; a legacy **Bitcoin Silver** address shows as BTC.
- **DigiByte and Dogecoin** addresses starting with **D** look the same and show as DGB.
- **A pool login that is an account name**, not a wallet address, carries no coin at all.

Fix any of these with a **pool mapping** on the Coin Map page (v5.0.0+): map the pool's host and port to the coin. The page's "What your miners report" list shows each pool your miners use, the badge it gets and why, with a **Map** button.

### A pool mapping does not take effect

A mapping matches exactly what the miner reports. A mapping for `192.168.7.10:3334` does not match a miner set to `gss.local:3334`. Use the **Map** button, which fills in the value the miner reports. If the coin moved to another port, update the mapping.

### A miner on the Hash Hopper does not show the Hash Hopper badge

- It needs GSSM v5.1.0 or newer.
- The miner's username must start with `hopper.` (it logs in to the hopper as `hopper.<profile>.<rig>`).
- **A pool mapping for the hopper's host and port wins over the badge.** If you mapped the hopper's port to a custom coin before v5.1.0, delete that mapping.

The badge does not say which chain the miner is on at the moment. The Hash Hopper card on the Pools page shows that.

### GSSM will not make an address rule from your address

A built-in coin already claims that kind of address (most legacy addresses starting with `1`, `3`, `L`, `M`, `X`, `W`, `D`, `S`, `A`, `9` or `n`), or the address has no form GSSM can identify. Use a pool mapping.

### A new logo does not show

A dashboard that was already open picks up a new logo within a minute. Only coins you added can have their own logo: built-in coins and the Hash Hopper keep the one they ship with.

### A GoSlimStratum pool shows a different coin after updating to 5.1.0

From v5.1.0 the pool's badge comes from the coin GoSlimStratum says it is mining, which wins over the Coin Type you picked. If the two disagreed, GoSlimStratum's answer is the one now shown. For a GoSlimStratum custom coin, give the coin its **GSS coin type** on the Coin Map page so GSSM knows it.

### The coin badge has an amber ring

The miner is mining on its backup pool (v3.0.10+). It is working, but not where you pointed it. Most miners stay on the backup after the primary comes back; restarting the miner makes it try the primary again. A NerdQAxe++ mining two coins at once never shows the ring, and a NerdMiner cannot report it.

---

## Figures That Look Wrong

### A NerdQAxe shows V1 when it is mining on Stratum V2

Fixed in v3.1.3. Only the badge was wrong.

### The hardware error rate jumps around

The miner measures it over its last few seconds, so it can read 0.07% on one refresh and 0.3% on the next. That is normal. A NerdQAxe shows an error rate only on NerdQAxe++ firmware 1.1.1 or newer (GSSM v4.0.0+); older firmware shows none.

### Best Share on a Scrypt pool is enormous

Fixed in v3.0.5. Litecoin, Dogecoin and DigiByte-Scrypt pools showed it about 65,000 times too large.

### An ElphaPex shows no frequency

On purpose (v3.0.3+). The device does not report its frequency in MHz, so GSSM shows none.

### A miner shows no power draw, or "not reported"

The device does not report its power (NerdMiner). It is left out of cost and energy totals, and the totals say so.

### A Bitaxe's firmware version shows as "Unified"

Fixed in v3.1.0, for AxeOS 2.15.

### A row is missing from a card

Rows appear only when the device reports the value. A miner with one fan has one fan row; a board with no temperature target shows no Target row; older firmware that does not report a figure shows no row for it.

### A miner's model name changed after updating to 4.0

From v4.0.0 every miner names itself, so the dashboard and Historicals show the device's own name (**Gamma 601**, **Avalon Q**, **DG-Home1**). Its history moved with it.

### The Fleet page's cost does not match the electricity bill

It is an estimate from what the miners are drawing right now, multiplied out. It knows nothing about tiered rates, delivery charges or taxes, and a fleet that idles overnight projects low. For real figures, turn on energy tracking in Historicals and use the Energy report.

### The Hash Hopper card's share counts are lower than expected, or dropped

GoSlimStratum counts a hopper rig's shares from when the rig connected to the hopper. They start again when it reconnects. The card labels them "(connected)".

### The Hash Hopper card shows no blocks or rewards

Blocks found through the hopper are recorded under the coin that was being mined. They show on that coin's own pool card.

### The Hash Hopper's Switch Log shows only 20 rows

GSSM lists the newest 20 switches. GoSlimStratum keeps its newest 500, and its own Hash Hopper page lists them all.

---

## Alerts

### No alerts arrive at all

Check each of these:

1. **The license.** Notifications need Pro or Enterprise.
2. **The master switch:** Enable Notifications.
3. **The channel is enabled** and tested. Use **Send Test Email**, **Send Test Message** or **Test Webhook**.
4. **The event group is enabled** (Enable Miner Notifications, and so on).
5. **The channel is ticked under that group's "Send to Channels".** A channel that is set up but not chosen for a group gets nothing from it.
6. **The thing is not on the exclusion list**, and is not disabled.

### Nothing was sent when GSSM started and a miner was already offline

The first check after GSSM starts sends nothing. GSSM learns the state of everything first and alerts on changes after that.

### An offline alert arrived a minute or two late

An offline alert waits for two missed checks in a row (v3.0.1+), so that one slow answer does not page you. At the default miner check interval of 60 seconds, that is about a minute later than the outage.

### A sleeping miner sent a Zero Hashrate alert

Fixed in v3.0.6. A miner that reports itself idled (standby, or Sleep on an ElphaPex) no longer alerts, however it was idled.

### A miner's alerts stopped after it was renamed

Exclusions go by name. If the miner was excluded under its old name it is no longer excluded; if it now shares a name with an excluded one, it is. Check the exclusion list.

### A miner on the exclusion list has no history and its triggers do not fire

That is how exclusion works: GSSM's background check skips an excluded miner, and Historicals, energy tracking and triggers all run on that check. Take it off the exclusion list and turn off the event types you do not want.

### Trigger alerts arrive as critical where they used to be info

From v3.2.0 a protective rule alerts as critical, whether it idled the miner or only alerted. Routine restarts stay as info.

### A big outage sent an alert for every miner

That is expected. The Rate Limiting settings on the Notifications page are saved but not applied as of v5.1.0, so every miner alert is sent.

### A litecoinpool pool sends no alerts

Pool alerts cover GoSlimStratum pools only.

### The Telegram bot does not answer

Turn on **Enable Bot Commands**. The bot only answers in the chat named as the Chat ID.

---

## Standby, Schedules and Triggers

These need a Pro or Enterprise license. The Miner Control Guide explains how each works.

### A schedule runs at the wrong hour

Window times use the server's clock. With no `TZ` set for the GSSM container it runs on UTC. Set `TZ` (for example `TZ=America/Toronto`) and restart the container. The Schedule page shows the zone GSSM is using and warns when `TZ` is missing or cannot be loaded. The MMFP installer sets `TZ=America/New_York`: change it if that is not your zone.

### You saved a schedule and nothing happened

Saving never changes the miner. A schedule acts only when a window opens or closes. To test one, set a window to start a couple of minutes from now.

### A change you made by hand was undone

A schedule takes over again at its next window edge. To keep a miner as you set it, turn its schedule off.

### A "Run" window started the miner and nothing stopped it

The schedule has no resting state. Set one (for example Power: Standby) so that something applies outside the window.

### A miner did not wake at its window

It is **held**: a protective trigger idled it, and a hold makes the schedule leave the miner alone. Open the miner's Triggers page, check why, and use **Release hold**. Holds are only released by hand, and they survive a GSSM restart.

### No Schedule or Triggers badge on a miner

The badge appears only where the device has something to schedule or a rule it can carry. See the table under Device Types in the Configuration Guide.

### The Standby choice on a protective rule is greyed out

That device has no standby or sleep state (Avalon Nano3s, Antminer, Whatsminer). The rule can alert instead.

### A reading cannot be picked for a rule

The device does not report it. It is shown greyed out and marked "not reported by this device".

### A fan rule cannot see a fan

Many boards report the speed of one fan header only. A Bitaxe GammaHex reports only what is on header 1. Fan duty and temperature are what cover the rest.

### A "below" fan rule did not fire

It is not checked while the miner is in standby, and after a wake the reading must stay low for your full number of minutes. It also only catches a fan that has stopped: most fans do not slow below about a third of full duty, so the value must sit under that.

### A rule stopped firing

It was **parked**: a rule that acts on a miner is parked after firing five times in 24 hours. Look into the cause, then re-enable it on the Triggers page. **Reset firing history** clears the counts for every rule on that miner.

### A weekly restart did not happen

The miner was idle at that time, so the restart was skipped; the page says so. Or the time is in UTC because `TZ` is not set.

### A rule takes too long to act

Rules are checked on GSSM's background miner check. Lower the **Miner Check Interval** under Notifications → Polling. The rule editor shows the figure for your install.

### Standby on a Bitaxe gives an error

Standby needs Bitaxe firmware v2.14.0 or newer.

### Waking a NerdQAxe restarts it

That is how its firmware works.

### An idled miner is mining again after a power cut

Standby does not survive a loss of power. A schedule idles it again at its next window edge.

### Two GSSM installs control the same miner

They each apply their own schedules and rules and fight over the miner. Control a miner from one install.

---

## Settings That Don't Take Effect

### A hand edit to `config.json` did nothing, or was lost

A hand edit is read when GSSM restarts, or at the next save from the web UI. A save from the web UI to the same section (the miners list, for example) before then writes over the edit. Stop GSSM, edit, start GSSM.

### "Settings saved" but a Bitaxe's pool did not change

AxeOS 2.15 changed how pool settings are stored. Fixed in GSSM v3.1.1. If you changed a pool before that, apply it again.

### A setting is not on the Configuration page

`webServerPort`, `cookieMaxAge`, a pool's `apiPort`, `updates` and the `powerUtilization` threshold are in `config.json` only. Edit the file and restart.

### Restart buttons and settings pages are missing or refused

`disableSettings` is `true` (it blocks every change to a miner from the web UI), or the device is monitor-only (Antminer, Whatsminer).

### The Configuration page is read-only

`disableConfigurations` is `true`. Set it to `false` in `config.json` and restart.

### A license was installed and nothing changed

Restart GSSM after installing a license.

### The update badge does not appear, or you do not want it

The check runs when GSSM starts and keeps its answer for 24 hours; **Check Now** on the Version page asks again. If `get.mmfpsolutions.io` cannot be reached, no badge appears. To turn the check off, set `"updates": { "enabled": false }` in `config.json`.

---

## Historicals

### Historicals will not connect

Use **Test Connection**. Check the host (`127.0.0.1` when PostgreSQL is on the same machine), the port (`5432`), the database name, the user and the password. `sslMode` must be `disable`, `require`, `verify-ca` or `verify-full`. If the database or the user does not exist yet, **Create database & user** makes them; it needs a PostgreSQL admin account, used once. With the MMFP installer the admin username and password are in `/data/docker-compose/.env`.

### A miner has no history

Historicals records a miner on GSSM's background check. A disabled miner, or one on the notification exclusion list, is not checked and not recorded.

### Charts stop at 7 days

Detailed readings are kept for `retentionDays` (7 unless you change it). Alert history is kept for 90 days. Energy records are kept until you delete them.

### The Energy report shows less than 100% measured

GSSM records only what it measured. Time when GSSM was stopped, when the miner was disabled or excluded, or when the miner did not report its power is left empty, and the coverage percentage says how much of the period was measured.

### The Energy report shows nothing for last year

Energy tracking records from the day you turn it on. Earlier months cannot be rebuilt.

### "Best (lifetime)" is shown in green

GSSM is remembering the all-time best for a miner that does not keep its own. **Reset best** under Data Management starts it again from the device.

---

## Auto-Discover

### The scan finds nothing, or misses devices you know are there

- Check the subnet, in CIDR form (`192.168.1.0/24`). It must be the miners' network.
- **Lower the concurrency.** Networks that translate addresses, such as Docker's bridge network, drop packets when many checks run at once. The MMFP installer runs GSSM on the host's network, which does not have this problem.
- The GSSM server must be able to reach that network at all.

### Pools or nodes are not found

They are found by asking a GoSlimStratum server on its API port, `4004`. Check that GoSlimStratum is running and reachable from the GSSM server.

### A discovered pool has no coin chosen

GSSM could not match the coin GoSlimStratum reports, which happens for a GoSlimStratum custom coin. Pick the coin yourself, or add the coin in the Coin Map with its **GSS coin type** first.

---

## Auto Fan Control

### A Nano3s's fan is stuck at one speed

GSSM was stopped suddenly (a crash or a power cut) while it was managing the fan, so it could not hand the fan back. Start GSSM and it takes control again. A normal stop, and disabling the miner, hand the fan back to the device's automatic mode (v2.0.5+).

### Docker stops GSSM before it finishes shutting down

Give the container a `stop_grace_period` of 30 seconds or more.

---

## Updating and Going Back

### Is there a newer version?

A badge beside the version in the footer says so: orange for an update, red when your version is older than the oldest one still recommended. The current version is also in `https://get.mmfpsolutions.io/versions/gssm/latest.json`.

### Going back to an older version

- **From 5.1.0 to 5.0.x:** delete any Hash Hopper pool entry first. An older version reads it as a coin pool with no coin and shows it offline.
- **From 5.x to 4.x or older:** your logo files stay on disk and the Coin Map stays in `config.json` through ordinary saves. Adding a node on the older version removes the Coin Map from the file, so keep a copy of `config.json`.
- **Keep a copy of `config.json` and `notifications.json` before any downgrade.**
