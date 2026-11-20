# MIM Configuration Guide

Reference for every setting in MIM (Mining Infrastructure Manager): the servers it manages, its global settings, Host Monitoring and notifications.

*Current for MIM 3.7.0.*

See also the [User Guide](mim-user-guide.md) (what each page does, installing products) and the [Troubleshooting Guide](mim-troubleshooting-guide.md).

> [!TIP]
> Almost everything here is set in the web UI: the **Config** page (gear icon) and the **Notifications** page (bell icon). Editing the files by hand is rarely needed.

---

## Summary

MIM keeps its configuration as JSON files in one config folder.

| File | Holds | Changed on |
|-----|-----|-----|
| `servers.json` | The servers MIM manages and the global settings (timeouts, logging, update check) | **Config** page |
| `monitoring.json` | Host Monitoring: which hosts are watched and how (v3.5.0+) | **Config** page, Host Monitoring section |
| `notifications.json` | Where alerts go: channels, events, rate limiting (v3.5.0+) | **Notifications** page |

MIM also writes these files itself. Don't edit them unless a guide tells you to:

| File | Holds |
|-----|-----|
| `product-inventory.json` | Which products are installed on each server |
| `os-updates-state.json` | The latest OS update check result for each host (v3.6.0+) |
| `host-boot-state.json` | Each host's boot ID and its last 10 reboots (v3.7.0+) |
| `mmfp_license.dat` | Your license, installed from the License page |

**Where the folder is.** Inside the MIM container it is `/app/config`. On a server set up with the [CLI installer](../../cli-installer.md), that folder is `/data/mim/config` on the host.

MIM looks for `servers.json` in two places, in this order, and keeps the other files in the same folder:

1. `./config/servers.json` (a local path, for development)
2. `/app/config/servers.json` (the Docker container path)

> **The config folder must be writable.** MIM saves settings to it. If the folder is mounted read-only (`:ro` in `docker-compose.yml`), remove the `:ro`.

### When a Change Takes Effect

| Change | Takes effect |
|-----|-----|
| A server added, edited or deleted on the Config page | At once. It is saved when you click **Save** in the server form. |
| General Settings and Logging | When you click **Save Settings**. The log level and file logging apply at once; `ssh_timeout` applies to the next connection. |
| Host Monitoring | When you click **Save Settings**. The checks pick it up at once. |
| Notifications page | When you click **Save Settings**. |
| `servers.json` edited by hand | Click **Reload from Disk** on the Config page, or restart MIM. |
| `monitoring.json` or `notifications.json` edited by hand | Restart MIM. They are read at startup. |
| The update check (`settings.updates`) | Restart MIM. |
| A license installed or deleted | Restart MIM. |

---

## servers.json

Two top-level sections:

- **`servers`**: each physical server (or VM) MIM connects to and manages.
- **`settings`**: global settings: timeouts, logging and the update check.

### Example

```json
{
    "servers": [
        {
            "id": "qCwwociO",
            "name": "MIM Server",
            "description": "MIM Server",
            "ssh_host": "192.168.1.100",
            "ssh_port": 22,
            "ssh_user": "mim",
            "ssh_password": "password",
            "enabled": true,
            "mim_host": true
        }
    ],
    "settings": {
        "ssh_timeout": 30,
        "docker_timeout": 30,
        "refresh_interval": 60,
        "logging": {
            "level": "INFO",
            "log_to_file": false,
            "log_file_path": "/app/logs/mim.log",
            "max_size_mb": 20,
            "max_age_days": 30,
            "max_backups": 10,
            "compress": false
        }
    }
}
```

---

## Servers

The `servers` array lists every machine MIM connects to. MIM does all its work on a server over SSH: Docker commands, system information, updates and the terminal.

### Server Fields

