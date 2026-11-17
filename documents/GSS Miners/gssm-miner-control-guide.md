# GSS Miners (GSSM) Miner Control Guide

How GSSM changes what a miner is doing: restart, device settings, Standby and Wake, Schedules, Triggers and Auto Fan Control.

*Current for GSS Miners 5.1.0.*

See also the [Configuration Guide](gssm-config-guide.md), the [Notifications Guide](gssm-notifications-guide.md) and the [Troubleshooting Guide](gssm-troubleshooting-guide.md).

---

## Summary

GSSM mostly watches. These are the things it can do to a miner, and only when you ask or set them up:

| Feature | What it does | License |
|---|---|---|
| Restart, Bulk Restart | Reboots a miner, or a batch of them | Any |
| Settings page | Changes the device's own settings | Any |
| Standby / Wake | Idles a miner now, and wakes it | Pro or Enterprise |
| Schedules | Holds a miner in a chosen state by time of day | Pro or Enterprise |
| Triggers | Acts when something happens: idle a hot miner, alert on a stopped fan, restart weekly | Pro or Enterprise |
| Auto Fan Control | Runs an Avalon Nano3s's fan to a target temperature | Pro or Enterprise |

These rules apply to all of them:

- **Each device only offers what its firmware can do.** A control that a device cannot support does not appear, or appears greyed out with the reason. The table in the Configuration Guide ("Device Types") lists what each family supports.
- **Control a miner from one GSSM install.** Two installs that both schedule, trigger or fan-control the same miner will fight over it. Any number of installs can monitor it.
- **`disableSettings: true` in `config.json` blocks every change made from the web UI:** restart, device settings, Standby and Wake, fan control, and editing schedules and triggers. A schedule, trigger or Auto Fan Control that is already set up keeps running.
- **A disabled miner is never acted on.**

Schedules and triggers are saved inside each miner's entry in `config.json`. You set them up in the web UI; the JSON is shown below so the file can be read, not so it can be written by hand.

---

## Restart and Bulk Restart

Miners that can be restarted have a restart button (↻) on their card and in the list view: AxeOS (Bitaxe, NerdQAxe), Canaan, ElphaPex and NerdMiner. Antminers and other CGMiner devices, and Whatsminers, are monitor-only.

**Bulk Restart** (a link on the Miners page) opens a page where you tick the miners to restart and restart them together.

---

## The Settings Page

A miner's **Settings** page (the **Settings** link on its **Details** page) shows the settings its firmware exposes and writes changes to the device. What is there depends on the device:

- **Bitaxe and NerdQAxe:** device, network, pool and tuning settings.
- **Avalon Q and Avalon Nano3s:** work mode; on a Nano3s also the LED and the fan.
- **ElphaPex DG-Home1:** work mode (**Sleep**, **Low**, **Normal**, **Overclock**).
- **NerdMiner:** its own settings.
- **Antminer / CGMiner and Whatsminer:** no settings page.

Good to know:

- **Pool settings on a Bitaxe with AxeOS 2.15 or newer** are saved correctly from GSSM v3.1.1. Before that, GSSM said "Settings saved" and the pool did not change.
- **Overclock** on an ElphaPex raises hashrate and power draw; **Sleep** stops mining.

---

## Standby and Wake

*v3.0.6+ (Avalon Q), v3.1.0+ (Bitaxe and NerdQAxe).*

Standby idles a miner without unplugging it. Mining stops and power draw falls, and the miner stays on the network so GSSM keeps watching it and can wake it. The control is the **Power** card on the miner's Settings page.

| Device | In standby | Notes |
|---|---|---|
| Avalon Q | About 124 W, fans stop | |
| Bitaxe | About 5 W (from about 20 W) | Needs Bitaxe firmware v2.14.0 or newer. Older firmware gives a clear error. |
| NerdQAxe | Almost nothing | **Waking it restarts it.** That is how its firmware works; expect the usual restart delay. |
| ElphaPex DG-Home1 | About 25 W | No Power card: its **Sleep** work mode is its standby, and GSSM treats it as one. |

