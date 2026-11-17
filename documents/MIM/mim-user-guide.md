# MIM User Guide

What MIM (Mining Infrastructure Manager) does, page by page, and how to install and look after products with it.

*Current for MIM 3.6.1.*

See also the [Configuration Guide](mim-config-guide.md) (every setting) and the [Troubleshooting Guide](mim-troubleshooting-guide.md).

---

## What MIM Is

MIM is a web dashboard for the servers that run your mining stack. From one page you can:

- see and control the Docker containers on each server;
- watch a server's load, memory, storage, sensors and performance;
- install, update and remove products: coin nodes, GoSlimStratum, GSS Miners and others;
- check for and install operating system updates;
- open a terminal on a server;
- be told when a server stops responding or has new OS updates (with a license).

**How it works.** MIM runs as one Docker container. It manages a server by logging in to it over SSH and running commands there. Nothing is installed on the servers for MIM itself: it needs only an SSH user with `sudo` (see "What the SSH User Needs" in the Configuration Guide). One MIM can manage several servers.

**Opening it.** A browser on port **3001** of the server MIM runs on: `http://<server-ip>:3001`.

**What MIM is not.** It is not the mining pool (that is GoSlimStratum) and not the miner dashboard (that is GSS Miners). It does not mine, hold coins or talk to miners. It manages the servers and containers those products run in.

---

## Finding Your Way Around

**Header, on every page:**

| Control | What it does |
|-----|-----|
| **MIM** (title) | Back to the first server's Containers page |
| Server tabs | One per enabled server. Click to switch server. On a phone this is a dropdown. |
| Refresh (circular arrow) | Reloads the page |
| Notifications (bell) | Where alerts go |
| Monitoring (pulse) | Status of watched hosts and their OS updates |
| Config (gear) | Servers, settings, logging, Host Monitoring |

The header buttons show icons only (v3.6.1+). Hover over one to see its name.

**Tabs for the selected server:** Containers, Server, Performance, Products.

**Footer, on every page:**

| Link | What it opens |
|-----|-----|
| The version number | The Version page: version, runtime status, the update check and your license. An **update** badge appears beside it when a newer MIM is out. |
| Logs | A live view of MIM's own log. Needs file logging turned on (Config page, Logging). |
| Health | How the MIM application itself is doing: uptime, memory, garbage collection (v3.3.7+) |

**MIM does not refresh pages in the background.** A page reads its data when you open it and when you press Refresh. The exception is the Monitoring page, which updates itself every 10 seconds.

---

## Containers

Every Docker container on the selected server, whether MIM installed it or not.

- **Start, Stop, Restart** a container. Each asks you to confirm.
- **Logs:** the container's log.
- **Inspect:** the container's full details, with a **Copy JSON** button.
- **Prune:** removes dangling (unused, untagged) Docker images to free disk space. It shows how many and how much space before you confirm.

---

## Server

A quick look at the machine itself.

- **System Resources:** CPU load, memory and swap.
- **Storage:** one row per drive with a usage dial. The used figure turns amber, then red, as a drive fills.
- **Sensors (v3.2.3+):** temperatures, voltages, fan speeds, fan duty, power and clock speeds, grouped by chip. MIM shows whatever `lm-sensors` reports on that server, so how much you see depends on the server. Install `lm-sensors` and run `sudo sensors-detect` once to get the most out of it. This is read-only: MIM does not control fans.

Buttons at the top:

| Button | What it does |
|-----|-----|
| **Terminal** | A command line on the server, in the browser |
| **Updates** | The server's OS updates (see below) |
| **Reboot** | Restarts the server, after you confirm |
| **Shutdown** | Powers the server off, after you confirm |

---

## Performance (v3.3.0+)

How hard the server is working right now: CPU (overall and per core), memory, network speed per connection, disk activity per drive, and **Pressure**, a plain reading of whether the machine is struggling. Each card has a **Details** link for the deeper numbers. If the server bonds network cards, the bond's health shows too.

It reads the server when you open the tab and when you press **Refresh**, not continuously.

---

## Products

Install and manage software on the selected server. Products are grouped:

| Section | What is in it |
|-----|-----|
| **MMFP Solutions** | MIM, GoSlimStratum, GSS Miners, GoSlimStratum User Client, Axeos Dashboard (deprecated) |
| **Crypto Nodes** | The coin nodes in the table below |
| **3rd Party** | PostgreSQL, Dozzle, Watchtower |
| **Other** | Services you have added to the server's `docker-compose.yml` yourself that are not in MIM's catalog |

Each installed product shows the version it is actually running, read from the container.

### Buttons on a Product

