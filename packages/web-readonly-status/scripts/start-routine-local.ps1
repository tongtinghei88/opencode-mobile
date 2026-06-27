param(
  [string]$OpenCodePassword,
  [ValidateRange(1, 30)]
  [int]$TimeoutSec = 5,
  [switch]$SkipReadOnlyStatus,
  [switch]$SkipOpenCode
)

$ErrorActionPreference = "Stop"

$ReadOnlyUrl = "http://192.168.50.202:4173/"
$AdapterUrl = "http://192.168.50.202:8790/api/local/v0/summary"
$OpenCodeUrl = "http://127.0.0.1:4096/"
$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$ReadOnlyScript = Join-Path $PSScriptRoot "start-readonly-status.ps1"
$OpenCodeScript = Join-Path $PSScriptRoot "start-opencode-local.ps1"
$StopReadOnlyScript = Join-Path $PSScriptRoot "stop-readonly-status.ps1"
$StopOpenCodeScript = Join-Path $PSScriptRoot "stop-opencode-local.ps1"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Invoke-ManagedScript {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [string[]]$Arguments = @()
  )

  & $PowerShellExe -ExecutionPolicy Bypass -File $ScriptPath @Arguments
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    throw "$Label failed with exit code $exitCode."
  }
}

if ($SkipReadOnlyStatus -and $SkipOpenCode) {
  Fail "Nothing to start. Remove at least one skip switch."
}

if (-not $SkipOpenCode -and [string]::IsNullOrWhiteSpace($OpenCodePassword)) {
  Fail "OpenCodePassword is required unless -SkipOpenCode is used."
}

$startedReadOnly = $false
$startedOpenCode = $false

try {
  if (-not $SkipReadOnlyStatus) {
    Write-Host "Starting read-only status launch pack..."
    Invoke-ManagedScript -ScriptPath $ReadOnlyScript -Label "Read-only status" -Arguments @("-TimeoutSec", [string]$TimeoutSec)
    $startedReadOnly = $true
  } else {
    Write-Host "Skipping read-only status launch pack."
  }

  if (-not $SkipOpenCode) {
    Write-Host ""
    Write-Host "Starting local OpenCode helper..."
    Invoke-ManagedScript -ScriptPath $OpenCodeScript -Label "OpenCode local helper" -Arguments @("-Password", $OpenCodePassword)
    $startedOpenCode = $true
  } else {
    Write-Host ""
    Write-Host "Skipping local OpenCode helper."
  }
} catch {
  Write-Warning $_.Exception.Message

  if ($startedOpenCode) {
    Write-Host "Rolling back OpenCode local helper..."
    & $PowerShellExe -ExecutionPolicy Bypass -File $StopOpenCodeScript
  }

  if ($startedReadOnly) {
    Write-Host "Rolling back read-only status launch pack..."
    & $PowerShellExe -ExecutionPolicy Bypass -File $StopReadOnlyScript
  }

  Write-Host ""
  Write-Host "Rollback advice:"
  Write-Host "- Re-run .\packages\web-readonly-status\scripts\status-routine-local.ps1 -TimeoutSec $TimeoutSec to confirm current state."
  Write-Host "- Logs remain under %TEMP%\web-readonly-status\ and %TEMP%\opencode-local\."
  Write-Host "- OpenCode remains local-only and is not exposed to LAN by this routine."
  exit 1
}

Write-Host ""
Write-Host "Routine dual launcher started."
Write-Host "Read-only status URL:    $ReadOnlyUrl"
Write-Host "Adapter endpoint:        $AdapterUrl"
Write-Host "Local OpenCode URL:      $OpenCodeUrl"
Write-Host "OpenCode Basic Auth:     username 'opencode'"
if (-not $SkipOpenCode) {
  Write-Host "OpenCode password:       use the value you supplied to -OpenCodePassword"
}
Write-Host "Safety:                  OpenCode stays on 127.0.0.1 only, no LAN bind, no firewall rules"
Write-Host "Read-only boundary:      LAN devices should open only $ReadOnlyUrl"
Write-Host "Status:                  .\packages\web-readonly-status\scripts\status-routine-local.ps1 -TimeoutSec $TimeoutSec"
Write-Host "Stop:                    .\packages\web-readonly-status\scripts\stop-routine-local.ps1"
