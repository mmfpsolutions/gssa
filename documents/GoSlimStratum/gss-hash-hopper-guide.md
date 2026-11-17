# GoSlimStratum Hash Hopper Guide

What the Hash Hopper is, how to set it up, what every setting does, and what to expect when it runs.

*Current for GoSlimStratum 6.0.0. The Hash Hopper is new in 6.0.0.*

See also the [Coin Configuration Guide](gss-coin-config-guide.md), the [Global Configuration Guide](gss-global-config-guide.md) and the [Troubleshooting Guide](gss-troubleshooting-guide.md).

---

## Summary

The Hash Hopper points SHA256d hash at whichever of your coins gives the most blocks per hash right now. Your miners connect to **one port of its own**. The hopper decides which coin each rig works on and moves it when another coin becomes the better one. The miner is never reconfigured and never reconnects when it is moved.

Things to have right before anything else:

- **The hopper only chooses and moves.** Each coin pool still does the mining work: it builds the jobs, checks the shares and builds any block found, exactly as it does for miners on its own port. A block found through the hopper is that coin's block, on that coin's Blocks and Earnings pages.
- **It works between coins you already run in GoSlimStratum.** Each coin it uses (a "chain") is a coin pool you have set up, with its own node. The hopper does not connect to outside pools.
- **Rewards go straight to you.** Each chain must be in Direct-to-Miner (DTM) mode, and each block pays the address you gave for that chain.
- **It maximises blocks, adjusted by your weights. It does not maximise value.** It knows nothing about prices. Weights are how you tell it what a block on each chain is worth to you.
- **It is built for a home or solo miner's own rigs.**
- **Shadow mode** lets you watch what it would do, without moving any hash, before you commit to it. It is on by default.

---

## What You Need

A coin can take hopper miners only when it:

- uses the `sha256d` algorithm (Scrypt, Skein, Qubit and Odo coins cannot take part),
- is running, with its node healthy,
- is in **Direct-to-Miner mode**: `enable_dtm` with a license, or, on a built-in coin, revenue share accepted,
- is **not a merged-mining parent**, and
- has the same `extranonce_size` as the first chain you select.

You need **at least two** such coins for the hopper to move between.

**Licensing:** the Hash Hopper has no license check of its own. DTM mode on each chain is the gate. Hopper connections count toward your license's miner limit, once each, whichever coin they are mining. Shadow mode needs neither a license nor DTM, and scores any SHA256d coin.

---

## Setting It Up

1. **Open the Hash Hopper config page** from the Hash Hopper card on the Global Configuration page.
2. **Select the chains** and leave each weight at `1` to begin with. The page tells you what a coin would need before it could take miners. Weights of `1` are a starting point, not a finished set-up: see [Choosing Weights](#choosing-weights) before you turn shadow mode off.
3. **Add a profile.** A profile is a name plus one payout address per chain. Give it a short name such as `myfarm` (letters, digits, `-` or `_`; no dots).
4. **Set the hopper's stratum port**, one that no coin uses.
5. **Turn the hopper on and leave Shadow mode on.** Save. The Hash Hopper tab appears in the header.
6. **Watch it in shadow mode** for a day or so, and settle your weights while you do. The Chains table shows each chain's next-block cost and which is best; the Switch Log shows the switches it would have made.
7. **Turn Shadow mode off** and save. The hopper port opens.
8. **Point your miners at the hopper port** (see below).

Saving the hopper config does not need a GoSlimStratum restart. Rules, weights, shadow mode and addresses take effect at once. Changing the port, the symbol, the chain list, the Stratum V2 listeners or the hopper's Stratum and VarDiff settings restarts the hopper's port only, and its miners reconnect.

### Pointing a Miner at the Hopper

| Miner setting | Value |
|---|---|
| Pool URL / host | Your GoSlimStratum host |
| Port | The hopper's port (not a coin's port) |
| Username | `hopper.<profile>` or `hopper.<profile>.<rig>` |
| Password | Anything (`x`) or d=1234 for miner suggested diff |

```
hopper.myfarm            — profile "myfarm"
hopper.myfarm.bitaxe2    — profile "myfarm", rig "bitaxe2"
```

