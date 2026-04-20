#!/bin/bash
# SILO RPi Setup — Batteries-included MacEff agent bootstrap
# Run: curl -fsSL https://raw.githubusercontent.com/silomaceff-d0cdcf/silo-rpi-setup/main/setup.sh | bash
#
# Prerequisites:
#   - Raspberry Pi 500 with RPi OS Bookworm 64-bit
#   - Internet connection
#   - Claude Code already installed and authenticated (see README)
#
# SiloMacEff@d0cdcf (working with @cversek)

set -euo pipefail

AGENT_NAME="${SILO_AGENT_NAME:-silo}"
MACEFF_REPO="https://github.com/cversek/MacEff.git"
GITWORK="$HOME/gitwork/cversek"

echo "========================================="
echo "  SILO RPi Setup — MacEff Agent Bootstrap"
echo "  Agent: $AGENT_NAME"
echo "========================================="
echo ""

# --- Phase 1: Fix RPi OS issues ---
echo "[1/7] Fixing keyboard layout (US)..."
mkdir -p ~/.config/labwc
cat > ~/.config/labwc/environment << 'EOF'
XKB_DEFAULT_MODEL=pc105
XKB_DEFAULT_LAYOUT=us
XKB_DEFAULT_VARIANT=
XKB_DEFAULT_OPTIONS=
EOF
echo "  Done. (Log out/in to apply)"

# --- Phase 2: System packages ---
echo "[2/7] Installing system packages..."
sudo apt update -qq
sudo apt install -y -qq ffmpeg fonts-noto-color-emoji git curl > /dev/null 2>&1
echo "  Done."

# --- Phase 3: Clone MacEff ---
echo "[3/7] Cloning MacEff framework..."
mkdir -p "$GITWORK"
if [ -d "$GITWORK/MacEff" ]; then
    echo "  MacEff already cloned, pulling latest..."
    (cd "$GITWORK/MacEff" && git pull -q)
else
    git clone -q "$MACEFF_REPO" "$GITWORK/MacEff"
fi
echo "  Done."

# --- Phase 4: Python venv + macf ---
echo "[4/7] Creating Python venv and installing macf..."
python3 -m venv ~/.venvs/macf
~/.venvs/macf/bin/pip install -q -e "$GITWORK/MacEff/macf"
echo "  Done. (macf $(~/.venvs/macf/bin/macf_tools --version 2>/dev/null || echo 'installed'))"

# --- Phase 5: Shell initialization ---
echo "[5/7] Configuring shell environment..."

# Generate UUID
UUID=$(python3 -c "import uuid; print(uuid.uuid4().hex)")
UUID_PREFIX="${UUID:0:6}"
echo "$UUID" > ~/.maceff_primary_agent.id
echo "  Agent UUID: $UUID_PREFIX"

# Create .bash_init.sh
cat > ~/.bash_init.sh << INITEOF
#!/bin/bash
# MacEff: Shell initialization for interactive and non-interactive shells
export BASH_ENV="\$HOME/.bash_init.sh"
export MACEFF_ROOT_DIR="\$HOME/gitwork/cversek/MacEff"
export MACEFF_AGENT_HOME_DIR="\$HOME"
export MACEFF_AGENT_NAME="$AGENT_NAME"
export MACF_CONTEXT_WINDOW=1000000
export PATH="\$HOME/.venvs/macf/bin:\$HOME/.local/bin:\$PATH"
INITEOF
chmod 755 ~/.bash_init.sh

# Patch .bashrc (idempotent)
if ! grep -q "MacEff: Source BEFORE interactive guard" ~/.bashrc 2>/dev/null; then
    TMPRC=$(mktemp)
    cat > "$TMPRC" << 'RCEOF'
# MacEff: Source BEFORE interactive guard (for bash -c commands)
if [ -f ~/.bash_init.sh ]; then
    . ~/.bash_init.sh
fi

RCEOF
    cat ~/.bashrc >> "$TMPRC"
    mv "$TMPRC" ~/.bashrc
    echo "  Patched .bashrc"
else
    echo "  .bashrc already patched"
fi

# Source for current session
source ~/.bash_init.sh
echo "  Done."