| Button | What it does |
|-----|-----|
| **Install** | Opens the install wizard |
| **Update** | Checks the registry for a newer image. If there is one, pulls it and restarts the container. If not, says "already up to date". |
| **Config** | Downloads the product's configuration files |
| **Disable** | Stops the container and keeps it from starting |
| **Enable** | The reverse of Disable |
| **Uninstall** | Removes the product. **For a coin node this deletes its data folder, including the downloaded blockchain.** |

Not every product has every button. MIM itself and PostgreSQL cannot be installed or uninstalled from this page: MIM has **Update** only, and PostgreSQL has Update, Disable and Enable. Deprecated products (Bitcoin Knots, Axeos Dashboard) have no Install or Update, but can still be disabled, enabled and uninstalled.

### Buttons at the Top of the Page

- **Discover:** scans the server and records which products are already installed there. A new server's Products page offers this the first time you open it.
- **Set Timezone (v3.3.4+):** sets the timezone for MIM, GoSlimStratum, GSS Miners and GoSlimStratum User Client on this server, whichever are installed. MIM writes the setting but does **not** restart anything; it tells you which products need a restart to pick it up. Each of those products shows its timezone in the list; **Not Set** means it is running on UTC.

### Where Things Live on the Server

- Every product is a service in one compose file: `/data/docker-compose/docker-compose.yml`.
- Each product keeps its files in its own folder under `/data` (for example `/data/mim`, `/data/goslimstratum`, `/data/ltc`).

### Installing a Coin Node

A coin node needs **GoSlimStratum installed on that server first** (and GoSlimStratum needs PostgreSQL). The wizard asks for:

- an **RPC username** and **RPC password** for the node;
- a **Node Type**: **Full**, **Pruned (Recommended)**, the default, or **Custom** with a prune size in MB;
- the **Server IP Address**, filled in for you.

Then MIM does the rest:

1. creates the node's folders and configuration;
2. adds the node to the compose file and starts it;
3. creates a wallet and shows you its address (not for Dogecoin, see below);
4. adds a ready-to-mine pool for that coin to GoSlimStratum's configuration;
5. restarts GoSlimStratum.

After that, point your miners at the stratum port in the table. **Restarting GoSlimStratum briefly disconnects miners on every coin on that server.**

Uninstalling reverses it: the node is stopped and removed, its pool is removed from GoSlimStratum, GoSlimStratum is restarted, and the node's data folder is deleted.

### Coin Nodes

| Node | Coin | Algorithm | Stratum port | Runs on | Smallest pruned size |
|-----|-----|-----|-----|-----|-----|
| DigiByte Node | DGB | SHA256d (the pool MIM creates) | 3333 | AMD64, ARM64 | 563 MB |
| Bitcoin Cash Node | BCH | SHA256d | 3334 | AMD64, ARM64 | 563 MB |
| Bitcoin Knots Node (deprecated) | BTC | SHA256d | 3335 | AMD64, ARM64 | 563 MB |
| Bitcoin Core Node | BTC | SHA256d | 3336 | AMD64, ARM64 | 563 MB |
| eCash Node | XEC | SHA256d | 3337 | AMD64, ARM64 | 550 MB |
| Bitcoin II Node | BC2 | SHA256d | 3338 | **AMD64 only** | 563 MB |
| Bitcoin Cash II Node | BCH2 | SHA256d | 3339 | AMD64, ARM64 | 563 MB |
| Bitcoin Silver Node | BTCS | SHA256d | 3340 | **AMD64 only** | 563 MB |
| Wojakcoin Node | WJK | SHA256d | 3341 | AMD64, ARM64 | 563 MB |
| Fractal Bitcoin Node | FB | SHA256d | 3342 | **AMD64 only** | 30000 MB |
| Litecoin Node | LTC | Scrypt | 4335 | AMD64, ARM64 | 563 MB |
| Doge Node | DOGE | Scrypt | 4040 | AMD64, ARM64 | 2300 MB |

Notes:

- **"Pruned (Recommended)" uses the smallest pruned size** in the table. A full node needs far more disk and a long first sync.
- **AMD64 only** nodes will not install on ARM servers such as a Raspberry Pi. The list marks them with an "AMD64 only" badge.
- **Bitcoin has two nodes.** Bitcoin Core is the supported one. Bitcoin Knots is deprecated (v3.3.8): an existing Knots node keeps running and can be managed, but it cannot be newly installed or updated. The two can run side by side as separate pools on separate ports.
- **Dogecoin is Direct-to-Miner only.** MIM creates no wallet for it, and installing it accepts GoSlimStratum's 0.5% revenue share unless you have a GoSlimStratum license. Read the product's description before installing.
- **GoSlimStratum version needed:** Bitcoin Cash II and Bitcoin Silver need GoSlimStratum 5.4.0 or later, WojakCoin 5.5.4 or later, Fractal Bitcoin 5.5.5 or later. Update GoSlimStratum first: an older GoSlimStratum does not know the coin and will not start once it is added.
- **Already running a coin yourself?** Do not install the same coin's node from MIM on that server. MIM would replace that coin's pool settings in GoSlimStratum, including its wallet address, with the new node's.
- **The pool MIM creates is a starting point.** Tune it afterwards in GoSlimStratum's own web UI.