Avalon Nano3s, NerdMiner, Antminers and Whatsminers have no standby.

What to expect:

- **The Power card shows the miner's real state**, read from the miner. It stays right when something else idled the miner: the vendor's app, a script or a schedule.
- **An idled miner does not raise alarms.** While a miner reports itself idled, Zero Hashrate and Offline alerts are held back for it, and its card shows a **Standby** badge. This works however it was idled. Alerts start again when it wakes.
- **Standby does not survive a power cut.** If the power drops while a miner is idled, it comes back mining.
- **Standby is not permanent if a schedule is running.** A change made by hand holds until the schedule's next window edge, then the schedule takes over again. To idle a miner indefinitely, turn its schedule off or disable the miner.

---

## Schedules

*v3.0.6+. Open a miner's **Details** page and click the **Schedule** badge. The badge only appears on a miner that has something to schedule.*

A schedule holds a miner in a chosen state by time of day: run overnight, idle at the weekend, drop to a quieter work mode while you sleep.

What can be scheduled:

| Device | Power (`run` / `standby`) | Work mode |
|---|:-:|:-:|
| Avalon Q | Yes | Yes |
| Avalon Nano3s | No | Yes |
| ElphaPex DG-Home1 | No | Yes (Sleep is its standby) |
| Bitaxe, NerdQAxe | Yes | No |

### The model

**Resting state** is what you want most of the time. **Windows** are the exceptions.

A window says: between these hours, on these days, hold the miner like this. Outside every window, the resting state applies.

Example, "mine flat out overnight, idle during the day":

- Resting state: Power **Standby**
- Window "Overnight": every day, 21:00 to 07:00, Power **Run**, Work Mode **High**

At 21:00 the window opens and the miner runs at High. At 07:00 it closes and the miner idles until the evening. The same thing can be written the other way round: resting state Run, and a Standby window for the daytime.

> **With no resting state, nothing takes the miner back.** A "Run" window can start the miner, but when the window closes the schedule has no opinion, so the miner keeps running. If you want the schedule in charge all day, set a resting state.

### How settings are decided

- **Each setting is decided by itself.** For power, and separately for work mode: the last window in the list that sets it wins; if no open window sets it, the resting state does; if neither does, GSSM leaves it alone. So one window can set power while another sets work mode.
- **The resting state also applies while a window is open**, for anything the window does not set.
- **"Leave alone" is a real choice.** It means the schedule has no opinion on that setting.
- **An idle miner ignores other settings.** When the result is Standby, GSSM only sends the power command.

### When changes happen

- **Only at window edges.** GSSM acts when a window opens or closes, and at no other time. In between, the miner is yours: change it by hand, use Standby and Wake, use the vendor's app. Nothing is undone until the next edge.
- **Saving a schedule does not change the miner.** It takes effect at the next window edge. To make something happen now, use Standby and Wake.
- **To test a schedule**, set a window to start a couple of minutes from now and watch it cross. Saving inside a window you just created does nothing until the next edge.
- **Restarting GSSM changes nothing.** GSSM takes the miners as it finds them and waits for the next edge. An edge that passed while GSSM was stopped is not applied afterwards.
- **A miner that cannot be reached at an edge** gets the change as soon as it can be reached. GSSM keeps trying.

### Timezone: check this first

Window times use the server's clock. With no `TZ` set for the GSSM container, that clock is UTC, and a "21:00" window runs at 9 PM UTC. Nothing looks wrong until the miner sleeps at the wrong hour.

The Schedule page shows the timezone GSSM is using, its current time and the next change due. Compare that with your own clock before trusting a schedule. See "Timezone" in the [Configuration Guide](gssm-config-guide.md) for how to set it.

- An amber note means no `TZ` is set.
- A red warning means `TZ` is set but could not be loaded, and names the value; check its spelling against the zone list (for example `America/Toronto`).