| Field | Required | Default | Description |
|-----|--------|-------|-----------|
| `id` | Auto-generated | - | Unique 8-character identifier. MIM creates it. Do not edit it: Host Monitoring and the product inventory refer to a server by this ID. |
| `name` | Yes | - | Display name shown in the server tabs. |
| `description` | No | - | Free-text description (its role or location, for example). |
| `ssh_host` | Yes | - | IP address or hostname MIM uses to SSH into the server. |
| `ssh_port` | No | `22` | SSH port. `22` if omitted or `0`. |
| `ssh_user` | Yes | - | SSH username. See "What the SSH User Needs" below. |
| `ssh_password` | Conditional | - | SSH password. Either this or `ssh_key_path` is required. Stored encrypted (see below). |
| `ssh_key_path` | Conditional | - | Path to an SSH private key file. Either this or `ssh_password` is required. |
| `enabled` | Yes | - | `true`: the server is managed and shown. `false`: it stays in the file but is not shown, not checked and not counted toward the license. |
| `mim_host` | No | `true` | Whether MIM itself runs on this server. See below. |

### SSH Authentication

A server needs a password, a key, or both.

**Password:**
```json
"ssh_user": "mim",
"ssh_password": "yourpassword"
```

**Key:**
```json
"ssh_user": "mim",
"ssh_key_path": "/app/config/id_ed25519"
```

- **The password is stored encrypted.** MIM encrypts `ssh_password` the first time it loads the file, so on disk the value starts with `ENC:`. To change it by hand, replace the whole value with the new password in plain text; MIM encrypts it on the next load. In the web UI a saved password shows as `****`, and leaving it as `****` keeps the saved one.
- **The key path is a path inside the MIM container.** Put the key file in the config folder (`/data/mim/config` on the host) and refer to it as `/app/config/<file>`. The key must not have a passphrase.
- **If both are set,** MIM offers both when logging in and uses the password for `sudo`.

### What the SSH User Needs

MIM runs Docker commands and system commands on the server with `sudo`, and gives `sudo` the SSH password. So the SSH user must:

- be allowed to use `sudo`;
- have the same password for `sudo` as for SSH (the normal case).

**Key-only servers:** with `ssh_key_path` and no `ssh_password`, MIM has no password to give `sudo`. That user needs passwordless `sudo` (`NOPASSWD`) on the server, or most of MIM's actions will fail.

The CLI installer creates a `mim` user for this, in the `sudo` and `docker` groups.

### The `mim_host` Field

`mim_host` says which server runs the MIM application itself. MIM's self-update depends on it: when MIM updates itself on its own host, it restarts in a way that survives its own container being replaced.

| Value | Meaning |
|-----|-------|
| `true` (or omitted) | MIM runs on this server. |
| `false` | A remote server. MIM does not run here. |

> **Only one server should be the MIM host.** Because the default is `true`, every *other* server must say `"mim_host": false`. On the Config page this is the **MIM Host** checkbox in the server form: untick it for remote servers.

Host Monitoring marks this server **MIM host** in its list, because MIM can't report an outage of the machine it runs on.

### The `enabled` Field

`enabled: false` switches a server off without removing it. A disabled server:

- does not appear in the server tabs;
- is not connected to, monitored or checked for updates;
- does not count toward the license's server limit.

### `docker_host` (removed in v3.2.0)

Older files have a `"docker_host": "ssh://user@host"` line on each server. MIM has ignored it since v3.2.0 and no longer writes it. A file that still has the line works unchanged; delete the line whenever you like.

---

## Settings

Global settings, under `settings` in `servers.json`. On the Config page they are the **General Settings** and **Logging** sections.

### General Settings

| Field | Default | Description |
|-----|-------|-----------|
| `ssh_timeout` | `30` | Seconds MIM waits for an SSH connection and login to a server before giving up. From v3.6.0 this also covers a server that accepts the connection and then stops responding. It does not limit how long a command may run once connected. Raise it for slow or distant servers. |
| `docker_timeout` | `30` | **Not used by MIM 3.7.0.** The value is kept in the file and shown on the Config page (Docker Timeout), but changing it has no effect. Docker commands run over the SSH connection. |
| `refresh_interval` | `60` | **Not used by MIM 3.7.0.** The value is kept in the file and shown on the Config page (Refresh Interval), but changing it has no effect. Pages load their data when you open them and when you press **Refresh**; the Monitoring page refreshes itself every 10 seconds. |

### Update Check (v3.1.2+)

MIM checks once at startup whether a newer MIM has been released, and shows an **update** badge in the footer when one has. It downloads one small file and sends nothing about your install.

