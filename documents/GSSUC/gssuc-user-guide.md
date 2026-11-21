# GoSlimStratum User Client (GSSUC) User Guide

What GSSUC is, how to install it, what each page shows, and how to turn on the Hash Hopper pages. Accurate for GSSUC 2.0.0.

Other GSSUC guides: the [Configuration Guide](gssuc-config-guide.md) (every setting) and the [Troubleshooting Guide](gssuc-troubleshooting-guide.md).

---

## What GSSUC Is

GSSUC is a web page for the miners of a GoSlimStratum pool. A miner opens it, picks a coin, enters a wallet address and sees their own miners, hashrate, blocks and payments. It has no pool controls: nothing a visitor does in GSSUC changes the pool.

- **It reads GoSlimStratum and keeps nothing itself.** Every figure comes from GoSlimStratum at the moment the page asks. GSSUC has no database.
- **A visitor's browser never talks to GoSlimStratum.** It talks to GSSUC, and GSSUC talks to GoSlimStratum. You can put GSSUC where your miners can reach it without exposing GoSlimStratum's own web UI.
- **It is not the pool.** Miners do not connect to GSSUC. The stratum host and port it shows are information for the miner, taken from its own settings.
- **There are no accounts.** Anyone who knows a wallet address can open that address's dashboard, in the same way anyone can look an address up on a block explorer.
- **It is for the pool operator to run.** The operator installs it, points it at GoSlimStratum, and chooses which coins it shows.

The version is at the bottom of every page: "Powered by GoSlimStratum User Client v2.0.0".

---

## Installing

GSSUC runs as one Docker container and is opened in a browser on port **3005**.

### From MIM (recommended)

On MIM's **Products** page, GoSlimStratum User Client is in the **MMFP Solutions** group. It needs GoSlimStratum installed first. MIM asks for:

| MIM asks for | What to enter |
|---|---|
| GoSlimStratum API Host | The address of the server GoSlimStratum runs on. |
| Pool Key (GSS Configuration) | The coin's key in GoSlimStratum, for example `DGB`. |
| Coin Symbol | The coin's ticker, for example `DGB`. |
| Pool Display Name | The coin's name as miners should see it. |
| Stratum Host Connection String | The hostname or IP your miners connect to. |
| Stratum Port | That coin's stratum port. |
| Configuration PIN (minimum 4 digits) | The PIN for GSSUC's admin panel. |

MIM writes the configuration to `/data/gssuc/config/config.json` and starts the container. Add more coins afterwards in GSSUC's admin panel.

GSSUC is not part of the CLI installer.

### What it needs

- **A running GoSlimStratum** whose API GSSUC can reach (port 4004 by default).
- **GoSlimStratum 6.0.0 or later** for the Hash Hopper pages. Everything else works with earlier versions.

### First steps after installing

1. Open `http://<server>:3005`.
2. Click the gear icon, enter your PIN, and open **Configuration**.
3. Check **Mining Pools**: one card for each coin you want to show, each with the coin's GoSlimStratum key.
4. Set the **Site Title** and the footer to your pool's name.
5. Change the PIN if it is still the one you installed with and others know it.

All settings are covered in the [Configuration Guide](gssuc-config-guide.md).

### Putting GSSUC on the internet

GSSUC is made to be reached by your miners, and GSSUC itself serves plain HTTP. If it can be reached from outside your own network, do both of these:

- **Put it behind a reverse proxy.** Do not publish port 3005 straight to the internet. Run a reverse proxy (nginx, Caddy, Traefik, HAProxy or similar) in front of GSSUC and let only the proxy reach port 3005.
- **Serve it over TLS (HTTPS).** Let the reverse proxy hold the certificate and answer on HTTPS, and pass requests on to GSSUC. The admin PIN then travels encrypted.

And for the admin panel:

- **Never serve the admin panel to the outside.** This is the best protection there is. Have the proxy refuse `/admin` and `/api/v1/admin` for outside visitors, and open the admin panel from inside your network or over a VPN (see the [Tailscale Install Guide](../tailscale-install.md)).
- **Set your own PIN.** Never leave it at a default or at something guessable. It is the lock on GSSUC's settings.
- **Keep Restrict Admin to Private Network on** (it is on by default), and have the proxy pass on each visitor's real address so that GSSUC can tell an outside visitor from one on your network.

