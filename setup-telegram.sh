#!/bin/bash
# SILO Telegram Channel Setup — uses the official Anthropic plugin from
# the claude-plugins-official marketplace (no custom fork required).
#
# Run AFTER setup.sh and creating a Telegram bot via @BotFather.
#
# Usage: ./setup-telegram.sh YOUR_BOT_TOKEN
#
# SiloMacEff@d0cdcf (working with @cversek)

set -euo pipefail

TOKEN="${1:-}"
if [ -z "$TOKEN" ]; then
    echo "Usage: ./setup-telegram.sh YOUR_BOT_TOKEN"
    echo ""
    echo "Get a token from @BotFather on Telegram:"
    echo "  1. Open Telegram → search @BotFather → Start"
    echo "  2. Send /newbot"
    echo "  3. Choose name and username (must end in 'bot')"
    echo "  4. Copy the token and run this script"
    exit 1
fi

echo "========================================="
echo "  SILO Telegram Channel Setup"
echo "========================================="
echo ""

# --- [1/3] Install Bun ---
# Bun is the JS/TS runtime the official plugin's server.ts uses at run time.
# The plugin itself is installed by Claude Code via /plugin install telegram,
# so we don't need to clone or bun-install any plugin source here.
echo "[1/3] Installing Bun runtime..."
if command -v bun &>/dev/null; then
    echo "  Bun already installed ($(bun --version))"
else
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    echo "  Bun installed ($(bun --version))"
fi

# --- [2/3] Save bot token ---
echo "[2/3] Saving bot token..."
mkdir -p ~/.claude/channels/telegram
echo "TELEGRAM_BOT_TOKEN=$TOKEN" > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env
echo "  Token saved at ~/.claude/channels/telegram/.env (chmod 600)."

# --- [3/3] Add launch alias ---
echo "[3/3] Configuring launch alias..."
if ! grep -q "launch_silo" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# MacEff: Launch Silo with Telegram channel (official plugin)" >> ~/.bashrc
    echo "alias launch_silo='claude --channels plugin:telegram@claude-plugins-official -c'" >> ~/.bashrc
    echo "  Added launch_silo alias to .bashrc"
else
    echo "  launch_silo alias already exists"
fi

echo ""
echo "========================================="
echo "  Telegram setup complete!"
echo ""
echo "  Next steps — in a Claude Code session:"
echo "  1. Launch:    claude --channels plugin:telegram@claude-plugins-official"
echo "                (or 'source ~/.bashrc && launch_silo' after first run)"
echo "  2. /plugin install telegram   # pulls the latest official version"
echo "  3. /reload-plugins            # register the MCP server"
echo "  4. /mcp                       # confirm telegram MCP is connected"
echo "  5. Send your first message to the bot from your phone"
echo "  6. /telegram:access pair <code>"
echo "  7. /telegram:access policy allowlist"
echo "========================================="