| Field | Default | Description |
|-----|-------|-----------|
| `updates.enabled` | `true` | `false` turns the check off: no badge, and the Version page shows the update status as Unknown. |
| `updates.url` | `https://get.mmfpsolutions.io/versions/mim/latest.json` | Where the version file is read from. Leave it alone unless support tells you otherwise. |

This block is not on the Config page. To turn the check off, add it to `settings` by hand and restart MIM:

```json
"settings": {
    "updates": { "enabled": false }
}
```

If the block is missing, the check is on. MIM does not add the block to your file.

---

## Logging

How MIM writes its own log. Under `settings.logging`; the **Logging** section of the Config page.

```json
"logging": {
    "level": "INFO",
    "log_to_file": false,
    "log_file_path": "/app/logs/mim.log",
    "max_size_mb": 20,
    "max_age_days": 30,
    "max_backups": 10,
    "compress": false
}
```

| Field | Default | Description |
|-----|-------|-----------|
| `level` | `"INFO"` | Log detail. See the levels below. |
| `log_to_file` | `false` | `true` writes the log to a file as well as the console. **The Logs page (footer) needs this on.** |
| `log_file_path` | - | Path of the log file inside the container, for example `/app/logs/mim.log`. Required when `log_to_file` is `true`. |
| `max_size_mb` | `20` | Size in MB at which the log file is rotated. |
| `max_age_days` | `30` | Days to keep rotated log files. |
| `max_backups` | `10` | How many rotated log files to keep. |
| `compress` | `false` | Compress rotated log files with gzip. |

### Log Levels

| Level | What Gets Logged |
|-----|----------------|
| `DEBUG` | Everything: SSH commands, Docker operations, request details |
| `INFO` | Normal operation: connections, container changes, checks and alerts |
| `WARN` or `WARNING` | Recoverable problems: a failed check, a setting that couldn't be saved |
| `ERROR` | Failures only |

> **Tip:** `INFO` is right for normal use. Use `DEBUG` while tracking down a connection problem, then set it back.

Log timestamps follow the container's timezone (the `TZ` line in `docker-compose.yml`). Set it for MIM and your other MMFP products with **Set Timezone** on the Products page.

---

## Host Monitoring (monitoring.json)

**AS OF Version 3.5.0** (per-host settings and OS update checks from 3.6.0; on the Config page from 3.6.1; reboot detection from 3.7.0)

Host Monitoring watches the servers you choose and raises an alert when something changes. It has three checks:

- **SSH check:** connects to the host's SSH port and waits for the SSH service to answer. It does not log in. It catches a server that has hung even when it still answers ping.
- **OS updates:** logs in with the server's saved SSH credentials, runs `apt update` with `sudo`, and reports what is pending. It never installs anything.
- **Reboots (v3.7.0+):** logs in and reads the host's boot ID, a value Linux sets fresh at every boot. If it has changed since the last check, the host rebooted, however briefly it was away. MIM then says whether the shutdown was clean or unplanned.

Results show on the **Monitoring** page (pulse icon in the header). Whether an alert is *sent*, and where, is set on the Notifications page.

> [!IMPORTANT]
> Host Monitoring needs a MIM license. Without one, the Host Monitoring section of the Config page shows a "License required" notice and the checks do not run. Checking and installing OS updates by hand on a server's Updates page stays free.

### Example

```json
{
  "enabled": true,
  "host_checks": {
    "qCwwociO": { "armed": true, "ssh_check": true, "os_updates": true, "reboot_check": true },
    "Xk29LmP4": { "armed": false, "ssh_check": true, "os_updates": false, "reboot_check": false }
  },
  "checks": {
    "ssh_banner": {
      "interval_seconds": 60,
      "timeout_seconds": 10,
      "failures_to_down": 3,
      "successes_to_up": 1
    },
    "os_updates": {
      "interval_hours": 24,
      "notify_security": true,
      "notify_risky": true,
      "notify_other": false
    },
    "reboot": {
      "interval_minutes": 5
    }
  }
}
```

