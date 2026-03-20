# MCP Setup Checklist

Follow this checklist on the machine where you'll run Chrome (Windows/macOS/Linux). Run each step and check the box when complete.

- [ ] Install Node.js v20+ (`node --version`)
- [ ] Ensure Google Chrome is installed
- [ ] Pick or create a dedicated Chrome profile (e.g., `Profile 1`)
- [ ] Close all Chrome windows
- [ ] Run the appropriate starter script:
  - Windows PowerShell: `scripts\start-mcp.ps1 -Port 9222 -ProfilePath "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 1" -ChromePath "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"`
  - Linux/macOS: `./scripts/start-mcp.sh 9222 "$HOME/.config/google-chrome/Profile 1" /path/to/google-chrome`
- [ ] Verify debug endpoint: open `http://127.0.0.1:9222/json` in a browser or run the verify script
- [ ] Start your MiniMax/agent client and ensure it can call the MCP server per `.minimax-agent/mcp.json`
- [ ] (Optional) Copy `.minimax-agent/mcp.json` to your user agent config (`~/.minimax-agent/mcp.json`)

If you run into issues, consult `docs/guides/mcp-setup.md` for troubleshooting tips.