### What the page tells you

Windows may overlap on purpose. The editor says what the result is:

- **Active now:** this window is in force.
- **Overridden by "…":** another window wins this setting.
- **This window has no effect:** everything it sets is decided elsewhere.
- **Windows that nearly meet:** two windows leave a short gap, so the miner drops to the resting state and straight back. Make them meet (07:00 to 07:00) if that was not intended.

### Being told

Turn on **Schedule Applied** under Notifications → Events → Miner Events. You get a message each time a schedule changes a miner, and one message when a schedule cannot be applied.

### In `config.json`

```json
"schedule": {
    "enabled": true,
    "base": { "power": "standby" },
    "windows": [
        {
            "id": "wN4kR8tZ",
            "name": "Overnight",
            "enabled": true,
            "days": ["all"],
            "start": "21:00",
            "end": "07:00",
            "set": { "power": "run", "workmode": "High" }
        }
    ]
}
```

| Field | Description |
|---|---|
| `enabled` | The schedule's on/off switch. Off keeps the schedule without running it. |
| `base` | The resting state: settings to hold outside every window. |
| `windows[].id` | Generated for you. |
| `windows[].name` | Required. The name used in the log, in messages and on the page. |
| `windows[].enabled` | Turn one window off without deleting it. |
| `windows[].days` | `"mon"` to `"sun"`, or `["all"]`. A window that crosses midnight belongs to the day it starts on. |
| `windows[].start`, `windows[].end` | `"HH:MM"`, on the server's clock. An `end` earlier than `start` crosses midnight. They cannot be equal; use `00:00` to `23:59` for a full day. |
| `windows[].set` | The settings to hold while the window is open. |

Settings in `base` and `set`: `power` is `"run"` or `"standby"`; `workmode` is the mode's name as the device's Settings page shows it (for example `"Low"`, `"High"`, `"Sleep"`).

---

## Triggers

*v3.0.8+; cooling rules and alert-only rules v3.2.0+. Open a miner's **Details** page and click the **Triggers** badge.*

A schedule says what state a miner should be **in**. A trigger says what to **do** when something happens.

There are two kinds of rule, and choosing the kind decides the rest.

### Protective rules

A protective rule watches a reading. When the reading stays past your value for the number of minutes you set (3 unless you change it), the rule fires.

What a rule can watch:

| Reading | Fires when it goes | Notes |
|---|---|---|
| Hottest chip temperature | above your value | On a miner with several chips, the hottest one. |
| Temperature | above your value | The miner's main temperature. |
| Fan speed (RPM) | above **or below** your value | One fan per rule. Catches a fan or pump that has stopped (it reads 0), or a pump with air in it (it spins faster). |
| Fan duty (%) | above your value | One fan per rule. How hard the fan is being asked to work. A fan held near 100% means cooling is at its limit. |

What a rule does when it fires. You choose one:

- **Standby and hold its schedule.** The miner is idled and held (see "Holds" below). Offered on a miner that can be idled: Avalon Q, Bitaxe, NerdQAxe and ElphaPex.
- **Alert and take no action.** GSSM tells you and leaves the miner alone. Offered on every miner, including Antminers, Whatsminers and the Avalon Nano3s.

Where a miner cannot be idled, the Standby choice is shown greyed out with the reason. GSSM does not offer a restart in its place: restarting an overheating miner brings it straight back up hot.

Good to know about fan rules:

- **GSSM cannot tell a fan from a pump.** It sees a speed on a fan header. Name the rule after what is plugged in ("Pump stalled").
- **Only fans that report a speed can be watched.** Many boards read the speed of one header only. A Bitaxe GammaHex with two fans and a pump reports only what is on header 1.
- **A "below" rule is not checked while the miner is in standby**, because an idle miner slows or stops its fans on purpose. After it wakes, the reading must stay low for your full number of minutes before the rule can fire.
- **A "below" rule detects a fan that has stopped, not one that is a little slow.** Most fans stop slowing down below about a third of full duty, so the value must sit under that.
- **For a pump you want between two speeds, add two rules.** One rule makes one comparison.