### Top Level

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | The **Monitor hosts** switch. `false` stops every check on every host. It is independent of the notifications switch: monitoring can run and fill the Monitoring page with nothing being sent. |
| `host_checks` | empty | What is watched on each server. One entry per server, keyed by the server's `id` from `servers.json`. |

### Per Host (`host_checks`)

On the Config page this is the **Hosts to watch** table: one row per server.

| Field | Default | Description |
|-----|-------|-----------|
| `armed` | `false` | The host's own on/off switch (the **Armed** column). Disarming stops every check on that host but keeps the settings below, so re-arming puts them back. |
| `ssh_check` | `false` | Run the SSH check on this host (the **SSH check** column). On the Config page, a host armed for the first time starts with this ticked. |
| `os_updates` | `false` | Run the OS update check on this host (the **OS updates** column). |
| `reboot_check` | `false` | Run reboot detection on this host (the **Reboots** column, v3.7.0+). |

A host is checked only when `enabled` is on, the host is `armed`, and that check's own setting is on. A server that is disabled in `servers.json` cannot be armed.

### SSH Check Settings (`checks.ssh_banner`)

| Field | Default | Range | Description |
|-----|-------|-----|-----------|
| `interval_seconds` | `60` | 15 to 3600 | How often each host is checked. |
| `timeout_seconds` | `10` | 1 to 60 | How long to wait for an answer. Must be shorter than the interval. |
| `failures_to_down` | `3` | 1 to 10 | Failed checks in a row before a host is reported down. |
| `successes_to_up` | `1` | 1 to 10 | Successful checks in a row before a down host is reported up again. |

With the defaults, a host is reported down 2 to 3 minutes after it stops answering. Time to an alert is roughly `interval_seconds` × `failures_to_down`.

Each check appears in the host's login log as a connection that closed before logging in. If the host runs fail2ban, sshguard or CrowdSec, add MIM's address to its allow list (for fail2ban, `ignoreip` in `jail.local`) so the checks can't get MIM blocked.

### OS Update Check Settings (`checks.os_updates`)

**AS OF Version 3.6.0**

| Field | Default | Range | Description |
|-----|-------|-----|-----------|
| `interval_hours` | `24` | 1 to 720 | How often each host is checked. Each host's schedule runs from its own last check. |
| `notify_security` | `true` | | Raise an alert for new **Security** updates (packages from a `-security` source). |
| `notify_risky` | `true` | | Raise an alert for new **Risky** updates (kernel and Docker packages: upgrading them needs a reboot or restarts containers). |
| `notify_other` | `false` | | Raise an alert for new updates that are neither. |

On the Config page, **All updates** ticks all three. It is a shortcut, not a setting of its own.

How the check behaves:

- **Each new update is reported once.** The same pending update does not alert again the next day. A newer version of it does.
- **A host's first check is silent.** Turning the check on does not send everything that is already pending. The Monitoring page shows all of it.
- **One summary per run,** covering every host with something new.
- **If a host can't be checked,** the Monitoring page says so and MIM tries again every hour. This is not counted as the host being down.
- **Updates installed outside MIM** show up at the next check. Clicking **Check** on the server's Updates page refreshes the result straight away.

### Reboot Detection Settings (`checks.reboot`)

**AS OF Version 3.7.0**

| Field | Default | Range | Description |
|-----|-------|-----|-----------|
| `interval_minutes` | `5` | 1 to 1440 | How often each host's boot ID is read. On the Config page: **Check every (minutes)** under Reboot detection. |

**Choosing the interval.** It only sets how soon you are told. A reboot leaves a mark that stays, so a slower check never misses one; it reports it later. Each check is one SSH login, which the host records in its login log. `5` tells you within 5 minutes at 288 logins a day per host. Use a larger number (`15`, `60`) if you want fewer logins and can wait longer to hear.

**Clean, unplanned or unknown.** When a reboot is found, MIM reads the end of the previous boot's system journal with `sudo`:

| Kind | Meaning |
|-----|-----|
| **Clean** | The system logged a normal shutdown: someone or something asked for the reboot (a maintenance reboot, the Reboot button, an update). |
| **Unplanned** | The previous boot's journal has no shutdown in it: a hang, a watchdog reset, a power cut, or a forced reboot. |
| **Unknown** | MIM could not read the journal, so it does not guess. The alert gives the reason, usually `sudo failed` (see "What the SSH User Needs"). The reboot is still reported. |

