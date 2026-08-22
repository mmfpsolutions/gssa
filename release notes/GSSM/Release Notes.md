# GSSM Release Notes
## v3.x Series

## v3.1.1

**Two fixes for AxeOS miners**, both found while reviewing the AxeOS 2.15 firmware update.

> **No operator action required on upgrade.**

### Bug Fixes

- **Pool settings silently failed to save on Bitaxe running AxeOS 2.15 or newer.** The new firmware changed how pool settings are stored, and quietly ignored the old format — so GSSM reported "Settings saved" while the pool never actually changed. GSSM now detects which format your miner speaks and uses the right one. Older Bitaxe firmware and all NerdQAxe devices were never affected, and nothing else on the settings page was.

  If you changed a pool on a 2.15 Bitaxe through GSSM recently and it didn't take effect, this is why — please re-apply it.

### Improvements

- **Temperature alerts now watch the hottest chip on multi-ASIC miners.** On devices with more than one ASIC — such as the Bitaxe GammaHex — a protective trigger previously watched only the first chip's temperature. It now watches whichever is hottest, which is the one that matters. Single-ASIC miners are unchanged.

---

## v3.1.0

**Your Bitaxe and NerdQAxe can now be put to sleep — on a schedule, or automatically when they get too hot.** Standby, Schedules and Triggers previously only worked on Nano3s, Avalon Q and ElphaPex hardware. Now they work on the miners more people actually own.

> **No operator action required on upgrade.** New controls appear on supported miners; nothing changes until you use them.
>
> Standby, Schedules and Triggers require **Pro or Enterprise**.

### New Features

- **Standby / Wake for Bitaxe and NerdQAxe.** A Power control on the miner's settings page, the same one Avalon Q owners have had. Idling a Bitaxe drops it from about **20.6 W to 5 W**; a NerdQAxe drops to **almost nothing**. Both stay reachable the whole time, so GSSM keeps monitoring them and you can wake them from the dashboard.

- **Schedules.** Run overnight and idle through the expensive hours, or whatever fits your tariff — the same per-miner schedule editor, now offered on AxeOS hardware.

- **Protective triggers — the one worth having.** Set a temperature limit and GSSM idles the miner if it's exceeded for long enough, then holds it there until *you* release it. Previously impossible on a Bitaxe: the only option was a restart, which brings an overheating device straight back up hot.

### Good to know

- **Idled miners stop alerting.** GSSM reads the device's own paused state, so a miner you deliberately put to sleep won't fire "zero hashrate" warnings. That works even if you idled it from the miner's own web page rather than from GSSM.

- **Idle power still gets metered.** If you're using power tracking, the reduced draw is recorded like any other reading — so you can see exactly what your schedule saved you.

- **Bitaxe needs firmware v2.14.0 or newer.** Older firmware simply doesn't have the pause command; you'll get a clear error if you try. Most devices are well past this.

- **Waking a NerdQAxe restarts it.** That's how its firmware works — the shutdown can only be undone by a reboot. Nothing is lost, but expect the usual restart delay rather than an instant wake.

- **Neither survives a power cut.** If mains power drops while a miner is idled, it comes back mining. GSSM will re-apply a schedule at the next window, but it deliberately won't silently re-idle a device you may have just power-cycled on purpose.

- **Per-chip temperatures on multi-ASIC devices.** Miners with more than one ASIC — a Bitaxe GammaHex, or the NerdQAxe boards whose firmware reports it — now show a per-chip temperature grid on the miner card, colour-coded against your thresholds. It's the same grid Avalon Nano3s owners have had.

  Devices with a single ASIC are unchanged, and so are boards whose firmware doesn't actually report per-chip readings — GSSM shows nothing rather than a row of zeros.

### Bug Fixes

- **Bitaxe firmware version showed as "Unified"** after upgrading to AxeOS 2.15. GSSM was reading a field the new firmware repurposed as a label. It now reads the correct version on every AxeOS device.

---

## v3.0.12

**Know what your miners actually cost you in electricity — from records, not estimates.** GSSM can now meter each miner's energy use, keep a permanent daily record, and report it back for any date range — so when the tax year comes round the number is already there.

> **Off by default. No operator action required on upgrade** — nothing changes until you switch it on.
>
> Requires **Pro or Enterprise** and the optional Historicals database.

### New Features

- **Track power consumption.** A new toggle under *Historicals → Collection*. Once on, GSSM records **kWh per miner per day** from what your devices actually report, and keeps it. No fixed wattage guesses, no "hours × nameplate" arithmetic.

- **Your records are kept until you delete them.** Unlike the rest of Historicals, energy history is **never** aged out — not at 7 days, not at 90. It is the one thing GSSM stores that cannot be rebuilt afterwards, so nothing removes it but you.

- **A new Energy report page.** Under *Historicals → Energy*. Pick a period — **This month, Last month, Year to date, Last year**, or your own dates — and see total kWh for the fleet and a breakdown per miner, sorted by heaviest first. **Last year** is one click, which is the whole point come filing season.

- **Download it as a spreadsheet.** The CSV holds **one row per miner per day**, so you can apply whatever your electricity actually costs — tiered rates, seasonal rates, a mid-year price change — in Excel or Google Sheets. That's deliberately your job rather than GSSM's, because real tariffs are far more complicated than any single number we could ask you for.

