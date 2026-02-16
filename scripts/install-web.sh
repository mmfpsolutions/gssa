#!/bin/bash
# ============================================================================
# MMFP Solutions - MIM Bootstrap Installer
# https://mmfpsolutions.io
#
# Usage: curl -sSL https://raw.githubusercontent.com/mmfpsolutions/gssa/main/scripts/install-web.sh | sudo bash
# ============================================================================
set -euo pipefail

# ── Version ─────────────────────────────────────────────────────────────────
INSTALLER_VERSION="1.0.0"
MIM_BOOTSTRAP_IMAGE="ghcr.io/mmfpsolutions/mim-bootstrap:latest"
MIM_BOOTSTRAP_PORT="3002"
DATA_DIR="/data"
MIN_MEMORY_GB=8

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[  OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[FAIL]${NC} $1"; }
step()    { echo -e "\n${BOLD}${GREEN}[$1/$TOTAL_STEPS]${NC} ${BOLD}$2${NC}"; }

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

TOTAL_STEPS=4

# ── Banner ──────────────────────────────────────────────────────────────────
banner() {
  echo -e "${GREEN}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║                                                  ║"
  echo "  ║       MMFP Solutions - MIM Bootstrap             ║"
  echo "  ║       Installer v${INSTALLER_VERSION}                           ║"
  echo "  ║                                                  ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ── Preflight Checks ───────────────────────────────────────────────────────
preflight() {
  step "1" "Preflight checks"

  # Must be root
  if [[ "$EUID" -ne 0 ]]; then
    error "This script must be run as root."
    echo "  Run with: sudo bash install.sh"
    echo "  Or:       curl -sSL https://get.mmfpsolutions.io | sudo bash"
    exit 1
  fi
  success "Running as root"

  # Must be Ubuntu
  if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect OS. /etc/os-release not found."
    exit 1
  fi

  source /etc/os-release

  if [[ "$ID" != "ubuntu" ]]; then
    error "This installer requires Ubuntu. Detected: $ID"
    exit 1
  fi
  success "OS: Ubuntu"

  # Must be 24.04+
  local version_major
  version_major=$(echo "$VERSION_ID" | cut -d. -f1)
  if [[ "$version_major" -lt 24 ]]; then
    error "Ubuntu 24.04 or later required. Detected: $VERSION_ID"
    exit 1
  fi
  success "Version: $VERSION_ID"

  # Must be ARM64 or AMD64
  local arch
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "$arch" in
    amd64|x86_64)
      ARCH="amd64"
      ;;
    arm64|aarch64)
      ARCH="arm64"
      ;;
    *)
      error "Unsupported architecture: $arch"
      error "Only AMD64 and ARM64 are supported."
      exit 1
      ;;
  esac
  success "Architecture: $ARCH"

  # Check memory
  local total_mem_kb
  total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local total_mem_gb=$(( total_mem_kb / 1024 / 1024 ))
  if [[ "$total_mem_gb" -lt "$MIN_MEMORY_GB" ]]; then
    error "Minimum ${MIN_MEMORY_GB} GB RAM required. Detected: ${total_mem_gb} GB"
    exit 1
  fi
  success "Memory: ${total_mem_gb} GB"

  # Must have curl
  if ! command -v curl &>/dev/null; then
    warn "curl not found. Installing..."
    apt-get update -qq && apt-get install -y -qq curl
    success "curl installed"
  else
    success "curl available"
  fi
}

# ── Create /data ────────────────────────────────────────────────────────────
create_data_dir() {
  step "2" "Creating ${DATA_DIR} directory"

  if [[ -d "$DATA_DIR" ]]; then
    success "${DATA_DIR} already exists"
  else
    mkdir -p "$DATA_DIR"
    success "${DATA_DIR} created"
  fi
}

