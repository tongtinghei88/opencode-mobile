param()

$ErrorActionPreference = "Stop"

$ExpectedIp = "192.168.50.202"
$AdapterPort = 8790
$PreviewPort = 4173
$AppUrl = "http://192.168.50.202:4173/"
$AdapterUrl = "http://192.168.50.202:8790/api/local/v0/summary"
$StateDir = Join-Path $env:TEMP "web-readonly-status"
$AdapterPidFile = Join-Path $StateDir "adapter.pid.json"
$PreviewPidFile = Join-Path $StateDir "preview.pid.json"
$WarningPorts = @(4096, 3000, 8081, 5173)

function Test-ExpectedIp {
  $matches = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
    Where-Object { $_.IPAddress -eq $ExpectedIp }
  return [bool]$matches
}

function Test-Listening($Port) {
  $listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
  return [bool]$listener
}

function Show-PidFile($Label, $Path) {
  if (Test-Path -LiteralPath $Path) {
    try {
      $entry = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
      $pidValue = [int]$entry.pid
      $running = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
      if ($running) {
        Write-Host "$Label PID file: $Path (PID $pidValue running)"
      } else {
        Write-Host "$Label PID file: $Path (PID $pidValue not running)"
      }
    } catch {
      Write-Host "$Label PID file: $Path (unreadable)"
    }
  } else {
    Write-Host "$Label PID file: missing"
  }
}

function Invoke-BasicHttpCheck($Label, $Url) {
  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
    Write-Host "$Label HTTP: $($response.StatusCode)"
  } catch {
    Write-Host "$Label HTTP: FAILED ($($_.Exception.Message))"
  }
}

Write-Host "Web Read-Only Status launch pack status"
Write-Host "PC has $ExpectedIp`: $(Test-ExpectedIp)"
Write-Host "Adapter listening on $AdapterPort`: $(Test-Listening $AdapterPort)"
Write-Host "Preview listening on $PreviewPort`: $(Test-Listening $PreviewPort)"
Write-Host "App URL: $AppUrl"
Write-Host "Approved endpoint: $AdapterUrl"
Show-PidFile "Adapter" $AdapterPidFile
Show-PidFile "Preview" $PreviewPidFile
Invoke-BasicHttpCheck "App" $AppUrl
Invoke-BasicHttpCheck "Adapter" $AdapterUrl

foreach ($port in $WarningPorts) {
  if (Test-Listening $port) {
    Write-Warning "Unexpected listener on port $port"
  }
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0 -and $repoRoot) {
  Write-Host ""
  Write-Host "Git status:"
  git status --short --branch
}