- **Energy History in Data Management.** See what's stored per miner — total kWh, how many days, and the period covered — and delete one miner's history or all of it, both behind a confirmation.

### Good to know

- **It measures, it doesn't model.** GSSM reads each miner's real power draw every poll and adds it up. So a rig that sits in standby overnight on a schedule is recorded at its **actual** idle draw, and switching a miner from Low to High mid-afternoon is picked up the moment the wattage moves. Nothing needs teaching about work modes or schedules.

- **Idle time is not free, and now you can see it.** An ElphaPex DG-Home1 draws around 25 W asleep and an Avalon Q around 124 W — roughly 130 and 630 kWh a year respectively if they idle 14 hours a day. That is invisible to any hours-times-nameplate estimate.

- **When GSSM can't know, it records nothing rather than guessing.** If GSSM is stopped, if a miner is removed or disabled, or if a device doesn't report power at all (NerdMiner), that time is simply left unmeasured — never filled in with an assumption. Your totals may be slightly conservative; they will not be invented.

- **Every figure comes with its coverage, and its dates.** A total is shown as something like *"1,482.66 kWh · 96% measured · 2026-01-01 → 2026-12-31"*. That percentage is how much of the period GSSM was actually watching, so you can tell at a glance whether a number is solid or whether an outage left a hole in it. Miners GSSM has nothing recorded for say **not reported** rather than showing a misleading zero.

- **Miners you've since removed still count.** If you sold a rig in August, it still drew power in July — so it stays in the total, marked *no longer configured*, and the report tells you how many such miners are included.

- **Cost is shown, never stored.** If you've entered an electricity rate, the report multiplies it out as a convenience. But only the energy is kept, because rates change and a price baked into last year's records would simply be wrong. If your rate moved during the period, the CSV is the honest answer.

- **Start now, not in December.** Every month before you switch it on is a month that can't be recovered. Turn it on today and you have a full year of real figures by next filing season.

- **Energy is recorded, cost is not.** Rates change, and a rate baked into old records would be wrong the day it moved. Export the kWh and apply whatever rate you need in a spreadsheet. The Fleet page's cost estimate (v3.0.11) is separate and unchanged.

- **Devices that don't report power are still not counted.** A NerdMiner exposes no power figure at all, so it appears as *not reported* rather than being estimated. Letting you supply a wattage for such devices by hand is planned for a future release.

---

## v3.0.11

**What is this costing me to run?** Enter your electricity rate and the Fleet page shows an estimated running cost — for the whole fleet, and broken down per miner.

> **No operator action required on upgrade.** Nothing appears until you enter a rate.

### New Features

- **Electricity cost estimate on the Fleet page.** Set your cost per kWh under *Configuration → App Settings*, pick your currency, and the **Total Power** card gains an estimated cost per day, month and year. Free on every licence.

- **Per-miner breakdown.** A new **Estimated Cost by Miner** card lists every device sorted dearest first, with its power draw and daily and monthly cost — so "what's costing me the most?" is answered at a glance rather than worked out.

### Good to know

- **It's an estimate at what your miners are drawing right now**, not a bill. Multiply-out from the current moment: a fleet idling overnight on a schedule will project low, and a busy one high. Handy for a sense of scale, not for reconciling against your utility statement — real bills carry tiered rates, delivery charges and taxes that GSSM knows nothing about.

- **Some miners can't report their power draw.** NerdMiner devices don't expose it at all. Those appear in the table as *"not reported"* rather than being quietly dropped, and when any are present the fleet figure says so plainly — the real cost is **higher** than shown.

- **Idle, offline and disabled miners say why** they show no cost, instead of a misleading $0.00.

- **Currency is a label, not a conversion.** GSSM doesn't fetch exchange rates or convert anything; it just puts the right symbol next to your own number.

- **Leave the rate blank and nothing appears at all** — no empty card, no nag.

### Bug Fixes

- **Some configuration settings could silently fail to save.** The config page would report success while certain newer settings never actually reached disk. Fixed, with a guard so it can't happen to future settings either.

---

## v3.0.10

**Spot a miner that's fallen back to its backup pool, at a glance.** Its coin badge now carries an amber ring — on the dashboard cards, in the list view, and on the miner's detail page.

> **No operator action required on upgrade.**

### New Features

- **Failover ring on the coin badge.** When a miner is mining on its backup pool rather than its primary, the coin icon is ringed in amber. Hover or long-press it and the tooltip says so.

  Amber rather than red on purpose — running on backup is *degraded*, not broken. Your miner is still working, it's just not where you pointed it.

### Good to know

- **Miners with no ring are on their primary pool**, which is the normal case — there's no badge to learn, just an absence.
- **The ring often stays on, and that's the miner, not the display.** Most miners pick a pool at connect time and then stay there — nothing re-checks once the connection is healthy. So a device that failed over during a brief pool outage will happily sit on its backup for days after the primary is fine again. **Restarting it is what makes it retry the primary.** That's your call to make; GSSM won't do it behind your back, because if the primary is genuinely still down a restart just lands you back on the backup.

- **Dual-pool miners never show the ring.** On a NerdQAxe++ mining two coins at once, both pools are intentional, so "backup" doesn't mean anything there.

