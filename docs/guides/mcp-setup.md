# Chrome DevTools MCP quick setup

This guide contains small, user-run scripts to start Chrome with remote debugging and run the MCP server locally. You must run these on your local machine (not the Codespace) because they start your local Chrome instance and use your profile.

- Cloud Shell URL: https://cloud.oracle.com/cloudshell
- Bash helper: `scripts/start-mcp.sh`
- PowerShell helper: `scripts/start-mcp.ps1`

Basic usage (Linux/macOS):
```bash
./scripts/start-mcp.sh 9222 "$HOME/.config/google-chrome/Profile 2" /path/to/google-chrome
```

Basic usage (Windows PowerShell):
```powershell
.\scripts\start-mcp.ps1 -Port 9222 -ProfilePath "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 2" -ChromePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
```

After starting the script:
- Verify the debug endpoint: `http://127.0.0.1:9222/json`
- Start `npx -y chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9222` (the bash/ps1 scripts do this for you)

Security notes:
- Do not expose the debugging port to untrusted networks.
- Prefer a dedicated Chrome profile when using remote debugging.

Registering MCP with your local agent and VS Code
-------------------------------------------------

1. Workspace MCP config
	- A sample agent config is available at `.minimax-agent/mcp.json` in this repository. You can copy that into your user agent config (for example `%USERPROFILE%\.minimax-agent\mcp.json` on Windows or `~/.minimax-agent/mcp.json` on Linux/macOS) so your agent knows how to start or call the `chrome-devtools` MCP server.

2. Start MCP from VS Code
	- Use the VS Code tasks: open the Command Palette and run `Tasks: Run Task` → choose `Start MCP (bash)` or `Start MCP (PowerShell)` depending on your OS. The task will start Chrome with remote debugging (using the profile path you supply) and then run the MCP server via `npx`.

3. How the agent uses it
	- Once Chrome is running with `--remote-debugging-port=9222` and the MCP server is active, your local MiniMax/agent client can call the MCP at `http://127.0.0.1:9222` via the MCP server command configured in `.minimax-agent/mcp.json`.

Notes and safety
----------------
- This repository can only provide the config and tasks; you must copy workspace config into your user agent configuration for the agent to use it as a long-lived tool.
- I cannot change your global VS Code tool settings or register tools in your personal environment remotely; you must accept the workspace files and run the task locally.