### The Other Section

Services in the server's compose file that MIM's catalog does not know. Each can be **Updated**, **Disabled** and **Enabled** from here. For plain start and stop, use the Containers tab.

### Orphaned Inventory

If a server's address changed in the past, MIM may hold a record of products under the old address. The Products page then shows an amber banner, "N product(s) from unknown IPs need attention". Click **Resolve** to assign the record to one of your servers or delete it.

---

## OS Updates

Open a server's **Server** tab and click **Updates**. This uses `apt`, so it is for Debian-family servers such as Ubuntu.

1. **Check for Updates** runs `apt update` and lists every package that can be upgraded, with its current and new version.
2. Two badges mark packages worth a second look:
   - **security:** the package comes from a `-security` source.
   - **⚠ risky:** kernel and Docker packages. Upgrading a kernel needs a reboot to take effect; upgrading Docker restarts the containers on that server. Hover the badge to see why.
3. Tick what you want. The quick choices are **All safe** (everything except risky, the default), **Security only**, **All including risky** and **Clear**.
4. **Apply Selected** upgrades exactly those packages and shows progress for each. Choosing a risky package asks you to confirm first.
5. If a reboot is needed afterwards, a red banner says so and lists the packages. MIM never reboots by itself: use **Reboot** on the Server tab.

> **Upgrading Docker on the server MIM runs on stops MIM itself** part-way through, which can leave the upgrade half-finished. That is why Docker packages are unticked by default. Upgrade Docker on the MIM host from a terminal session instead.

From v3.6.0, if something else on the server is using `apt`, MIM waits up to 2 minutes instead of failing straight away.

Checking and installing updates here is free. Having MIM check on a schedule and tell you about new updates is part of Host Monitoring, which needs a license.

---

## Monitoring (licensed)

The **Monitoring** page (pulse icon) shows what Host Monitoring has found. It has two parts.

**Host Monitoring:** one row per host with the SSH check on.

| Column | Meaning |
|-----|-----|
| Status | **Up**, **Down**, or **Checking** (not decided yet) |
| Latency | How long the last check took |
| Avg (min-max) | Over the last 20 successful checks |
| Since | How long the host has been in this state |
| Detail | Why a down host is failing, or how many checks have failed so far on an up host |

**OS Updates (v3.6.0+):** totals across your servers, then one row per host with the OS update check on: how many updates are pending, how many are Security and Risky, when it was last checked, whether a reboot is needed, and an **Updates** button that opens that server's Updates page. A host with nothing pending shows **Up to date**. If a host could not be checked, its row says so and keeps its last figures.

There is no "check now" button here. To check a server right away, use **Check** on its Updates page.

Which hosts are watched, and how, is set on the Config page under **Host Monitoring**; the **Settings** button on this page goes there. Where alerts are sent is set on the Notifications page. Both are described in the [Configuration Guide](mim-config-guide.md).

---

## Notifications (licensed)

The **Notifications** page (bell icon) sets up where alerts go: email, Telegram, and any number of webhooks (Discord, or JSON for your own receiver), and which events go to which. Each channel has a **Send Test** button that works before you save.

Events MIM can send: host down, host back up, OS updates available, MIM started, MIM shutting down. See the [Configuration Guide](mim-config-guide.md#notifications-notificationsjson) for every setting.

---

## Updating MIM

MIM shows an **update** badge beside the version in the footer when a newer release is out (red and reading **critical** when the release is one you should not skip). Click it for the details and a link to the release notes.

To update: open the **Products** tab of the server MIM runs on and click **Update** on the MIM row. MIM pulls the new image and restarts itself. The page will be unavailable for a few moments.

From a terminal on the MIM host, the same thing is:

```
sudo docker compose -f /data/docker-compose/docker-compose.yml pull mim && \
sudo docker compose -f /data/docker-compose/docker-compose.yml up -d mim
```

---

## Installing MIM as an App (v3.3.0+)

MIM can be added to a phone's home screen or a desktop, where it opens in its own window. On iPhone and iPad: Safari, Share, **Add to Home Screen**. This works over a plain `http://` address. In desktop or Android Chrome the one-click install button needs MIM to be served over HTTPS (a reverse proxy, or `tailscale serve`). It is the same MIM either way and still needs your servers to be reachable.