- **Do not put a wallet address in the username.** The payout addresses come from the profile. An address on the hopper port is refused.
- A `hopper.` username on a coin's own port is refused too.
- A rig name tells your rigs apart on the dashboards. With no rig name, the rig is given a worker ID when Auto Worker ID is on.
- Stratum V2 miners use the hopper's own V2 port, if you enable one (the `sv2` setting below).

---

## How a Chain Is Chosen

- Each chain's **cost** is the expected number of hashes to find its next block, taken from its current block template (that is, from the network difficulty right now).
- The hopper mines the selected chain with the lowest **weighted cost**: cost divided by weight.
- It **moves** a rig when another chain is better by more than the **switch threshold** and the rig has been on its chain for at least the **minimum dwell**.
- A chain whose node goes down, or whose coin is stopped, is **left at once**.
- A chain is **skipped** unless other miners found at least the configured number of blocks on it inside the **liveness window**. This keeps the hopper off a chain that looks cheap because nobody is mining it. If no chain passes, the best healthy chain is used, so miners are never left without work.

### Weights

A weight of `1` counts blocks only. A weight of `50` says one block on that chain is worth 50 blocks on a chain weighted `1`. Set each weight to what a block on that chain is worth to you compared with the others. The hopper only looks at how the weights compare with each other, not at their size.

- **A weight is any number above 0.** Decimals and values below 1 are fine: `0.9`, `2.4` and `15.8` are ordinary weights. A weight left empty or at `0` counts as `1`.
- **Only the proportions matter.** `1` / `2.5` / `16` and `6.25` / `15.625` / `100` are the same set. Multiply every weight by the same number and nothing the hopper does changes, so a set built up from `1` and a set scaled so that the largest is `100` are equally right. Use whichever you find easier to read.
- **With every weight at `1` the hopper sits on the chain with the lowest next-block cost.** Chains often differ in cost by ten times or more, so with equal weights that is usually the same chain all day. Weights are what make it hop.

Giving one chain a weight far above the rest keeps every rig on that chain. The hopper still moves the rigs if that chain's node goes down.

**Presets** are named sets of weights kept on the config page's Chains card. Choosing one fills in the weights (a selected chain the preset doesn't name gets `1`), and Save Changes applies them. No rig reconnects when a preset is applied. A preset holds weights only.

### Choosing Weights

Weights do two jobs at once. They cancel the difference in cost between chains (a block on a large chain takes many more hashes than a block on a small one), and they say which chain you favour. A set that only ranks the chains by preference, such as `3` / `2` / `1`, does not do the first job and will not behave the way you expect.

**Start from value, if your coins have a price.** On the Hash Hopper config page, the Chains card has a **Suggested weight** column: one block's reward at today's price, relative to the lowest-value selected chain that has a price. It needs **Show Coin Price and Value** turned on, on the Global Configuration page, and only built-in coins on mainnet that have a price get one. WojakCoin and `coins.json` coins do not. It is a hint only: nothing applies it. Type the figure into **Weight** if you want to use it.

**Or start from cost: level the chains, then favour one.**

1. On the Hash Hopper page, read each chain's **Next-block cost** in the Chains table. One reading is one moment, and costs move all day. Multiply it by the chain's **Opportunity** figure to get its average over the last day. (Opportunity appears once the hopper has 30 minutes of history.)
2. Leave the cheapest chain at `1`. Give each other chain its usual cost divided by the cheapest chain's usual cost. The chains are now level, and the hopper moves among all of them as their costs rise and fall.
3. To spend more time on a chain, raise its weight. To spend less, lower it. Halving a chain's weight means its cost must fall to half of its usual before it draws level again.

An example, for three chains whose usual costs are 170 PH, 420 PH and 2.8 EH. These figures are an illustration. Use the costs on your own page.

| Chain | Usual cost | Level weights | Mostly DGB, then BTCS, and WJK only when it is very cheap |
|---|---|---|---|
| WJK | 170 PH | `1` | `0.5` |
| BTCS | 420 PH | `2.5` | `2` |
| DGB | 2.8 EH (2,800 PH) | `16.5` | `16.5` |

