#!/bin/bash
# ============================================================================
# MMFP Solutions - Full CLI Installer
# https://mmfpsolutions.io
#
# Deploys the complete MMFP mining infrastructure via terminal prompts.
# No MIM Bootstrap web UI required.
#
# Usage: sudo bash -c "$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)"
#        or: sudo bash scripts/install-cli.sh
# ============================================================================
set -euo pipefail

# ── Interactive input guard ──────────────────────────────────────────────────
# This script requires interactive prompts. If stdin is not a terminal
# (e.g. piped from curl), exit with instructions for the correct command.
if [[ ! -t 0 ]]; then
  echo -e "\033[0;31m[FAIL]\033[0m This installer requires interactive input but stdin is not a terminal."
  echo ""
  echo "  Please use one of these commands instead:"
  echo ""
  echo "    sudo bash -c \"\$(curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh)\""
  echo ""
  echo "  Or download and run:"
  echo ""
  echo "    curl -sSL https://get.mmfpsolutions.io/scripts/install-cli.sh -o /tmp/install-cli.sh"
  echo "    sudo bash /tmp/install-cli.sh"
  echo ""
  exit 1
fi

# ── Configuration ─────────────────────────────────────────────────────────────
INSTALLER_VERSION="1.0.0"
GITHUB_RAW="https://get.mmfpsolutions.io/templates"
DATA_DIR="/data"
TEMPLATE_DIR="/tmp/mmfp-templates"
COMPOSE_DIR="${DATA_DIR}/docker-compose"
MIN_MEMORY_GB=8

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

prompt_value() {
  local prompt="$1"
  local default="${2:-}"
  local value

  if [[ -n "$default" ]]; then
    echo -en "${CYAN}${prompt} [${default}]:${NC} " >&2
  else
    echo -en "${CYAN}${prompt}:${NC} " >&2
  fi

  read -r value
  value="${value:-$default}"

  if [[ -z "$value" ]]; then
    error "Value cannot be empty." >&2
    exit 1
  fi

  echo "$value"
}

TOTAL_STEPS=10

# ── Cleanup trap ──────────────────────────────────────────────────────────────
cleanup() {
  if [[ -d "$TEMPLATE_DIR" ]]; then
    rm -rf "$TEMPLATE_DIR"
  fi
}
trap cleanup EXIT

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
  echo -e "${GREEN}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║                                                  ║"
  echo "  ║       MMFP Solutions - Full CLI Installer        ║"
  echo "  ║       v${INSTALLER_VERSION}                      ║"
  echo "  ║                                                  ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ── Step 1: Preflight Checks ─────────────────────────────────────────────────
preflight() {
  step "1" "Preflight checks"

  # Must be root
  if [[ "$EUID" -ne 0 ]]; then
    error "This script must be run as root."
    echo "  Run with: sudo bash install-cli.sh"
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

  # Must have openssl (for RPC auth generation)
  if ! command -v openssl &>/dev/null; then
    warn "openssl not found. Installing..."
    apt-get update -qq && apt-get install -y -qq openssl
    success "openssl installed"
  else
    success "openssl available"
  fi
}

# ── Step 2: Create /data ──────────────────────────────────────────────────────
create_data_dir() {
  step "2" "Creating ${DATA_DIR} directory"

  if [[ -d "$DATA_DIR" ]]; then
    success "${DATA_DIR} already exists"
  else
    mkdir -p "$DATA_DIR"
    success "${DATA_DIR} created"
  fi
}

# ── Step 3: Docker Check & Install ───────────────────────────────────────────
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