### Routine rules

A routine rule restarts the miner at a time of day, on the days you choose ("Sunday 03:00"). Nothing else changes. Offered on a miner that can be restarted.

- **A restart is skipped if the miner is idle**, because restarting would undo the schedule or the hold that idled it. The page says it was skipped.
- **The time is on the server's clock.** The Triggers page shows GSSM's clock and warns when the timezone is not set, the same as the Schedule page.

### Why there are so few choices

A rule like "hashrate below X, restart" sounds useful and is dangerous: a miner that is starting up, waking or idle reports almost nothing, so the rule would fire on healthy hardware. Every reading a trigger can watch reads low when a miner is not running, and rules fire on a value going **above** yours. Fan speed is the one reading that can also be watched going below, with the standby guard described above. GSSM still alerts on low hashrate (the Zero Hashrate alert); it does not act on it.

**The values in a rule are separate from the card thresholds.** Changing what turns a card amber never changes when a miner is idled.

### Guards on every rule

- **It fires on the change.** Once, when the reading goes past your value. Not on every check while it stays there.
- **It waits.** The reading must stay past your value for the minutes you set. That is real time, whatever the check interval.
- **It re-arms only when the reading comes back** inside your value.
- **An alert-only rule stays quiet for a while after it fires:** 60 minutes unless you change it.
- **A rule that acts on the miner is parked after five firings in 24 hours**, and you are told. Re-enable it on the Triggers page once you have looked into the cause. Alert-only rules are never parked.
- **Disabled and offline miners never fire triggers.**

**Reset firing history** on the Triggers page clears the quiet periods, the 24-hour counts and any parked rules. It does not release a hold.

**How fast a rule can act.** Rules are checked on GSSM's background miner check, so that interval is the fastest a rule can react. The rule editor shows the figure for your install. To make it faster, lower the **Miner Check Interval** under Notifications → Polling.

### Holds

When a protective rule idles a miner, the miner is **held**: its schedule leaves it alone, and so do its other rules, until you release it. Without a hold, the schedule would wake the miner at the next window and undo the protection.

- A held miner is marked **Held** on the dashboard.
- The Triggers page shows which rule did it, why and when, with a **Release hold** button.
- **Releasing is by hand only.** A miner cools down because it is idle, so releasing by itself would let it heat up and trip again.
- **A hold survives a GSSM restart.**

### Being told

Turn on **Trigger Fired** under Notifications → Events → Miner Events. You get a message when a rule fires, and when a rule is parked. Protective rules alert as critical, whether they idled the miner or only alerted; routine restarts as information.

### In `config.json`

```json
"triggers": {
    "enabled": true,
    "rules": [
        {
            "id": "pT6vB3nM",
            "name": "Too hot",
            "category": "critical",
            "enabled": true,
            "when": { "type": "metric", "metric": "chipTemp", "op": ">", "value": 97, "forMinutes": 3 },
            "do": { "action": "idle" },
            "holdSchedule": true
        },
        {
            "id": "rF2cX9hJ",
            "name": "Pump stalled",
            "category": "critical",
            "enabled": true,
            "when": { "type": "metric", "metric": "fanRPM", "fan": 1, "op": "<", "value": 500, "forMinutes": 3 },
            "do": { "action": "alert" },
            "cooldownMinutes": 60
        },
        {
            "id": "sD8wQ4yL",
            "name": "Weekly restart",
            "category": "nominal",
            "enabled": true,
            "when": { "type": "time", "days": ["sun"], "at": "03:00" },
            "do": { "action": "restart" }
        }
    ]
}
```

