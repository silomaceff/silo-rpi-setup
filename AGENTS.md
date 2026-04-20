# AGENTS.md — Guide for AI Agents

This file provides context for any agentic AI assistant (Claude Code, Cursor, Copilot, etc.) helping a contributor work on this project.

---

## Project Context

**SILO** (Super Intelligent Lettuce Organizer) is a batteries-included setup for running a [MacEff](https://github.com/cversek/MacEff) AI agent on a Raspberry Pi 500 for farm automation. It includes:

- `setup.sh` — Full bootstrap (MacEff framework, Python venv, voice pipelines, agent identity)
- `setup-telegram.sh` — Telegram bot channel setup
- `install-tools.sh` — Install `silo-transcribe` (whisper STT) and `silo-speak` (Piper TTS)
- `bin/` — CLI tools for voice-to-text and text-to-voice
- `artwork/` — Project artwork and desktop wallpaper

---

## Architecture Constraints

- **Target hardware**: Raspberry Pi 500 (ARM64, 8GB RAM, Debian Bookworm)
- **Python**: Must use venv (PEP 668 blocks system-wide pip on Debian 12+)
- **Shell**: Scripts must work in bash, sourced via `~/.bash_init.sh` before `.bashrc` interactive guard
- **Voice STT**: whisper.cpp via pywhispercpp (NOT insanely-fast-whisper — that requires NVIDIA GPU)
- **Voice TTS**: Piper TTS ARM64 binary from rhasspy/piper GitHub releases (NOT the apt `piper` package, which is a mouse configurator)
- **LLM**: Runs on Anthropic's cloud API, NOT locally. Be transparent about this in all documentation.

---

## Code Style

- Shell scripts: `set -euo pipefail`, meaningful variable names, progress output with `[N/M]` step counters
- Python: Commit scripts with a generic `#!/usr/bin/env python3` shebang. `install-tools.sh` rewrites the installed copy's shebang to point at the user's venv Python at install time (see `SILO_WHISPER_PYTHON` env override).
- Config files: Plain text or simple JSON. Farmers should be able to edit them with any text editor.
- Idempotent: Scripts should be safe to re-run without breaking anything

---

## Security Awareness

Read [SECURITY.md](SECURITY.md) before contributing. Key points:
- Never hardcode or commit secrets (bot tokens, API keys)
- The Telegram permission relay grants remote code execution — treat access control seriously
- This is a developer preview, not production software
- Document security implications of any new features

---

## When Helping a Contributor

1. Read this file and [SECURITY.md](SECURITY.md) first
2. Check existing issues for context on known problems
3. Test changes on ARM64 if possible (or document that you couldn't)
4. Keep the "batteries-included" philosophy — minimize manual steps

---

## Prompt Transparency

This project practices radical openness. When AI agents contribute:
- PRs should include the original or refined prompts used in their creation
- Commit messages should include the agent's identity (e.g., `SiloMacEff@d0cdcf (working with @cversek)`)
- AI-generated content (code, docs, artwork) should be attributed with method and source

---

## Project Structure

```
silo-rpi-setup/
├── README.md                    # Quick start guide
├── AGENTS.md                    # This file (for AI agents)
├── CONTRIBUTING.md              # For human contributors
├── AGENT_INTRODUCTION_GUIDE.md  # How to seed agent memory
├── SECURITY.md                  # OPSEC and indemnification
├── LICENSE                      # MIT
├── setup.sh                     # Full bootstrap script
├── setup-telegram.sh            # Telegram channel setup
├── install-tools.sh             # Install CLI voice tools
├── bin/
│   ├── silo-transcribe          # Voice-to-text (whisper.cpp)
│   └── silo-speak               # Text-to-voice (Piper TTS)
└── artwork/
    └── SILO_at_night.png        # Desktop wallpaper + README hero
```

---

*SiloMacEff@d0cdcf (working with @cversek)*