With the last column, and DGB at its usual cost, BTCS draws level with DGB when it is about 20% cheaper than usual, and WJK when it is at half its usual cost. A chain then has to be better by the switch threshold as well before rigs move to it.

**Check the result before you rely on it.**

- **Chosen now**, on the config page's Chains card, marks the chain that the weights on screen would pick, before you save them.
- On the Hash Hopper page, the line under **Against the best chain** gives the cost at which a chain would take the rigs: "Needs to fall below 298 PH to beat DGB by 15.0%".
- Run in shadow mode for a day and read the Switch Log: how often the hopper would have moved, and how long it stayed on each chain. With rigs connected, **Time and shares** on the Profiles table shows how their time was split between the chains.
- New weights apply as soon as you save them, and no rig reconnects. Hopping gain starts again, because it is worked out with the weights.

**Your hashrate does not change the right weights.** Cost comes from each chain's network difficulty, and the same rigs would mine whichever chain wins. Hashrate only sets how long a block takes, which is what the **Blocks / day** column shows.

### Install Offset

Each GoSlimStratum install moves its switch threshold and minimum dwell by an offset of its own, so hoppers on different pools don't all switch at the same instant. **Install offset** sets its size: up to 20% either way by default, from 0 to 50. It is a share of each value, not percentage points: with a 15% threshold and the default offset, the threshold in force is somewhere from 12% to 18%. Where this install sits inside that range is picked when GoSlimStratum starts and kept until it restarts. At `0` the hopper uses the two values exactly as you set them, which is what you want when comparing one run with another. The Switch rules card shows the figures in force.

---

## Settings Reference (`hopper.json`)

The Hash Hopper's settings are in `hopper.json`, in the same directory as `config.json`. If the file is absent, the hopper is off. Use the Hash Hopper config page to change them; it checks what you enter.

```json
{
  "enabled": true,
  "symbol": "HOPPER",
  "shadow_mode": true,
  "port": 3340,
  "chains": [
    { "symbol": "BTCS", "weight": 1 },
    { "symbol": "WJK", "weight": 1 },
    { "symbol": "BCH2", "weight": 1 }
  ],
  "switch_threshold_percent": 15,
  "min_dwell_seconds": 600,
  "install_offset_percent": 20,
  "liveness_window_minutes": 120,
  "liveness_min_blocks": 3,
  "profiles": {
    "myfarm": {
      "addresses": {
        "BTCS": "YOUR_BTCS_ADDRESS",
        "WJK": "YOUR_WJK_ADDRESS",
        "BCH2": "YOUR_BCH2_ADDRESS"
      }
    }
  },
  "sv2": [
    { "enabled": false, "variant": "bip324", "port": 3341 }
  ],
  "presets": {
    "Blocks only": { "weights": { "BTCS": 1, "WJK": 1, "BCH2": 1 } }
  }
}
```

A full example, including the `stratum` block, is in [hopper.example.json](../examples/GoSlimStratum/hopper.example.json).

### Top Level

