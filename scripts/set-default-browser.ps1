<#
Run as Administrator.

This script:
- Shows current defaults for http, https, .html and .htm
- Detects Chrome and its ProgId
- Prepares a DefaultAssociations XML and attempts to import it via DISM
- Falls back to opening Default Apps UI if DISM is unavailable or fails
#>

function Get-UserChoiceProgId {
    param([string]$KeyPath)
    try {
        $hk = "HKCU:\Software\Microsoft\Windows\Shell\Associations\$KeyPath\UserChoice"
        if (Test-Path $hk) {
            $v = Get-ItemProperty -Path $hk -ErrorAction Stop
            return $v.ProgId
        }
    } catch { }
    return $null
}

$handlers = @{
    "http"  = "UrlAssociations\http"
    "https" = "UrlAssociations\https"
    ".htm"  = "UrlAssociations\\.htm"
    ".html" = "UrlAssociations\\.html"
}

Write-Host "Current user defaults (HKCU UserChoice ProgId):" -ForegroundColor Cyan
foreach ($k in $handlers.Keys) {
    $prog = Get-UserChoiceProgId -KeyPath $handlers[$k]
    if ($prog) { $display = $prog } else { $display = "<not set>" }
    Write-Host ("  {0,-6}: {1}" -f $k, $display)
}

Write-Host "`nDetecting Chrome installation..." -ForegroundColor Cyan
$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
$chromeExe = $null
foreach ($p in $chromePaths) { if (Test-Path $p) { $chromeExe = $p; break } }

if (-not $chromeExe) {
    try {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction SilentlyContinue
        if ($reg -and $reg.Path) { $chromeExe = $reg.Path }
        if (-not $chromeExe) {
            $regx = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" -ErrorAction SilentlyContinue
            if ($regx -and $regx.Path) { $chromeExe = $regx.Path }
        }
    } catch { }
}

if (-not $chromeExe) {
    try { $which = & where.exe chrome 2>$null; if ($which) { $chromeExe = $which.Split("`n")[0].Trim() } } catch { }
}

if ($chromeExe) { Write-Host "Found Chrome executable at: $chromeExe" -ForegroundColor Green } else { Write-Host "Chrome not found; open Default Apps manually." -ForegroundColor Yellow; Start-Process ms-settings:defaultapps; exit 1 }

Write-Host "`nAttempting to discover Chrome ProgId..." -ForegroundColor Cyan
$chromeProgId = $null
try {
    $candidates = @("ChromeHTML","ChromeHTML.open","ChromeHTML2")
    foreach ($pid in $candidates) {
        $cmdPath = "HKCR:\$pid\shell\open\command"
        if (Test-Path $cmdPath) {
            $cmd = (Get-ItemProperty -Path $cmdPath -ErrorAction SilentlyContinue).'(default)'
            if ($cmd -and $cmd -match [regex]::Escape($chromeExe)) { $chromeProgId = $pid; break }
        }
    }
    if (-not $chromeProgId) {
        $keys = Get-ChildItem HKCR: -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName }
        foreach ($k in $keys) {
            try {
                $cmdPath = "HKCR:\$k\shell\open\command"
                if (Test-Path $cmdPath) {
                    $cmd = (Get-ItemProperty -Path $cmdPath -ErrorAction SilentlyContinue).'(default)'
                    if ($cmd -and $cmd -match [regex]::Escape($chromeExe)) { $chromeProgId = $k; break }
                }
            } catch { }
        }
    }
} catch { }

if (-not $chromeProgId) { Write-Host "Could not determine a Chrome ProgId. Defaulting to 'ChromeHTML'." -ForegroundColor Yellow; $chromeProgId = "ChromeHTML" } else { Write-Host "Detected Chrome ProgId: $chromeProgId" -ForegroundColor Green }

$tmpXml = Join-Path $env:TEMP "assoc-chrome.xml"
$assocs = @(
    @{ Identifier = ".htm";  ProgId = $chromeProgId },
    @{ Identifier = ".html"; ProgId = $chromeProgId },
    @{ Identifier = "http";  ProgId = $chromeProgId },
    @{ Identifier = "https"; ProgId = $chromeProgId }
)

$xml = New-Object System.Xml.XmlDocument
$pi = $xml.CreateXmlDeclaration("1.0","UTF-8",$null); $xml.AppendChild($pi) | Out-Null
$root = $xml.CreateElement("DefaultAssociations"); $xml.AppendChild($root) | Out-Null
foreach ($a in $assocs) { $node = $xml.CreateElement("Association"); $node.SetAttribute("Identifier", $a.Identifier); $node.SetAttribute("ProgId", $a.ProgId); $root.AppendChild($node) | Out-Null }
$xml.Save($tmpXml)
Write-Host "`nPrepared associations file at: $tmpXml" -ForegroundColor Cyan
Write-Host "Contents:"; Get-Content $tmpXml | ForEach-Object { Write-Host "  $_" }

Write-Host "`nThis will attempt to set those defaults using DISM (requires Administrator)." -ForegroundColor Yellow
$confirm = Read-Host "Proceed to apply these associations now? (Y/N)"
if ($confirm -notin @('Y','y')) { Write-Host "Aborted by user." -ForegroundColor Yellow; exit 0 }

Write-Host "`nApplying associations via DISM..." -ForegroundColor Cyan
try {
    $proc = Start-Process -FilePath "dism.exe" -ArgumentList "/online","/Import-DefaultAppAssociations:$tmpXml" -Wait -NoNewWindow -PassThru -ErrorAction Stop
    if ($proc.ExitCode -eq 0) { Write-Host "DISM import reported success. Sign out/in for changes to apply." -ForegroundColor Green }
    else { Write-Host "DISM exited with code $($proc.ExitCode). It may not be supported or policy blocks it." -ForegroundColor Yellow; Start-Process ms-settings:defaultapps }
} catch {
    Write-Host "Failed to run DISM or import associations: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Opening Default Apps UI for manual change..." -ForegroundColor Cyan
    Start-Process ms-settings:defaultapps
}

Write-Host "`nDone. Re-check current defaults after sign-out/sign-in or restart if needed." -ForegroundColor Cyan
