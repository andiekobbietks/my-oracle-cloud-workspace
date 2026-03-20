# Agent Instructions — Chrome DevTools MCP Integration

Purpose
-------
This file is for local agents (Copilot Chat / MiniMax / similar) and humans who open this repository locally. It contains the minimal, machine-friendly instructions an agent needs to find and use the Chrome DevTools MCP server provided by this repo.

Where to find the implementation (doc-as-code)
---------------------------------------------
- MCP server config sample: `.minimax-agent/mcp.json`
- VS Code tasks: `.vscode/tasks.json`
- Start scripts: `scripts/start-mcp.sh` (bash) and `scripts/start-mcp.ps1` (PowerShell)
- Verify scripts: `scripts/verify-mcp.sh` and `scripts/verify-mcp.ps1`
- User-facing guides: `docs/guides/mcp-setup.md`, `docs/guides/mcp-checklist.md`, `docs/guides/agent-mcp-integration.md`

Agent checklist (automatable)
-----------------------------
1. Ensure the workspace is checked out and up-to-date.
   - `git pull origin main`

2. Ensure Node.js and Chrome are available on the local host.
   - `node --version` (needs v20+)
   - Chrome must be installed and reachable.

3. Copy the workspace MCP sample into the agent's user MCP config (manual step):
   - Linux/macOS: `cp .minimax-agent/mcp.json ~/.minimax-agent/mcp.json`
   - Windows PowerShell: `Copy-Item .minimax-agent\\mcp.json "$env:USERPROFILE\\.minimax-agent\\mcp.json"`

4. Start Chrome with remote debugging and run the MCP server (the repo provides tasks and scripts):
   - Use VS Code Task: Command Palette → `Tasks: Run Task` → `Start MCP (PowerShell)` or `Start MCP (bash)`.
   - Or run directly:
     - PowerShell example:
       ```powershell
       .\scripts\start-mcp.ps1 -Port 9222 -ProfilePath "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 1" -ChromePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
       ```
     - Bash example:
       ```bash
       ./scripts/start-mcp.sh 9222 "$HOME/.config/google-chrome/Profile 1" /path/to/google-chrome
       ```

5. Verify the MCP debug endpoint is reachable:
   - `./scripts/verify-mcp.sh 9222` or `.\scripts\verify-mcp.ps1 -Port 9222`

6. Configure local Copilot Chat / agent tools (user-scoped, required):
   - Register a tool named `chrome-devtools-mcp` pointing to `npx` with args `-y chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9222`.
   - In VS Code: open the Tools configuration UI and allow the new tool for chat sessions.

Security & safety
-----------------
- Always use a dedicated Chrome profile when enabling remote debugging.
- Keep the debug endpoint bound to `127.0.0.1`; do not expose it to untrusted networks.
- The repository only supplies scripts and sample config; user approval is required for copying config into user-scoped files and for starting Chrome.

Where an agent can look programmatically
--------------------------------------
- Root: `agent.md` (this file)
- `.minimax-agent/mcp.json` — sample command/args
- `docs/guides/agent-mcp-integration.md` — step-by-step copy instructions

If anything in this file is missing or out of date, update the relevant `scripts/` or `docs/guides/` files and commit.
