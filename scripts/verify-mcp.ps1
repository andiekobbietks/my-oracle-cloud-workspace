param(
  [int]$Port = 9222
)
$url = "http://127.0.0.1:$Port/json"
Write-Output "Checking MCP debug endpoint at $url"
try {
  $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
  $json = $resp.Content | ConvertFrom-Json
  Write-Output "OK: MCP debug endpoint returned JSON."
  $json | Format-List
} catch {
  Write-Error "ERROR: Could not fetch JSON from $url"
  Write-Output "Raw response:"
  Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Content
  exit 2
}