# ── Step 4: Collect Configuration ─────────────────────────────────────────────
collect_config() {
  step "4" "Configuration"

  # ── Coin selection ──
  echo ""
  echo -e "  ${BOLD}Which coin would you like to mine?${NC}"
  echo ""
  echo -e "    1) DigiByte  (DGB)"
  echo -e "    2) Bitcoin Cash (BCH)"
  echo -e "    3) Bitcoin   (BTC)"
  echo ""
  local coin_choice
  coin_choice=$(prompt_value "Select [1-3]" "1")

  case "$coin_choice" in
    1)
      COIN_ID="dgb";  COIN_ID_UPPER="DGB";  COIN_NAME="DigiByte"
      COIN_TYPE="digibyte";  COIN_NODE_TYPE="dgb";  COIN_NODE_ID="dgb1"
      CONTAINER_NAME="dgb";  DATA_SUBDIR="dgb";  DEFAULT_RPC_USER="digibyterpc"
      RPC_PORT=9001;  ZMQ_PORT=28332;  STRATUM_PORT=3333
      NODE_CLI="digibyte-cli";  NODE_CONF="digibyte.conf"
      ;;
    2)
      COIN_ID="bch";  COIN_ID_UPPER="BCH";  COIN_NAME="Bitcoin Cash"
      COIN_TYPE="bitcoincash";  COIN_NODE_TYPE="bch";  COIN_NODE_ID="bch1"
      CONTAINER_NAME="bch";  DATA_SUBDIR="bch";  DEFAULT_RPC_USER="bitcoincashrpc"
      RPC_PORT=9002;  ZMQ_PORT=28333;  STRATUM_PORT=3334
      NODE_CLI="bitcoin-cli";  NODE_CONF="bitcoin.conf"
      ;;
    3)
      COIN_ID="btc";  COIN_ID_UPPER="BTC";  COIN_NAME="Bitcoin"
      COIN_TYPE="bitcoin";  COIN_NODE_TYPE="btc";  COIN_NODE_ID="btc1"
      CONTAINER_NAME="btc";  DATA_SUBDIR="btc";  DEFAULT_RPC_USER="bitcoinrpc"
      RPC_PORT=9003;  ZMQ_PORT=28334;  STRATUM_PORT=3335
      NODE_CLI="bitcoin-cli";  NODE_CONF="bitcoin.conf"
      ;;
    *)
      error "Invalid selection. Please enter 1, 2, or 3."
      exit 1
      ;;
  esac
  success "Selected: ${COIN_NAME} (${COIN_ID_UPPER})"

  echo ""
  echo -e "  ${BOLD}Please provide the following configuration values.${NC}"
  echo -e "  ${BOLD}Passwords are displayed as you type.${NC}"
  echo ""

  # Postgres admin password
  POSTGRES_ADMIN_PASSWORD=$(prompt_value "Postgres admin password")
  success "Postgres admin password set"

  # GoSlimStratum DB password
  GSS_DB_PASSWORD=$(prompt_value "GoSlimStratum database password")
  success "GoSlimStratum DB password set"

  # Node RPC username
  RPC_USER=$(prompt_value "Node RPC username" "$DEFAULT_RPC_USER")
  success "RPC username: $RPC_USER"

  # Node RPC password
  echo ""
  if confirm "Auto-generate Node RPC password?"; then
    RPC_PASSWORD=$(openssl rand -base64 32)
    echo -e "  ${BOLD}Generated RPC password:${NC} ${CYAN}${RPC_PASSWORD}${NC}"
    echo -e "  ${YELLOW}Save this password — you will need it for RPC access.${NC}"
  else
    RPC_PASSWORD=$(prompt_value "Node RPC password")
  fi
  success "RPC password set"

  # MIM user password
  MIM_PASSWORD=$(prompt_value "MIM system user password (for SSH access)")
  success "MIM password set"

  # Pruning
  echo ""
  if confirm "Enable blockchain pruning? (saves disk space)"; then
    PRUNE_MB=$(prompt_value "Prune size in MB (minimum 550)" "550")
    PRUNE_VALUE="prune=${PRUNE_MB}"
    success "Pruning enabled: ${PRUNE_MB} MB"
  else
    PRUNE_VALUE="#prune=4096"
    success "Pruning disabled (full blockchain)"
  fi

  # Server IP
  local detected_ip
  detected_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [[ -n "$detected_ip" ]]; then
    SERVER_IP=$(prompt_value "Server IP address" "$detected_ip")
  else
    SERVER_IP=$(prompt_value "Server IP address")
  fi
  success "Server IP: $SERVER_IP"

  # Confirmation
  echo ""
  echo -e "  ${BOLD}Configuration Summary:${NC}"
  echo -e "    Coin:                     ${CYAN}${COIN_NAME} (${COIN_ID_UPPER})${NC}"
  echo -e "    Postgres admin password:  ${CYAN}${POSTGRES_ADMIN_PASSWORD}${NC}"
  echo -e "    GSS database password:    ${CYAN}${GSS_DB_PASSWORD}${NC}"
  echo -e "    RPC username:             ${CYAN}${RPC_USER}${NC}"
  echo -e "    RPC password:             ${CYAN}${RPC_PASSWORD}${NC}"
  echo -e "    MIM user password:        ${CYAN}${MIM_PASSWORD}${NC}"
  echo -e "    Pruning:                  ${CYAN}${PRUNE_VALUE}${NC}"
  echo -e "    Server IP:                ${CYAN}${SERVER_IP}${NC}"
  echo ""

  if ! confirm "Proceed with these settings?"; then
    error "Installation cancelled by user."
    exit 1
  fi
}

