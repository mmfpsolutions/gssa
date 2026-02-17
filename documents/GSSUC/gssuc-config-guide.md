# GoSlimStratum User Client (GSSUC) Configuration Guide

Complete reference for the `config.json` configuration file used by GSSUC.

> [!TIP]
> Configuration can be done via the Web UI for most settings.

---

## Summary

GoSlimStratum User Client (GSSUC) is a lightweight public-facing web dashboard for miners using a GoSlimStratum pool. It gives individual miners a place to look up their wallet address, view their active miners, track block discoveries, and monitor payment history — without exposing any administrative controls.

GSSUC connects to the GoSlimStratum HTTP API on the backend and serves a clean, user-facing UI. All API calls are server-side — browsers never talk directly to GoSlimStratum.

All configuration lives in a single `config.json` file.

> **Note:** Changes to `port`, `host`, and `gss_api.base_url` require a restart. All other settings (pool visibility, refresh intervals, log level, footer, security) can be changed via the admin panel and take effect immediately without a restart.

---

## Example Configuration

```json
{
    "app": {
        "name": "GoSlimStratum User Client",
        "port": 3005,
        "host": "0.0.0.0"
    },
    "gss_api": {
        "base_url": "http://localhost:4004/api/v1",
        "timeout_seconds": 10,
        "retry_attempts": 3,
        "retry_delay_ms": 1000
    },
    "pools": [
        {
            "gss_key": "DGB",
            "symbol": "DGB",
            "display_name": "DigiByte",
            "icon_url": "",
            "enabled": true,
            "stratum_host": "stratum.example.com",
            "stratum_port": 3333
        },
        {
            "gss_key": "BTC",
            "symbol": "BTC",
            "display_name": "Bitcoin",
            "icon_url": "",
            "enabled": false,
            "stratum_host": "stratum.example.com",
            "stratum_port": 3334
        }
    ],
    "web_ui": {
        "site_title": "My Mining Pool",
        "refresh_intervals": {
            "dashboard": 30,
            "miner_detail": 30,
            "blocks": 60,
            "payments": 60,
            "network": 30
        },
        "pagination": {
            "blocks_per_page": 50,
            "payments_per_page": 100
        }
    },
    "logging": {
        "level": "info",
        "log_to_file": true,
        "log_file_path": "/app/logs/gssuc.log",
        "max_size_mb": 100,
        "max_age_days": 30,
        "max_backups": 10,
        "compress": true
    },
    "footer": {
        "company_name": "MMFP Solutions",
        "website_url": "https://www.mmfpsolutions.io",
        "copyright_year": 2026
    },
    "security": {
        "config_pin": "1234",
        "enable_web_admin": true,
        "hide_admin_icon": false,
        "restrict_admin_to_private_network": true
    }
}
```

---

## App Section

Controls the web server that serves the GSSUC dashboard.

| Field  | Default                        | Description                                                                                                     |
|--------|--------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `name` | `"GoSlimStratum User Client"`  | Application name shown in the startup banner and logs.                                                          |
| `port` | `3005`                         | Port the GSSUC web server listens on. Can be overridden with the `GSSUC_PORT` environment variable.             |
| `host` | `"0.0.0.0"`                   | IP address to bind to. `"0.0.0.0"` accepts connections on all interfaces.                                       |

> **Note:** `port` and `host` require a restart to change.

---

## GSS API Section

Configures how GSSUC connects to the GoSlimStratum HTTP API. All miner data, blocks, and payment information is fetched from this endpoint.

| Field              | Default                              | Description                                                                                                       |
|--------------------|--------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `base_url`         | `"http://localhost:4004/api/v1"`     | Full URL to the GoSlimStratum HTTP API. Must match `http_api_port` in the GSS config. Can be overridden with `GSSUC_GSS_API_BASE_URL`. |
| `timeout_seconds`  | `10`                                 | Seconds to wait for a GoSlimStratum API response before timing out. Valid range: 1–300.                            |
| `retry_attempts`   | `3`                                  | Number of times to retry a failed API request before giving up. Set to `0` to disable retries. Valid range: 0–10. |
| `retry_delay_ms`   | `1000`                               | Milliseconds to wait between retry attempts. Valid range: 0–60000.                                                |

