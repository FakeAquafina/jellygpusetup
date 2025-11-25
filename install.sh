#!/usr/bin/env bash
#
# install.sh - Friendly installer wrapper for Jellyfin GPU setup
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/FakeAquafina/jellygpusetup/main/install.sh)"
#
set -euo pipefail

REPO_OWNER="FakeAquafina"
REPO_NAME="jellygpusetup"
BRANCH="${JELLYGPUSETUP_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

SCRIPT_NAME="setup_jellyfin.sh"
LOCAL_SCRIPT="./${SCRIPT_NAME}"

log() {
  printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

main() {
  log "Jellyfin GPU setup installer"
  log "Repository: ${REPO_OWNER}/${REPO_NAME} (branch: ${BRANCH})"

  # Basic requirements for fetching and running the script
  check_cmd curl
  check_cmd bash

  # Download the latest setup script
  log "Downloading latest ${SCRIPT_NAME} from GitHub…"
  curl -fsSL "${RAW_BASE}/${SCRIPT_NAME}" -o "${LOCAL_SCRIPT}" \
    || die "Failed to download ${SCRIPT_NAME} from ${RAW_BASE}"

  chmod +x "${LOCAL_SCRIPT}"

  log "Running ${SCRIPT_NAME}…"
  # Forward any arguments passed to install.sh down to the setup script
  "${LOCAL_SCRIPT}" "$@"

  log "Done."
}

main "$@"
