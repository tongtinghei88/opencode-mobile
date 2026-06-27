param(
  [ValidateRange(1, 30)]
  [int]$TimeoutSec = 5
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$ExpectedIp = "192.168.50.202"
$AdapterPort = 8790
$PreviewPort = 4173
$AdapterPath = "C:\Codex-Recovery\opencode-local-adapter-spike3O\server.mjs"
$StateDir = Join-Path $env:TEMP "web-readonly-status"
$AdapterPidFile = Join-Path $StateDir "adapter.pid.json"
$PreviewPidFile = Join-Path $StateDir "preview.pid.json"
$AdapterLog = Join-Path $StateDir "adapter.log"
$AdapterErrorLog = Join-Path $StateDir "adapter.err.log"
$PreviewLog = Join-Path $StateDir "preview.log"
$PreviewErrorLog = Join-Path $StateDir "preview.err.log"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Get-RepoRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
}

function Test-ExpectedIp {
  $matches = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
    Where-Object { $_.IPAddress -eq $ExpectedIp }
  return [bool]$matches
}

function Wait-ForPort($Port, $TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $portMap = Get-PortObservationMap -Ports @($Port) -TimeoutSec ([Math]::Min($TimeoutSec, 5))
    if ($portMap[$Port].State -eq "LISTENING") {
      return $true
    }
    Start-Sleep -Milliseconds 300
  }
  return $false
}

function Write-PidFile($Path, $Name, $Process, $CommandLine, $LogPath) {
  [pscustomobject]@{
    name = $Name
    pid = $Process.Id
    commandLine = $CommandLine
    log = $LogPath
    startedAt = (Get-Date).ToString("o")
  } | ConvertTo-Json | Set-Content -LiteralPath $Path -Encoding ASCII
}

$RepoRoot = Get-RepoRoot
$ExpectedPackage = Join-Path $RepoRoot "packages\web-readonly-status\package.json"
if (-not (Test-Path -LiteralPath $ExpectedPackage)) {
  Fail "Unexpected repo structure. Cannot find packages\web-readonly-status\package.json from $RepoRoot"
}

if (-not (Test-ExpectedIp)) {
  Fail "This PC does not currently hold IP $ExpectedIp. Refusing to start LAN launch pack."
}

if (-not (Test-Path -LiteralPath $AdapterPath)) {
  Fail "Adapter file not found: $AdapterPath"
}

$portMap = Get-PortObservationMap -Ports @($AdapterPort, $PreviewPort) -TimeoutSec $TimeoutSec
if ($portMap[$AdapterPort].State -eq "LISTENING") {
  Fail "Port $AdapterPort is already listening. Refusing to start."
}

if ($portMap[$PreviewPort].State -eq "LISTENING") {
  Fail "Port $PreviewPort is already listening. Refusing to start."
}

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCommand) {
  Fail "node is not available on PATH."
}

$bunCommand = Get-Command bun -ErrorAction SilentlyContinue
if (-not $bunCommand) {
  Fail "bun is not available on PATH."
}

New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
Remove-Item -LiteralPath $AdapterPidFile, $PreviewPidFile -ErrorAction SilentlyContinue

Write-Host "Building production app..."
& $bunCommand.Source run --cwd (Join-Path $RepoRoot "packages\web-readonly-status") build
if ($LASTEXITCODE -ne 0) {
  Fail "Production build failed. Nothing was started."
}

Write-Host "Starting read-only adapter..."
$oldHost = $env:HOST
$oldPort = $env:PORT
try {
  $env:HOST = $ExpectedIp
  $env:PORT = [string]$AdapterPort
  $adapterProcess = Start-Process -FilePath $nodeCommand.Source `
    -ArgumentList @($AdapterPath) `
    -WorkingDirectory (Split-Path -Parent $AdapterPath) `
    -RedirectStandardOutput $AdapterLog `
    -RedirectStandardError $AdapterErrorLog `
    -WindowStyle Hidden `
    -PassThru
} finally {
  $env:HOST = $oldHost
  $env:PORT = $oldPort
}

if (-not (Wait-ForPort -Port $AdapterPort -TimeoutSeconds 10)) {
  if ($adapterProcess -and -not $adapterProcess.HasExited) {
    Stop-Process -Id $adapterProcess.Id -Force -ErrorAction SilentlyContinue
  }
  Fail "Adapter did not start listening on $ExpectedIp`:$AdapterPort. See $AdapterLog"
}
Write-PidFile $AdapterPidFile "adapter" $adapterProcess "node `"$AdapterPath`"" $AdapterLog

Write-Host "Starting production preview..."
$previewArgs = @(
  "run",
  "--cwd",
  (Join-Path $RepoRoot "packages\web-readonly-status"),
  "preview",
  "--",
  "--host",
  $ExpectedIp,
  "--port",
  [string]$PreviewPort
)
$previewProcess = Start-Process -FilePath $bunCommand.Source `
  -ArgumentList $previewArgs `
  -WorkingDirectory $RepoRoot `
  -RedirectStandardOutput $PreviewLog `
  -RedirectStandardError $PreviewErrorLog `
  -WindowStyle Hidden `
  -PassThru

if (-not (Wait-ForPort -Port $PreviewPort -TimeoutSeconds 15)) {
  if ($previewProcess -and -not $previewProcess.HasExited) {
    Stop-Process -Id $previewProcess.Id -Force -ErrorAction SilentlyContinue
  }
  if ($adapterProcess -and -not $adapterProcess.HasExited) {
    Stop-Process -Id $adapterProcess.Id -Force -ErrorAction SilentlyContinue
  }
  Remove-Item -LiteralPath $AdapterPidFile, $PreviewPidFile -ErrorAction SilentlyContinue
  Fail "Preview did not start listening on $ExpectedIp`:$PreviewPort. See $PreviewLog"
}
Write-PidFile $PreviewPidFile "preview" $previewProcess "bun $($previewArgs -join ' ')" $PreviewLog

Write-Host ""
Write-Host "Web Read-Only Status launch pack started."
Write-Host "Adapter URL: http://$ExpectedIp`:$AdapterPort/api/local/v0/summary"
Write-Host "App URL:     http://$ExpectedIp`:$PreviewPort/"
Write-Host "PID files:   $StateDir"
Write-Host "Logs:        $StateDir"
Write-Host "Open http://$ExpectedIp`:$PreviewPort/ from devices on the same Wi-Fi/LAN."
Write-Host "Status:      .\packages\web-readonly-status\scripts\status-readonly-status.ps1 -TimeoutSec $TimeoutSec"
Write-Host "Stop:        .\packages\web-readonly-status\scripts\stop-readonly-status.ps1"