> **Note:** `base_url` requires a restart to change. The other fields can be updated via the admin panel.

> **Tip:** If GSSUC and GoSlimStratum run on the same host, `localhost` works. If they run on separate machines, use the GSS server's IP or hostname.

---

## Pools Section

Defines which coins/pools are available to miners in the GSSUC dashboard. Each entry represents one mining pool. At least one pool must be configured and enabled.

```json
"pools": [
    {
        "gss_key": "DGB",
        "symbol": "DGB",
        "display_name": "DigiByte",
        "icon_url": "",
        "enabled": true,
        "stratum_host": "stratum.example.com",
        "stratum_port": 3333
    }
]
```

| Field           | Required | Description                                                                                                                              |
|-----------------|----------|------------------------------------------------------------------------------------------------------------------------------------------|
| `gss_key`       | Yes      | The coin key as defined in GoSlimStratum's config (e.g., `"DGB"`). This is how GSSUC maps pool entries to GSS API data. Must be unique across all pool entries. |
| `symbol`        | Yes      | Coin ticker symbol displayed in the UI (e.g., `"DGB"`, `"BTC"`). Multiple pools can share the same symbol (e.g., mainnet and testnet).  |
| `display_name`  | Yes      | Full coin name shown in the dashboard (e.g., `"DigiByte"`, `"Bitcoin Cash"`).                                                           |
| `enabled`       | Yes      | When `true`, this pool appears in the UI and miners can look up stats for it. When `false`, the pool is hidden entirely.                 |
| `stratum_host`  | Yes      | The stratum server hostname or IP shown to miners so they know how to connect. This is informational — GSSUC does not connect to stratum. |
| `stratum_port`  | Yes      | The stratum port shown to miners. Must be a valid port (1–65535).                                                                        |
| `icon_url`      | No       | URL to a coin icon image displayed in the pool selector. Leave empty to use a generic icon.                                              |

> **Tip:** To temporarily remove a coin from the public dashboard without deleting its config, set `enabled: false`.

---

## Web UI Section

Controls the dashboard's appearance and data refresh behavior.

### Site Title

| Field         | Default             | Description                                                                              |
|---------------|---------------------|------------------------------------------------------------------------------------------|
| `site_title`  | `"My Mining Pool"`  | Displayed in the browser tab and as the main header on every page. Can be overridden with `GSSUC_SITE_TITLE`. |

### Refresh Intervals

Controls how often each page automatically polls for updated data, in seconds.

| Field           | Default  | Valid Range  | Description                                             |
|-----------------|----------|--------------|---------------------------------------------------------|
| `dashboard`     | `30`     | 5–300        | How often the wallet dashboard refreshes miner stats.   |
| `miner_detail`  | `30`     | 5–300        | How often an individual miner's detail page refreshes.  |
| `blocks`        | `60`     | 10–600       | How often the block discovery history refreshes.        |
| `payments`      | `60`     | 10–600       | How often the payment history refreshes.                |
| `network`       | `30`     | 5–300        | How often the network stats (difficulty, hashrate) refresh. |

> **Tip:** Lower intervals give more real-time data but increase API load on GoSlimStratum. The defaults are suitable for most public-facing pools.

### Pagination

> [!NOTE] 
> This is a legacy setting and is not applied in GSSUC

Controls how many rows are shown per page in history tables.

| Field                | Default  | Valid Range  | Description                                    |
|----------------------|----------|--------------|------------------------------------------------|
| `blocks_per_page`    | `50`     | 10–1000      | Number of blocks to display per page.          |
| `payments_per_page`  | `100`    | 10–1000      | Number of payment records to display per page. |

---

## Logging Section

Controls how GSSUC writes log output.

| Field            | Default                    | Description                                                              |
|------------------|----------------------------|--------------------------------------------------------------------------|
| `level`          | `"info"`                   | Log verbosity. See levels below. Can be overridden with `GSSUC_LOG_LEVEL`. |
| `log_to_file`    | `true`                     | Write logs to a file in addition to console output.                      |
| `log_file_path`  | `"/app/logs/gssuc.log"`    | Path to the log file. Required when `log_to_file` is `true`. Can be overridden with `GSSUC_LOG_FILE_PATH`. |
| `max_size_mb`    | `100`                      | Maximum log file size in MB before rotation. Valid range: 1–1000.        |
| `max_age_days`   | `30`                       | Number of days to retain old log files. Valid range: 1–365.              |
| `max_backups`    | `10`                       | Number of rotated backup log files to keep. Valid range: 0–100.          |
| `compress`       | `true`                     | Compress rotated log files with gzip.                                    |

