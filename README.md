# SILO RPi Setup

![SILO at Night](artwork/SILO_at_night.png)

*"SILO at Night" — AI-generated artwork by @cversek using [ChatGPT 5.4 image generation](https://chatgpt.com/share/69c5fbea-671c-832f-b879-79fa54d0b6b1). Radical openness: source prompts and method linked.*

> **Developer Preview** — This project is for research and educational purposes. It has not been formally audited for security. See [SECURITY.md](SECURITY.md) for risks, OPSEC guidance, and indemnification. Licensed under [MIT](LICENSE).

**Batteries-included setup for a [MacEff](https://github.com/cversek/MacEff) AI agent on Raspberry Pi 500.**

Turn a fresh Raspberry Pi into a farm automation assistant with voice input/output and Telegram remote control — in under 30 minutes.

## What You Get

| Component | What It Does | Runs Where |
|---|---|---|
| **Claude Code** | AI reasoning via Anthropic API | Cloud (requires Max/Team/Enterprise plan) |
| **MacEff Framework** | Agent identity, memory, compaction recovery | Local (RPi) |
| **Telegram Channel** | Remote messaging + permission relay from phone | Local bridge → Telegram API |
| **Whisper STT** | Voice-to-text (whisper.cpp, ARM NEON optimized) | Local (RPi) |
| **Piper TTS** | Text-to-voice (neural, Ryan voice) | Local (RPi) |

**Architecture honesty**: The LLM runs in Anthropic's cloud. The Pi runs everything else. Fully local LLM is a future goal.

## Quick Start

### Prerequisites

1. Raspberry Pi 500 with fresh Raspberry Pi OS Bookworm 64-bit
2. Internet connection
3. [Claude Code](https://claude.ai/code) installed and authenticated:
   ```bash
   # Install Claude Code (bundled installer — no Node.js required)
   curl -fsSL https://claude.ai/install.sh | bash

   # Authenticate (opens browser)
   claude
   ```

### Step 1: Run Setup Script

```bash
git clone https://github.com/silomaceff-d0cdcf/silo-rpi-setup.git
cd silo-rpi-setup
chmod +x setup.sh
./setup.sh
```

This installs everything: MacEff framework, hooks, voice pipelines, context profiles, agent identity.

**Optional**: Set your agent name before running:
```bash
SILO_AGENT_NAME=myagent ./setup.sh
```

### Step 2: Set Display Name

```bash
sudo chfn -f "Silo MacEff" $(whoami)
```

### Step 3: Log Out and Back In

Applies keyboard layout fix and shell environment changes.

### Step 4: Launch

```bash
claude -c
```

Verify with `macf_tools env` — you should see your agent identity and all paths configured.

## Telegram Setup (Optional)

Enables remote messaging and permission relay from your phone.

### Create a Bot

1. Open Telegram → search **@BotFather** → Start
2. Send `/newbot`
3. Choose a name and username (must end in `bot`)
4. Copy the bot token

### Run Telegram Setup

```bash
./setup-telegram.sh YOUR_BOT_TOKEN
```

### Launch with Telegram

```bash
claude --channels plugin:telegram@claude-plugins-official -c
```

Then in the Claude Code session:
1. `/plugin install telegram` — pulls the latest official plugin from `claude-plugins-official`
2. `/reload-plugins` — register the plugin's MCP server
3. `/mcp` — confirm the telegram MCP is connected
4. Send a message to your bot from your phone
5. Pair: `/telegram:access pair <code>`
6. Lock down: `/telegram:access policy allowlist`

After first setup, just use: `launch_silo`

## Voice Tools

### Transcribe Speech

```bash
silo-transcribe recording.oga
```

With specific context profile:
```bash
silo-transcribe recording.oga --context lettuce-farm
```

Manage profiles:
```bash
silo-transcribe --list-contexts
silo-transcribe --set-context lettuce-farm
silo-transcribe --show-context
```

Context profiles are plain text files at `~/.config/silo/whisper/contexts/` — edit freely.

### Generate Speech

```bash
silo-speak "Soil moisture looks good today." --ogg output.ogg
```

Manage voices:
```bash
silo-speak --list-voices
silo-speak --set-voice amy
silo-speak "Hello" --voice joe --ogg test.ogg
```

Voice models at `~/.local/share/piper/`. Browse more at [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices).

## Benchmarks (RPi 500)

### Whisper STT (tiny.en)

| Audio | Transcribe | RTF | RAM |
|---|---|---|---|
| 5.9s | 9.8s | 1.68x | 187 MB |
| 8.4s | 12.5s | 1.49x | 228 MB |
| 26.4s | 17.1s | 0.65x | 237 MB |

### Piper TTS (Ryan medium)

| Metric | Value |
|---|---|
| Generation | 2.6s per ~4.4s audio |
| Model | 61 MB |
| RAM | ~150 MB |

## Troubleshooting

| Problem | Fix |
|---|---|
| Keyboard: £ instead of # | Run `setup.sh` (fixes labwc layout), log out/in |
| `macf_tools` not found | `source ~/.bash_init.sh` |
| "Could not determine session path" | `mkdir -p ~/.claude/tasks/$(macf_tools session info \| python3 -c "import json,sys;print(json.load(sys.stdin)['session_id'])")` |
| Telegram plugin not found | `claude plugins marketplace update` then `/plugin` |
| Telegram 409 Conflict | `pkill -f "bun.*server.ts"` |
| Whisper sample rate error | Use `silo-transcribe` (auto-converts via ffmpeg) |
| `piper` is wrong program | The apt `piper` is a mouse tool. Real Piper TTS is at `~/.local/share/piper/piper/piper` |

## Deep Dive

For the full first-principles tutorial explaining every step and why, see:
[rpi500_silo_setup.md](https://gist.github.com/silomaceff/35e730e5dd03060b01561b7a9dcaa0bf)

## Introducing Your Agent

After technical setup, your agent needs context: who you are, what the project is, and who you work with. This is the most important step — a well-introduced agent is dramatically more useful.

See **[AGENT_INTRODUCTION_GUIDE.md](AGENT_INTRODUCTION_GUIDE.md)** for a complete walkthrough with templates and examples.

## Documentation

| Document | Purpose |
|---|---|
| [README.md](README.md) | Quick start (this file) |
| [AGENT_INTRODUCTION_GUIDE.md](AGENT_INTRODUCTION_GUIDE.md) | How to seed agent memory with your context |
| [SECURITY.md](SECURITY.md) | OPSEC warnings, risks, indemnification |
| [Deep-dive tutorial](https://gist.github.com/silomaceff/35e730e5dd03060b01561b7a9dcaa0bf) | First-principles walkthrough explaining every step |
| [LICENSE](LICENSE) | MIT License |

## About

Built for the [PVOS](https://pvos.org) / [FarmHack](https://farmhack.org) / [Edge Collective](https://edgecollective.io) open agricultural technology community.

**SILO** = Super Intelligent Lettuce Organizer

---

*SiloMacEff@d0cdcf (working with @cversek)*