How the check behaves:

- **Every reboot is reported,** clean or not. The kind tells them apart.
- **A host's first check is silent.** It records the current boot and alerts on changes after that.
- **Reboots that happen while MIM is stopped are still reported,** when MIM starts. This includes the server MIM itself runs on: MIM goes down with it and reports the reboot once it is back.
- **Several reboots between two checks count as one.**
- **If a host can't be checked,** its row on the Monitoring page says so. Nothing is lost: the reboot is found when the host answers again.
- **It needs a Linux host with systemd** to tell clean from unplanned. No change is needed on the host: the SSH user does not have to be in any extra group, because MIM uses `sudo`.

### Upgrading From 3.5.x

A 3.5.x file has a `hosts` list and an `enabled` setting under `ssh_banner`. MIM 3.6.0 and later read it as: every listed host armed, with the SSH check as it was and OS updates off. The file is rewritten in the new form the next time you save.

---

## Notifications (notifications.json)

**AS OF Version 3.5.0**

The Notifications page (bell icon) sets where alerts go. It decides delivery only: *what* raises an alert is set under Host Monitoring.

> [!IMPORTANT]
> Notifications need a MIM license. Without one the Notifications page shows a "License required" notice.

### Example

```json
{
  "enabled": true,
  "channels": {
    "email": {
      "enabled": true,
      "smtp_server": "smtp.example.com",
      "smtp_port": 587,
      "username": "mim@example.com",
      "password": "your-smtp-password",
      "use_tls": true,
      "from_address": "mim@example.com",
      "to_addresses": ["ops@example.com"]
    },
    "telegram": {
      "enabled": true,
      "bot_token": "123456:your-bot-token",
      "chat_id": "123456789",
      "message_prefix": "[Home]",
      "parse_mode": "HTML"
    },
    "webhooks": {
      "discord-alerts": {
        "enabled": true,
        "type": "discord",
        "url": "https://discord.com/api/webhooks/your-webhook",
        "message_prefix": "[Home]",
        "username": "MIM"
      },
      "my-receiver": {
        "enabled": false,
        "type": "generic",
        "url": "https://example.com/hooks/mim",
        "method": "POST",
        "headers": { "Authorization": "Bearer your-token" },
        "timeout_seconds": 10
      }
    }
  },
  "events": {
    "hosts": { "enabled": true, "channels": ["telegram", "email"], "down": true, "up": true, "rebooted": true },
    "updates": { "enabled": true, "channels": ["telegram"] },
    "system": {
      "startup": { "enabled": false, "channels": [] },
      "shutdown": { "enabled": false, "channels": [] }
    }
  },
  "rate_limiting": {
    "hosts": { "enabled": true, "batch_window_seconds": 60, "max_per_batch": 10 }
  }
}
```

### Master Switch

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | **Send notifications.** `false` sends nothing. A channel's **Send Test** button still works while it is off. |

### Secrets

The email `password`, the Telegram `bot_token`, every webhook `url`, and the values of `Authorization` and `X-Api-Key` webhook headers are stored encrypted (on disk they start with `ENC:`). The web UI shows them as `****` once saved; leaving `****` in a field keeps the saved value. To change one by hand, replace the whole value with the new plain text and restart MIM; it is encrypted on load.

### Email (`channels.email`)

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Use this channel. |
| `smtp_server` | - | SMTP server name. Required when enabled. |
| `smtp_port` | `587` | SMTP port, 1 to 65535. |
| `username` | - | SMTP username. Leave empty if the server needs no login. |
| `password` | - | SMTP password. Stored encrypted. |
| `use_tls` | `true` | Secure the connection. MIM tries implicit TLS first (as used on port 465), then STARTTLS. `false` sends over plain SMTP. |
| `from_address` | - | The address alerts are sent from. Required when enabled. |
| `to_addresses` | empty | List of recipients. At least one is required when enabled. |

