# MIM Release Notes
## v3.x Series

## v3.2.0

A long-overdue rebuild of the per-server System Updates page. The old three-button terminal-style flow (Check for Updates / List Updates / Upgrade, each streaming scrolling apt output into a black box at the bottom of the page) has been replaced with a structured table where you check, see what's available, pick what you want to apply, watch live progress, and see a summary — the same shape every other MIM page already uses. The legacy page is gone entirely; this is the new home for system updates from 3.2.0 forward.

### New Features

- **Structured Updates page replaces the terminal-style flow** — The Updates page now starts with a single "Check for Updates" button. Click it and MIM runs `apt update` + lists upgradable packages, then shows you a table with each package's current version, new version, and source. Two badges call out important categories: a purple **security** badge for packages from a `-security` source (Ubuntu's `jammy-security`, Debian's `bookworm-security`, etc.) and an amber **⚠ risky** badge for packages that have an outsized effect when upgraded (Docker, containerd, kernel meta-packages). Hover a risky badge to see what specifically is risky about it.

- **Selective per-package upgrade via checkboxes** — Every row has a checkbox. Pick what you want to apply, leave the rest alone. Quick-select chips at the top of the table give you sensible bulk choices: **All safe** (everything except risky packages — the default on first render), **Security only** (just the `security`-badged rows), **All including risky** (everything), and **Clear**. The chips don't lock you in — you can still toggle individual rows after using a chip.

- **`apt install --only-upgrade` under the hood, transparently** — When you click "Apply Selected", MIM runs `sudo apt install -y --only-upgrade <packages>` on the server. apt upgrades exactly the named packages (plus any deps they need), and leaves everything else at its current version. No MIM-specific state, no hold/unhold dance, no chance of leaving the system in an awkward state if MIM dies mid-flight. apt's own primitive for selective upgrade.

- **Live progress during apply** — Once you click Apply, the table replaces itself with a per-package progress view: each row starts as ⏳ pending, flips to ⚙ installing when apt sets it up, and lands on ✓ done or ✗ failed when complete. A spinner + status line at the top of the table tells you what MIM is doing ("Starting upgrade of N package(s)...", then "Running apt install --only-upgrade"), and a thin monospace subtitle underneath shows apt's actual current activity in real time (`Get:1 http://archive.ubuntu.com/...`, `Preparing to unpack...`, `Unpacking curl over (7.81.0-1ubuntu1.14)`, `Processing triggers for man-db...`). Cancel is available with a confirmation modal that warns about partial-state risk.

- **Reboot-required banner** — After any upgrade involving a kernel or other package that needs a reboot, MIM checks `/var/run/reboot-required` and surfaces a red banner at the top of the page listing which packages triggered the requirement. MIM never reboots automatically — the existing Reboot button on the Server page is the trigger.

### Improvements

- **Faster Check for Updates** — The old flow streamed `apt update` output line-by-line through SSE; the new flow runs it as a single command and parses the structured `apt list --upgradable` output. The visible difference is less — you see "Checking..." for a second or two instead of watching scrolling progress — but it does cleaner work for the same wait.

- **Risky default is unchecked, not checked** — The most meaningful safety improvement isn't a block or a confirmation modal — it's just defaulting risky packages to unchecked so you have to opt them in deliberately. If you're not specifically thinking about your Docker upgrade, you won't accidentally include it in a "let me grab the security patches" run.

### Behind the scenes

- **What MIM considers "risky"** — Docker stack (`docker-ce`, `docker-ce-cli`, `docker-ce-rootless-extras`, `containerd.io`, `docker-compose-plugin`, `docker-buildx-plugin`, `docker.io`, `docker-compose`) and kernel-related packages (`linux-image-*`, `linux-headers-*`, `linux-modules-*`, `linux-generic*`, plus the cloud kernel families: `linux-aws-*`, `linux-azure-*`, `linux-gcp-*`, `linux-oracle-*`, `linux-kvm-*`). Bias toward false positives — better to show a `⚠ risky` badge unnecessarily than to miss a real one. The badge is informational; you can always check the box and proceed.

- **Why the old flow was a footgun** — On the MIM-host server (the one MIM itself runs on), the old `apt upgrade -y` button would happily try to upgrade Docker, which restarts the docker daemon mid-upgrade, which kills the MIM container, which kills the SSH client, which kills apt mid-`dpkg-configure`, and leaves the system in a half-configured state requiring direct SSH and `sudo dpkg --configure -a` to recover. Non-technical operators don't know to do this. The new flow defaults Docker to unchecked, surfaces the risk badge explicitly, and uses `apt install --only-upgrade` so anything you didn't deliberately pick stays at its current version. Docker doesn't get touched unless you check its box on purpose.

