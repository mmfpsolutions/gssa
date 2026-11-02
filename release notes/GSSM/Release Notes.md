# GSSM Release Notes
## v5.x Series

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