GSSUC on a home network that only you reach needs none of this beyond your own PIN.

---

## The Pages

### Home: Select Mining Pool

One card for each enabled coin, with:

- the coin's badge, name and symbol,
- **Active Miners**: miners connected to that coin on the pool right now (all miners, not one person's),
- **Connection Information**: Stratum Host, Stratum Port, and "Password: Not Required",
- **View My Stats**, which asks for a wallet address and opens that address's dashboard.

When the Hash Hopper is turned on there is one more card for it (see [Hash Hopper](#hash-hopper-v200)).

### Wallet dashboard

Everything mining to one wallet address on one coin.

**How a miner is matched to an address:** a miner's stratum username is its wallet address, optionally followed by a dot and a worker name (`<address>.<worker>`). GSSUC lists every miner whose username starts with the address entered.

| Card | Shows |
|---|---|
| Total Hashrate | The connected miners' hashrate, 15-minute average. |
| Active Miners | Two figures: miners online now, and all miners on record for the address ("Online · Total"). |
| Shares/Min | The connected miners' share rate. |
| Total Shares | Shares on record for the address. |

Below the cards:

- **Hashrate History (4h):** the combined hashrate of the connected miners.
- **Your Miners:** one row per miner: Worker, Status (Online or Offline), Hashrate, Shares/Min, Best Share, Valid · Invalid, Last Seen, and a **Details** link.
- **Recent Blocks** and **Recent Payments**, each with **View All**.

**The pill in front of a worker's name (v2.0.0+)** reads `v1` or `v2`: the stratum protocol of the miner's latest connection. It is green while the miner is connected and red when it is not. A pill with no label means GoSlimStratum has no record of the protocol.

Each card on the page folds away when its heading is clicked, and the browser remembers it.

### Miner Details

One miner: Hashrate, Shares/Min, Shares (Valid · Invalid), Best Share and Uptime, then **Hashrate History (4h)**, **Difficulty History** (each change to the miner's share difficulty) and **Blocks Found by This Miner**.

### Block History

Blocks found by the address's miners: **Total Blocks**, **Total Rewards**, and a **Blocks Timeline** with height, hash, worker, reward, confirmations, status and when it was found. Height and hash link to the coin's block explorer when GoSlimStratum has an explorer address for that coin.

| Status | Means |
|---|---|
| Immature | In the chain, waiting for the coin's maturity period. |
| Mature | Past the maturity period. |
| Spendable | A block whose reward was paid straight to the miner's own address (a pool in Direct-to-Miner mode), now past the maturity period. |
| Orphaned | Not in the chain. No reward. |

Any other status is shown as GoSlimStratum reports it.

### Payment History

Payments the pool has sent to the address: **Total Earned**, **Total Payments**, **Average Payment**, **Pending Amount**, and the list of payments. A transaction links to the coin's explorer when GoSlimStratum has one.

On a pool that pays each block's reward straight to the miner's address (Direct-to-Miner mode) the pool sends no payments, so this page stays empty. Those rewards are on Block History, marked Spendable once mature.

### Network Statistics

Opened from **Network Stats** in the header while on a coin's page. Block Height, Network Difficulty, Network Hashrate, a trend chart for each of the last two, and **Pool Statistics** (Pool Hashrate, Pool Shares, Active Miners) for the whole pool.

---

## Hash Hopper (v2.0.0+)

The Hash Hopper is a GoSlimStratum feature (6.0.0 or later): one stratum port that moves a miner's rigs between several SHA-256d chains, mining whichever the pool operator's settings rank best at the moment. It is set up in GoSlimStratum. GSSUC shows a miner what their rigs on it are doing. How the Hash Hopper itself works and is configured is in the [GoSlimStratum Hash Hopper Guide](../GoSlimStratum/gss-hash-hopper-guide.md).

Two things about the Hash Hopper explain the GSSUC pages:

- **A miner on the Hash Hopper has a profile, not just an address.** A profile is a name the pool operator creates in GoSlimStratum, with one payout address for each chain. The rig's stratum username is `hopper.<profile>.<rig>`. GSSUC cannot create or change a profile.
- **A rig is on one chain at a time.** While it mines DigiByte it is sending nothing to the other chains.

### Turning it on

1. In GoSlimStratum, the Hash Hopper must be turned on, with its port open, and **not in shadow mode**.
2. In GSSUC: gear icon, PIN, **Configuration**, **Hash Hopper**.
3. Tick **Show the Hash Hopper**.
4. Enter the **Stratum Host** your miners connect to. **Display Name** is optional.
5. Save. The card appears on the home page straight away.

There is no port to enter: GSSUC reads it from GoSlimStratum.

If the card does not appear, GoSlimStratum is not reporting a Hash Hopper that is on, listening and out of shadow mode, or it is older than 6.0.0. See the [Troubleshooting Guide](gssuc-troubleshooting-guide.md#the-hash-hopper-card-is-not-on-the-home-page).

### The Hash Hopper card (home page)

The chains it hops between, **Rigs Connected** (every profile's rigs), the Stratum Host and Stratum Port, the username format `hopper.<profile>.<rig>`, and **View My Stats**, which asks for a **profile name**. The profile name is the part after `hopper.` in the miner's username; pasting the whole username works too.

### The Hash Hopper dashboard

One profile's rigs, at `/hopper/profile/<profile name>`.

| Card | Shows |
|---|---|
| Mining Now | The chain the profile's rigs are on, and since when. "No rigs connected" when none are. |
| Total Hashrate | The profile's connected rigs, 15-minute average. |
| Rigs | Two figures: rigs connected now, and all rigs on record for the profile ("Connected · Total"). |
| Blocks Found | Blocks the profile's rigs found through the Hash Hopper, on every coin, with how many coins. Hover for the count per coin. |

- **Chains:** each chain the profile has a payout address for: the address (shortened; enough to recognise it), **Time On Chain** and **Shares**. The chain being mined is marked **Mining now**. Time and shares are counted while a rig is connected and start again when GoSlimStratum restarts.
- **Your Rigs:** one row per rig: the `v1` / `v2` pill and the rig's name, Status, Chain, Hashrate, Difficulty, Accepted · Rejected shares, Last Seen, and **Details**. Connected rigs come first, highest hashrate first; rigs that have disconnected follow.
- **Blocks Found:** the profile's blocks across all its coins, newest first, with the count per coin above the table. Each block links to the explorer of the coin it was found on, when GoSlimStratum has one for that coin. Rewards are not totalled, because they are in different coins.

**Details** opens the Miner Details page for the rig. It is the same page as for a coin's miner, with two additions: the chain the rig is mining now beside its status, and the chain its best share was on. Its blocks list covers every coin.

### What miners are not shown

The operator's Hash Hopper settings stay in GoSlimStratum. GSSUC does not show chain weights, costs, the switching rules, the Switch Log or the hopping gain, and it does not show one profile's rigs or addresses to someone looking at another.

Anyone who knows a profile's name can open its dashboard, as anyone who knows a wallet address can open that address's dashboard. Payout addresses on it are shortened.

### Hash Hopper rigs on a coin's wallet dashboard

A profile's payout address on a chain is an ordinary wallet address, so entering it on that coin's card works: the profile's rigs are listed there, named `hopper.<profile>.<rig>`, with the rabbit badge.

- **A rig that is mining another chain reads "On DGB"** (the chain it is on) in the Status column. It is not Offline: it is connected and working, on a different chain. Its pill stays green.
- **Online** on a coin's dashboard means mining that coin now, so the Active Miners card and the hashrate count only the rigs on that coin at the moment.
- **A line above the Miners table** says where the profile's rigs are ("14 Hash Hopper rigs · mining DGB now") and links to the Hash Hopper dashboard.
- **Blocks** a rig finds are on the Block History page of the coin it found them on, as well as on the Hash Hopper dashboard.

---

## Updating

Update GSSUC from MIM's Products page, like any other product. Settings are kept: they are in `config.json`, outside the container.

Nothing changes when you upgrade from 1.x to 2.0.0 until you turn the Hash Hopper on.
