# MIM Troubleshooting Guide

Symptoms, what they mean, and what to do. Many of them are not faults: they are a setting, a design choice, or something fixed in a later release.

*Current for MIM 3.6.1.*

See also the [User Guide](mim-user-guide.md) and the [Configuration Guide](mim-config-guide.md).

---

## Start Here

- **Which version are you running?** It is the version link in the footer of every page. Several entries below were fixed in a particular release, and updating is often the answer (see "Updating MIM" in the User Guide).
- **MIM's own log.** The **Logs** link in the footer shows it live, if file logging is on (Config page, Logging, **Log to File**). Without file logging, read the container's log on the MIM host: `sudo docker logs mim`. Set **Log Level** to `DEBUG` while tracking a problem down, then set it back to `INFO`.
- **The Health page** (footer) shows how long MIM has been running. A short uptime means MIM restarted recently.
- **The Monitoring page** (pulse icon) says why a watched host is failing, in a few words.

> **A note on what kind of software this is.** MIM is its own product. It is not Portainer, Cockpit or Webmin, and their settings and behaviour do not apply to it. If advice names a setting that is not in the MIM guides, the setting does not exist in MIM.

---

## MIM Won't Start, or Its Pages Are Blocked

### The MIM container keeps restarting or exits at startup

MIM refuses to start when `servers.json` fails its checks. Read the log (`sudo docker logs mim`); the last lines name the problem:

| Log says | Meaning |
|-----|-----|
| `failed to parse config JSON` | The file is not valid JSON, usually after a hand edit (a missing comma or quote). |
| `no servers configured` | The `servers` list is empty. MIM needs at least one. |
| `name is required`, `ssh_host is required`, `ssh_user is required` | That server entry is missing the setting named. |
| `either ssh_password or ssh_key_path is required` | That server has neither a password nor a key. |

Fix the file (`/data/mim/config/servers.json` on a server set up by the CLI installer) and start MIM again.

### "Server Limit Exceeded" covers every page

More servers are **enabled** than your license allows. The Config page stays reachable: open it (gear icon), then disable or delete servers until you are within the limit, or install a license that covers them. Disabled servers do not count. Tiers and limits: https://www.mmfpsolutions.io/pricing.html

### Adding a server is refused with "Server limit exceeded"

The same limit, met when adding. Save the new server with **Enabled** unticked, disable another one first, or upgrade the license.

### Settings are gone after MIM restarts

MIM saves settings to its config folder. If that folder is mounted read-only (`:ro` on the `mim` service in `docker-compose.yml`), nothing can be saved. Remove the `:ro` and recreate the container.

---

## A Server Won't Connect

### A server's pages show a connection error

MIM reaches a server only over SSH. Check, in this order:

1. **The server is up and reachable** from the machine MIM runs on.
2. **SSH Host, Port and User** on the Config page are right.
3. **The password is current.** If it was changed on the server, edit the server on the Config page and type the new one.
4. **The user may use `sudo`,** and its `sudo` password is its SSH password. MIM runs Docker and system commands with `sudo`.

For a slow or distant server, raise **SSH Timeout** on the Config page.

### A server that logs in with a key connects, but nothing works

With a key and no password, MIM has no password to give `sudo`. Give that user passwordless `sudo` (`NOPASSWD`) on the server, or add its password to the server entry as well.

Two more things about keys: the **SSH Key Path** is a path inside the MIM container (put the key in the config folder and use `/app/config/<file>`), and the key must not have a passphrase.

### The saved password shows as `****`

That is normal. MIM never shows a saved password. Leave `****` to keep it, or type a new one to change it.

### A server is missing from the tabs

It is disabled. Edit it on the Config page and tick **Enabled**.

### MIM hung on a server that had frozen (before v3.6.0)

A server that accepted the connection and then stopped responding could leave MIM waiting with no time limit. Fixed in 3.6.0: the wait now ends at the SSH Timeout.

---

## Settings That Seem to Do Nothing

### Changing Docker Timeout or Refresh Interval changes nothing