# ── Step 5: Download Templates ────────────────────────────────────────────────
download_file() {
  local path="$1"
  local dest="${TEMPLATE_DIR}/${path}"
  mkdir -p "$(dirname "$dest")"
  if ! curl -sSfL "${GITHUB_RAW}/${path}" -o "$dest"; then
    error "Failed to download: ${path}"
    exit 1
  fi
}

download_templates() {
  step "5" "Downloading templates"

  if [[ -d "$TEMPLATE_DIR" ]]; then
    rm -rf "$TEMPLATE_DIR"
  fi
  mkdir -p "$TEMPLATE_DIR"

  info "Downloading templates from GitHub..."

  local files=(
    "docker-compose.yml"
    "env.template"
    "goslimstratum/config.json.template"
    "axeos-dashboard/config.json.template"
    "axeos-dashboard/rpcConfig.json.template"
    "axeos-dashboard/access.json"
    "axeos-dashboard/jsonWebTokenKey.json"
    "mim-config/servers.json.template"
    "postgres/user-db-setup.sql.template"
    "coins/${COIN_ID}/docker-compose.yml"
    "coins/${COIN_ID}/node.conf.template"
    "coins/${COIN_ID}/gss-coin.json.template"
  )

  for file in "${files[@]}"; do
    download_file "$file"
    success "$file"
  done

  success "All templates downloaded"
}