| Field | Default | Description |
|-----|-------|-----------|
| `enabled` | `false` | Turns the Hash Hopper on. While on, it has its own tab in the header. |
| `symbol` | `"HOPPER"` | The name the hopper's own records are kept under, and its name in notifications. 1 to 16 letters, digits, `-` or `_`. It must not be the same as one of your coins. |
| `shadow_mode` | `true` | `true`: score the chains and log where the hopper would mine, without opening a port or moving any hash. `false`: move hash. |
| `port` | none | The stratum (V1) port miners connect to. Required when shadow mode is off. Must not be used by a coin. |
| `chains` | `[]` | The coins the hopper may use, each with a `symbol` (the coin's key in `config.json`) and a `weight`. At least two when shadow mode is off. |
| `switch_threshold_percent` | `15` | How much better another chain's weighted cost must be before rigs move to it. From 0 to under 100. |
| `min_dwell_seconds` | `600` | The least time a profile's rigs stay on a chain before a better chain can take them. A chain that goes unhealthy is left at once regardless. |
| `install_offset_percent` | `20` | The size of this install's own offset to the threshold and dwell, as a share of each (20 moves a 15% threshold to somewhere from 12% to 18%). From 0 to 50. `0` turns it off. |
| `liveness_window_minutes` | `120` | The window the liveness check looks back over. At least 1. |
| `liveness_min_blocks` | `3` | Blocks other miners must have found on a chain inside the window for it to count as live. `0` turns the check off. |
| `profiles` | `{}` | Payout addresses, by profile name. See below. |
| `sv2` | `[]` | Stratum V2 listeners on the hopper. See below. |
| `presets` | `{}` | Named sets of weights for the config page. The hopper itself never reads a preset; it uses the weights saved on the chains. |
| `stratum` | defaults below | The hopper port's own Stratum and VarDiff settings. |

### Chains

| Field | Default | Description |
|-----|-------|-----------|
| `symbol` | — | The coin's key in the `coins` section of `config.json`, for example `"BTCS"`. |
| `weight` | `1` | What one block on this chain is worth compared with the others. Any number above 0; decimals and values below 1 are allowed. See [Choosing Weights](#choosing-weights). |

### Profiles

```json
"profiles": {
  "myfarm": {
    "addresses": { "BTCS": "B...", "WJK": "W..." }
  }
}
```

- The profile's name is what miners put in their username: `hopper.myfarm`. 1 to 32 letters, digits, `-` or `_`, with no dots.
- `addresses` holds one payout address per chain, keyed by the coin's symbol. Each address is checked against that coin's address rules.
- **A chain with no address in a profile is never mined by that profile.** This is how you run one profile on all chains and another on only some.
- A profile needs at least one address.
- Each block is paid straight to the profile's address on the chain it was found on, with the pool fee and revenue share that chain's Direct-to-Miner mode applies.

You can have several profiles, and the same device can be pointed at one or another by changing its username.

### Stratum V2 Listeners (`sv2`)

| Field | Description |
|-----|-----------|
| `enabled` | Whether this listener starts. |
| `variant` | `"bip324"`. |
| `port` | The V2 port. Must be different from the hopper's V1 port and from every coin's ports. |

The hopper's V2 listeners use the same pool-wide Stratum V2 keys as your coins. Generate them once on the Global Config page; see the [Global Configuration Guide](gss-global-config-guide.md).

### Stratum and VarDiff Settings (`stratum`)

The hopper port has its own Stratum Settings and VarDiff Settings, on the Hash Hopper config page. They have the same names and the same meaning as on a coin's page (see the Stratum and VarDiff sections of the [Coin Configuration Guide](gss-coin-config-guide.md)), but different defaults, chosen for a port that takes anything from a small ESP miner to an ASIC.

| Field | Hopper default |
|-----|-------|
| `host` | `"0.0.0.0"` |
| `difficulty` | `0.0024` |
| `connection_timeout_seconds` | `0` (use the Global Config value) |
| `consolidation_threshold_seconds` | `3` |
| `disambiguation_enabled` | `false` |
| `auto_worker_id` | `true` |
| `default_worker_id` | `""` |
| `ping_enabled` | `true` |
| `ping_interval_seconds` | `30` (from 5 to 3600) |
| `accept_miner_suggested_diff` | `false` |
| `probe_difficulty` | `15599` (`0` turns it off) |
| `user_agent_difficulty_map` | `{}` |
| `vardiff.enabled` | `true` |
| `vardiff.minDiff` | `0.0006` |
| `vardiff.maxDiff` | `62398` (`-1` for no limit) |
| `vardiff.targetTime` | `10` |
| `vardiff.retargetTime` | `120` |
| `vardiff.variancePercent` | `30` |
| `vardiff.onNewBlock` | `false` |
| `vardiff.useFloatDiff` | `true` |
| `vardiff.floatDiffPrecision` | `4` |
| `vardiff.floatDiffBelowOne` | `true` |
| `vardiff.floodProtection.enabled` | `true` |
| `vardiff.floodProtection.sharesToCheck` | `4` |
| `vardiff.floodProtection.triggerThreshold` | `0.25` |
| `vardiff.floodProtection.maxAdjustmentMultiplier` | `16` |

- **These settings follow a rig from chain to chain.** A coin's own Stratum and VarDiff settings never apply to hopper miners, whichever coin they are mining. Share difficulty depends on the rig, and a hopper rig is the same rig on every chain.
- **Mining and payout settings are not set on the hopper.** Each coin applies its own job history, stale share grace period, pool fee and maturity to the work a hopper miner does on it.
- TCP keepalive is always taken from the Global Config.
- Saving a change to these restarts the hopper port, and its miners reconnect.

---

## Reading the Hash Hopper Page

**Header tab.** While the hopper is turned on it has its own tab, after the coin tabs. The dot is green when it is moving hash, blue in shadow mode, and red when it is set to move hash but its port is not open.

**Chains table.** One row per chain.

| Column | Meaning |
|---|---|
| State | An icon; see the table below. |
| Next-block cost | The expected number of hashes to find the chain's next block, from its network difficulty right now. |
| Weight | The weight saved for the chain. |
| Weighted cost | Next-block cost divided by weight. This is the figure the hopper ranks chains on, and the lowest is the best chain. The small line under it gives the chain's place ("Lowest", "Rank 2 of 3"). |
| Blocks / day | The blocks a day to expect on that chain at your hashrate: the hopper's own miners when it has any, otherwise the miners on the selected chains' own ports. |
| Against the best chain | Names the better chain: "WJK is 3.2% better" on the BTCS row means WJK's weighted cost is 3.2% below BTCS's, so a larger figure means a worse chain. The line under it says what that means for rigs on the chain (when they move, or that they stay) or, for a chain with no rigs, the cost it must fall below to take them. |
| Opportunity | The chain's average cost over the last day divided by its cost now. Above 1 means it is easier than usual. It is shown only; no switch uses it. It appears after 30 minutes. |
| Others' blocks | Blocks found by other miners inside the liveness window. |
| Rigs | The hopper rigs on that chain now. |

The config page's Chains card shows Next-block cost and Blocks / day as well, and has two columns of its own, **Suggested weight** and **Chosen now**; see [Choosing Weights](#choosing-weights).

The **State** column shows:

| State | Meaning |
|---|---|
| Eligible | The chain can be chosen now. |
| Not live | Other miners found too few blocks on it in the liveness window. It is passed over unless no chain passes that check. |
| Unhealthy | Its node is down, the coin is stopped, or there is no block template. Rigs on it are moved at once. |
| Can't take part | The coin's set-up doesn't allow it (it is not in DTM mode, for example). The reason is written under the icon. |

**Switch rules card.** The threshold and dwell in force, the values you configured, and what the install offset is doing.

**Miners table.** Each rig, the chain it is on, its hashrate and difficulty. **Shares** is what the hopper port has accepted from the rig since it connected, on every chain. A rig that has left the hopper port stays in the table, under the connected ones, with a red badge, for as long as the hopper has share records for it. The red ✕ deletes that one rig's hopper records. A rig's name opens its **details page**: hashrate history, share submissions, difficulty adjustments, its best share on any chain and the blocks it has found on every chain.

**Profiles table.** Under **Can mine**, each chain the profile has an address for. **Time and shares** is the time the profile's rigs have spent on that chain and the shares accepted there, counted since GoSlimStratum started.

**Hopping gain** (last column of the Profiles table) says whether hopping is paying:

- "+6.2% over DGB alone" is what hopping earned the profile, in expected block value, against a rig left on the one chain that would have done best alone. "1.4% behind DGB alone" means staying put would have done better.
- "+8.7% with perfect switching", beneath it, is what a hopper with no threshold, dwell or liveness check would have earned. The gap between the two lines is what those rules cost.
- It counts **expected** blocks, worked out from each chain's difficulty and your weights. It does not measure luck, and it is only as right as your weights.
- It appears after 30 minutes with a rig connected, and starts again when GoSlimStratum restarts, when you reset the miner statistics, or when you save a change to the chains, a weight, the switch rules or the profile's addresses.

**Blocks found card.** Every block the hopper's rigs have found, on all coins together, including orphaned blocks. It opens the hopper's **Block History** page: all those blocks in one list, newest first, each with its coin and links to that coin's explorer. There is no rewards total, because the blocks are paid in different coins.

**Switch Log.** The newest 500 switches, each with why it was made and how long the rigs had been on the previous chain. It is kept in memory and starts again when GoSlimStratum restarts; every switch is also written to the GoSlimStratum log.

**Miners card buttons.** Remove inactive miners (the trash can) and Reset all miner statistics (the circular arrows) act on the hopper's own records only. Blocks, earnings and the Switch Log are kept, and the records a rig left on the coins it mined are not touched; clear those from that coin's dashboard.

---

## What to Expect

- **A hopper rig appears in two places.** On the Hash Hopper page under its own name, and on the dashboard of the coin it is mining right now as worker `hopper.<profile>.<rig>`, with the Hash Hopper's rabbit badge after its name. When the hopper moves it, it shows as disconnected on the old coin and connected on the new one. That is the hopper at work, not a miner dropping.
- **The coin's figures include it.** A coin's active miner count, hashrate and block odds include a hopper rig while it is there.
- **Blocks and rewards are the coin's.** A block found through the hopper is on that coin's Blocks and Earnings pages, paid to the profile's address for that coin.
- **Notifications.** A rig on the hopper port sends the same miner connected and miner disconnected messages as a rig on a coin's port, under the hopper's symbol, when miner events are turned on. A move from one chain to another sends neither. Turning the hopper off, or saving a change that restarts its port, disconnects every rig and is reported.
- **Counts on the Hash Hopper page belong to the connection.** When a rig reconnects, its share count on the Miners table starts again.
- **The Switch Log needs rigs.** With shadow mode off, switches are logged for profiles that have a rig connected. In shadow mode, would-be switches are logged with no miners at all.
- **More database rows.** A hopper rig's shares are recorded twice: once under the hopper and once under the coin it is mining. The hopper port's default share target is also 10 seconds, against a coin port's 15. Together that is about three times the share rows the same rig would write on a coin's port at default settings. The number of chains makes no difference to this. The rows are pruned on the usual `share_retention_hours` window by the cleanup job.
- **Default Pool.** If you want the web UI to open on the Hash Hopper page, choose it as the Default Pool on the Global Config page.

---

## Common Questions

**Do I have to change anything on my miners when the hopper moves them?**
No. The miner stays connected to the hopper port and is simply sent work for the new chain.

**Can it hop to an outside pool, or to a coin I don't run a node for?**
No. It moves hash between coin pools in your own GoSlimStratum.

**Does it pick the most profitable coin?**
It picks the chain with the lowest weighted cost: the fewest expected hashes per block, adjusted by your weights. It has no price information. If you want it to follow value, put the value into the weights.

**Do weights have to be whole numbers, or at least 1?**
No. A weight is any number above 0, so `0.5` and `15.8` are fine.

**Two sets of weights look very different in size. Which is right?**
Both, if the proportions are the same. `1` / `2.5` / `16` and `6.25` / `15.625` / `100` make the hopper do exactly the same thing.

**Does my hashrate change which weights I should use?**
No. The choice between chains comes from their network difficulties and your weights. Your hashrate only sets how long a block takes.

**Why is it not on the chain the table says is best?**
Either the better chain is not yet better by the switch threshold, or the rigs have not been on their chain for the minimum dwell. The line under "Against the best chain" says which, and when they will move.

**A chain I selected shows "Can't take part". Why?**
The reason is under the icon. Most often the coin is not in Direct-to-Miner mode, is a merged-mining parent, is stopped, or has a different `extranonce_size`.

**A profile never mines one of my chains.**
The profile has no payout address for that chain. Add one.

**Can two profiles run at once?**
Yes. Each profile's rigs are chosen for separately, from the chains that profile has addresses for.

**Is shadow mode safe to leave on?**
Yes. It opens no port and moves no hash. It only scores the chains and logs what it would do.

**How do I stop hopping without unplugging anything?**
Turn the hopper off, or turn shadow mode on. Either closes the hopper port, so point the miners back at a coin's port. To keep them connected but on one chain, give that chain a weight far above the rest.
