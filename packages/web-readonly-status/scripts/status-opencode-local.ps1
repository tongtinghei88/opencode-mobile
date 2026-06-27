param(
  [ValidateRange(1, 30)]
  [int]$TimeoutSec = 5,
  [switch]$VerboseChecks,
  [switch]$SkipGitStatus
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$ExpectedIp = "192.168.50.202"
$Port = 4096
$Hostname = "127.0.0.1"
$LocalUrl = "http://127.0.0.1:4096/"
$StateDir = Join-Path $env:TEMP "opencode-local"
$PidFile = Join-Path $StateDir "opencode-local.pid.json"
$StdOutLog = Join-Path $StateDir "opencode-local.out.log"
$StdErrLog = Join-Path $StateDir "opencode-local.err.log"
$LoopbackAddresses = @("127.0.0.1", "::1")
$WildcardAddresses = @("0.0.0.0", "::")

function Test-ExpectedIp {
  $matches = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
    Where-Object { $_.IPAddress -eq $ExpectedIp }
  return [bool]$matches
}

function Write-PortStatus($Label, $Observation) {
  $addresses = if ($Observation.LocalAddresses.Count -gt 0) { $Observation.LocalAddresses -join ", " } else { "n/a" }
  $pids = if ($Observation.OwningProcesses.Count -gt 0) { $Observation.OwningProcesses -join ", " } else { "n/a" }
  Write-Host "$Label port $($Observation.Port): $($Observation.State) ($($Observation.Details); addresses: $addresses; pids: $pids)"
}

function Write-HttpStatus($Result, $AuthMode) {
  if ($Result.State -eq "OK" -and $Result.StatusCode -eq 401) {
    $detail = if ($AuthMode -eq "PASSWORD") {
      "HTTP 401 (expected for unauthenticated check when password protection is enabled)"
    } else {
      "HTTP 401"
    }
    Write-Host "OpenCode HTTP: OK ($detail)"
    return
  }

  if ($Result.State -eq "OK") {
    Write-Host "OpenCode HTTP: OK (HTTP $($Result.StatusCode))"
    return
  }

  Write-Host "OpenCode HTTP: $($Result.State) ($($Result.Detail))"
}

function Write-PidStatus($Observation, $AuthMode) {
  $pidText = if ($Observation.ProcessId) { "PID $($Observation.ProcessId)" } else { "PID n/a" }
  Write-Host "OpenCode PID: $($Observation.State) ($pidText; $($Observation.Path))"
  Write-Host "OpenCode log: $($Observation.LogPath)"
  if ($AuthMode) {
    Write-Host "OpenCode auth mode: $AuthMode"
  }
  if ($VerboseChecks) {
    Write-Host "OpenCode detail: $($Observation.Detail)"
  }
}

function Write-LogStatus($Label, $Observation) {
  if ($VerboseChecks) {
    Write-Host "$Label log status: $($Observation.State) ($($Observation.Detail))"
  }
}

function Get-OpenCodePidEntry {
  if (-not (Test-Path -LiteralPath $PidFile)) {
    return $null
  }

  try {
    return Get-Content -LiteralPath $PidFile -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

$portMap = Get-PortObservationMap -Ports @($Port) -TimeoutSec $TimeoutSec
$opencodePort = $portMap[$Port]
$pidObservation = Get-PidFileObservation -Label "OpenCode" -Path $PidFile -ExpectedPattern "*opencode-ai*opencode.exe*" -DefaultLogPath $StdErrLog
$pidEntry = Get-OpenCodePidEntry
$authMode = if ($pidEntry -and $pidEntry.authMode) { [string]$pidEntry.authMode } else { $null }
$stdoutObservation = Get-LogObservation -Path $StdOutLog
$stderrObservation = Get-LogObservation -Path $StdErrLog
$httpResult = if ($opencodePort.State -eq "LISTENING") {
  Invoke-HttpStatusCheck -Url $LocalUrl -TimeoutSec $TimeoutSec
} else {
  [pscustomobject]@{
    State = "FAILED"
    StatusCode = $null
    Detail = "OpenCode port is $($opencodePort.State)"
  }
}

$listeningAddresses = @($opencodePort.LocalAddresses | Select-Object -Unique)
$bindsToExpectedLan = [bool](@($listeningAddresses | Where-Object { $_ -eq $ExpectedIp }).Count)
$bindsToWildcard = [bool](@($listeningAddresses | Where-Object { $WildcardAddresses -contains $_ }).Count)
$unexpectedAddresses = @($listeningAddresses | Where-Object { $_ -and ($LoopbackAddresses -notcontains $_) })
$isExposedBeyondLoopback = ($unexpectedAddresses.Count -gt 0)

Write-Host "OpenCode local helper status"
Write-Host "TimeoutSec: $TimeoutSec"
Write-Host "PC has $ExpectedIp`: $(Test-ExpectedIp)"
Write-Host "Local URL: $LocalUrl"
Write-PortStatus "OpenCode" $opencodePort
Write-Host "OpenCode LAN bind ($ExpectedIp`:$Port): $(if ($bindsToExpectedLan) { 'LISTENING' } else { 'NOT LISTENING' })"
Write-Host "OpenCode wildcard bind (0.0.0.0`:$Port): $(if ($bindsToWildcard) { 'LISTENING' } else { 'NOT LISTENING' })"
Write-PidStatus $pidObservation $authMode
Write-LogStatus "OpenCode stdout" $stdoutObservation
Write-LogStatus "OpenCode stderr" $stderrObservation
Write-HttpStatus $httpResult $authMode

if ($isExposedBeyondLoopback) {
  Write-Warning "OpenCode appears exposed beyond loopback on: $($unexpectedAddresses -join ', ')"
} else {
  Write-Host "OpenCode exposure warning: none detected beyond loopback."
}

$repoRoot = if (-not $SkipGitStatus) { git rev-parse --show-toplevel 2>$null } else { $null }
if (-not $SkipGitStatus -and $LASTEXITCODE -eq 0 -and $repoRoot) {
  Write-Host ""
  Write-Host "Git status:"
  git status --short --branch
}