- **NerdMiner devices can't report this.** Their firmware only ever exposes a single pool, so there's no primary-versus-backup for GSSM to compare — those miners never show a ring, whatever they're connected to. Nothing to fix on our side; the information simply isn't there.
- **It costs no space.** The ring is drawn outside the badge, so nothing shifts and no column gets wider — which is exactly why it lives on the coin icon rather than becoming a fourth automation badge.

---

## v3.0.9

**See what's running your miners, from the dashboard.** Three small badges now sit beside each miner's coin icon showing which GSSM automations are driving it — no more opening a miner's details and digging through sub-pages to remember what you set up.

> **No operator action required on upgrade.** Nothing changes about how your miners behave; this only makes what you already configured visible.

### New Features

- **Automation badges on every miner view** — gallery cards, list rows, and the miner detail page:

  - A purple **clock** — a schedule is holding this device to a state by time of day.
  - An amber **bolt** — at least one trigger rule is armed.
  - A blue **snowflake** — automatic fan control is running.

  Hover or long-press any badge for what it means.

### Improvements

- **A badge only appears when something can actually happen.** A schedule that's switched on but has no windows, or triggers with every rule disabled, won't show one — those settings don't drive anything, and a badge for them would tell you a device is being managed when it isn't.

- **A held miner shows only the ⚡ Held badge.** When a protective trigger has idled a device, that's the one thing worth your attention, so the automation badges step aside rather than crowd it.

- **Disabled miners show no badges.** Automations don't run on a disabled device, so claiming otherwise would be misleading.

- **Offline miners keep theirs.** Knowing a device has a schedule is *more* useful when it isn't responding, not less.

- **The Standby badge moved next to the miner name**, so it no longer sits right beside the purple Schedule badge where the two could blur together.

### Bug Fixes

- **Miner cards fit properly on a phone now.** The card header — status, name, badges, coin, and the stats when collapsed — has been overflowing the screen even with short miner names. It now breaks into tidy rows: the **V1/V2 badge and name on the first line**, everything else on the second, with the action buttons alongside. Every card breaks in the same place regardless of name length, so the list reads evenly instead of each card wrapping differently.

- **Long miner names no longer run off the card.** They wrap to a second line instead of disappearing past the edge or colliding with the action buttons.

- **The list view no longer clips automation badges.** The coin column was a fixed width sized for a single coin icon, so a miner with two pools and all three automations had its badges cut off. The column now sizes itself to what's actually there — and it's fixed at every screen width, not just wide desktops.

- **Badges on the miner detail page are properly aligned** with the coin icon beside them, rather than sitting slightly low.

---

## v3.0.8

**Triggers** — have GSSM act on its own when something happens. Idle a miner that gets too hot, or reboot one every Sunday. Where a schedule keeps a device in a chosen state at chosen hours, a trigger handles the things you cannot put in a calendar.

> **No operator action required on upgrade.** Nothing acts on your miners unless you create a rule.

### New Features

- **Triggers — two kinds of rule, per miner** *(Pro/Enterprise)* — Open a miner's **Details** page and click the new **⚡ Triggers** badge. Pick the kind, and everything else follows:

  - **Protective** — *"Hottest chip above 97 °C for 3 minutes."* The miner is idled, and everything else stands down: its schedule and its other rules, until you release it. Something went wrong enough to stop the device, so it stays stopped until you have looked.
  - **Routine** — *"Sunday 03:00."* The miner restarts. Nothing else changes.

  There is no action to choose — each kind does one thing. GSSM works out how *your* device idles (standby on an Avalon Q, sleep mode on an ElphaPex), so the same rule reads correctly on both.

  > **Who this affects:** the Triggers badge appears on almost every miner GSSM supports, because nearly all of them can restart. **Protective** rules need somewhere to put the miner — a standby or sleep state — which today means an Avalon Q or an ElphaPex. The page tells you when your device cannot take one, rather than quietly leaving the option out.

- **Know when a rule acts.** A new **Trigger Fired** switch under *Notifications → Events → Miner Events* messages you whenever a rule does something — naming the miner, the rule, what set it off, and what was done — through the channels your miner alerts already use. Protective rules alert at critical severity; routine ones as information.

### Improvements

- **Every reading shows what the miner is doing right now, right in the list you pick it from** — *"Hottest chip temperature — now 96 °C"*. Setting a threshold without knowing what the device normally reports is guesswork, and this particular guess power-cycles hardware. It is the same reading GSSM compares your rule against, so what you see is what the rule sees.

- **Readings your miner does not report cannot be picked.** Not every device measures everything — a Bitaxe has no per-chip temperature. Those appear greyed out and marked *"not reported by this device"*, so you cannot build a rule that would quietly never fire. If you already have one, the page says so plainly.

- **A rule waits in minutes, not in "checks".** You set how long a temperature must stay high before the rule acts, and that means the same thing no matter how often GSSM polls your miners. The editor also tells you how fast a rule can actually react on your setup — and if that is slow, it points at the *Miner Check Interval* under Notifications → Polling, which is the setting that governs it.

- **A restart is skipped if the miner is already idle.** Restarting a sleeping device brings it back in whatever state its firmware defaults to — which would quietly undo a schedule that put it to sleep, or a protective hold. GSSM skips it and tells you, rather than doing it silently.

