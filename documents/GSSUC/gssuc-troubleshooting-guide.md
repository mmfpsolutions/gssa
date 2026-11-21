# GoSlimStratum User Client (GSSUC) Troubleshooting Guide

Symptoms and what they mean. Many of them are not faults. Accurate for GSSUC 2.0.0.

Other GSSUC guides: the [User Guide](gssuc-user-guide.md) and the [Configuration Guide](gssuc-config-guide.md).

**First, for any problem:** note the GSSUC version (bottom of every page), and look at the log. In the admin panel (gear icon, PIN) open **Logs**, then **Live Log Stream**; set the level to `debug` there to see each request GSSUC makes to GoSlimStratum.

---

## A miner can't find their stats

### "No Mining Activity Found"

GoSlimStratum has no miner on that coin whose username starts with the address entered. Check, in this order:

1. **The address is exactly the one in the miner's stratum username.** GSSUC matches from the first character. A different address format for the same wallet does not match.
2. **The right coin was picked.** An address used on DigiByte is not found under Bitcoin Cash.
3. **The miner has connected to this pool** and has had at least one share accepted.
4. **The miner's records were not cleared.** If the operator removed inactive miners or reset the coin's statistics in GoSlimStratum, a miner that is not connected has no records left.

### "Pool not found or disabled"

The coin in the address bar is not an enabled pool in GSSUC. The pool was disabled or removed in **Configuration**, or an old bookmark uses a key that has changed. Go back to the home page and pick the coin again.

### A miner shows Offline but is hashing

