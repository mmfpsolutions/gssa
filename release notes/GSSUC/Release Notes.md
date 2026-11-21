# GSSUC Release Notes
## v2.x Series

## v2.0.0

**GSSUC now shows the Hash Hopper.** GoSlimStratum 6.0.0 added the Hash Hopper, one stratum port that
moves a miner's rigs between chains. GSSUC 2.0.0 gives those miners a dashboard of their own, and
stops telling them their rigs are offline when they are busy on another chain.

### What's new

- **A Hash Hopper card on the home page.** It shows the chains the Hash Hopper moves between, how many
  rigs are connected, and how to connect: host, port and the username format `hopper.<profile>.<rig>`.
- **A Hash Hopper dashboard for each profile.** **View My Stats** on the card asks for a profile name
  (the part after `hopper.` in the miner's username). The dashboard shows:
  - **Mining Now:** the chain the rigs are on, and since when.
  - **Total Hashrate**, **Rigs** and **Blocks Found** across every coin.
  - **Chains:** each chain the profile mines, where it pays, and the time and shares spent on it.
  - **Your Rigs:** every rig with its chain, hashrate, difficulty and accepted and rejected shares.
  - **Blocks Found:** the profile's blocks on all its coins in one list, each linked to its own
    coin's explorer.
- **A details page for each Hash Hopper rig,** with its hashrate and difficulty charts, its best share
  and the chain it was on, and its blocks across coins.
- **Hash Hopper rigs on a coin's dashboard are no longer shown as Offline** while they mine another
  chain. They carry the rabbit badge and read "On DGB" (the chain they are on). A line above the
  Miners table says where the rigs are and links to the Hash Hopper dashboard.
- **V1 and V2 at a glance.** A small pill in front of each miner's name shows whether it is connected
  with Stratum V1 or V2, green when connected and red when not. On coin dashboards and the Hash Hopper
  dashboard.
- **Badges for Bitcoin Silver and WojakCoin.** Pools with the symbol `BTCS` or `WJK` now show their
  own badge.

### Improved

- **Two figures side by side are separated by a dot, not a slash:** Active Miners (Online · Total),
  Valid · Invalid shares, and the Shares card on the Miner Details page.

### Fixed

- **Worker names are always shown as plain text.** A worker name is chosen by the miner; the dashboard
  and Block History pages now display it exactly as typed, whatever characters it contains.

### Good to know

- **Nothing changes when you upgrade.** The Hash Hopper pages are off until you turn them on. Your
  `config.json` needs no changes.
- **To turn it on:** gear icon, PIN, **Configuration**, **Hash Hopper**. Tick **Show the Hash Hopper**
  and enter the **Stratum Host** your miners connect to. There is no port to enter; GSSUC reads it
  from GoSlimStratum.
- **The Hash Hopper pages need GoSlimStratum 6.0.0 or later,** with the Hash Hopper turned on, its
  port open, and not in shadow mode. Until all of that is true GSSUC shows nothing about it, and the
  rest of GSSUC works as before. The rest of GSSUC 2.0.0 works with earlier GoSlimStratum versions.
- **Profiles are created in GoSlimStratum** by the pool operator. GSSUC shows them; it cannot create
  or change one.
- **Your Hash Hopper settings stay private.** Miners see the chains, where their rigs are and what
  they found. They do not see chain weights, costs, the switching rules, the Switch Log or the hopping
  gain, and nobody sees another profile's rigs. Payout addresses on the Hash Hopper dashboard are
  shortened.
- **Anyone who knows a profile's name can open its dashboard,** just as anyone who knows a wallet
  address can open that address's dashboard.
- **On a coin's dashboard, Online still means "mining this coin now".** A rig on another chain is not
  counted in that coin's Active Miners or hashrate. The Hash Hopper dashboard shows all of a profile's
  rigs together.
- **Time and shares on each chain start again when GoSlimStratum restarts.** Blocks Found does not.
- **The Blocks Found list reads the pool's newest 1,000 Hash Hopper blocks.** Past that, older blocks
  are still on each coin's own Block History page. The page says so when the limit is reached.
- **Block links appear only for coins that have a block explorer address in GoSlimStratum's Global
  Config.**
- **Putting GSSUC on the internet?** Run it behind a reverse proxy, serve it over TLS (HTTPS), and
  set your own admin PIN. The User Guide has the short list.
- **New guides.** A [User Guide](https://github.com/mmfpsolutions/gssa/blob/main/documents/GSSUC/gssuc-user-guide.md)
  and a [Troubleshooting Guide](https://github.com/mmfpsolutions/gssa/blob/main/documents/GSSUC/gssuc-troubleshooting-guide.md)
  join the [Configuration Guide](https://github.com/mmfpsolutions/gssa/blob/main/documents/GSSUC/gssuc-config-guide.md).

---
