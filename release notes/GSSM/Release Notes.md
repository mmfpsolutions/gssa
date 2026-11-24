# GSSM Release Notes
## v5.x Series

## v5.1.2

**A tidier Workers table on the Pool Details page.**

> **No operator action required on upgrade.**

### Improvements

- **Workers table: the protocol is a badge on the worker.** The Protocol column is gone. Each worker now has a V1 or V2 badge in front of its name, green when the worker is active and red when it isn't, the same as the Rigs table on the Hash Hopper page.

- **Workers table: one Shares column.** Valid and Invalid are now a single Shares column showing accepted · rejected in green and red. Hover over it for the two figures in words.

- **Workers table: the user agent sits under the worker.** The User Agent column is gone too. A worker's user agent is now a small line under its name, so the table is four columns and fits a narrow screen better.

- **Workers table: shorter names for Hash Hopper rigs.** A rig that mines through the Hash Hopper used to be listed by its full name, wallet address and all. It is now listed as profile.rig with the Hash Hopper badge after it, so hopper rigs are easy to tell from miners that connect to the coin directly. Hover over the name for the full name. Direct miners are listed as before.

- **Blocks table: shorter names for Hash Hopper rigs.** A block found by a hopper rig now lists its worker as hopper.profile.rig, without the wallet address. Hover over it for the full name.

- **A Run ID on the License page.** The License page now shows a short ID for the current run of GSS Miners. Support may ask you for it.

### Bug Fixes

- **Telegram bot: nodes and pools it hasn't checked are no longer called offline.** Just after GSS Miners starts, or when Node alerts are off, `/status` could say "No nodes configured" and `/nodes` could list every node as Offline. They now say "not checked" and show the node as Unknown, with a line explaining why. The same goes for `/pools`. Offline now always means a check ran and failed.

- **A failed Telegram or webhook test no longer shows your bot token.** When a Telegram message or a webhook could not be sent, the error message included the full address it was sent to, and for Telegram and Discord that address contains the token. The error now gives only the reason. If you have shared a screenshot or a log of such an error, make a new token with BotFather (or a new webhook in Discord) and save it in GSS Miners.

---

## v5.1.1

**A Blocks Found card on the Miners dashboard, an Auto Fan Control fix for the Avalon Nano3s, and the in-app Help page is up to date again.**

> **No operator action required on upgrade.**

### New Features

- **A Blocks Found card on the Miners dashboard.** A fifth summary card adds up the blocks your online miners say they've found. Hover over it for the small print: each miner counts from when it last started, and ElphaPex and Whatsminer devices don't report a count, so it isn't an all-time record.

- **Blocks Found by miner on Fleet View.** A new chart shows which miners found those blocks. If none have, it says so.

### Improvements

- **Help matches the pages it describes.** The Add Pool form no longer shows an API Port or WebUI Port field it doesn't have, the device list covers all six device types (including Whatsminer on port 4433), refresh intervals show the real default of 120 seconds, and Standby names Bitaxe and NerdQAxe alongside the Avalon Q.

- **Help covers more of what GSSM does.** New entries for the badges on a miner card, the electricity rate, the Disabled switch, what can be scheduled on which device, the Schedule Applied and Trigger Fired alerts, power tracking and the Energy report.

### Bug Fixes

- **Auto Fan Control takes the fan back after a Nano3s restarts.** A restart puts the Nano3s on its own automatic fan mode, and GSSM didn't notice. It took the fan back only once the temperature rose above your target, so in Low or Medium, where the device stays at or under it, your minimum fan speed was not held. GSSM now notices the restart and sets the fan again once the miner has been up for 10 minutes. If you worked around this by disabling and re-enabling the miner, you no longer need to.

- **Auto Fan Control lets a Nano3s warm up first.** A Nano3s tunes itself in its first few minutes, and it settles at a lower hashrate if the fan is held at your minimum speed while it does. GSSM now leaves the fan to the miner for its first 10 minutes after a start, then takes over. The emergency temperature still applies during that time. The miner's Settings page shows "Device (warming up)" and how long is left.