- **Holds — and a ⚡ Held badge, so a paused schedule always explains itself.** When a protective rule idles a miner, your schedule would otherwise wake it at the next window and undo the protection. Instead the miner is *held*, and the dashboard marks it. The Triggers page shows which rule did it, why, and when, with a **Release hold** button.

  > **Releasing is deliberately manual.** A device cools down *because* it is idle, so releasing automatically would let it warm straight back up and trip again. The hold also survives restarting GSSM — whatever caused it probably did too.

- **Reset firing history** — one button that clears cooldowns, the 24-hour fire counts, and any parked rules for a miner. The button you want after experimenting. It does not release an active hold.

- **The Triggers page shows GSSM's clock**, exactly as the Schedules page does, and warns you if the timezone is not set. A rule that fires at a time of day uses the app's time — so a "Sunday 03:00" reboot on a container with no timezone would quietly run at 3 AM UTC, and nothing would look wrong.

- **Temperature values for triggers are separate from your card thresholds**, on purpose. Adjusting what turns a card amber should never change the point at which a miner shuts itself down.

- **A new Help section** covering triggers vs schedules, the two kinds of rule, the guards, and holds.

### Good to know

- **Why so few choices?** Rules like *"hashrate below X → restart"* sound useful and are quietly dangerous: a miner that is booting, waking from sleep, or deliberately idle reports almost nothing, so the rule fires on perfectly healthy hardware. Every reading a trigger can watch is one that reads *low* when a device is not running, and rules only fire on a value going **above** yours — which makes that whole class of mistake impossible rather than merely unlikely. GSSM still **alerts** you about low hashrate; it just will not act on it.
- **Guards on every rule.** It fires on the change rather than every minute the condition holds; the temperature must stay high for the time you set; it re-arms only once things return to normal; and a rule that fires five times in 24 hours is parked and you are told.
- **Disabled and offline miners never fire triggers.** An unreachable device cannot act on a command it will not receive.
- **Set up triggers for a device on one GSSM instance only.** Two instances will each fire their own rules — restarting a miner twice, or arguing over whether it should be idle. GSSM reminds you when you switch triggers on.
- **Rules are checked on the same cycle GSSM already polls your miners**, so nothing new is asked of your devices.

---

## v3.0.7

A small hardening release for the **schedule timezone** introduced in 3.0.6 — making sure the zone you set is the zone you actually get, and that GSSM tells you plainly when it isn't.

> **No operator action required on upgrade.** If your schedules are already running at the right times, nothing changes.

### Improvements

- **Timezones now work even on a stripped-down host.** GSSM carries its own copy of the world timezone database, used only as a backup when the system it's running on doesn't provide one. Previously, if the zone data was missing, setting `TZ=America/Toronto` would silently fall back to **UTC** — your schedule would run flawlessly, just at the wrong hour, with nothing to indicate why. Your system's own timezone data is still preferred when present, so daylight-saving updates from your OS continue to apply as normal.

  > **Who this affects:** mainly anyone running GSSM outside the official Docker image, which already includes timezone data. It removes the possibility of the problem entirely rather than depending on the image to prevent it.

### Bug Fixes

- **A timezone that can't be loaded now says so, instead of looking correct.** If GSSM couldn't load the zone you asked for, the Schedule page would still display it back to you — `America/Toronto (UTC+00:00)` — which reads as properly configured while the schedule actually runs on UTC. That was the one thing the timezone display exists to catch, so it was precisely the wrong moment to be reassuring. The page now shows the zone GSSM **really** resolved, and distinguishes two different situations that both end up on UTC:

  - **No `TZ` set** — an amber note telling you to set one.
  - **`TZ` set but not loadable** — a red warning naming the value you asked for, so you can check the spelling against the IANA zone list (e.g. `America/Toronto`) or, if it's correct, look at the container's timezone data.

  > **Who this affects:** in practice, only installs without system timezone data — the official Docker image was never at risk. With the improvement above, this warning should now only appear for a genuinely mistyped zone name.

---

## v3.0.6

A feature release for **controlling** your miners, not just watching them: put a device into **standby** with one click, or set up a **schedule** that holds it in a chosen state by time of day — run overnight, idle on weekends, drop to a quieter work mode while you're asleep. Plus a fix, for everyone, that stops a deliberately-idled miner from firing false alarms.

> **No operator action required on upgrade.** Nothing in your configuration changes, and nothing starts controlling your miners unless you set it up. **If you do create a schedule**, please read the timezone note under *Good to know* first — it's the one thing that can quietly go wrong.

### New Features

- **Standby & Wake** *(Pro/Enterprise)* — Idle a miner without unplugging it. On the miner's **Settings** page, a new **Power** control puts the device into standby — mining stops, fans wind down, and power draw falls to a trickle (roughly **124 W** on an Avalon Q) — while it stays on the network so you can wake it again from the same screen. Handy for a hot afternoon, a noisy evening, or an expensive hour on your power tariff.

  > **Who this affects:** Avalon Q owners. Standby appears only on devices where GSSM can genuinely idle the hardware. Other miners reach the same result through their work mode — an ElphaPex DG-Home1's **Sleep** mode *is* its standby, and GSSM treats it as one.