Neither is used by MIM 3.6.1. They are kept on the Config page and in `servers.json`, but nothing reads them. Pages load when you open them and when you press Refresh; the Monitoring page updates itself every 10 seconds.

### I edited `monitoring.json` or `notifications.json` and nothing changed

Those two files are read when MIM starts. Restart MIM after editing them by hand. (`servers.json` is different: **Reload from Disk** on the Config page re-reads it.) Changing these settings in the web UI needs no restart.

### The Logs page says file logging is not configured

The Logs page reads MIM's log file. Turn on **Log to File** on the Config page (Logging), give it a **Log File Path** such as `/app/logs/mim.log`, and save.

### Log times are in the wrong timezone

MIM's log follows its container's timezone. On the Products tab, use **Set Timezone**, then restart MIM. A product whose timezone reads **Not Set** is running on UTC.

### I can't find the Host Monitoring settings

They moved in 3.6.1, from the Notifications page to the **Config** page, in a section called Host Monitoring. The Monitoring page's **Settings** button goes straight there.

### I installed a license and nothing unlocked

Restart MIM. A license that is installed or deleted takes full effect only after a restart.

---

## Products

### A product has no Update, Config, Disable or Uninstall buttons

- **The server needs discovery.** If the page says discovery is needed, click **Discover** so MIM can record what is installed.
- **Before v3.3.1,** the buttons could be missing on a new browser or phone until Discover was clicked on that device. Fixed in 3.3.1.

### The MIM row has no Update or Config buttons

On versions before 3.2.2, MIM could get stuck after updating itself. Version 3.2.2 fixes it and repairs a stuck MIM when it starts. To get there, on the MIM host:

```
sudo docker compose -f /data/docker-compose/docker-compose.yml pull mim && \
sudo docker compose -f /data/docker-compose/docker-compose.yml up -d mim
```

### Update says an update is available, then "no change detected"

Nothing was updated wrongly: MIM pulled the image, found it unchanged, and left the container as it was.

- **On every product, every time:** fixed in **3.5.1**. It affected servers where Docker was newly installed at version 29 or later. Update MIM.
- **Still happening on 3.5.1 or later:** the check needs Docker's `buildx` plugin (`docker-buildx-plugin`). It comes with Docker's own packages and with the CLI installer. If you installed Docker another way, install the plugin.
- **Now and then on an ARM server** (a Raspberry Pi): the registry can report a different image than the one stored even when they are the same. Harmless.

### The install wizard's Next button does nothing

A bug in 3.2.0 when installing a coin node. Fixed in 3.2.1. Update MIM.

### Install fails with "missing dependencies"

The product needs another one installed on that server first. A coin node needs **GoSlimStratum**, and GoSlimStratum needs **PostgreSQL**. Install those, then try again.

### A node won't install on a Raspberry Pi or other ARM server

Bitcoin II, Bitcoin Silver and Fractal Bitcoin run on Intel/AMD (AMD64) servers only. They carry an "AMD64 only" badge in the list.

### GoSlimStratum won't start after I installed a coin node

Your GoSlimStratum is older than that coin's support. Bitcoin Cash II and Bitcoin Silver need GoSlimStratum 5.4.0 or later, WojakCoin 5.5.4, Fractal Bitcoin 5.5.5. An older GoSlimStratum does not know the coin and refuses to start once it is in its configuration. Update GoSlimStratum (the **Update** button on its row) and it will start.

### Miners on my other coins disconnected when I installed or removed a node

Expected. MIM adds or removes the coin's pool in GoSlimStratum and restarts GoSlimStratum, which serves every coin on that server. Miners reconnect by themselves.

### After installing a node, my existing pool for that coin has different settings

Installing a coin's node from MIM writes that coin's pool into GoSlimStratum, replacing any pool of the same name, including its wallet address. Do not install a node from MIM for a coin you already run on that server. If it has happened, put your settings back in GoSlimStratum's web UI.

### Bitcoin Knots has no Install or Update button

Bitcoin Knots is deprecated (3.3.8). A node you already run keeps working and can still be disabled, enabled and uninstalled. For a new Bitcoin node use **Bitcoin Core** (miners connect on port **3336**; Knots is on 3335). To move over: install Core, let it finish syncing, point your miners at 3336, and only then uninstall Knots.

