#!/bin/sh
# install.sh - installer for the scrolls.md CLI (macOS / Linux)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/absilutely/scrolls-releases/main/install.sh | sh
#
# What it does:
#   1. Detects your OS (linux/darwin) and CPU arch (x64/arm64).
#   2. Downloads the matching `scrolls-<os>-<arch>` binary from the latest
#      GitHub release of absilutely/scrolls-releases.
#   3. Installs it to /usr/local/bin/scrolls (falling back to ~/.local/bin
#      if /usr/local/bin is not writable) and marks it executable.
#
# It is safe to re-run: it simply overwrites the existing binary with the
# latest release. If no matching asset exists yet it fails with a clear
# message rather than installing a broken file.

# Abort on any error or use of an unset variable.
set -eu

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
REPO="absilutely/scrolls-releases"
BIN_NAME="scrolls"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# ----------------------------------------------------------------------------
# 1. Detect OS
# ----------------------------------------------------------------------------
os="$(uname -s)"
case "$os" in
  Linux)  OS="linux"  ;;
  Darwin) OS="darwin" ;;
  *) err "unsupported OS: $os (this installer supports Linux and macOS; on Windows use install.ps1)" ;;
esac

# ----------------------------------------------------------------------------
# 2. Detect architecture
#    Asset naming uses: x64 and arm64
# ----------------------------------------------------------------------------
arch="$(uname -m)"
case "$arch" in
  x86_64 | amd64)         ARCH="x64"   ;;
  arm64 | aarch64)        ARCH="arm64" ;;
  *) err "unsupported architecture: $arch (supported: x86_64/amd64, arm64/aarch64)" ;;
esac

ASSET="${BIN_NAME}-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

info "Detected platform: ${OS}/${ARCH}"
info "Latest-release asset: ${ASSET}"

# ----------------------------------------------------------------------------
# 3. Pick a downloader (curl or wget)
# ----------------------------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  # -f: fail on HTTP error, -L: follow redirects, -o: output file
  download() { curl -fSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  download() { wget -q "$1" -O "$2"; }
else
  err "need either curl or wget installed to download the binary"
fi

# ----------------------------------------------------------------------------
# 4. Choose an install directory
#    Prefer /usr/local/bin; if it isn't writable, fall back to ~/.local/bin.
# ----------------------------------------------------------------------------
INSTALL_DIR="/usr/local/bin"
if [ ! -d "$INSTALL_DIR" ] || [ ! -w "$INSTALL_DIR" ]; then
  INSTALL_DIR="${HOME}/.local/bin"
  warn "/usr/local/bin is not writable; installing to ${INSTALL_DIR} instead"
  mkdir -p "$INSTALL_DIR"
fi
DEST="${INSTALL_DIR}/${BIN_NAME}"

# ----------------------------------------------------------------------------
# 5. Download to a temp file, then move into place atomically
# ----------------------------------------------------------------------------
TMP="$(mktemp "${TMPDIR:-/tmp}/${BIN_NAME}.XXXXXX")"
# Clean up the temp file on any exit.
trap 'rm -f "$TMP"' EXIT INT TERM

info "Downloading ${URL}"
if ! download "$URL" "$TMP"; then
  err "could not download ${ASSET}.
No matching release asset was found (yet) for ${OS}/${ARCH}.
Check the available downloads at:
  https://github.com/${REPO}/releases/latest"
fi

# Guard against an empty/placeholder file (e.g. a redirect to an error page).
if [ ! -s "$TMP" ]; then
  err "downloaded file is empty - the ${ASSET} asset may not be published yet.
See https://github.com/${REPO}/releases/latest"
fi

chmod +x "$TMP"
mv "$TMP" "$DEST"
# The move consumed the temp file, so the trap has nothing left to clean.
trap - EXIT INT TERM

# ----------------------------------------------------------------------------
# 6. Success message + PATH hint
# ----------------------------------------------------------------------------
info "Installed ${BIN_NAME} to ${DEST}"

# Warn if the install dir isn't on PATH so the user knows to fix it.
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) : ;;  # already on PATH - nothing to do
  *)
    warn "${INSTALL_DIR} is not on your PATH."
    warn "Add it, e.g.:  export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac

printf '\n\033[1;32mDone!\033[0m Verify with:\n  %s --version\n' "$BIN_NAME"
