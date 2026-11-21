# GoSlimStratum User Client (GSSUC) Configuration Guide

Complete reference for the `config.json` configuration file used by GSSUC. Accurate for GSSUC 2.0.0.

> [!TIP]
> Every setting in this guide is on the **Configuration** page of the admin panel (the gear icon, then your PIN). Change settings there: it checks what you enter, keeps a backup copy of the file and applies the change without a restart. This guide lists each setting by its name in `config.json` so that you can read the file, not so that you edit it by hand.

Other GSSUC guides: the [User Guide](gssuc-user-guide.md) (installing, what each page shows, turning on the Hash Hopper) and the [Troubleshooting Guide](gssuc-troubleshooting-guide.md).

---

## Summary

GoSlimStratum User Client (GSSUC) is a lightweight public-facing web dashboard for miners using a GoSlimStratum pool. It gives individual miners a place to look up their wallet address, view their active miners, track block discoveries, and monitor payment history — without exposing any administrative controls.

GSSUC connects to the GoSlimStratum HTTP API on the backend and serves a clean, user-facing UI. All API calls are server-side — browsers never talk directly to GoSlimStratum.

All configuration lives in a single `config.json` file. On a server where GSSUC was installed from MIM it is `/data/gssuc/config/config.json`.

> **Note:** Changes to `port`, `host`, `gss_api.base_url` and `security.enable_web_admin` require a restart. All other settings (pools, the Hash Hopper, refresh intervals, log level, footer, the rest of security) take effect as soon as they are saved in the admin panel.

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
    "hash_hopper": {
        "enabled": false,
        "display_name": "Hash Hopper",
        "stratum_host": "stratum.example.com"
    },
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
| `symbol`        | Yes      | Coin ticker symbol displayed in the UI (e.g., `"DGB"`, `"BTC"`). It also picks the coin's badge (see below). Multiple pools can share the same symbol (e.g., mainnet and testnet). |
| `display_name`  | Yes      | Full coin name shown in the dashboard (e.g., `"DigiByte"`, `"Bitcoin Cash"`).                                                           |
| `enabled`       | Yes      | When `true`, this pool appears in the UI and miners can look up stats for it. When `false`, the pool is hidden entirely.                 |
| `stratum_host`  | Yes      | The stratum server hostname or IP shown to miners so they know how to connect. This is informational — GSSUC does not connect to stratum. |
| `stratum_port`  | Yes      | The stratum port shown to miners. Must be a valid port (1–65535).                                                                        |
| `icon_url`      | No       | URL to a coin badge image for this pool. Leave empty to use the built-in badge for the pool's `symbol`.                                  |

> **Tip:** To temporarily remove a coin from the public dashboard without deleting its config, set `enabled: false`.

**Coin badges.** With `icon_url` empty, GSSUC shows its built-in badge for the pool's `symbol`. Built-in badges: `BCH`, `BSV`, `BTC`, `BTCS` (v2.0.0+), `CRW`, `DGB`, `EMC`, `PPC`, `WJK` (v2.0.0+), `XEC`, `XMY`, `XRO`. A symbol with no built-in badge shows the Bitcoin badge on the home page; give that pool an `icon_url` to show its own.

The Mining Pools section of the Configuration page has one card per pool, an **Add Pool** button, and a button on each card to remove it.

---

## Hash Hopper Section (v2.0.0+)

Turns on the Hash Hopper pages. The Hash Hopper is a GoSlimStratum feature (GoSlimStratum 6.0.0 or later): one stratum port that moves a miner's rigs between chains. It is set up in GoSlimStratum, not here; this section only decides whether GSSUC shows it. See the [User Guide](gssuc-user-guide.md#hash-hopper-v200) for what the pages show and how to turn them on.

```json
"hash_hopper": {
    "enabled": false,
    "display_name": "Hash Hopper",
    "stratum_host": "stratum.example.com"
}
```

| Field           | Default          | On the Configuration page | Description |
|-----------------|------------------|---------------------------|-------------|
| `enabled`       | `false`          | **Show the Hash Hopper**  | When `true`, GSSUC shows the Hash Hopper card on the home page, the Hash Hopper dashboards, and marks Hash Hopper rigs on the coin dashboards. |
| `display_name`  | `"Hash Hopper"`  | **Display Name**          | The name shown on the card and the pages. Empty uses "Hash Hopper". |
| `stratum_host`  | none             | **Stratum Host**          | The hostname or IP shown to miners so they know where to connect. Required when `enabled` is `true`. Informational, like a pool's `stratum_host`. |