### Uninstalling a node deleted my blockchain

Uninstalling a coin node removes its data folder. To stop a node and keep its data, use **Disable**.

### Uninstall fails saying it can't find the product's configuration

MIM reads what it needs for an uninstall from the product's files on the server. If those were deleted by hand, MIM cannot finish and says so. Remove what is left over SSH.

### An amber banner says products from unknown IPs need attention

MIM holds a record of products under a server address it no longer knows, usually after a server changed IP. Click **Resolve** and either assign the record to one of your servers or delete it.

### A product's version shows as a dash

MIM shows the version the running container reports. Where the image does not report one it can trust, it shows a dash.

### A product's timezone still shows the old zone

**Set Timezone** writes the setting but does not restart anything. Restart that product to pick it up.

### Payouts fail with "insufficient funds" on a pool MIM created

This is a GoSlimStratum setting, **Maturity Confirmations**, set lower than the coin requires. Dogecoin needs 240: Dogecoin pools created by MIM before 3.4.0 were given 100. Bitcoin Silver needs 200. Correct the value in GoSlimStratum; see the GoSlimStratum guides.

---

## OS Updates

### Check for Updates fails or lists nothing

The Updates page uses `apt`, so it works on Debian-family servers such as Ubuntu. It also needs `sudo`: see "A Server Won't Connect".

### An update failed because something else was using apt

