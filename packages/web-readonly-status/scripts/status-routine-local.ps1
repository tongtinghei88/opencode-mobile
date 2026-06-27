param(
  [ValidateRange(1, 30)]
  [int]$TimeoutSec = 5
)

$ErrorActionPreference = "Stop"

$ReadOnlyScript = Join-Path $PSScriptRoot "status-readonly-status.ps1"
$OpenCodeScript = Join-Path $PSScriptRoot "status-opencode-local.ps1"
$ExpectedIp = "192.168.50.202"

function Test-ExpectedIp {
  $matches = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
    Where-Object { $_.IPAddress -eq $ExpectedIp }
  return [bool]$matches
}

function Invoke-StatusScript {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  try {
    & $ScriptPath -TimeoutSec $TimeoutSec -SkipGitStatus
  } catch {
    Write-Warning "$Label status script failed: $($_.Exception.Message)"
    return $false
  }

  return $true
}

$allHealthy = $true

Write-Host "Routine dual launcher status"
Write-Host "TimeoutSec: $TimeoutSec"
Write-Host "PC has $ExpectedIp`: $(Test-ExpectedIp)"
Write-Host ""

Write-Host "== Read-only status =="
if (-not (Invoke-StatusScript -ScriptPath $ReadOnlyScript -Label "Read-only status")) {
  $allHealthy = $false
}

Write-Host ""
Write-Host "== Local OpenCode =="
if (-not (Invoke-StatusScript -ScriptPath $OpenCodeScript -Label "OpenCode local")) {
  $allHealthy = $false
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0 -and $repoRoot) {
  Write-Host ""
  Write-Host "Git status:"
  git status --short --branch
}

if (-not $allHealthy) {
  exit 1
}