- **Confirmation modal when you select something risky** — If you check any risky-flagged package and hit "Apply Selected," MIM pops a confirmation modal listing exactly which risky packages are in the selection and why each one is flagged (Docker daemon restart, kernel needs reboot, etc.). The Cancel button is the default focus and the Proceed Anyway button is amber-colored — so a stray Enter dismisses the risky action rather than confirming it. The unchecked default protects against accidentally including Docker; the modal protects against forgetting you checked it.

### Compatibility

- **The legacy `GET /api/server/updates` SSE endpoint is removed** in this release. Anything bookmarking that endpoint directly will get a 404. The Updates page at `/{server}/server/updates` keeps the same URL; it's just a different UI now.

## Product Catalog Redesign

The Products page also gets a long-overdue refresh in 3.2.0. Same page, much cleaner shape — products are now grouped into categories, the inventory file behind the scenes has been quietly rebuilt to use stable server IDs instead of IP addresses, and MIM itself shows up in the list as a product you can update from the Products page (no more bouncing to a different page to update MIM). All of this happens transparently on first boot of 3.2.0 — your existing inventory gets migrated automatically.

### New Features

- **Four-section grouped Products page** — Instead of one long alphabetical list, the Products page now shows four sections in fixed order: **MMFP Solutions** (MIM, GoSlimStratum, GSS Miners, GoSlimStratum User Client, Axeos Dashboard), **Crypto Nodes** (DigiByte, Bitcoin Knots, Bitcoin Cash, eCash, Bitcoin II), **3rd Party** (PostgreSQL, Dozzle, Watchtower), and **Other** — anything you've added to MIM's docker-compose.yml that isn't in the catalog (a `dgb-test` build sitting alongside the catalog DGB, for example). Each section header shows a count badge. Products are sorted alphabetically inside each section.

- **MIM itself is a product now** — MIM was previously hidden from the Products page (it special-cased itself out of discovery). It's now a regular entry in the MMFP Solutions section on the MIM-host server, with an **Update** button that opens the same update modal you already see from the footer badge. This makes the update path the same regardless of how you got there. Disable/Enable/Uninstall aren't options for MIM — disabling MIM would shut off the tool you're using.

- **Live version numbers from `docker inspect`** — Each installed product row shows its actual running version, read fresh from `docker inspect` of the container's OCI labels every time you load the page. MMFP-built products (GoSlimStratum, GSSM, etc.) show the version their image was tagged with at build time. PostgreSQL shows its real version (e.g. `v18.4`) by reading the container's `PG_VERSION` env var since the postgres image doesn't ship an OCI version label. Dozzle's `v10.6.5` shows up directly. For containers where the version source isn't trustworthy (vendor label missing, image tag is `:latest`), MIM shows `—`.

- **First-run prompt when you visit a new server's Products page** — Add a new server to MIM, navigate to its Products page, and you'll see a small modal prompting you to run discovery so MIM can scan the server and import what's installed. You can dismiss it and use the existing Discover button later instead — the modal just makes the first-run path obvious instead of leaving you staring at an empty page wondering what to do next.