# --- Phase 5b: Desktop wallpaper ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER="$SCRIPT_DIR/artwork/SILO_at_night.png"
if [ -f "$WALLPAPER" ]; then
    mkdir -p ~/Pictures
    cp "$WALLPAPER" ~/Pictures/SILO_at_night.png
    # Set wallpaper via pcmanfm config (labwc desktop manager)
    PCMANFM_DIR="$HOME/.config/pcmanfm/LXDE-pi"
    mkdir -p "$PCMANFM_DIR"
    for conf in "$PCMANFM_DIR"/desktop-items-*.conf; do
        if [ -f "$conf" ]; then
            sed -i "s|^wallpaper=.*|wallpaper=$HOME/Pictures/SILO_at_night.png|" "$conf"
            sed -i "s|^wallpaper_mode=.*|wallpaper_mode=crop|" "$conf"
        fi
    done
    # Create default config if none exists
    if [ ! -f "$PCMANFM_DIR/desktop-items-HDMI-A-1.conf" ]; then
        cat > "$PCMANFM_DIR/desktop-items-HDMI-A-1.conf" << WPEOF
[*]
wallpaper=$HOME/Pictures/SILO_at_night.png
wallpaper_mode=crop
WPEOF
    fi
    echo "  Desktop wallpaper set (SILO at Night)"
fi

# --- Phase 6: MacEff framework install ---
echo "[6/7] Installing MacEff framework..."
macf_tools hooks install --global 2>&1 | tail -1
macf_tools framework install --skip-hooks 2>&1 | tail -1
macf_tools agent init -y 2>&1 | tail -1
macf_tools statusline install 2>&1 | tail -1

# Bootstrap task directory
SESSION_ID=$(macf_tools session info 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
if [ "$SESSION_ID" != "unknown" ]; then
    mkdir -p ~/.claude/tasks/"$SESSION_ID"
    echo "  Task directory bootstrapped."
fi
echo "  Done."

# --- Phase 7: Voice pipelines ---
echo "[7/7] Installing voice pipelines..."

# Whisper STT
python3 -m venv ~/.venvs/whisper
~/.venvs/whisper/bin/pip install -q pywhispercpp
echo "  Whisper STT installed."

# Download tiny.en model
~/.venvs/whisper/bin/python3 -c "
from pywhispercpp.model import Model
m = Model('tiny.en')
print('  Whisper tiny.en model downloaded.')
" 2>/dev/null

# Whisper context profiles
mkdir -p ~/.config/silo/whisper/contexts
cat > ~/.config/silo/whisper/contexts/default.txt << 'EOF'
General farming and automation vocabulary.
soil moisture, drip irrigation, seedlings, transplant, harvest, compost,
row planting, raised bed, greenhouse, hoop house, cold frame,
FarmOS, sensor, temperature, humidity, water level, pH,
lettuce, tomato, pepper, squash, bean, herb, garlic, onion,
tractor, cultivator, tiller, mower, irrigation timer,
MacEff, Silo MacEff, SiloMacEff
EOF
ln -sf ~/.config/silo/whisper/contexts/default.txt ~/.config/silo/whisper/active_context.txt

# Piper TTS
mkdir -p ~/.local/share/piper
(cd /tmp && curl -sL "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_aarch64.tar.gz" -o piper_aarch64.tar.gz && tar -xzf piper_aarch64.tar.gz -C ~/.local/share/piper/)
echo "  Piper TTS installed."

# Download Ryan voice
curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx" -o ~/.local/share/piper/en_US-ryan-medium.onnx
curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json" -o ~/.local/share/piper/en_US-ryan-medium.onnx.json
mkdir -p ~/.config/silo/tts/voices
ln -sf ~/.local/share/piper/en_US-ryan-medium.onnx ~/.config/silo/tts/voices/active.onnx
ln -sf ~/.local/share/piper/en_US-ryan-medium.onnx.json ~/.config/silo/tts/voices/active.onnx.json
echo "  Ryan voice downloaded and set as default."

echo ""
echo "========================================="
echo "  Setup complete!"
echo "  Agent: ${AGENT_NAME}@${UUID_PREFIX}"
echo ""
echo "  Next steps:"
echo "  1. Log out and back in (keyboard fix)"
echo "  2. Set display name: sudo chfn -f \"Your Agent Name\" $(whoami)"
echo "  3. Launch: claude -c"
echo "  4. For Telegram: see README for bot setup"
echo "========================================="