| Field | Description |
|---|---|
| `enabled` | On/off switch for all of this miner's rules. |
| `rules[].id` | Generated for you. |
| `rules[].name` | Required. Used in the log, in messages and on the Held badge. |
| `rules[].category` | `"critical"` for a protective rule, `"nominal"` for a routine rule. |
| `rules[].enabled` | Turn one rule off without deleting it. |
| `rules[].when.type` | `"metric"` (protective) or `"time"` (routine). |
| `rules[].when.metric` | `"chipTemp"`, `"temperature"`, `"fanRPM"` or `"fanPercent"`. |
| `rules[].when.fan` | Which fan, `1` to `4`. For `fanRPM` and `fanPercent` only. |
| `rules[].when.op` | `">"` or `">="`. For `fanRPM` also `"<"` or `"<="`. |
| `rules[].when.value` | The value to compare with. |
| `rules[].when.forMinutes` | Minutes the reading must stay past the value. Default `3`. |
| `rules[].when.days`, `rules[].when.at` | For a routine rule: the days (`"mon"` to `"sun"`, or `"all"`) and the time, `"HH:MM"`. |
| `rules[].do.action` | `"idle"` or `"alert"` for a protective rule; `"restart"` for a routine rule. |
| `rules[].holdSchedule` | Set by GSSM: `true` when the rule idles the miner. |
| `rules[].cooldownMinutes` | The quiet period after the rule fires. Shown in the editor for alert-only rules; default `60`. |
| `hold`, `state` | Written by GSSM: the current hold, and each rule's firing history. Do not edit them. |

---

## Auto Fan Control

*For the Avalon Nano3s. On the miner's Settings page, in the Fan Control section.*

The Fan Control section sets the Nano3s's fan three ways: the device's own automatic mode, a fixed speed, or **GSSM Auto Fan Control**, where GSSM adjusts the fan to hold a temperature you choose.

| Setting | Default | Range | Description |
|---|:-:|:-:|---|
| Target Temperature | 90 °C | 40 to 95 | The average chip temperature GSSM aims for. |
| Minimum Fan Speed | 30% | 30 to 80 | The fan never goes below this. |
| Emergency Temp | 100 °C | 85 to 110 | If the hottest chip reaches this, the fan goes to 100% until it drops back. Must be higher than the target. |

In `config.json` these are saved in the miner's entry:

```json
"fanControl": {
    "enabled": true,
    "targetTemp": 90,
    "minFanSpeed": 30,
    "emergencyTemp": 100
}
```

What to expect:

- **GSSM adjusts the fan on its own timer**, every 30 seconds unless changed (`fan_control_interval_seconds` in the [Notifications Guide](gssm-notifications-guide.md)).
- **When GSSM stops managing the fan, it hands the fan back to the device's automatic mode** (v2.0.5+): when you disable the miner, and when GSSM shuts down normally. Your setting is remembered, so re-enabling the miner or starting GSSM again resumes control.
- **A fan emergency sends an alert**, and another when it clears, if High Temperature alerts are on for miners.
- **If GSSM is killed suddenly** (a crash or a power cut, not a normal stop), it cannot hand the fan back. The fan holds its last speed, never below 30%, until GSSM starts again. Do not rely on Auto Fan Control on a machine that crashes often.
- **Docker:** give the GSSM container a `stop_grace_period` of 30 seconds or more, so a container stop has time to finish. The MMFP installer sets 120 seconds.

---

## What You See on the Dashboard

Small badges beside a miner's coin icon show which of these are driving it (v3.0.9+):

| Badge | Meaning |
|---|---|
| Purple clock | A schedule is holding this miner to a state by time of day. |
| Amber bolt | At least one trigger rule is armed. |
| Blue snowflake | Auto Fan Control is running. |
| **Standby** | The miner is idled on purpose. |
| **Held** | A protective trigger idled the miner and is holding it. The other badges are hidden while this shows. |

A badge only appears when something can happen: a schedule with no windows, or triggers with every rule off, shows nothing. Disabled miners show no badges. Offline miners keep theirs.
