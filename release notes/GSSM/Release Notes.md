# GSSM Release Notes
## v4.x Series

## v4.0.0

**Every miner now identifies itself.** You no longer pick a model when adding a miner: GSSM reads it from the device, and the dashboard and history show your actual hardware, such as Gamma 601, GammaHex 1300, Avalon Q, DG-Home1 or NMMiner. **NerdQAxe miners also show a hardware error rate**, and the miner detail page can break it down chip by chip. Plus every bar chart on the detail page now runs horizontally, and the comparison bars on Antminer charts are easier to see.

> **Action required only for NerdMiner firmware older than 2.0.** GSSM 4.0 supports NerdMiner firmware **2.0 and newer**. A NerdMiner on older firmware shows as offline with the message "NerdMiner firmware older than 2.0 isn't supported — update the firmware". Update the miner and it reappears on its own. Every other miner needs no action.
>
> The NerdQAxe error rate needs NerdQAxe++ firmware **1.1.1 or newer** (currently in beta). On older firmware, nothing changes.

### New Features

- **HW error % for NerdQAxe.** Bitaxe miners have always shown how much of their work is lost to hardware errors. NerdQAxe miners on firmware 1.1.1+ now show the same figure on their card, worked out the same way and coloured against the same thresholds, so the two are directly comparable.

- **Hashrate · By Chip and HW Errors · By Chip.** Two new cards in the **Mining Performance** section of the miner detail page, one row per chip:
  - **Hashrate · By Chip** shows how fast each chip is hashing, and turns a chip amber or red when it's out of step with the others.
  - **HW Errors · By Chip** shows each chip's error rate, with a line marking the miner's overall figure, and turns a chip amber or red when it errors more than its neighbours.

  Hover over a chip on either card to see both of its numbers together. It's a quick way to spot one chip that's struggling while the miner as a whole looks fine.

- **AxeOS miners identify themselves.** You no longer pick `bitaxe` or `nerdqaxe` when adding an AxeOS miner. GSSM asks the device which firmware it runs and which board it is, and shows the device's own name on the card and in Historicals:
  - Bitaxe boards show the board family and number, such as **Gamma 601**, **Gamma 602** or **GammaHex 1300**. Bitaxe firmware older than 2.9 doesn't report the family, so those show the board number, such as **Board 601**.
  - NerdQAxe-firmware boards show their own name, such as **NerdQAxe++**, **NerdOCTAXE-γ** or **Q1370**.

  The miner card also shows a new **HW Family** next to **HW Type**, such as **Gamma** beside **601**. NerdQAxe firmware doesn't report a board number, so those cards show only the family.

  The Historicals **Model** filter groups miners by this name, so a GammaHex no longer shares a group with a single-chip Gamma. New boards name themselves with no GSSM update needed.

- **Canaan miners identify themselves.** You no longer pick `avalonq` or `nano3s` when adding a Canaan miner. GSSM reads the model from the device, and the miner card shows its product name, **Avalon Q** or **Avalon Nano3s**, as **HW Family** next to **HW Type**. Historicals groups by the same name.

  The model setting was optional, and a Nano3s saved without one was treated like an Avalon Q: it showed no LED settings, used the generic Canaan temperature thresholds, and was offered standby it can't do. It now always gets its own settings and thresholds, and standby is offered only on the Avalon Q.

- **ElphaPex, Whatsminer, NerdMiner and CGMiner miners identify themselves.** There's no model to pick or type for these either. The card shows the device's own name as **HW Family**:
  - ElphaPex: **DG-Home1**, next to its hardware revision.
  - Whatsminer: the model, such as **M30S++**, with the hashboard variant, such as **VH70**, as **HW Type**. Historicals groups Whatsminers by both, so an M30S++ VH70 and an M30S++ VH40 stay separate.
  - NerdMiner: **NMMiner**.
  - CGMiner: the type the miner reports, such as **Antminer S9 (vnish 3.9.0)**.

- **No Model field on the Configuration page.** Since every miner now names itself, the Model column and the Model field when adding or editing a miner are gone.

### Improvements

- **Horizontal bar charts throughout the detail page.** Fans, per-board hashrate, temperature, frequency and chip counts, and per-domain hashrate now run horizontally, one row per fan, board or domain. They're easier to read and to hover.

- **Clearer comparison bars on Antminers.** The gray **Expected** bars on per-board hashrate and **PCB** bars on per-board temperature were hard to see against the dark background. They're brighter now.

### Good to know

- **The error rate moves from moment to moment.** The miner measures it over its last few seconds, so it can read 0.07% on one refresh and 0.3% on the next. That's normal, and it's the same for Bitaxe. Use the colours to see which chip stands out.

- **Older NerdQAxe firmware simply shows no error rate,** rather than a zero. GSSM checks each time, so the figure appears on its own once the miner is updated.

- **Your existing miners need no changes** (apart from NerdMiner firmware older than 2.0, above). The model you entered for any miner stays in your configuration but is no longer used. Each miner moves to its new name in Historicals, along with all of its history, on its first check after the upgrade.

- **Avalon Q standby and schedules work exactly as before,** and so does Nano3s automatic fan control.

- **The error rate and the per-chip cards now cover every NerdQAxe-firmware board,** including the Q1370 and Q1373.

---