- **Fleet View keeps its fleet total current.** The "Fleet Total" in the middle of the Device Types chart, and the percentages when you hover over it or over Hashrate Contribution, stayed at the value from when the page was opened. They now update with each refresh.

### Good to know

- **Excluding a miner from notifications also stops its history, its energy tracking and its triggers.** They all run on the same background check. Help now says so. To silence one kind of alert, turn that alert off instead.

- **The Rate Limiting settings on the Notifications page are saved but not applied yet.** Every miner alert is sent. Help now says so.

---

## v5.1.0

**GSS Hash Hopper support.** GoSlimStratum 6.0.0's Hash Hopper mines whichever of your chains is best at
the moment and moves your rigs as difficulties change. GSSM now shows it: a hopping miner shows the Hash
Hopper badge, and the hopper gets a card of its own on the Pools tab.

### New Features

- **The Hash Hopper badge on hopping miners.** A miner logged in to the hopper (`hopper.<profile>.<rig>`)
  shows the Hash Hopper badge on its card, in the list view and on its detail page, whichever chain it's
  on at the moment. Hover over the badge to see the profile. This works for every miner GSSM supports
  and needs nothing from GSS, so it keeps working while GSS is down.

- **A Hash Hopper card on the Pools tab.** Add your GSS's Hash Hopper as a pool: tick **Hash Hopper** when
  you add a GoSlimStratum pool (no coin needed), or let **Autodiscover** find it. The card shows:
  - whether it's hopping, or in shadow mode
  - the best chain right now
  - which chain your rigs are on, and for how long
  - the switch rules in force
  - how many rigs are connected, and their hashrate

  Its **Details** page lists your chains and how they rank, your profiles, every connected rig, the
  switch log, and any logins the hopper turned away.

- **Hash Hopper alerts.** If the hopper's port closes or GSS goes away, you get the usual pool offline
  alert, and the card says why.

- **GSS coin type for your custom coins.** GSS lets you name a coin's pool anything, such as `VTX-New`. In
  the Coin Map, give a custom coin its **GSS coin type** (its key in GSS's `coins.json`, such as
  `vertexcoin`), and the Hash Hopper card shows your logo for that coin whatever its pool is called.
  GSSM already knows GSS's built-in coins. Set it when you add the coin, or later with the new **Edit**
  button.

### Improvements

- **GoSlimStratum pools show the coin GSS says they're mining.** GSS knows what each of its pools mines,
  so GSSM now takes the coin from GSS itself instead of from the pool's name. A pool called `DGBT`,
  `DGB-DD` or `VTX-New` shows the right logo, and **Coin Type** on the pool form is now optional. GSS's
  answer wins if the two disagree.

- **Autodiscover fills in the coin for you.** Discovered GoSlimStratum pools come with their coin already
  picked, straight from GSS. You only pick one for a GSS custom coin GSSM doesn't know.

- **Icons on the pool details page's summary cards,** matching the dashboards.

- **Tidier table headers on the pool and node details pages.** The small sort mark after every column name
  is gone, which saves room on a phone. Click a header to sort, as before; the sorted column still shows
  its arrow.

### Good to know

- **The Pools card needs GSS 6.0.0 or later.** On an older GSS the card reads offline and says so. The miner
  badge works with any GSS.
- **Blocks found through the hopper show on each coin's own pool card,** where GSS records them, not on the
  hopper's card.
- **The hopper card's share counts start when each rig connects,** which is why they're labelled
  "(connected)".
- **The Hash Hopper badge can't be replaced** with your own logo, just like the built-in coins.
- **If you mapped the hopper's IP:Port to a custom coin in the Coin Map,** that mapping still wins.
  Delete it to see the Hash Hopper badge.

---

## v5.0.1

**GSSM's pages now load everything from GSSM itself.** The charts on the miner, pool and node detail
pages, Fleet, Metrics and Historicals used to download their code from an outside website (a CDN) each
time those pages opened. That code is now built into GSSM.

### What's changed

- **Charts work without internet access.** Handy if the computer you open GSSM from can reach your
  miners but not the internet.
- **More secure.** The code that draws the charts can no longer be changed from outside GSSM. It only
  changes when we release a new version.
