#!/bin/bash
# Install silo-transcribe and silo-speak to ~/.local/bin
# Run from the repo root: ./install-tools.sh
#
# SiloMacEff@d0cdcf (working with @cversek)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/.local/bin

cp "$SCRIPT_DIR/bin/silo-transcribe" ~/.local/bin/silo-transcribe
cp "$SCRIPT_DIR/bin/silo-speak" ~/.local/bin/silo-speak
chmod +x ~/.local/bin/silo-transcribe ~/.local/bin/silo-speak

# Rewrite silo-transcribe's shebang to point at the whisper venv on THIS user's
# account. The committed copy uses a generic `#!/usr/bin/env python3` shebang so
# the repo stays user-agnostic; install time is when we bind it to $HOME.
WHISPER_PYTHON="${SILO_WHISPER_PYTHON:-$HOME/.venvs/whisper/bin/python3}"
if [ -x "$WHISPER_PYTHON" ]; then
  sed -i "1c#!/usr/bin/env $WHISPER_PYTHON" ~/.local/bin/silo-transcribe
  echo "Shebang set to: $WHISPER_PYTHON"
else
  echo "Warning: whisper venv python not found at $WHISPER_PYTHON"
  echo "  silo-transcribe installed with generic shebang; activate the whisper venv before use,"
  echo "  or re-run this script after running setup.sh, or set SILO_WHISPER_PYTHON env var."
fi

echo "Installed:"
echo "  ~/.local/bin/silo-transcribe"
echo "  ~/.local/bin/silo-speak"
echo ""
echo "Make sure ~/.local/bin is on your PATH."