- **It is a Hash Hopper rig and the Hash Hopper is not turned on in GSSUC.** Its name starts with `hopper.`. Until the Hash Hopper is turned on in GSSUC (v2.0.0+), a rig that is mining another chain shows as Offline on every other coin. Turn it on: see the [User Guide](gssuc-user-guide.md#turning-it-on).
- **It connected moments ago.** GoSlimStratum's figures can be up to a minute behind.
- **It is connected to a different coin's port** on the same pool. Check the port in the miner.

### A miner reads "On DGB" (or another coin) instead of Online

Not a fault. It is a Hash Hopper rig that is connected and mining that other chain right now. See [Hash Hopper rigs on a coin's wallet dashboard](gssuc-user-guide.md#hash-hopper-rigs-on-a-coins-wallet-dashboard).

### Active Miners or Total Hashrate is lower than expected on a coin

On a coin's wallet dashboard, Online and the hashrate count only miners on that coin now. Hash Hopper rigs that are on another chain are not counted there. The Hash Hopper dashboard shows all of a profile's rigs together.

### The pill in front of a worker has no v1 or v2 in it

GoSlimStratum has no record of that miner's protocol, which happens after its records were cleared. The label returns the next time the miner connects.

### Payment History is empty

- The pool pays each block's reward straight to the miner's address (Direct-to-Miner mode), so there are no pool payments. Look at Block History; those blocks become **Spendable**.
- Or no payment has been sent to that address yet.

### Block or transaction links don't go anywhere

GSSUC takes explorer addresses from GoSlimStratum. A coin with no block explorer address in GoSlimStratum's Global Config shows the hash as plain text. Add the address in GoSlimStratum; GSSUC picks it up without a restart.

### A coin shows the Bitcoin badge

GSSUC has no built-in badge for that pool's symbol. Give the pool an **Icon URL** in **Configuration**. Built-in badges are listed in the [Configuration Guide](gssuc-config-guide.md#pools-section).

---

## Hash Hopper

### The Hash Hopper card is not on the home page

All of these must be true. Check them in order:

1. **GSSUC is 2.0.0 or later** (bottom of the page).
2. **Show the Hash Hopper is ticked** and a **Stratum Host** is entered, in **Configuration**, **Hash Hopper**.
3. **GoSlimStratum is 6.0.0 or later.**
4. **The Hash Hopper is turned on in GoSlimStratum.**
5. **It is not in shadow mode.** In shadow mode the Hash Hopper only works out where it would mine; its port is closed and no rig can connect, so GSSUC shows nothing.
6. **Its port is open.** GoSlimStratum's Hash Hopper page shows whether it is listening.
7. **GSSUC can reach GoSlimStratum.** If the coin cards show 0 Active Miners for every coin as well, see [GSSUC can't reach GoSlimStratum](#gssuc-cant-reach-goslimstratum).

Nothing needs restarting. GSSUC asks GoSlimStratum again within a few seconds.

### "No Hash Hopper profile named ..."

GoSlimStratum has no profile with exactly that name.

- The name is the part after `hopper.` in the miner's username: for `hopper.myfarm.rig1` it is `myfarm`.
- Upper and lower case matter.
- Profiles are created by the pool operator in GoSlimStratum. GSSUC cannot create one. A miner without a profile needs to ask the operator.

### "Hash Hopper is not available"

The page was opened (from a bookmark, usually) while the pool is not running the Hash Hopper: it was turned off, put in shadow mode, or its port was closed in GoSlimStratum. Miners on a coin's own port are not affected. The page works again when the Hash Hopper is back.

### Time On Chain and Shares went back to zero

They are counted by GoSlimStratum while a rig of the profile is connected. They start again when GoSlimStratum restarts, when the profile's last rig disconnects, and when the operator resets the Hash Hopper's statistics. Blocks Found is not affected.

### A block is missing from the Hash Hopper dashboard

- **The count has not caught up.** The blocks list is re-read every minute.
- **The pool has more than 1,000 Hash Hopper blocks.** The dashboard reads the newest 1,000 across all profiles, and says so under the table when that limit is reached. Older blocks are still on each coin's own Block History page, under the profile's payout address for that coin.

### A rig's Difficulty History is empty on a coin's page but not on the Hash Hopper page

Expected. A Hash Hopper rig's difficulty changes are recorded under the Hash Hopper, not under each coin. Open the rig from the Hash Hopper dashboard to see them.

### The port on the card is not the one I expected

The card shows the port GoSlimStratum reports for the Hash Hopper's Stratum V1 port. Change it in GoSlimStratum, not in GSSUC.

---

## GSSUC can't reach GoSlimStratum

Signs: every coin card shows 0 Active Miners, dashboards say "Error Loading Data" or "Failed to fetch", and the log has "GSS API" errors.

1. **Check the Base URL** in **Configuration**, **GSS API Settings**. It is `http://<GoSlimStratum server>:4004/api/v1` unless GoSlimStratum's API port was changed.
2. **`localhost` means the GSSUC container, not the server.** If GoSlimStratum is on the same server, use the server's IP address.
3. **GoSlimStratum is running**, and a firewall is not blocking its API port from the GSSUC server.
4. **A changed Base URL needs a restart** of GSSUC.

Pages are slow rather than failing: GSSUC waits **Timeout (seconds)** and retries **Retry Attempts** times before giving up, so an unreachable GoSlimStratum makes every page wait. The defaults are 10 seconds and 3 retries.

---

## The admin panel

### There is no gear icon

One of:

- **Hide Admin Icon** is on. The panel is still at `/admin`.
- **Restrict Admin to Private Network** is on and you are not on a private network address (`10.x`, `172.16.x` to `172.31.x`, `192.168.x`, or the server itself).
- **Enable Web Admin** is off.

### `/admin` says Not Found

- **Restrict Admin to Private Network** is on and your address is not a private one. Open GSSUC from inside the network, or over a VPN.
- **Behind a reverse proxy**, GSSUC sees the address the proxy passes on. The proxy must send the visitor's real address, or every visitor looks like the proxy. Running GSSUC behind a reverse proxy with TLS is the recommended way to put it on the internet: see [Putting GSSUC on the internet](gssuc-user-guide.md#putting-gssuc-on-the-internet).
- **Enable Web Admin** is off. With it off there is no admin panel at all; turn it back on in `config.json` (`security.enable_web_admin`) and restart GSSUC.

### The PIN is refused

- **Five wrong PINs in 15 minutes lock that address out for one hour.** Wait, or restart GSSUC, which clears the lock.
- **Forgotten PIN:** it is `security.config_pin` in `config.json` (`/data/gssuc/config/config.json` on a MIM install). Read it there, or change it there and restart GSSUC. This is one of the few times a file edit is the right answer.

### I was signed out

A sign-in lasts 30 minutes from the last thing you did in the admin panel. A restart of GSSUC also signs everyone out.

### A setting was saved but nothing changed

Four settings need a restart of GSSUC: **Port**, **Host**, the GSS API **Base URL**, and **Enable Web Admin**. Everything else applies when saved.

A setting given by an environment variable on the container (`GSSUC_PORT`, `GSSUC_GSS_API_BASE_URL`, `GSSUC_LOG_LEVEL`, `GSSUC_LOG_FILE_PATH`, `GSSUC_SITE_TITLE`) wins over the saved value after the next restart.

### Saving is refused

The Configuration page checks the settings before saving and names the one that failed. The rules are in the [Configuration Guide](gssuc-config-guide.md#configuration-validation). Common ones: at least one pool must be enabled, two pools can't have the same GSS key, and the Hash Hopper needs a Stratum Host when it is ticked.

### I saved something wrong

Each save keeps the previous file as `config.json.backup` in the same folder. Change the setting back in the admin panel, or copy the backup over `config.json` and restart GSSUC.

---

## GSSUC won't start

GSSUC checks `config.json` when it starts and stops with a message naming the setting if something is wrong. Read the container's log (in MIM: the container's **Logs**).

- **"config file not found":** there is no `config.json` in the folder mounted at `/app/config`.
- **"failed to parse config file":** the file is not valid JSON, usually after a hand edit. Restore `config.json.backup`.
- **"invalid configuration: ...":** a value breaks a rule. The message names it. See [Configuration Validation](gssuc-config-guide.md#configuration-validation).

---

## After an update

- **The page looks unchanged or oddly laid out:** reload it with the browser's hard refresh, so it fetches the new version's files.
- **Nothing about the Hash Hopper appeared after updating to 2.0.0:** it is off until you turn it on. See the [User Guide](gssuc-user-guide.md#turning-it-on).