- **Schedules — put your miners on a timer** *(Pro/Enterprise)* — Open any capable miner's **Details** page and click the new **Schedule** badge. Set a **resting state** (what you want most of the time) and add **windows** for the exceptions — each with its own name, days of the week, start and end times, and the state to hold while it's active. Windows can cross midnight, so "9 PM to 7 AM, every day" is a single window, and different days can do different things: full power midweek, quieter at weekends.

  What you can schedule depends on the device — **power** (run / standby) on an Avalon Q, and **work mode** on Avalon Q, Nano3s, and ElphaPex DG-Home1. The Schedule badge appears only where there's something to schedule, and each device only offers the modes it actually has.

  > **Who this affects:** anyone who'd rather not be at the keyboard at 9 PM every night. A schedule is per-device, so you can put one miner on a timer and leave the rest alone.

- **Know when your schedule fires.** A new **Schedule Applied** event under *Notifications → Events → Miner Events* sends a message whenever a schedule changes a device — naming the miner, the window responsible, and what was applied — through whichever channels your miner alerts already use (Telegram, email, webhooks, alert history). The same switch also tells you if a schedule **couldn't** apply, which is the more useful half: a schedule that silently never fires is otherwise invisible.

### Bug Fixes

- **An intentionally idled miner no longer sets off false alarms.** Putting a miner to sleep — for example, setting **Sleep** on an ElphaPex DG-Home1 — used to trigger a **Zero Hashrate** alert, because from the outside a sleeping miner looks exactly like one with dead hashboards: online, but hashing nothing. GSSM now recognises when a device reports itself deliberately idled and stays quiet, resuming normal alerting the moment it wakes.

  This works **however** the device was idled — GSSM's own schedule, the new Standby button, the manufacturer's app, or your own script — because it reads the state from the miner itself rather than tracking what it was told.

  > **Who this affects:** everyone, on any licence. If you've ever used ElphaPex Sleep mode and wondered why you got an alert, this is that.

### Improvements

- **Sleeping miners look asleep, not broken.** A miner that's intentionally idled now carries a **⏾ Standby** badge on its dashboard card and in the list view, so a device showing 0 H/s with stopped fans reads as "resting" at a glance instead of "something's wrong".

- **The schedule page shows you what your schedule will actually do.** Windows are flexible enough to overlap — that's how one window can set power while another adjusts work mode — so the editor spells out the result rather than leaving you to work it out. It marks which windows are **active now**, flags a setting that's **overridden** by another window, points out a window that has **no effect** at all, and asks about two windows that **nearly meet** — a short stretch between them where the device dips into the resting state and straight back out. It also shows the server's clock and the next change due, so you can confirm GSSM agrees with your intent before trusting it overnight.

- **A new Help section for all of this.** The in-app **Help** page (linked in the footer) gains a **Device Control** group covering Standby & Wake and Schedules — the resting-state model, a worked example, when changes actually happen, the timezone check, and what each on-screen note means.

### Good to know

- **Set your timezone before trusting a schedule.** Window times use the **server's** clock. If no `TZ` is set in your docker-compose, the container runs on **UTC** — so a "21:00" window still works perfectly, just at 9 PM UTC, and nothing looks wrong until you notice your miner sleeping at the wrong hour. Set it (for example `TZ=America/Toronto`) and restart. The Schedule page shows the timezone it resolved, the current app time, and the next change due, and warns you when `TZ` isn't set. Named zones handle daylight saving automatically.

- **Schedules change your miner only at window edges.** GSSM acts when a window opens or closes, and at no other time. In between, the device is yours — change its work mode by hand, use Standby/Wake, use the vendor app — and nothing will be undone until the next edge, when the schedule takes back over. Restarting GSSM doesn't disturb anything either: it adopts whatever state your devices are in and waits for the next edge.