### Telegram (`channels.telegram`)

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Use this channel. |
| `bot_token` | - | The bot's token. Stored encrypted. Required when enabled. |
| `chat_id` | - | The chat the bot posts to. Required when enabled. |
| `message_prefix` | - | Optional text put on a line of its own above each message, for example `[Home]`, so you can tell installs apart. |
| `parse_mode` | `"HTML"` | Message format. Leave as `HTML`. It is not on the Notifications page. |

MIM only sends to Telegram. It does not take commands from it.

### Webhooks (`channels.webhooks`)

Any number of webhooks, each under a name you choose. The name is how events refer to it.

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Use this webhook. |
| `type` | - | `"discord"` or `"generic"`. Required. |
| `url` | - | Where to send. Stored encrypted. Required when enabled. |
| `message_prefix` | - | Optional text added to each message. |
| `username` | - | Discord only: the name the message is posted under. |
| `avatar_url` | - | Discord only: the avatar picture. |
| `method` | `POST` | Generic only: `POST` or `PUT`. |
| `headers` | - | Generic only: extra HTTP headers, for example an `Authorization` header for your receiver. |
| `timeout_seconds` | `10` | Seconds to wait for the receiver, 0 to 60. `0` means the default of 10. |

**What a generic webhook receives.** A JSON body:

```json
{
  "source": "mim",
  "event_type": "host_down",
  "category": "hosts",
  "severity": "critical",
  "entity": "Mining Rig 2",
  "message": "Mining Rig 2 (192.168.1.101) is not responding: timed out connecting",
  "details": { "host": "192.168.1.101", "port": 22 },
  "timestamp": "2026-11-04T15:13:57-05:00"
}
```

`source` is always `"mim"`. `details` differs by event.

### Events (`events`)

Each event has its own switch and its own list of channels. A channel is named `"email"`, `"telegram"` or `"webhook:<name>"`.

| Event | `event_type` | Severity | Sent when | Settings |
|-----|-----|-----|-----|-----|
| Host down | `host_down` | critical | A watched host fails the SSH check `failures_to_down` times in a row | `events.hosts.enabled` and `events.hosts.down` |
| Host back up | `host_up` | info | A down host answers again. The message says how long it was down. | `events.hosts.enabled` and `events.hosts.up` |
| Host rebooted (v3.7.0+) | `host_rebooted` | info for a clean reboot; warning for unplanned or unknown | Reboot detection finds a host's boot ID has changed | `events.hosts.enabled` and `events.hosts.rebooted` |
| OS updates available | `os_updates_available` | warning if any new update is a Security update, otherwise info | A scheduled OS update check finds new updates | `events.updates.enabled` |
| MIM started | `system_startup` | info | MIM starts | `events.system.startup.enabled` |
| MIM shutting down | `system_shutdown` | info | MIM is stopped or restarted | `events.system.shutdown.enabled` |

| Field | Default | Description |
|-----|-------|-----------|
| `events.hosts.enabled` | `true` | Host events on or off as a group. |
| `events.hosts.down` | `true` | Send "host down". |
| `events.hosts.up` | `true` | Send "host back up". |
| `events.hosts.rebooted` | `true` on a new install | Send "host rebooted" (**Host rebooted** on the Hosts row). **Off after upgrading from 3.6.x or earlier** until you tick it. |
| `events.hosts.channels` | empty | Channels for host events. |
| `events.updates.enabled` | `true` on a new install | Send "OS updates available". **Off after upgrading from 3.5.x** until you turn it on. |
| `events.updates.channels` | empty | Channels for OS update alerts. |
| `events.system.startup.enabled` | `false` | Send "MIM started". |
| `events.system.startup.channels` | empty | Channels for it. |
| `events.system.shutdown.enabled` | `false` | Send "MIM shutting down". |
| `events.system.shutdown.channels` | empty | Channels for it. |

An event is delivered only when all of these are true: `enabled` at the top is on, the event's own switch is on, at least one channel is listed for it, and that channel is itself enabled.

Things to know:

- **A host that is already down when monitoring starts does not raise "host down".** MIM alerts on changes it sees, so restarting MIM does not resend alerts. You still get "host back up" when it returns.
- **MIM can't report its own outage while it is happening.** If the server MIM runs on goes down, MIM goes down with it. With reboot detection on for that server (v3.7.0+), MIM does report the reboot once it is back up.
- **A "host rebooted" alert carries details:** `kind` (`clean`, `unplanned` or `unknown`), `back_up_at`, `last_log_entry` (the last thing the previous boot logged, which is not the exact moment of a hang) and `up_before` (how long it had been up).

