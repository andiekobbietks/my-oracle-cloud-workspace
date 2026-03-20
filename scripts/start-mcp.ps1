param(
  [int]$Port = 9222,
  [string]$ProfilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Profile 1",
  [string]$ChromePath = "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
)

Write-Output "Starting Chrome with remote debugging on port $Port using profile: $ProfilePath"
Write-Output "Make sure all Chrome windows are closed first."
Start-Sleep -Seconds 1

Start-Process -FilePath $ChromePath -ArgumentList "--remote-debugging-port=$Port","--user-data-dir=$ProfilePath" -PassThru | Out-Null
Start-Sleep -Seconds 2
Write-Output "Starting chrome-devtools-mcp via npx. Press Ctrl+C to stop."
npx -y chrome-devtools-mcp@latest --browser-url="http://127.0.0.1:$Port"
