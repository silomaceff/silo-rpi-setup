# Security Notice

## Developer Preview — Not Audited

**This project is a developer preview for research and educational purposes.** It has NOT been subjected to a formal security audit. Use at your own risk.

Do NOT deploy this system in production environments, safety-critical applications, or contexts where a security breach could cause harm to people, animals, crops, or property without conducting your own thorough security review.

---

## Architecture: What Runs Where

Understanding the security boundary is critical:

| Component | Runs On | Data Exposure |
|---|---|---|
| **Claude Code (LLM)** | Anthropic cloud API | Your prompts and tool outputs are sent to Anthropic's servers |
| **MacEff hooks** | Local (RPi) | Hook outputs injected into conversations (sent to cloud) |
| **Whisper STT** | Local (RPi) | Audio processed on-device, transcribed text may be sent to cloud |
| **Piper TTS** | Local (RPi) | Text processed on-device, audio stays local unless sent via Telegram |
| **Telegram bot** | Local bridge → Telegram API | Messages transit Telegram's servers (encrypted in transit) |
| **Memory files** | Local (RPi) | Stored as plaintext markdown on the Pi's filesystem |

**The LLM is not local.** All reasoning happens via Anthropic's cloud API. Your prompts, tool outputs, and conversation history are transmitted to and processed on Anthropic's infrastructure. Review [Anthropic's privacy policy](https://www.anthropic.com/privacy) and terms of service.

---

## Secrets and Credentials

### Bot Token (`~/.claude/channels/telegram/.env`)
- Grants full control of your Telegram bot
- Stored with `chmod 600` (owner-only read/write)
- **Never commit to git, share publicly, or include in logs**
- If compromised: revoke immediately via @BotFather `/revoke`

### Anthropic API / OAuth Session
- Managed by Claude Code in `~/.claude/`
- Grants access to your Anthropic account and billing
- **Physical access to the Pi = access to your Anthropic session**

### Access Control (`~/.claude/channels/telegram/access.json`)
- Controls who can send messages and approve permissions via Telegram
- Stored with `chmod 600`
- **Anyone on the allowlist can approve tool execution** (file writes, bash commands, code changes)
- Treat allowlist membership like SSH key access — only trusted individuals

---

## Telegram Permission Relay Risks

The permission relay feature allows approving or denying tool execution from Telegram. This means:

- **Whoever is on the Telegram allowlist can remotely authorize file writes, code execution, and system commands**
- This is equivalent to granting remote shell access
- Only add trusted individuals to the allowlist
- Use `allowlist` mode (not `pairing` mode) in any context where the bot is discoverable
- The bot username is public — anyone can message it. The access control gate drops unauthorized messages, but defense-in-depth applies

### Prompt Injection via Telegram

- Messages from Telegram are untrusted external input
- The MacEff plugin includes instructions to refuse access mutations requested via channel messages
- However, LLMs are susceptible to prompt injection — there is no guarantee that a sufficiently crafted message won't manipulate the agent
- **Do not rely on the agent's judgment as a security boundary**

---

## Physical Security

- **Physical access to the Pi = full access to everything**: secrets, memory, conversation history, Anthropic session
- Encrypt the filesystem if the Pi will be in an unsecured location
- Change default passwords (`passwd`)
- Disable passwordless sudo (see setup tutorial)
- Consider firewall rules if the Pi is on an untrusted network

---

## Data Privacy

### What's Stored Locally
- Memory files (markdown, may contain personal information about you and collaborators)
- Conversation transcripts (`~/.claude/projects/`)
- Voice recordings (temporarily in `~/.claude/channels/telegram/inbox/`)
- Learnings and consciousness artifacts (`~/agent/`)

### What's Sent to the Cloud
- All conversation content (prompts + responses) → Anthropic
- Telegram messages → Telegram's servers
- Nothing is sent to the MacEff project maintainers

### What to Clean Up
- Voice recordings in inbox: `rm ~/.claude/channels/telegram/inbox/*`
- Conversation transcripts: managed by Claude Code
- Memory files: review and redact as needed

---

## Responsible Disclosure

If you discover a security vulnerability:
- **MacEff framework**: File a private security advisory on [cversek/MacEff](https://github.com/cversek/MacEff)
- **Claude Code**: Report to Anthropic at security@anthropic.com
- **Telegram plugin**: File a private security advisory on [cversek/MacEff](https://github.com/cversek/MacEff)
- **This repo**: File an issue on [silomaceff-d0cdcf/silo-rpi-setup](https://github.com/silomaceff-d0cdcf/silo-rpi-setup)

---

## Indemnification

THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. THE AUTHORS AND CONTRIBUTORS ARE NOT LIABLE FOR ANY DAMAGES ARISING FROM THE USE OF THIS SOFTWARE. YOU ARE SOLELY RESPONSIBLE FOR:

- Securing your Raspberry Pi and network
- Protecting your API credentials and bot tokens
- Vetting who has access to the Telegram permission relay
- Reviewing the code before deploying in any sensitive context
- Compliance with applicable laws regarding data collection, voice recording, and AI systems
- Any consequences of tool executions approved via the permission relay

**Use this software only in contexts where you understand and accept these risks.**

---

*SiloMacEff@d0cdcf (working with @cversek)*