# ── Step 6: System Setup ──────────────────────────────────────────────────────
system_setup() {
  step "6" "System setup"

  # Create MIM system user
  if id "mim" &>/dev/null; then
    info "User 'mim' already exists"
    echo "mim:$MIM_PASSWORD" | chpasswd
    success "MIM user password updated"
  else
    info "Creating 'mim' system user..."
    useradd -m -s /bin/bash mim
    echo "mim:$MIM_PASSWORD" | chpasswd
    success "MIM user created"
  fi

  # Add to sudo and docker groups
  usermod -aG sudo mim 2>/dev/null || true
  usermod -aG docker mim 2>/dev/null || true
  success "MIM user added to sudo and docker groups"

  # Create directory structure
  info "Creating directory structure..."
  local dirs=(
    "${DATA_DIR}/${DATA_SUBDIR}/data"
    "${DATA_DIR}/goslimstratum/config"
    "${DATA_DIR}/goslimstratum/logs"
    "${DATA_DIR}/goslimstratum/data"
    "${DATA_DIR}/postgres18"
    "${DATA_DIR}/axeos-dashboard/config"
    "${DATA_DIR}/axeos-dashboard/data"
    "${DATA_DIR}/mim/config"
    "${DATA_DIR}/mim/data"
    "${DATA_DIR}/mim/logs"
    "${COMPOSE_DIR}"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
  done
  success "Directory structure created"

}

# ── Step 7: Generate Configs ──────────────────────────────────────────────────
generate_configs() {
  step "7" "Generating configuration files"

  # Generate RPC auth string (pure bash, no Python)
  info "Generating RPC auth string..."
  local salt
  salt=$(openssl rand -hex 16)
  local password_hmac
  password_hmac=$(echo -n "$RPC_PASSWORD" | openssl dgst -sha256 -hmac "$salt" 2>/dev/null | awk '{print $NF}')
  RPC_AUTH_STRING="${RPC_USER}:${salt}\$${password_hmac}"
  success "RPC auth string generated"

  # Generate JWT secret for AxeOS
  local jwt_secret
  jwt_secret=$(openssl rand -base64 32)

  # ── Node config (digibyte.conf / bitcoin.conf) ──
  info "Generating ${NODE_CONF}..."
  sed -e "s|{RPC_AUTH_STRING}|${RPC_AUTH_STRING}|g" \
      -e "s|{PRUNE_VALUE}|${PRUNE_VALUE}|g" \
      "${TEMPLATE_DIR}/coins/${COIN_ID}/node.conf.template" > "${DATA_DIR}/${DATA_SUBDIR}/data/${NODE_CONF}"
  success "${NODE_CONF} → /data/${DATA_SUBDIR}/data/${NODE_CONF}"

  # ── docker-compose.yml (base + coin service) ──
  info "Generating docker-compose.yml..."
  {
    cat "${TEMPLATE_DIR}/docker-compose.yml"
    echo ""
    cat "${TEMPLATE_DIR}/coins/${COIN_ID}/docker-compose.yml"
  } > "${COMPOSE_DIR}/docker-compose.yml"
  success "docker-compose.yml → /data/docker-compose/docker-compose.yml"

  # ── .env ──
  info "Generating .env..."
  sed -e "s|{POSTGRES_ADMIN_PASSWORD}|${POSTGRES_ADMIN_PASSWORD}|g" \
      "${TEMPLATE_DIR}/env.template" > "${COMPOSE_DIR}/.env"
  success ".env → /data/docker-compose/.env"

  # ── goslimstratum config.json ──
  info "Generating goslimstratum config.json..."
  # Process the coin-specific GSS block
  local coin_block
  coin_block=$(sed -e "s|{RPC_USER}|${RPC_USER}|g" \
      -e "s|{RPC_PASSWORD}|${RPC_PASSWORD}|g" \
      -e "s|{WALLET_ADDRESS}|PENDING_WALLET_CREATION|g" \
      "${TEMPLATE_DIR}/coins/${COIN_ID}/gss-coin.json.template")
  # Insert coin block at __COIN_CONFIG__ placeholder and substitute shared values
  awk -v block="$coin_block" '{gsub(/__COIN_CONFIG__/, block); print}' \
      "${TEMPLATE_DIR}/goslimstratum/config.json.template" | \
      sed -e "s|{GOSLIMSTRATUM_DB_PASSWORD}|${GSS_DB_PASSWORD}|g" \
          -e "s|{SERVER_IP}|${SERVER_IP}|g" \
      > "${DATA_DIR}/goslimstratum/config/config.json"
  success "config.json → /data/goslimstratum/config/config.json"

  # ── axeos-dashboard config.json ──
  info "Generating axeos-dashboard config.json..."
  sed -e "s|{COIN_NODE_ID}|${COIN_NODE_ID}|g" \
      -e "s|{COIN_NAME}|${COIN_NAME}|g" \
      -e "s|{COIN_NODE_TYPE}|${COIN_NODE_TYPE}|g" \
      -e "s|{COIN_ID}|${COIN_ID}|g" \
      -e "s|{COIN_ID_UPPER}|${COIN_ID_UPPER}|g" \
      -e "s|{SERVER_IP}|${SERVER_IP}|g" \
      "${TEMPLATE_DIR}/axeos-dashboard/config.json.template" > "${DATA_DIR}/axeos-dashboard/config/config.json"
  success "config.json → /data/axeos-dashboard/config/config.json"

  # ── axeos-dashboard rpcConfig.json ──
  info "Generating axeos-dashboard rpcConfig.json..."
  sed -e "s|{COIN_NODE_ID}|${COIN_NODE_ID}|g" \
      -e "s|{RPC_PORT}|${RPC_PORT}|g" \
      -e "s|{RPC_USER}|${RPC_USER}|g" \
      -e "s|{RPC_PASSWORD}|${RPC_PASSWORD}|g" \
      "${TEMPLATE_DIR}/axeos-dashboard/rpcConfig.json.template" > "${DATA_DIR}/axeos-dashboard/config/rpcConfig.json"
  success "rpcConfig.json → /data/axeos-dashboard/config/rpcConfig.json"

  # ── axeos-dashboard access.json ──
  cp "${TEMPLATE_DIR}/axeos-dashboard/access.json" "${DATA_DIR}/axeos-dashboard/config/access.json"
  success "access.json → /data/axeos-dashboard/config/access.json"

  # ── axeos-dashboard jsonWebTokenKey.json ──
  info "Generating jsonWebTokenKey.json..."
  sed -e "s|{JWT_SECRET}|${jwt_secret}|g" \
      "${TEMPLATE_DIR}/axeos-dashboard/jsonWebTokenKey.json" > "${DATA_DIR}/axeos-dashboard/config/jsonWebTokenKey.json"
  success "jsonWebTokenKey.json → /data/axeos-dashboard/config/jsonWebTokenKey.json"

  # ── mim servers.json ──
  info "Generating MIM servers.json..."
  sed -e "s|{SERVER_IP}|${SERVER_IP}|g" \
      -e "s|{MIM_PASSWORD}|${MIM_PASSWORD}|g" \
      "${TEMPLATE_DIR}/mim-config/servers.json.template" > "${DATA_DIR}/mim/config/servers.json"
  success "servers.json → /data/mim/config/servers.json"

  # ── postgres user-db-setup.sql (prepared for later) ──
  info "Generating postgres setup SQL..."
  sed -e "s|{GOSLIMSTRATUM_DB_PASSWORD}|${GSS_DB_PASSWORD}|g" \
      "${TEMPLATE_DIR}/postgres/user-db-setup.sql.template" > "${TEMPLATE_DIR}/user-db-setup.sql"
  success "user-db-setup.sql prepared"

  # Container processes run as non-root users — ensure all data dirs are writable
  # Must run AFTER config files are generated so the files inherit the permissions
  info "Setting directory permissions..."
  chmod -R 777 "${DATA_DIR}/${DATA_SUBDIR}"
  chmod -R 777 "${DATA_DIR}/goslimstratum"
  chmod -R 777 "${DATA_DIR}/axeos-dashboard"
  chmod -R 777 "${DATA_DIR}/mim"
  chmod -R 777 "${DATA_DIR}/postgres18"
  success "Directory permissions set"
}

# ── Step 8: Start Node & Create Wallet ────────────────────────────────────────
start_node_and_wallet() {
  step "8" "Starting ${COIN_NAME} node & creating wallet"

  info "Starting ${COIN_NAME} container..."
  docker compose -f "${COMPOSE_DIR}/docker-compose.yml" up -d "$CONTAINER_NAME"

  # Wait for container to be running
  sleep 3
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error "${COIN_NAME} container failed to start. Check: docker logs ${CONTAINER_NAME}"
    exit 1
  fi
  success "${COIN_NAME} container running"

  # Wait for RPC to become available (poll with retries)
  info "Waiting for ${COIN_NAME} RPC to become available..."
  local max_attempts=24
  local attempt=0
  while [[ $attempt -lt $max_attempts ]]; do
    if docker exec "$CONTAINER_NAME" "$NODE_CLI" \
        -rpcuser="$RPC_USER" \
        -rpcpassword="$RPC_PASSWORD" \
        -rpcport="$RPC_PORT" \
        getblockchaininfo &>/dev/null 2>&1; then
      break
    fi
    attempt=$((attempt + 1))
    if [[ $attempt -eq $max_attempts ]]; then
      error "${COIN_NAME} RPC did not become available after 2 minutes."
      error "Check logs: docker logs ${CONTAINER_NAME}"
      exit 1
    fi
    echo -en "\r  Waiting... (${attempt}/${max_attempts})"
    sleep 5
  done
  echo ""
  success "${COIN_NAME} RPC available"

  # Create wallet
  info "Creating default wallet..."
  docker exec "$CONTAINER_NAME" "$NODE_CLI" \
    -rpcuser="$RPC_USER" \
    -rpcpassword="$RPC_PASSWORD" \
    -rpcport="$RPC_PORT" \
    createwallet "default" 2>/dev/null || true
  success "Default wallet created"

  # Get legacy address
  info "Generating legacy wallet address..."
  WALLET_ADDRESS=$(docker exec "$CONTAINER_NAME" "$NODE_CLI" \
    -rpcuser="$RPC_USER" \
    -rpcpassword="$RPC_PASSWORD" \
    -rpcport="$RPC_PORT" \
    getnewaddress "" "legacy" 2>/dev/null)

  if [[ -z "$WALLET_ADDRESS" ]]; then
    error "Failed to generate wallet address."
    exit 1
  fi

  # Save wallet address to file
  echo "$WALLET_ADDRESS" > "${DATA_DIR}/${DATA_SUBDIR}/${COIN_ID}_wallet.txt"
  success "Wallet address: $WALLET_ADDRESS"
  success "Saved to: /data/${DATA_SUBDIR}/${COIN_ID}_wallet.txt"

  # Update goslimstratum config with actual wallet address
  info "Updating GoSlimStratum config with wallet address..."
  sed -i "s|PENDING_WALLET_CREATION|${WALLET_ADDRESS}|g" "${DATA_DIR}/goslimstratum/config/config.json"
  success "GoSlimStratum config updated with wallet address"
}

# ── Step 9: Start PostgreSQL & Setup Database ─────────────────────────────────
setup_postgres() {
  step "9" "Setting up PostgreSQL"

  info "Starting PostgreSQL container..."
  docker compose -f "${COMPOSE_DIR}/docker-compose.yml" up -d postgres

  # Wait for postgres to accept connections
  info "Waiting for PostgreSQL to become available..."
  local max_attempts=12
  local attempt=0
  while [[ $attempt -lt $max_attempts ]]; do
    if docker exec postgres pg_isready -U admin &>/dev/null 2>&1; then
      break
    fi
    attempt=$((attempt + 1))
    if [[ $attempt -eq $max_attempts ]]; then
      error "PostgreSQL did not become available after 60 seconds."
      error "Check logs: docker logs postgres"
      exit 1
    fi
    echo -en "\r  Waiting... (${attempt}/${max_attempts})"
    sleep 5
  done
  echo ""
  success "PostgreSQL available"

  # Create goslimstratum role and database
  info "Creating goslimstratum database and role..."
  docker exec -i postgres psql -U admin -d master < "${TEMPLATE_DIR}/user-db-setup.sql"
  success "GoSlimStratum database and role created (GSS will create schema on first start)"
}

# ── Step 10: Bring Up Full Stack ──────────────────────────────────────────────
deploy_stack() {
  step "10" "Deploying full stack"

  info "Stopping all containers..."
  docker compose -f "${COMPOSE_DIR}/docker-compose.yml" down

  info "Starting all containers..."
  docker compose -f "${COMPOSE_DIR}/docker-compose.yml" up -d

  # Wait a moment then verify
  sleep 5
  info "Verifying containers..."

  local expected_containers=("$CONTAINER_NAME" goslimstratum postgres mim axeos-dashboard dozzle watchtower)
  local all_running=true

  for container in "${expected_containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
      success "${container} is running"
    else
      warn "${container} is NOT running"
      all_running=false
    fi
  done

  if [[ "$all_running" == false ]]; then
    warn "Some containers are not running. Check: docker ps -a"
    warn "View logs with: docker logs <container-name>"
  else
    success "All 7 containers are running"
  fi
}

# ── Success Banner ────────────────────────────────────────────────────────────
finish() {
  echo ""
  echo -e "${GREEN}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║                                                  ║"
  echo "  ║        Installation Complete!                    ║"
  echo "  ║                                                  ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${BOLD}Coin: ${COIN_NAME} (${COIN_ID_UPPER})${NC}"
  echo ""
  echo -e "  ${BOLD}Your Services:${NC}"
  echo ""
  echo -e "    MIM Dashboard:      ${CYAN}http://${SERVER_IP}:3001${NC}"
  echo -e "    AxeOS Dashboard:    ${CYAN}http://${SERVER_IP}:3000${NC}"
  echo -e "    GSS Web UI:         ${CYAN}http://${SERVER_IP}:3003${NC}"
  echo -e "    Stratum Connect:    ${CYAN}stratum+tcp://${SERVER_IP}:${STRATUM_PORT}${NC}"
  echo -e "    Dozzle Logs:        ${CYAN}http://${SERVER_IP}:8080${NC}"
  echo ""
  echo -e "  ${BOLD}Wallet Address:${NC}"
  echo -e "    ${CYAN}${WALLET_ADDRESS}${NC}"
  echo -e "    Saved to: ${CYAN}/data/${DATA_SUBDIR}/${COIN_ID}_wallet.txt${NC}"
  echo ""
  echo -e "  ${YELLOW}Note: ${COIN_NAME} blockchain sync is in progress.${NC}"
  echo -e "  ${YELLOW}This may take several hours depending on your connection.${NC}"
  echo ""
  echo -e "  ${BOLD}Useful commands:${NC}"
  echo -e "    ${CYAN}docker ps${NC}                              List running containers"
  echo -e "    ${CYAN}docker logs -f goslimstratum${NC}           View stratum logs"
  echo -e "    ${CYAN}docker logs -f ${CONTAINER_NAME}${NC}                     View ${COIN_NAME} logs"
  echo -e "    ${CYAN}docker compose -f ${COMPOSE_DIR}/docker-compose.yml down${NC}   Stop all"
  echo -e "    ${CYAN}docker compose -f ${COMPOSE_DIR}/docker-compose.yml up -d${NC}  Start all"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  banner
  preflight
  create_data_dir
  setup_docker
  collect_config
  download_templates
  system_setup
  generate_configs
  start_node_and_wallet
  setup_postgres
  deploy_stack
  finish
}

main "$@"
