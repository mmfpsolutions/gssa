#!/bin/bash
# ============================================================================
# MMFP Solutions - Uninstaller
# https://mmfpsolutions.io
#
# Removes MMFP mining infrastructure components with tiered prompts.
#
# Usage: sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)"
#        or: sudo bash scripts/uninstall.sh
# ============================================================================
set -euo pipefail

# ── Interactive input guard ──────────────────────────────────────────────────
if [[ ! -t 0 ]]; then
  echo -e "\033[0;31m[FAIL]\033[0m This script requires interactive input but stdin is not a terminal."
  echo ""
  echo "  Please use one of these commands instead:"
  echo ""
  echo "    sudo bash -c \"\$(curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh)\""
  echo ""
  echo "  Or download and run:"
  echo ""
  echo "    curl -sSL https://get.mmfpsolutions.io/scripts/uninstall.sh -o /tmp/uninstall.sh"
  echo "    sudo bash /tmp/uninstall.sh"
  echo ""
  exit 1
fi

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[  OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[FAIL]${NC} $1"; }

confirm() {
  local prompt="$1"
  local default="${2:-Y}"
  local reply

  if [[ "$default" == "Y" ]]; then
    echo -en "${CYAN}${prompt} [Y/n]:${NC} "
  else
    echo -en "${CYAN}${prompt} [y/N]:${NC} "
  fi

  read -r reply
  reply="${reply:-$default}"

  [[ "$reply" =~ ^[Yy]$ ]]
}

DATA_DIR="/data"
COMPOSE_DIR="${DATA_DIR}/docker-compose"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${RED}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║                                                  ║"
echo "  ║       MMFP Solutions - Uninstaller               ║"
echo "  ║                                                  ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Must be root ──────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  error "This script must be run as root."
  echo "  Run with: sudo bash uninstall.sh"
  exit 1
fi

# ── Step 1: Stop and remove containers ────────────────────────────────────────
echo ""
if [[ -f "$COMPOSE_FILE" ]]; then
  info "Docker Compose file found at ${COMPOSE_FILE}"
  if confirm "Stop and remove all MMFP containers?"; then
    info "Stopping containers..."
    docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    success "Containers stopped and removed"

    # Remove images
    if confirm "Remove Docker images used by MMFP?"; then
      info "Removing images..."
      docker compose -f "$COMPOSE_FILE" down --rmi all 2>/dev/null || true
      success "Docker images removed"
    fi
  fi
else
  # Try to stop containers by name if compose file is missing
  local_containers=(dgb goslimstratum postgres mim axeos-dashboard dozzle watchtower)
  running=false
  for c in "${local_containers[@]}"; do
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${c}$"; then
      running=true
      break
    fi
  done

  if [[ "$running" == true ]]; then
    warn "No compose file found, but MMFP containers detected."
    if confirm "Stop and remove MMFP containers individually?"; then
      for c in "${local_containers[@]}"; do
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${c}$"; then
          docker rm -f "$c" 2>/dev/null || true
          success "Removed: $c"
        fi
      done
    fi
  else
    info "No MMFP containers found."
  fi
fi

# ── Step 2: Remove /data directory ────────────────────────────────────────────
echo ""
if [[ -d "$DATA_DIR" ]]; then
  warn "This will permanently delete ALL data including:"
  echo -e "    ${YELLOW}-${NC} DigiByte blockchain data and wallet"
  echo -e "    ${YELLOW}-${NC} PostgreSQL database"
  echo -e "    ${YELLOW}-${NC} GoSlimStratum configuration and logs"
  echo -e "    ${YELLOW}-${NC} All other config files"
  echo ""

  # Show wallet address if available
  if [[ -f "${DATA_DIR}/dgb/dgb_wallet.txt" ]]; then
    wallet_addr=$(cat "${DATA_DIR}/dgb/dgb_wallet.txt" 2>/dev/null || echo "unknown")
    warn "Wallet address: ${wallet_addr}"
    echo -e "    ${RED}Make sure you have backed up any funds before proceeding!${NC}"
    echo ""
  fi

  if confirm "Delete ${DATA_DIR} directory and all its contents?" "N"; then
    rm -rf "$DATA_DIR"
    success "${DATA_DIR} removed"
  else
    info "Keeping ${DATA_DIR}"
  fi
else
  info "${DATA_DIR} does not exist — nothing to remove."
fi

# ── Step 3: Remove MIM system user ───────────────────────────────────────────
echo ""
if id "mim" &>/dev/null; then
  if confirm "Remove 'mim' system user and home directory?" "N"; then
    userdel -r mim 2>/dev/null || userdel mim 2>/dev/null || true
    success "User 'mim' removed"
  else
    info "Keeping 'mim' user"
  fi
else
  info "User 'mim' does not exist — nothing to remove."
fi

# ── Step 4: Remove Docker Engine ──────────────────────────────────────────────
echo ""
if dpkg -s docker-ce &>/dev/null 2>&1; then
  warn "This will remove Docker Engine from the system entirely."
  echo -e "    ${YELLOW}This affects ALL Docker containers on this machine, not just MMFP.${NC}"
  echo ""
  if confirm "Remove Docker Engine?" "N"; then
    info "Removing Docker Engine..."
    apt-get purge -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get autoremove -y -qq 2>/dev/null || true
    rm -rf /var/lib/docker /var/lib/containerd 2>/dev/null || true
    rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc 2>/dev/null || true
    success "Docker Engine removed"
  else
    info "Keeping Docker Engine"
  fi
else
  info "Docker Engine not installed — nothing to remove."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}  Uninstall complete.${NC}"
echo ""