### Log Levels

| Level    | What Gets Logged                                              |
|----------|---------------------------------------------------------------|
| `debug`  | Everything — API calls, request details, retry attempts       |
| `info`   | Normal operational events — startup, connections, requests    |
| `warn`   | Recoverable issues — timeouts, retries, degraded responses    |
| `error`  | Failures only — connection errors, config problems            |

---

## Footer Section

Controls the branding shown in the footer of every page.

| Field              | Default                            | Description                                                                                  |
|--------------------|------------------------------------|----------------------------------------------------------------------------------------------|
| `company_name`     | `"MMFP Solutions"`                 | Operator or company name displayed in the footer.                                            |
| `website_url`      | `"https://www.mmfpsolutions.io"`   | URL the company name links to. Leave empty for no link. Must be a valid URL if provided.     |
| `copyright_year`   | `2026`                             | Year shown in the copyright notice: `© 2026 [company_name]`. Valid range: 2020–2100.        |

---

## Security Section

Controls access to the GSSUC admin panel. The admin panel allows operators to view and edit configuration, view logs, and manage pool settings — all from the browser.

| Field                                | Default  | Description                                                                                                                                |
|--------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `config_pin`                         | `"1234"` | PIN required to access the admin panel. Minimum 4 characters. **Change from the default before deploying.**                               |
| `enable_web_admin`                   | `true`   | Enable the admin panel entirely. Set to `false` to disable all admin access.                                                              |
| `hide_admin_icon`                    | `false`  | When `true`, the admin icon is not shown in the UI — but the admin panel is still accessible at `/admin` if you know the URL.             |
| `restrict_admin_to_private_network`  | `true`   | When `true`, the admin panel is only accessible from private network IPs (`10.x.x.x`, `172.16.x.x`, `192.168.x.x`, `127.x.x.x`). Recommended for public deployments. |

### Admin Panel Access Layers

The admin panel has three independent security layers that all apply together:

1. **Network restriction** — Only private/local IPs can reach the admin panel (if `restrict_admin_to_private_network: true`).
2. **Icon visibility** — The admin link is hidden from the UI (if `hide_admin_icon: true`), though the URL still works.
3. **PIN protection** — A PIN must be entered to view or edit any configuration.

### What the Admin Panel Can Do

- View and edit the full configuration
- Toggle pool `enabled` status (takes effect immediately)
- Adjust refresh intervals, log level, footer, and security settings (takes effect immediately)
- View live application logs with filtering
- Download the current config as a backup

> **Note:** Changes to `port`, `host`, and `gss_api.base_url` through the admin panel require a restart to take effect.

---


## Configuration Validation

GSSUC validates the full configuration on startup and will exit with an error if any of the following are violated:

| Section     | Rules                                                                                                  |
|-------------|--------------------------------------------------------------------------------------------------------|
| `app`       | `name` non-empty; `port` 1–65535; `host` non-empty                                                    |
| `gss_api`   | `base_url` must be a valid `http://` or `https://` URL; `timeout_seconds` 1–300; `retry_attempts` 0–10; `retry_delay_ms` 0–60000 |
| `pools`     | At least one pool defined; at least one pool enabled; all required fields non-empty; no duplicate `gss_key` values; `stratum_port` 1–65535 |
| `web_ui`    | `site_title` non-empty; refresh intervals within valid ranges; pagination values 10–1000              |
| `logging`   | `level` must be `debug`, `info`, `warn`, or `error`; if `log_to_file` is `true`, path must be non-empty |
| `footer`    | `company_name` non-empty; `website_url` valid URL if provided; `copyright_year` 2020–2100            |
| `security`  | `config_pin` at least 4 characters                                                                     |

Check the startup logs for the specific field name if GSSUC fails to start.
