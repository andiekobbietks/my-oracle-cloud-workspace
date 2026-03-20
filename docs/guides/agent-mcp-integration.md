# Agent-visible MCP integration (for Copilot Chat / local agents)

Purpose
-------
This file explains how to expose the Chrome DevTools MCP server to a local Copilot Chat or MiniMax-style agent when the repository is opened locally. It is intended to be machine-readable and human-friendly so an agent or developer can find the steps quickly.

What this repo provides
-----------------------
- `.minimax-agent/mcp.json` — sample MCP server entry that starts `chrome-devtools-mcp` via `npx`.
- `.vscode/tasks.json` — VS Code tasks to start the MCP helper scripts.
- `scripts/start-mcp.sh` / `scripts/start-mcp.ps1` — start Chrome with `--remote-debugging-port` and run MCP.
- `scripts/verify-mcp.*` — verify the debug endpoint exists.

How an agent (or human) should enable and use the MCP tool
---------------------------------------------------------
1. Copy the workspace MCP config to the agent's user config (one-time, manual):

   - Linux/macOS: `cp .minimax-agent/mcp.json ~/.minimax-agent/mcp.json`
   - Windows PowerShell: `Copy-Item .minimax-agent\\mcp.json "$env:USERPROFILE\\.minimax-agent\\mcp.json"`

2. Start Chrome with the desired profile and the MCP server. Use the VS Code task or run the scripts directly:

   - VS Code: Command Palette → `Tasks: Run Task` → `Start MCP (PowerShell)` or `Start MCP (bash)`.
   - CLI examples:
     - PowerShell (example):
       ```powershell
       .\scripts\start-mcp.ps1 -Port 9222 -ProfilePath "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 1" -ChromePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
       ```
     - Bash (example):
       ```bash
       ./scripts/start-mcp.sh 9222 "$HOME/.config/google-chrome/Profile 1" /usr/bin/google-chrome
       ```

3. Verify MCP is reachable (run locally):
   - `./scripts/verify-mcp.sh 9222` or `.\scripts\verify-mcp.ps1 -Port 9222`

4. Configure Copilot Chat / local agent tools (manual step in VS Code UI):
   - Open Copilot Chat settings or the VS Code Tools configuration window.
   - Add a new tool entry named `chrome-devtools-mcp` and point it to the command in `.minimax-agent/mcp.json` (or to the `npx` command directly):
     - Command: `npx`
     - Args: `-y chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9222`

Notes & Security
----------------
- This repository only provides the scripts and sample config; you must perform the copy/registration steps locally because VS Code settings and Copilot tool registrations are user-scoped and cannot be changed by the repo.
- Use a dedicated Chrome profile for remote debugging to avoid exposing your primary browsing session.
- Do not expose the debugging port to the network. Keep MCP bound to `127.0.0.1`.

If you want, run the following commands on your machine after pulling this repo to finish setup:

PowerShell (copy config):
```powershell
git pull origin main
Copy-Item .minimax-agent\\mcp.json "$env:USERPROFILE\\.minimax-agent\\mcp.json"
```

Bash (copy config):
```bash
git pull origin main
cp .minimax-agent/mcp.json ~/.minimax-agent/mcp.json
```