- **Orphan-inventory banner with a Resolve flow** — If you've ever moved a server to a new IP, swapped a server out for a replacement at a different address, or otherwise had IPs change under MIM, the inventory file used to silently keep the old IP-keyed entry around as dead data. 3.2.0's migration catches these — anything keyed by an IP that no longer matches any server in your config lands in an `_orphans` section, and an amber **"N product(s) from unknown IPs need attention"** banner appears at the top of the Products page. Click **Resolve** to see each orphan with the products it carried and a per-server picker — assign it to an existing server (the products move into that server's inventory) or just delete it. Either way, the banner disappears when the orphan list is empty.

- **Custom prune size for blockchain nodes** — DigiByte, Bitcoin Knots, Bitcoin Cash, eCash, and Bitcoin II nodes now have three Node Type choices: **Full**, **Pruned (Recommended)**, and **Custom**. Pick Custom and a prune size (MB) field appears so you can pick something in between — 1 GB, 5 GB, whatever fits your disk. The floor is the bitcoind minimum (550 MB for eCash, 563 MB for the others), enforced by the form. Default stays at the canonical pruned size if you don't touch it.

- **Manage compose services that aren't in our catalog** — The Other section is the home for any service you've added to MIM's `docker-compose.yml` that doesn't have a catalog entry. MIM auto-detects these on every Products page load (no need to click Discover first). Each gets a real action surface: **Update** (`docker compose pull` + recreate, same flow as catalog products), **Disable** (stops the container and adds `profiles: [disabled]` to compose), **Enable** (the reverse). For raw Start/Stop on any container, the Containers tab is still where you go — Other on Products is focused on compose-managed services.

- **Axeos Dashboard's Update button is hidden** — Axeos has been deprecated in favor of GSS Miners (GSSM) since the 3.1 series, but the Products page still offered an Update button. As of 3.2.0 we suppress Update for any product marked deprecated — Disable and Uninstall still show up since those are the intended path to migrate away. No updates were ever going to ship for it anyway.

- **Copy JSON on the Inspect page actually copies now** — A long-standing bug: the Copy JSON button on a container's Inspect page (and the Copy buttons in the log viewers) did nothing in HTTP-served MIM installs. The clipboard API the buttons used only works over HTTPS or `localhost`, and most operators access MIM via plain HTTP on a LAN. Fixed with a clipboard fallback that works in both modes.

### Behind the scenes

- **Inventory file is now keyed by server ID** — `product-inventory.json` used to key the top-level `servers` map by SSH host (IP address), which broke any time an IP changed. As of 3.2.0 it's keyed by the stable 8-char base62 server ID MIM has been generating for every server since the multi-server work. Your existing inventory is migrated automatically the first time 3.2.0 boots — entries get rewritten under the matching server's ID, anything that can't be matched lands in `_orphans` for you to resolve.

- **Plaintext secrets in the inventory are gone** — Before 3.2.0, the inventory file stored RPC user passwords, PostgreSQL database passwords, and pool wallet secrets as plaintext fields on each installed product. SSH passwords in your `servers.json` had been encrypted-at-rest for a while; product config values weren't. As of 3.2.0 the inventory simply doesn't store these — when you uninstall a product, MIM recovers the values it needs from the live server (same way Discover already auto-detects them on install). If you'd previously deleted a product's config files by hand from the server and then tried to uninstall through MIM, you'll now see a clear error pointing at SSH cleanup instead of MIM trying to run uninstall steps with empty values.

- **Dead schema fields cleaned up** — Several fields were being written on every state change but never read by anything (`last_updated`, `health_status`, plus a `product_id` that just echoed its own map key, plus a `server_host` that just echoed its own parent key). These are all stripped during migration so the file stays slim and the schema matches the code's actual behavior.

- **"Other" section is compose-aware, not a host-wide container sweep** — The Containers tab is where you see "everything running on this host" — random `docker run` containers, unrelated compose projects, all of it. The Products page's Other section is focused: it's specifically the services declared in MIM's `docker-compose.yml` that don't have a catalog entry. So your hand-added `dgb-test` shows up; a one-off `docker run nginx` from a debugging session doesn't. The split matches how operators actually think about the two pages — Products is for things MIM should be helping you manage; Containers is for the full picture.

- **Versions are read live, not cached** — Previous versions of MIM stored a `product_version` field in the inventory file at install time, which slowly drifted out of sync with reality as containers got updated by other means. As of 3.2.0 the inventory doesn't store the version at all — each Products page load triggers a single batched `docker inspect` across all your installed products to grab whatever's running right now. One SSH round-trip, all products at once.

- **ARM64 caveat for the update check** — On ARM64 servers (mostly Raspberry Pi setups), the registry sometimes reports a different image digest than what's actually stored locally even when the content is identical — a quirk of how multi-arch images get rebuilt. If you click Update and Check says "update available" but the actual pull says "your container is already running this version," that's why. MIM now reports this honestly with "Pulled latest image, but no change detected" instead of the previous misleading "no updates available" message. AMD64 servers don't have this issue.

- **Repair flow removed** — The Repair button (and its API endpoint) was never fully implemented and never used. It's gone in 3.2.0. If you had it scripted against `POST /api/server/product/repair`, that endpoint now returns 404. Use Uninstall + Install for a true repair.

- **`docker_host` field dropped from `servers.json`** — Every server entry used to require a `"docker_host": "ssh://<user>@<host>"` line. Turns out MIM was reading the value into memory and writing it back out but **never actually using it for anything** — all the docker work runs through the SSH connection MIM already builds from `ssh_host` + `ssh_user` + `ssh_password`. The field is gone from the Config page form, the API, and the example config in 3.2.0. Your existing `servers.json` files keep working unchanged — MIM ignores the field on read, and the next time you save a server through the UI the line is dropped automatically. Or just delete the `docker_host` line by hand from your config now; MIM doesn't care either way.

### Compatibility

- **`POST /api/server/product/repair` returns 404** — the half-implemented Repair flow has been removed. No replacement endpoint; use Uninstall + Install.
- **`product-inventory.json` migrates automatically on first boot.** No operator action required. Your existing file is rewritten in place to the new format (the migration is idempotent — running 3.2.0 a second time on an already-migrated file is a no-op).
- **If you'd previously hand-edited `product-inventory.json`** with an entry under an IP that doesn't match any server in your `servers.json`, that entry will land in the new `_orphans` array after migration and show up in the orphan banner. Resolve via the UI or delete it from the JSON directly.
- **`docker_host` is no longer part of `servers.json`** — see the bullet above. MIM ignores the field if it's still in your file; first UI save drops it. No operator action needed unless you want to tidy up by hand.

---

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
