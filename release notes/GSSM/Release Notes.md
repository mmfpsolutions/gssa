# GSSM Release Notes

## v1.0.15

### New Features

- **Nano3s Fan Control** - Added fan speed controls to the Nano3s settings page:
  - Slider to set manual fan speed (30%-100%)
  - "Reset to Automatic" button to restore firmware automatic fan control (sends command immediately)
  - Current fan speed percentage displayed on the slider

- **Rejected Shares Status Indicator** - Miner dashboard status dot now shows purple when a miner is online but has rejected shares, providing at-a-glance visibility even with cards collapsed

### Improvements

- **Collapsible Settings Sections** - Work Mode, LED Control, and Fan Control sections on the Nano3s settings page are now individually collapsible with persistent state (remembered across page loads)

### Technical Details

- Backend: New `fanspeed` command in Canaan command handler (`ascset|0,fan-spd,<SPEED>`)
- Frontend: New `.status-rejected` CSS class (purple `#a855f7`)
- Fan speed range enforced at 30-100 (manual) or -1 (automatic) on both frontend and backend