# ── Docker Check & Install ──────────────────────────────────────────────────
setup_docker() {
  step "3" "Docker Engine setup"

  # ── Check for snap Docker FIRST (always a problem) ──
  if command -v snap &>/dev/null && snap list docker &>/dev/null 2>&1; then
    warn "Snap Docker detected. Snap Docker is not supported."
    echo ""
    if ! confirm "Remove snap Docker?"; then
      error "Cannot continue with snap Docker installed."
      echo "  Please remove it manually: sudo snap remove docker"
      exit 1
    fi
    echo ""
    info "Removing snap Docker..."
    snap remove docker 2>/dev/null || true
    success "Snap Docker removed"
  fi

  # ── Check if official Docker (docker-ce) is installed ──
  if dpkg -s docker-ce &>/dev/null 2>&1 && docker --version &>/dev/null 2>&1; then
    local docker_ver
    docker_ver=$(docker --version 2>/dev/null || echo "unknown")
    success "Official Docker already installed: $docker_ver"
    return 0
  fi

  # ── Check for unofficial apt Docker packages ──
  local unofficial_found=false
  local unofficial_pkgs=()
  local check_pkgs=(docker.io docker-compose docker-doc podman-docker containerd runc)

  for pkg in "${check_pkgs[@]}"; do
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
      unofficial_found=true
      unofficial_pkgs+=("$pkg")
    fi
  done

  if [[ "$unofficial_found" == true ]]; then
    warn "Unofficial Docker packages detected:"
    for pkg in "${unofficial_pkgs[@]}"; do
      echo -e "    ${YELLOW}-${NC} $pkg"
    done
    echo ""
    if ! confirm "Remove unofficial packages and install official Docker Engine?"; then
      error "Cannot continue without official Docker Engine."
      echo "  Please install Docker manually: https://docs.docker.com/engine/install/ubuntu/"
      exit 1
    fi
    echo ""
    info "Removing unofficial Docker packages..."
    apt-get remove -y -qq "${unofficial_pkgs[@]}" 2>/dev/null || true
    apt-get autoremove -y -qq 2>/dev/null || true
    success "Unofficial packages removed"
  else
    info "Docker is not installed."
    if ! confirm "Install official Docker Engine?"; then
      error "Cannot continue without Docker Engine."
      echo "  Please install Docker manually: https://docs.docker.com/engine/install/ubuntu/"
      exit 1
    fi
  fi

  # Install official Docker Engine
  echo ""
  info "Installing prerequisites..."
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl
  success "Prerequisites installed"

  info "Adding Docker GPG key..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  success "Docker GPG key added"

  info "Adding Docker repository..."
  echo \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  success "Docker repository added"

  info "Installing Docker Engine..."
  apt-get update -qq
  apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
  success "Docker Engine installed: $(docker --version)"
}

# ── Run MIM Bootstrap ───────────────────────────────────────────────────────
run_bootstrap() {
  step "4" "Starting MIM Bootstrap"

  info "Pulling ${MIM_BOOTSTRAP_IMAGE}..."
  docker pull "$MIM_BOOTSTRAP_IMAGE"
  success "Image pulled"

  # Remove existing bootstrap container if present
  if docker ps -a --format '{{.Names}}' | grep -q '^bootstrap$'; then
    warn "Existing 'bootstrap' container found. Removing..."
    docker stop bootstrap 2>/dev/null || true
    docker rm bootstrap 2>/dev/null || true
    success "Old container removed"
  fi

  info "Starting MIM Bootstrap container..."
  docker run -d \
    --name bootstrap \
    -p "${MIM_BOOTSTRAP_PORT}:${MIM_BOOTSTRAP_PORT}" \
    --restart unless-stopped \
    "$MIM_BOOTSTRAP_IMAGE"

  # Wait for container to start
  sleep 3

  if docker ps --format '{{.Names}}' | grep -q '^bootstrap$'; then
    success "MIM Bootstrap is running"
  else
    error "Container failed to start. Check logs with: docker logs bootstrap"
    exit 1
  fi
}

# ── Success Banner ──────────────────────────────────────────────────────────
finish() {
  local ip
  ip=$(hostname -I 2>/dev/null | awk '{print $1}')

  if [[ -z "$ip" ]]; then
    ip="<your-server-ip>"
  fi

  echo ""
  echo -e "${GREEN}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║                                                  ║"
  echo "  ║          Bootstrap start up Complete!            ║"
  echo "  ║                                                  ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${BOLD}Open your browser to complete setup:${NC}"
  echo ""
  echo -e "    ${CYAN}http://${ip}:${MIM_BOOTSTRAP_PORT}${NC}"
  echo ""
  echo -e "  ${BOLD}Follow the web installer to configure your${NC}"
  echo -e "  ${BOLD}mining infrastructure.${NC}"
  echo ""
  echo -e "  Useful commands:"
  echo -e "    ${CYAN}docker logs -f bootstrap${NC}   View bootstrap logs"
  echo -e "    ${CYAN}docker ps${NC}                  List running containers"
  echo ""
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  banner
  preflight
  create_data_dir
  setup_docker
  run_bootstrap
  finish
}

main "$@"