- **More private.** Opening those pages no longer contacts a third-party website.

### Good to know

- **The charts look and work as before.** It's the same code, just served by GSSM.

---

## v5.0.0

**Coin Map: bring your own coins.** GSSM no longer stops at the coins it ships with. A new **Coin Map** page lets you add your own coins with their own logos, use them on your pools and nodes, and tell GSSM which coin a miner is mining when it can't work that out by itself. Open it from the **Configuration** page. It's available on every license tier.

> **No action required.** If you don't add anything to the Coin Map, your miners keep the coin badges they show today.

### New Features

- **Add your own coins.** Give a coin a symbol, such as **VTX**, and optionally a logo. It appears in the pool and node dropdowns right away, with no restart. Logos are PNG files of up to 256 KB, and square ones work best. The symbol can't be renamed later. The coins GSSM ships with keep the logos they ship with.

- **Pools pick up your logo by themselves.** A pool whose GSS coin key matches a coin's symbol shows that coin's logo. If your key is a variant, such as `VTXT`, choose the coin as the pool's **Coin Type**.

- **Nodes can use your coins.** Pick your coin in the **Node Type** dropdown and the node shows its logo.

- **Address rules for miners.** If a coin has an address form of its own, such as its own Bech32 prefix, paste one real address and GSSM works out the rule. Every miner mining to that kind of address then shows your coin. GSSM refuses an address that one of its built-in coins already claims, which covers most legacy addresses starting with `1`, `3`, `L`, `M`, `X`, `W`, `D`, `S`, `A`, `9` or `n`. Use a pool mapping for those.

- **Pool mappings for miners.** If a coin's addresses look like another coin's, tell GSSM by pool instead: map a host and port to a coin, and every miner reporting that pool shows that coin. For example, a Bitcoin-style address on your Fractal Bitcoin port can show **FB** rather than **BTC**. A mapping is just a comparison with what the miner reports, and GSSM never contacts the pool for it. So it keeps working while the pool is down, and it works with any pool, not only GSS.

- **See what your miners report.** The Coin Map page lists every pool your miners are reporting, how many miners are on it, the badge it shows, and why. A **Map** or **Add rule** button on the row fills in the details for you.

### Improvements

- **Pools and nodes with no logo now show the default badge,** rather than no icon at all, the same as miners do.

### Bug Fixes

- **`odo` is now in the node Algorithm dropdown,** so a DigiByte Odo node can select it as its main algorithm.

- **A node's saved algorithm is no longer overwritten.** If a node's saved algorithm wasn't in the dropdown, the page showed `sha256d`, and saving anything on that node then wrote `sha256d` over it. The saved value now stays selected.

### Good to know

- **The order GSSM checks a miner's pool:** your address rules first, then your pool mappings, then GSSM's built-in rules. If nothing matches, the miner shows the default badge. An address rule never takes an address from a built-in coin, but a pool mapping deliberately overrides the built-in rules.

- **A pool mapping matches exactly what the miner reports.** A mapping for `192.168.7.10:3334` won't match a miner set to `gss.local:3334`, so that miner needs a mapping of its own. If you move a coin to a new port, update its mapping too. The **Map** button fills in the right value for you.

- **The Coin Map only changes what's displayed.** A coin symbol has no effect on how GSSM talks to your miners, pools or nodes.

- **Changes apply on the next refresh, with no restart.** A new logo shows straight away in the browser you changed it from. Other open dashboards catch up within a minute.

- **Logos live in a `coin-icons` folder next to `config.json`.** You can also drop `<symbol>.png` in there by hand for a coin you've added. Your coins, rules and mappings are stored in `config.json`, so back up both.

- **A coin that's in use can't be deleted.** GSSM tells you which pools, nodes, rules or mappings are using it, so you can move them first.

- **If editing is locked,** with `disableConfigurations` set, the Coin Map page is read-only.

- **Going back to an older version:** your logo files stay on disk, and your coin map stays in `config.json` through ordinary saves. Adding a node on the older version removes the coin map from the file, so keep a backup of `config.json` if you plan to go back.

---