- **Saving a schedule doesn't command the device.** Your changes take effect at the next window edge, so editing a schedule can't yank a running miner out from under you. Use the **Standby / Wake** buttons when you want something to happen right now. *(This also means you can't test a schedule by saving it in the middle of the window you just created — set one to start a couple of minutes out and watch it cross.)*

- **Schedule a miner from one GSSM instance only.** If two instances schedule the same device they'll each assert their own windows and fight over it — the same guidance that already applies to Auto Fan Control. GSSM reminds you when you switch a schedule on.

---

## v3.0.5

A quick fix for pools mining scrypt-based coins.

> **No operator action required on upgrade.**

### Bug Fixes

- **Correct "Best Share" for scrypt pools (Litecoin, Dogecoin, DigiByte-Scrypt).** On the pool card, the **Best Share** figure for scrypt-based coins was shown on Bitcoin's difficulty scale, making it read roughly **65,000× too large**. It's now scaled to the coin's own units, so it matches what you see on the pool's GoSlimStratum dashboard. SHA-256 coins (Bitcoin, Bitcoin Cash, and DigiByte's SHA-256 pools) were always correct and are unchanged.

---

## v3.0.4

A quick fix release on top of 3.0.3 — two small display corrections.

> **No operator action required on upgrade.**

### Bug Fixes

- **Configuration page names no longer disappear on hover.** With 3.0.3's new gradient titles, hovering a miner, pool, or node row on the Configuration page could briefly make its name vanish. Names now stay put on hover.

- **Pool coin badges show the correct coin.** A pool running on a coin *variant* — where the pool's internal coin key differs from its coin type — could show a **blank** coin badge instead of its icon (for example, a DigiByte pool showing no coin symbol at all). GSSM now takes the badge from the pool's configured **coin type**, so the right coin icon appears on both the pool card and the pool detail page.

---

## v3.0.3

A feature release for **ElphaPex (DG-Home1)** miners — previously monitor-only, they can now be **restarted** and have their **work mode** changed right from the dashboard — plus a small accuracy fix.

> **No operator action required on upgrade.**

### New Features

- **Restart ElphaPex (DG-Home1) miners from the dashboard.** ElphaPex miners now get the same **Restart** button (↻) that Bitaxe, NerdQAxe++, and Avalon devices already have — on the miner card, the list view, and the bulk-restart tool. Previously ElphaPex was monitor-only, so a reboot meant logging into each device's own web page; now you can restart one (or a whole batch) straight from GSSM.

- **Change ElphaPex (DG-Home1) work mode from the dashboard.** ElphaPex miners now have an editable **Work Mode** on their settings page — pick **Sleep**, **Low**, **Normal**, or **Overclock** and apply, without logging into the vendor's app. The miner card and detail page also show the current mode by name instead of a raw number.

  > **Heads-up:** **Overclock** significantly raises hashrate *and* power draw, and **Sleep** pauses mining — so both change how the rig behaves, not just a label.

### Bug Fixes

- **ElphaPex miners no longer show an inaccurate frequency.** The frequency shown for ElphaPex (DG-Home1) miners was based on a value the device doesn't actually report in MHz, so it read far lower than the real clock speed. Rather than display a misleading number, GSSM no longer shows a frequency for ElphaPex — the rest of the card (hashrate, temps, fans, pools) is unaffected.

### Improvements

- **A more polished, consistent look across the app.** Device names and section titles throughout GSSM — on the dashboard cards, the list views, the detail pages, and the configuration screens — now share the same subtle orange-to-amber gradient as the dashboard title, for a cleaner, more cohesive feel everywhere. Disabled devices show the same gradient, gently dimmed, so they stay easy to spot.

---

## v3.0.2

A fix release: correct miner **coin badges**, plus a reliability fix that stops false offline alerts on Bitaxe / NerdQAxe++ miners.

> **No operator action required on upgrade.** Nothing in your configuration changes.

### Bug Fixes

- **Fewer false offline alerts on Bitaxe & NerdQAxe++ miners.** On larger fleets, GSSM could report an AxeOS miner as offline — sometimes for many minutes — when it was actually mining fine, then send an "online" alert when it recovered. The cause was too many lingering network connections overwhelming the miner's small built-in web server until it briefly stopped responding. GSSM now closes each connection right after reading the miner (instead of holding it open) so it no longer ties up the device, and briefly retries a refused connection. This is on top of — and independent from — the alert-confirmation change in 3.0.1. Non-AxeOS miners (e.g. Avalon) were never affected.

  > **Who this affects:** anyone running several Bitaxe / NerdQAxe++ (AxeOS) miners, especially with a short dashboard refresh interval.

- **Miners on litecoinpool now show the right coin.** A miner pointed at litecoinpool.org (with a backup pool on another coin) could show the *backup* coin's badge — e.g. an LTC miner labeled **DGB**. GSSM now recognizes litecoinpool from its address and shows **LTC**, and the badge follows the pool the miner is *actually* connected to, so a failover to a different-coin pool moves the badge with it instead of a disconnected backup hijacking it.

  > **Who this affects:** anyone whose miner logs into a pool with an account-style username (like litecoinpool.org's `account.worker`) rather than a wallet address, especially with a different-coin backup configured.

### Improvements

- **A default badge when the coin can't be determined.** If GSSM genuinely can't tell which coin a miner is on, it now shows a neutral placeholder badge instead of a blank gap — so every miner keeps a consistent coin slot. (An offline miner shows it too, since there's no pool to read a coin from.)

- **Dual-mining badges are steadier.** For NerdQAxe++ devices mining two coins at once, both coin badges now stay put even if one of the two pools briefly disconnects — no more flicker between the dual and single display.

---

## v3.0.1

A focused follow-up to 3.0.0 that hardens how GSSM watches your miners and nodes: accurate failover status on AxeOS devices, far fewer false offline/online alerts, faster alert checks for larger setups, and a greatly expanded in-app Help page.

> **No operator action required on upgrade.** These are reliability fixes and improvements — nothing in your configuration changes.

### Bug Fixes

- **Accurate failover status on AxeOS miners (NerdQAxe++ & Bitaxe).** The miner card now correctly shows when a device is mining on its **backup pool** — previously a NerdQAxe++ always read *Failover: false* even after it had switched over. And the pool-switch notification now fires in **both** directions: when a miner fails over to its backup **and** when it moves back to its primary (it used to only alert on the way out).

  > **Who this affects:** anyone running AxeOS miners (Bitaxe / NerdQAxe++) with a primary + fallback pool configured.

- **Far fewer false "miner offline / online" alerts.** Some miners — NerdQAxe++ especially — occasionally answer slowly or briefly hang their API, which could make GSSM think a perfectly healthy miner had dropped and fire an offline-then-online alert pair. Two changes fix this:
  - **A longer response window for AxeOS miners** — 5 seconds (up from 3) before a check counts as a miss.
  - **A confirmation step** — a miner must now miss **two checks in a row** before an offline alert is sent. A single slow or hung check is absorbed silently, so one blip no longer pages you.

### Improvements

- **Faster, more reliable alert checks on larger setups.** GSSM now checks your **miners and crypto nodes in parallel** instead of one at a time. Previously, on a fleet of 20+ devices, a handful of slow or unresponsive ones could stretch a check cycle past its interval. Now a cycle is bounded by your *slowest* device, not the sum of all of them — so big fleets stay comfortably within their check window even when some devices are misbehaving. (Pools were already fast and are unchanged.)

- **Expanded Help & Reference page.** The in-app **Help** page (linked in the footer) is now a full visual guide: sample miner, pool, and crypto-node cards, plus field-by-field references for every Configuration, Notifications, and Historicals setting — all styled to match your dashboard, with a quick sidebar to jump around.

- **Consistent crypto-node logging.** Node checks now appear in the debug log — cycle start, per-node status, and event dispatch — matching what miners and pools already logged. If you ever turn on debug logging to troubleshoot a node, it now tells the same story as the rest of the dashboard.

### Good to know

- **Offline alerts are now confirmed over two check cycles.** That's the trade-off for killing the false alerts: a genuine outage is reported one check interval later than before (about a minute at default settings). Your **history and trends are unaffected** — the raw offline reading is still recorded; only the *alert* waits for confirmation.

---

## v3.0.0

Our biggest release yet. The headline is **Historicals** — an optional, Pro/Enterprise history database that gives your live dashboard a memory: trend charts, all-time best shares that survive reboots, and a searchable alert history. Alongside it: a new **Health** page, support for **two new coins** (Bitcoin Cash II and Bitcoin Silver), a richer pool and crypto-node detail experience (new charts, sortable tables, more of what your node actually knows), and a top-to-bottom **consistency and accuracy pass** across every miner, pool, and node — the card, the detail page, and your alerts now all read from one source, so they can't disagree, and details some devices reported all along but GSSM used to quietly drop now show up. There's a good round of bug fixes too, including one that stops a healthy node from spamming you with false offline alerts.

> **No operator action required on upgrade.** GSSM stays exactly as it is unless you choose to turn something on. Historicals is **off by default**, and with it off GSSM remains fully stateless and in-memory — behaving just like the 2.x series. Nothing in your `config.json` is rewritten when you upgrade.

### New Features

- **Historicals — optional mining history and trends** *(Pro/Enterprise)* — GSSM has always been live-only, showing you the current moment and nothing more. Historicals adds an optional history layer, backed by your own PostgreSQL database, that persists miner telemetry and lifetime records so you can look *back*, not just *now*.

  > **Who this affects:** only Pro/Enterprise users who choose to connect a database. If you don't turn Historicals on, nothing changes — GSSM stays stateless and in-memory, exactly as before.

  - **Turn it on from a config page** — a new **Historicals** configuration page (with a matching card on the main Configuration page). Enter your database connection details, use the **Test Connection** button to verify them, and — if you'd like — let the one-time first-run helper create the database for you. Enabling, disabling, or re-pointing the database applies live, with no restart.

  - **Fleet trend charts** — a new **Historicals → Miners** page with per-miner line charts for hashrate, temperature, fan RPM, assigned difficulty, and session best-share. Filter by device type and model, and pick the time range you want to see.

  - **All-time best share that survives reboots** — the miner detail page now shows a **Best (lifetime)** value. For miners that don't track their own all-time best, GSSM remembers it for them (shown in an emerald "tracked" color). A nice side effect: an offline miner keeps showing its last known best instead of going blank, then hands back to the device when it returns.

  - **Searchable alert history** — a new **Historicals → Notifications** timeline records every notification (offline, failover, temperature, and so on) so you can filter and review exactly what happened and when — per miner, pool, or node. Each detail page deep-links to its own history via a 🔔 link.

  - **You stay in control of the data** — the Historicals config page lists per-miner record counts and lets you reset a best or remove a miner's data. History is automatically trimmed to a retention window you set (default 7 days for detailed metrics, 90 days for alert history).

- **Health page** — a new **Health** page, linked in the footer next to the version, shows GSSM's own vitals at a glance: uptime, memory use, which services are running, how many miners/pools/nodes are online, and — when Historicals is connected — database size and statistics.

- **Pool detail page — charts** — the pool detail page now graphs **Blocks Found per day** and daily **Earnings**. For litecoinpool, LTC and DOGE earnings render as two separate charts so one currency doesn't dwarf the other.

- **Pool detail page — sortable tables** — **Workers**, **Blocks**, and **Payments** are now full tables with every column sortable and Prev/Next paging. Values a given pool doesn't provide show as **N/A** rather than blank.

- **Crypto node detail — more of what your node knows** — several new sections surface information your daemon reports:
  - **Mempool** — pending transaction count and size, as a node-health signal.
  - **Upload Target** — bandwidth-budget tracking (target, reached, bytes and time left), or **"Unlimited"** when no limit is set.
  - **Per-wallet balances** — each wallet listed by name and balance, instead of a single lumped total.
  - **Deployments** — a table tracking soft-fork activation status (the future home for DigiByte **DigiDollar** tracking).
  - **Peer Analysis** — a new card with four charts (Version Distribution, Connection Types, Peer Latency, Bandwidth) plus a richer peers table.
  - **Sortable tables** — Algorithms, Peers, Transactions, and Deployments are all sortable, with sensible default sorts.

- **litecoinpool card details** — litecoinpool cards now show the PPS ratio and fee, whole-pool miners and hashrate, dual LTC/DOGE earnings, and a **"Last Payment"** line.

- **Two new coins — Bitcoin Cash II (BCH2) and Bitcoin Silver (BTCS)** — both are now selectable as a GoSlimStratum pool and as a crypto node in the configuration dropdowns, each with its own coin icon across the card, detail, and list views. For miners, GSSM auto-detects these coins from the wallet address — BCH2 from its `bitcoincashii:` prefix, and BTCS from its `bs1…` / `tbs1…` format.

### Improvements

- **One consistent source for every miner, pool, and node** — under the hood, GSSM now reads each device through a single shared path, so the **dashboard card, the detail page, and your alerts always agree**. Two things you'll notice: values that used to occasionally disagree between the card and the detail page now match, and details a device reported all along but GSSM used to silently drop — like found-blocks on the Avalon Nano3s — now appear.

- **Offline devices explain themselves** — an offline miner, pool, or node now shows a short, plain reason for being down (unreachable, timeout, authentication failed, still loading, and so on) right on its card, instead of a wall of "--". Because each card is now its own error surface, the old yellow "Partial Results" banner is gone.

- **Cleaner, unified pool and node cards** — pools now share one card design regardless of source, and nodes share one design regardless of coin (the old DigiByte-specific special-casing is gone). Rows that don't apply to a given device simply don't appear. Enabling or disabling a pool or node updates the card **in place, without a full page reload**.

- **Cleaner detail summaries** — the pool detail page leads with 4 focused summary cards (Active Miners, Hashrate, Blocks Found, Total Paid); the node detail page leads with 6 (Block Height, Difficulty, Connections, Balance, Disk Size, Version). The old raw-JSON dump card on the node detail page is gone in favor of the readable, typed view.

- **Safer miner settings saves** — saving settings to AxeOS devices (Bitaxe / NerdQAxe++) is now hardened so a mistyped value can't accidentally reset the device, and renaming a device's hostname no longer looks like a failed save while the device re-registers on the network.

- **Accepted vs rejected shares are color-coded** — accepted in green, rejected in red — everywhere shares appear: the miners list, every expanded card, the detail page, and per-pool rows.

- **A cleaner separator for paired values** — two-value readouts (such as accepted·rejected shares or a best-diff pair) now use a middle dot (`·`) instead of a slash, so they're easier to read at a glance.

- **Feature discovery on the Configuration page** — the Notifications and Historicals cards now show for everyone, with a small **"PRO"** tag when unlicensed, so you can see what's available. The feature pages themselves stay license-gated.

- **Clearer pool labels** — a matured, spendable block now reads **"SPENDABLE"** instead of an internal status code, and the payments count now reflects the real number of payments.

### Bug Fixes

- **Healthy nodes no longer flap between online and offline** — some nodes (worst on Bitcoin Cash) were toggling offline → online roughly every 30 seconds and firing a stream of false alerts. A healthy node now stays steady, and only reports a transition when something real happens.

- **Idle pools now show as online** — a configured pool with no miners on it (for example, a standby BCH pool) was being mislabeled as offline and could fire false alerts. It now correctly reads online.

- **Correct difficulty on multi-algo coins** — on coins like DigiByte that mine with multiple algorithms, the card and alerts now always read the difficulty for the algorithm you configured (a subtle case-sensitivity slip could previously make it read the wrong one).

- **Correct block timing on the pool detail page** — the detail page no longer mixes up "time since the last block" with "expected time between blocks." Each pool now shows the right one.

- **Node warnings show on modern daemons** — warning messages from newer daemons (Bitcoin Core 29+) now display correctly, alongside older ones.

- **GSSM never overwrites a config it can't read** — if your `config.json` has a typo or a permission problem at startup, GSSM now stops with a clear message and leaves your file **untouched**, instead of quietly replacing it with a blank default. Previously, a single typo could wipe your whole configuration.

### Good to know

- **Historicals is entirely optional and Pro/Enterprise.** With it off (the default), GSSM is fully stateless — no database, no history, no behavior change from 2.x. Turning it on requires a PostgreSQL database that you provide.

- **Pool alerts are GoSlimStratum-only for now** — offline/online alerts for litecoinpool pools aren't wired up yet.

- **New node details are shown, not yet alerted on** — mempool, deployments, and the rest now appear on the dashboard, but new alert types (such as block-height-stuck or DigiDollar activation) are a follow-up.

- **Detail tables show the most recent 100 rows** — the Workers / Blocks / Payments tables and the node tables page through the latest 100 entries.

- **A few miner wallet formats can't be auto-detected.** A bare BCH2 address (no prefix) falls back to showing as **BCH**, and a legacy BTCS address falls back to **BTC**, because those older formats carry no distinguishing marker. The common prefixed / Bech32 forms detect correctly — and this only affects miners, since pools and nodes select their coin explicitly.

---