### Rate Limiting (`rate_limiting.hosts`)

Stops a flood of host alerts when several hosts go down or reboot together (a switch failing or a power cut, for example). The first alert goes out at once; any more in the same window are held and sent as one summary when the window closes. It applies to host events only.

| Field | Default | Range | Description |
|-----|-------|-----|-----------|
| `enabled` | `true` | | Batch host events. |
| `batch_window_seconds` | `60` | 10 to 3600 | Length of the window. |
| `max_per_batch` | `10` | 1 to 100 | How many hosts the summary names before it says "and N more". |

---

## Configuration Validation

### servers.json

MIM checks `servers.json` at startup and when it is reloaded. It will not start if any of these fail:

- At least one server is defined
- Every server has a `name`
- Every server has an `ssh_host`
- Every server has an `ssh_user`
- Every server has `ssh_password` or `ssh_key_path`

MIM logs the reason and exits. Check the container's startup log for the setting it names.

MIM makes these changes to the file by itself on load:

- **ID generation:** a server without an `id` is given one.
- **Password encryption:** a plain-text `ssh_password` is encrypted.
- **Log level:** an old `log_level` setting directly under `settings` is moved to `settings.logging.level`.

### monitoring.json and notifications.json

Settings are checked when you save on the web pages, and a value out of range is refused with a message saying which. A hand-edited file with a bad value still loads, with a warning in the log. If either file is missing, MIM creates it with monitoring and notifications switched off.

---

## Licensing

MIM runs without a license on the free tier, which manages a limited number of servers. A license raises the limit and unlocks notifications, Host Monitoring and scheduled OS update checks.

- Tiers and limits: https://www.mmfpsolutions.io/pricing.html
- Only **enabled** servers count toward the limit.
- If more servers are enabled than the license allows, MIM's pages are blocked with a "Server Limit Exceeded" message until you disable or remove servers on the Config page (which stays reachable) or install a license that covers them.
- A license is installed on the **License** page, reached from the **Version** page (the version link in the footer). Restart MIM after installing or deleting one.

---

## Multi-Server Setup

> [!IMPORTANT]
> How many servers one MIM can manage depends on your license. See [Licensing](#licensing).

One MIM manages several servers. Each needs an SSH user MIM can log in as (see "What the SSH User Needs").

```json
{
    "servers": [
        {
            "id": "{System-generated ID}",
            "name": "MIM Server",
            "description": "Primary host - MIM runs here",
            "ssh_host": "192.168.1.100",
            "ssh_port": 22,
            "ssh_user": "mim",
            "ssh_password": "password",
            "enabled": true,
            "mim_host": true
        },
        {
            "id": "{System-generated ID}",
            "name": "Mining Rig 2",
            "description": "Secondary rig - managed remotely",
            "ssh_host": "192.168.1.101",
            "ssh_port": 22,
            "ssh_user": "mim",
            "ssh_password": "password",
            "enabled": true,
            "mim_host": false
        },
        {
            "id": "{System-generated ID}",
            "name": "Spare Rig",
            "description": "Offline for maintenance",
            "ssh_host": "192.168.1.102",
            "ssh_port": 22,
            "ssh_user": "mim",
            "ssh_password": "password",
            "enabled": false,
            "mim_host": false
        }
    ],
    "settings": {
        "ssh_timeout": 30,
        "docker_timeout": 30,
        "refresh_interval": 60,
        "logging": {
            "level": "INFO",
            "log_to_file": true,
            "log_file_path": "/app/logs/mim.log",
            "max_size_mb": 20,
            "max_age_days": 30,
            "max_backups": 10,
            "compress": false
        }
    }
}
```

> **Note:** The first server is the MIM host. The other two say `"mim_host": false`: leaving it out on a remote server would mark that server as a MIM host too.

Leave `id` out when adding a server by hand; MIM generates it. Adding servers on the Config page is simpler and does this for you.