- **There is no port setting.** GSSUC reads the Hash Hopper's port from GoSlimStratum, so the card always shows the port GoSlimStratum is listening on.
- **`enabled: true` is not enough by itself.** The pages appear only while GoSlimStratum also reports a Hash Hopper that is turned on, has its port open and is not in shadow mode. Until then GSSUC shows nothing about it and nothing breaks.
- **A `config.json` with no `hash_hopper` section is valid.** It loads with the Hash Hopper pages off. Nothing needs adding when you upgrade from 1.x.
- A change takes effect as soon as it is saved.

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

Sets how many rows a history table shows per page when a visitor first opens it. Each table has a **Show** list (10, 20, 30, 50, 100) and the browser remembers what the visitor picks, so these values are only the starting point. Use one of the five values the list offers.

| Field                | Default  | Valid Range  | Description                                    |
|----------------------|----------|--------------|------------------------------------------------|
| `blocks_per_page`    | `50`     | 10–1000      | Number of blocks to display per page. Also the starting page size of the Hash Hopper dashboard's Blocks Found card (v2.0.0+). |
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
| `enable_web_admin`                   | `true`   | Enable the admin panel entirely. Set to `false` to disable all admin access. Requires a restart. With it `false`, settings can only be changed in `config.json`. |
| `hide_admin_icon`                    | `false`  | When `true`, the admin icon is not shown in the UI — but the admin panel is still accessible at `/admin` if you know the URL.             |
| `restrict_admin_to_private_network`  | `true`   | When `true`, the admin panel is only accessible from private network IPs (`10.x.x.x`, `172.16.x.x`, `192.168.x.x`, `127.x.x.x`). Recommended for public deployments. |

> **If GSSUC can be reached from the internet:** run it behind a reverse proxy, serve it over TLS (HTTPS) at the proxy, and set your own PIN. GSSUC itself serves plain HTTP. See [Putting GSSUC on the internet](gssuc-user-guide.md#putting-gssuc-on-the-internet) in the User Guide.

### Admin Panel Access Layers

The admin panel has three independent security layers that all apply together:

1. **Network restriction** — Only private/local IPs can reach the admin panel (if `restrict_admin_to_private_network: true`).
2. **Icon visibility** — The admin link is hidden from the UI (if `hide_admin_icon: true`), though the URL still works.
3. **PIN protection** — A PIN must be entered to view or edit any configuration.

### PIN Sign-In

- A sign-in lasts 30 minutes from the last thing you did in the admin panel.
- Five wrong PINs from one address within 15 minutes lock that address out of the admin panel for one hour.

### What the Admin Panel Can Do

The admin panel has two cards, **Configuration** and **Logs**.

- **Configuration:** view and edit every setting in this guide. **Validate Only** checks the form without saving; saving checks it again, writes a backup copy of the previous file (`config.json.backup`, in the same folder) and applies the change at once.
- **Logs:** list the log files, view or download one, and open the **Live Log Stream**, which shows log lines as they are written, with a filter, pause, and a log level you can change on the spot.

> **Note:** Changes to `port`, `host`, `gss_api.base_url` and `enable_web_admin` through the admin panel require a restart to take effect.

---


## Configuration Validation

GSSUC validates the full configuration on startup and will exit with an error if any of the following are violated:

| Section     | Rules                                                                                                  |
|-------------|--------------------------------------------------------------------------------------------------------|
| `app`       | `name` non-empty; `port` 1–65535; `host` non-empty                                                    |
| `gss_api`   | `base_url` must be a valid `http://` or `https://` URL; `timeout_seconds` 1–300; `retry_attempts` 0–10; `retry_delay_ms` 0–60000 |
| `pools`     | At least one pool defined; at least one pool enabled; all required fields non-empty; no duplicate `gss_key` values; `stratum_port` 1–65535 |
| `hash_hopper` | When `enabled` is `true`, `stratum_host` must be non-empty. Nothing is required while it is `false` or the section is absent |
| `web_ui`    | `site_title` non-empty; refresh intervals within valid ranges; pagination values 10–1000              |
| `logging`   | `level` must be `debug`, `info`, `warn`, or `error`; if `log_to_file` is `true`, path must be non-empty |
| `footer`    | `company_name` non-empty; `website_url` valid URL if provided; `copyright_year` 2020–2100            |
| `security`  | `config_pin` at least 4 characters                                                                     |

Check the startup logs for the specific field name if GSSUC fails to start. The admin panel runs the same checks before it saves, so a change made there cannot leave GSSUC unable to start.

---

## Environment Variables

A few settings can be set by an environment variable on the container. A variable wins over the value in `config.json`.

| Variable                   | Overrides                |
|----------------------------|--------------------------|
| `GSSUC_PORT`               | `app.port`               |
| `GSSUC_GSS_API_BASE_URL`   | `gss_api.base_url`       |
| `GSSUC_LOG_LEVEL`          | `logging.level`          |
| `GSSUC_LOG_FILE_PATH`      | `logging.log_file_path`  |
| `GSSUC_SITE_TITLE`         | `web_ui.site_title`      |
