# MIM Configuration Guide

Complete reference for the `servers.json` configuration file used by MIM (Mining Infrastructure Manager).

> [!TIP]
> Configuration can be done via the Web UI

---

## Summary

MIM uses a single configuration file, `servers.json`, which defines the servers MIM manages and controls global application behavior. The file contains two top-level sections:

- **`servers`** — Defines each physical server (or VM) that MIM connects to and manages.
- **`settings`** — Global application settings: timeouts, refresh rate, and logging.

MIM looks for the config file in two locations (in order):
1. `./config/servers.json` — Local path, for development
2. `/app/config/servers.json` — Default Docker container path

> **Note:** Changes made through the MIM WebUI are written directly to `servers.json`. Some changes (logging level, timeouts) take effect immediately; others may require a restart.

---

## Example Configuration

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
            "docker_host": "ssh://mim@192.168.1.100",
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

The `servers` array defines every machine MIM connects to. MIM manages Docker containers and services on these machines via SSH.

### Server Fields

| Field | Required | Default | Description |
|-----|--------|-------|-----------|
| `id` | Auto-generated | — | Unique 8-character identifier, base62. Auto-generated on first load — do not edit manually. Used by the API and internally to reference this server. |
| `name` | Yes | — | Display name shown in the MIM dashboard. |
| `description` | No | — | Optional free-text description of the server (e.g., its role or location). |
| `ssh_host` | Yes | — | IP address or hostname MIM uses to SSH into this server. |
| `ssh_port` | No | `22` | SSH port. Defaults to `22` if omitted or set to `0`. |
| `ssh_user` | Yes | — | SSH username. |
| `ssh_password` | Conditional | — | SSH password for password-based authentication. 
| `docker_host` | Yes | — | Docker connection string. Typically `ssh://user@host` format, which tunnels Docker commands over the SSH connection. |
| `enabled` | Yes | — | When `true`, this server is active and monitored. When `false`, the server is retained in config but does not appear in the dashboard and does not count toward any limits. |
| `mim_host` | No | `true` | Marks whether MIM itself runs on this server. See details below. |

### SSH Authentication

MIM supports two authentication methods per server. Use whichever is appropriate for your setup:

**Password authentication:**
```json
"ssh_user": "mim",
"ssh_password": "yourpassword"
```

### The `mim_host` Field

`mim_host` identifies which server runs the MIM application itself. This is important because MIM's self-update behavior depends on knowing its own host.

| Value | Meaning |
|-----|-------|
| `true` (or omitted) | This server runs the MIM application. |
| `false` | This is a managed remote server — MIM does not run here. |

> **Note:** Only one server should have `mim_host: true`. Typically this is the server MIM is deployed on. All other servers should have `mim_host: false` or simply omit the field on the primary server.

### The `docker_host` Field

MIM uses Docker to manage services on each server. The `docker_host` value tells Docker how to connect.

For SSH-tunneled connections (the standard approach):
```
"docker_host": "ssh://username@hostname"
```

This instructs Docker to connect over SSH, using the same SSH credentials defined in `ssh_user` / `ssh_password` / `ssh_key_path`. The SSH user must have permission to run Docker commands on the remote host (typically via the `docker` group).

### The `enabled` Field

Setting `enabled: false` is a non-destructive way to temporarily disable a server without removing its configuration. Disabled servers:
- Do not appear in the dashboard
- Are not polled or managed
- Do not count toward any usage limits

---

## Settings

Global application settings that apply across all servers.

### Timeouts

| Field | Default | Description |
|-----|-------|-----------|
| `ssh_timeout` | `30` | Seconds to wait for an SSH connection or command to complete before timing out. Applies to all SSH operations across all servers. Increase if you have high-latency connections to remote servers. |
| `docker_timeout` | `30` | Seconds to wait for a Docker operation (container start/stop, image pull, etc.) to complete. Increase for slow networks or large image operations. |

### Refresh Interval

| Field | Default | Description |
|-----|-------|-----------|
| `refresh_interval` | `60` | How often (in seconds) the MIM dashboard polls servers for updated container and service status. Lower values give more real-time data but increase SSH and network load. |

---

## Logging

Controls how MIM writes log output. Nested under `settings.logging`.

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
| `level` | `"INFO"` | Log verbosity. See levels below. |
| `log_to_file` | `false` | Set to `true` to write logs to a file in addition to console output. |
| `log_file_path` | `"/app/logs/mim.log"` | Path to the log file. Required when `log_to_file` is `true`. |
| `max_size_mb` | `20` | Maximum log file size in MB before rotation. |
| `max_age_days` | `30` | Number of days to retain old log files before deletion. |
| `max_backups` | `10` | Number of rotated backup log files to keep. |
| `compress` | `false` | Compress rotated log files with gzip to save disk space. |

### Log Levels

| Level | What Gets Logged |
|-----|----------------|
| `DEBUG` | Everything — SSH commands, Docker operations, request details |
| `INFO` | Normal operation — connections, container state changes, API calls |
| `WARN` or `WARNING` | Recoverable issues — connection retries, timeouts |
| `ERROR` | Failures only — SSH failures, Docker errors, config problems |

> **Tip:** `INFO` is recommended for production. Use `DEBUG` when troubleshooting connection or configuration issues.

---

## Configuration Validation

MIM validates `servers.json` on startup and when the file is reloaded. It will fail to start if any of these rules are violated:

- At least one server must be defined in the `servers` array
- Every server must have a `name`
- Every server must have an `ssh_host`
- Every server must have an `ssh_user`
- Every server must have either `ssh_password` or `ssh_key_path` (not both required, but at least one)

If any validation fails, MIM logs the error and exits. Check the startup logs for the specific field that caused the failure.

### Auto-Migrations

MIM automatically performs these migrations on first load and saves the updated file:

- **ID generation** — Any server without an `id` field is assigned a new 8-character alphanumeric ID.
- **Log level migration** — If an older-style `log_level` field exists at the `settings` root level, it is automatically moved to `settings.logging.level` and the old field is removed.

These happen silently and are written back to `servers.json` automatically.

---

## Multi-Server Setup

> [!IMPORTANT]
> Multiple host configurations require an MMFP License, this is a licensed feature

MIM is designed to manage multiple servers from a single instance. Here is an example with multiple servers:

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
            "mim_host":true,
            "docker_host": "ssh://mim@192.168.1.100",
            "enabled": true
        },
        {
            "id": "{System-generated ID}",
            "name": "Mining Rig 2",
            "description": "Secondary rig - managed remotely",
            "ssh_host": "192.168.1.101",
            "ssh_port": 22,
            "ssh_user": "mim",
            "ssh_password": "password",
            "docker_host": "ssh://mim@192.168.1.101",
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
            "docker_host": "ssh://mim@192.168.1.102",
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

> **Note:** The first server omits `mim_host` — it defaults to `true`, marking it as the MIM host. The second and third servers explicitly set `mim_host: false`.
