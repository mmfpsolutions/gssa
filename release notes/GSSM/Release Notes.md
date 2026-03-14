# GSSM Release Notes

## v1.0.16

### New Features

- **GSSM Auto Fan Control (Pro/Enterprise)** - Automatic fan speed adjustment for Nano3s based on target temperature:
  - Proportional controller with dead band algorithm — adjusts fan speed based on average chip temperature (TAvg)
  - Emergency override using max chip temperature (TMax) — forces fan to 100% if threshold exceeded
  - Configurable per-miner: target temperature (40-95°C, default 90°C), minimum fan speed (30-80%), emergency temperature (85-110°C, default 100°C)
  - Independent polling loop (default 30s interval), runs regardless of notification service state
  - Toggle on/off with confirmation modals warning about multi-instance conflicts and firmware auto fallback
  - Live status display showing current TAvg, TMax, fan speed, and last adjustment time
  - Styled slider controls for all settings (target temp, min fan speed, emergency temp)
  - Emergency temperature notifications via existing miner notification channels (tied to High Temperature toggle)
 

- **Per-Device TCP Connection Lock** - Serialized TCP connections to Canaan devices to prevent connection timeouts when multiple subsystems (dashboard, notifications, fan control) query the same miner simultaneously

### Improvements

- **Mobile Collapsible Settings** - Fixed collapse/expand sections not responding to taps on mobile devices (added touch-action, pointer-events fix)
- **Reduced Miner Load** - Fan control uses lightweight `stats` command (~8KB) instead of `estats` (~64KB) for temperature reads

### Technical Details

- New package: `internal/devicelock` — singleton per-device mutex manager for TCP connection serialization
- New file: `internal/notifications/fan_control.go` — P-controller algorithm, fan control loop, state management
- New file: `internal/handlers/v1/fan_control.go` — API handlers for fan status and configuration
- Config: `FanControlConfig` struct added to `Miner` in `config.json` (enabled, targetTemp, minFanSpeed, emergencyTemp)
- Notifications: `fanControlIntervalSeconds` added to polling config (default 30s)
- Events: `miner_fan_emergency` / `miner_fan_emergency_off` event types
- Design documents: `design-documents/auto-fan-control.md`

---

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