Another process (often the system's own automatic updates) held `apt`. From 3.6.0 MIM waits up to 2 minutes for it. On an earlier version, try again in a few minutes.

### MIM went down in the middle of an upgrade and the server's packages are half-installed

This happens when Docker is upgraded on the server MIM itself runs on: restarting Docker stops MIM, which stops the upgrade. Log in to that server over SSH and run:

```
sudo dpkg --configure -a
```

To avoid it, leave Docker packages unticked on the MIM host (they are unticked by default and marked **risky**) and upgrade Docker there from a terminal session.

### A red banner says a reboot is required

One of the upgraded packages, usually a kernel, takes effect only after a reboot. MIM never reboots by itself. Use **Reboot** on the Server tab when it suits you.

### Why are some updates unticked?

Packages marked **risky** (kernel and Docker) start unticked so they are not upgraded by accident. Tick them deliberately; MIM asks you to confirm.

---

## Monitoring and Notifications

### The Monitoring or Notifications page says "License required"

Notifications, Host Monitoring and scheduled OS update checks need a MIM license. See https://www.mmfpsolutions.io/pricing.html. Checking and installing OS updates by hand stays free.

### I get no alerts at all

Every one of these must be true. Work down the list:

1. **Notifications page:** **Send notifications** is ticked.
2. **Notifications page, Events:** the event is ticked, and at least one channel is ticked under it.
3. **Notifications page, Channels:** that channel is itself enabled. A channel shown as "(off)" under an event is selected but not enabled.
4. **Config page, Host Monitoring:** **Monitor hosts** is ticked.
5. **Config page, Host Monitoring:** the host is **Armed**, with **SSH check** (or **OS updates**) ticked.

Then press **Send Test** on the channel. Send Test works even when "Send notifications" is off, so a test that arrives proves the channel only, not the rest of the list. If the test fails, the message says why.

### A host is down but I got no "host down" alert

- **It was already down when MIM started** (or when monitoring was switched on). MIM alerts on changes it sees, so it does not report a host that was down from the start. You will get "host back up" when it returns.
- **It is the server MIM runs on.** If that server goes down, MIM goes down with it and cannot send anything. To watch it, use a MIM on another machine.
- **Not enough time has passed.** See the next entry.

### The alert took several minutes

By design. A host is reported down after `failures_to_down` failed checks in a row (3 by default), one every `interval_seconds` (60 by default), so 2 to 3 minutes with the defaults. This keeps a brief network blip from alerting. Both are on the Config page under Host Monitoring.

### A host shows "Checking" on the Monitoring page

MIM has not decided yet. A host shows Checking from the moment monitoring starts until its first successful check, or until it has failed enough checks in a row to be called Down.

### Several hosts went down but I got one alert and then a summary

That is rate limiting. The first alert goes out at once, and the rest arrive as one summary when the batch window closes (60 seconds by default). Settings are on the Notifications page under Rate Limiting.

### What the Detail column means for a failing host

| Detail | Meaning |
|-----|-----|
| `timed out connecting` | No answer at all: the host is off, frozen, or unreachable on the network |
| `connection refused` | The host is up but nothing is listening on the SSH port |
| `host unreachable` | No network route to the host |
| `cannot resolve host` | The host name could not be looked up |
| `connected but no SSH banner` | The connection opened but the SSH service never answered: the sign of a hung server |
| `unexpected banner` | Something other than SSH answered on that port |

### MIM's address got banned by fail2ban, sshguard or CrowdSec

Each SSH check appears in the host's login log as a connection that closed before logging in. Add MIM's address to the tool's allow list (for fail2ban, `ignoreip` in `jail.local`).

### I turned on OS update checks and got no notification

- **A host's first check is silent.** It records what is already pending without sending it. The Monitoring page shows all of it. You are told about updates that appear after that.
- **The event is off.** After upgrading from 3.5.x, **OS updates** under Events on the Notifications page is off until you tick it and choose a channel.
- **Only Security and Risky updates alert by default.** Tick **All updates** (Config page, Host Monitoring) to hear about the rest.
- **An update is reported once,** not every day it stays pending.

### The OS Updates section says "Couldn't check"

The check could not log in or list packages. The host keeps its last figures and MIM tries again every hour. This is separate from the host being down.

| It says | Meaning |
|-----|-----|
| `can't connect` | The host did not accept the SSH connection |
| `login failed` | The saved SSH user, password or key was refused |
| `timed out` | The check took longer than 5 minutes |
| `couldn't list packages` | `apt` could not list the pending updates |

### The OS Updates section says package lists couldn't be refreshed

MIM listed the pending updates but `apt update` did not run, so the list may be out of date. `sudo failed` means `sudo` did not accept the password MIM has for that server (or, on a key-only server, there is none: see "A Server Won't Connect"). `apt update failed` means `apt` itself reported an error; run `sudo apt update` on the server to see it.

### I installed updates in a terminal and the Monitoring page still shows them

MIM cannot see updates installed outside it. The figures catch up at the next scheduled check. To refresh now, click **Check** on that server's Updates page.

### I rolled back to an older MIM and my monitored hosts are unticked

The way watched hosts are stored changed in 3.6.0. After rolling back to 3.5.x, tick your hosts again.

### I didn't get the "MIM shutting down" alert

- **The event is off by default.** Tick **MIM shutting down** under Events on the Notifications page and choose a channel.
- **MIM can only send it when it is stopped in an orderly way** (stopped, restarted or updated). A power cut or a crash gives it no chance.
- MIM sends the alert in the first few seconds of shutting down, which fits inside Docker's default 10 seconds. New installs allow 120 seconds as headroom; on an install made before 3.5.0 you can add `stop_grace_period: 120s` to the `mim` service in `docker-compose.yml`.

---

## Display

### Charts or the terminal are blank

Before 3.6.1 the charts and the terminal loaded their code from an outside website each time, so they did not appear when the browser had no internet access. From 3.6.1 that code is part of MIM. Update MIM.

### Copy buttons do nothing

Before 3.2.0 the Copy buttons (Inspect page, log viewers) did not work when MIM was opened over plain `http://`. Fixed in 3.2.0.

### The Sensors card is empty or shows little

MIM shows what `lm-sensors` reports on that server. Install `lm-sensors`, run `sudo sensors-detect` once, and reload. Some boards need an extra driver before fan speeds and voltages appear at all.

### There is no update badge, or the Version page says Unknown

MIM could not reach `get.mmfpsolutions.io`, or the update check is turned off in `servers.json`. Either way MIM carries on working. See "Update Check" in the Configuration Guide.

### The Health page shows zeros under Garbage Collection

MIM has only just started. The figures fill in as it runs.
