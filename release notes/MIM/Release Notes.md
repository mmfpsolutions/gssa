# MIM Release Notes
## v3.x Series

## v3.1.2

MIM now tells you when there's a newer version available, so you stop finding out about updates months later from a Telegram message. A small badge appears next to the version link in the footer when a new release ships, the `/version` page picks up a new Updates card, and you can dismiss the badge per-version or turn the check off entirely if you'd rather not have it. This closes the loop on the same feature that already shipped in GSS and GSSM earlier this cycle — all three products now share the identical operator experience.

### New Features

- **Update-available check** — MIM fetches a small JSON file from `get.mmfpsolutions.io` on startup that describes the latest MIM release. When your running version is behind, a small orange **update** badge appears next to the version link in the footer of every page. Click the badge for a modal showing your current version, the latest version, the release date, and a link to the release notes. If the new release is also above the minimum-recommended threshold (e.g. a security-relevant fix), the badge turns red and reads **critical** instead — same modal, different urgency.

  The check runs once on startup and caches the result for 24 hours; there's no background polling or periodic phone-home. You can force an immediate refresh from the new Updates card on the `/version` page via the **Check Now** button (the refresh-arrow icon in the Updates section header).

- **Updates card on the `/version` page** — A new section between Runtime Status and License shows your current version, the latest version, when the latest was released, a link to the release notes, and when MIM last checked. The **Check Now** button bypasses the 24-hour cache and re-fetches immediately. If you've dismissed the badge for the current version (see below), a "Re-enable for this version" link appears here so you can change your mind.

- **Per-version dismiss** — Inside the modal, **"Don't show again for this version"** hides the badge across all pages until a newer version is published. Once a new release ships, the badge reappears with the new version's details — your dismissal is per-version, not permanent. The dismissed state lives in your browser's local storage (it doesn't sync across browsers).

- **Opt-out via config** — If you don't want MIM checking at all (running on an isolated network, behind a strict outbound firewall, or just personal preference), add `"updates": { "enabled": false }` to the `settings` block of your `config/servers.json`. The check never runs, no badge ever appears, and the `/version` Updates card shows the status as Unknown.

  **Privacy note** — the check is a one-way pull only. MIM downloads the JSON file from `get.mmfpsolutions.io` (which announces the latest version) and compares against your installed version locally. **No data about your install is sent.** No hostname, no machine ID, no version-ping, no telemetry.

  **No operator action required on upgrade** — defaults to enabled with the right URL. If you'd previously set `"updates": { "enabled": false }` in your config (manually adding the block on a prior install), that opt-out is preserved. If your `config/servers.json` has no `updates` block under `settings` — which is what every existing install will look like on first upgrade to 3.1.2 — defaults are applied in memory only; your file on disk is not rewritten.

- **Fails silently if offline** — If `get.mmfpsolutions.io` is unreachable for any reason (your MIM install is on an isolated network, your firewall blocks it, the CDN is having a bad day), MIM simply shows no badge and the `/version` Updates card displays Unknown. No error notifications, no log noise — the update check is best-effort and never gets in the way of your dashboard working.

---
