param(
  [string]$ChromePath = "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  [string]$Url = "https://cloud.oracle.com/cloudshell"
)

if (Test-Path $ChromePath) {
  Start-Process -FilePath $ChromePath -ArgumentList $Url
  exit 0
}

# Try default start
try {
  Start-Process -FilePath "chrome" -ArgumentList $Url -ErrorAction Stop
} catch {
  Write-Error "Could not find Chrome at $ChromePath and 'chrome' not on PATH. Open the Cloud Shell URL manually: $Url"
  exit 2
}
