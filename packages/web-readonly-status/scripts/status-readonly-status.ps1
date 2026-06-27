param(
  [ValidateRange(1, 30)]
  [int]$TimeoutSec = 3,
  [switch]$VerboseChecks,
  [switch]$SkipGitStatus
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$ExpectedIp = "192.168.50.202"
$AdapterPort = 8790
$PreviewPort = 4173
$AppUrl = "http://192.168.50.202:4173/"
$AdapterUrl = "http://192.168.50.202:8790/api/local/v0/summary"
$StateDir = Join-Path $env:TEMP "web-readonly-status"
$AdapterPidFile = Join-Path $StateDir "adapter.pid.json"
$PreviewPidFile = Join-Path $StateDir "preview.pid.json"
$AdapterLog = Join-Path $StateDir "adapter.log"
$AdapterErrorLog = Join-Path $StateDir "adapter.err.log"
$PreviewLog = Join-Path $StateDir "preview.log"
$PreviewErrorLog = Join-Path $StateDir "preview.err.log"
$WarningPorts = @(4096, 3000, 8081, 5173)

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

function Write-HttpStatus($Label, $Result) {
  if ($Result.State -eq "OK") {
    Write-Host "$Label HTTP: OK ($($Result.StatusCode))"
    return
  }

  Write-Host "$Label HTTP: $($Result.State) ($($Result.Detail))"
}

function Write-PidStatus($Observation) {
  $pidText = if ($Observation.ProcessId) { "PID $($Observation.ProcessId)" } else { "PID n/a" }
  Write-Host "$($Observation.Label) PID: $($Observation.State) ($pidText; $($Observation.Path))"
  Write-Host "$($Observation.Label) log: $($Observation.LogPath)"
  if ($VerboseChecks) {
    Write-Host "$($Observation.Label) detail: $($Observation.Detail)"
  }
}

function Write-LogStatus($Label, $Observation) {
  if ($VerboseChecks) {
    Write-Host "$Label log status: $($Observation.State) ($($Observation.Detail))"
  }
}

$portMap = Get-PortObservationMap -Ports @($AdapterPort, $PreviewPort, 4096, 5173, 3000, 8081) -TimeoutSec $TimeoutSec
$adapterPort = $portMap[$AdapterPort]
$previewPort = $portMap[$PreviewPort]
$adapterPid = Get-PidFileObservation -Label "Adapter" -Path $AdapterPidFile -ExpectedPattern "*opencode-local-adapter-spike3O*server.mjs*" -DefaultLogPath $AdapterLog
$previewPid = Get-PidFileObservation -Label "Preview" -Path $PreviewPidFile -ExpectedPattern "*web-readonly-status*preview*" -DefaultLogPath $PreviewLog
$adapterStdout = Get-LogObservation -Path $AdapterLog
$adapterStderr = Get-LogObservation -Path $AdapterErrorLog
$previewStdout = Get-LogObservation -Path $PreviewLog
$previewStderr = Get-LogObservation -Path $PreviewErrorLog
$appHttp = if ($previewPort.State -eq "LISTENING") {
  Invoke-HttpStatusCheck -Url $AppUrl -TimeoutSec $TimeoutSec
} else {
  [pscustomobject]@{
    State = "FAILED"
    StatusCode = $null
    Detail = "Preview port is $($previewPort.State)"
  }
}
$adapterHttp = if ($adapterPort.State -eq "LISTENING") {
  Invoke-HttpStatusCheck -Url $AdapterUrl -TimeoutSec $TimeoutSec
} else {
  [pscustomobject]@{
    State = "FAILED"
    StatusCode = $null
    Detail = "Adapter port is $($adapterPort.State)"
  }
}

Write-Host "Web Read-Only Status launch pack status"
Write-Host "TimeoutSec: $TimeoutSec"
Write-Host "PC has $ExpectedIp`: $(Test-ExpectedIp)"
Write-PortStatus "Adapter" $adapterPort
Write-PortStatus "Preview" $previewPort
Write-Host "App URL: $AppUrl"
Write-Host "Approved endpoint: $AdapterUrl"
Write-PidStatus $adapterPid
Write-PidStatus $previewPid
Write-LogStatus "Adapter stdout" $adapterStdout
Write-LogStatus "Adapter stderr" $adapterStderr
Write-LogStatus "Preview stdout" $previewStdout
Write-LogStatus "Preview stderr" $previewStderr
Write-HttpStatus "App" $appHttp
Write-HttpStatus "Adapter" $adapterHttp

foreach ($port in $WarningPorts) {
  $warningObservation = $portMap[$port]
  if ($warningObservation.State -eq "LISTENING") {
    $detail = if ($warningObservation.LocalAddresses.Count -gt 0) { $warningObservation.LocalAddresses -join ", " } else { "n/a" }
    Write-Warning "Port $port is LISTENING on $detail"
    if ($port -eq 4096) {
      $opencodeProcess = $null
      foreach ($processIdValue in $warningObservation.OwningProcesses) {
        $processInfo = Get-ManagedProcessInfo -ProcessIdValue $processIdValue
        if ($processInfo -and [string]$processInfo.CommandLine -like "*opencode.exe*serve*") {
          $opencodeProcess = $processInfo
          break
        }
      }
      if ($opencodeProcess) {
        Write-Host "OpenCode serve note: appears to be running on 127.0.0.1:4096 (PID $($opencodeProcess.ProcessId))."
      }
    }
  } elseif ($warningObservation.State -eq "TIME_WAIT ONLY") {
    Write-Host "Port ${port}: TIME_WAIT ONLY"
  }
}

$repoRoot = if (-not $SkipGitStatus) { git rev-parse --show-toplevel 2>$null } else { $null }
if (-not $SkipGitStatus -and $LASTEXITCODE -eq 0 -and $repoRoot) {
  Write-Host ""
  Write-Host "Git status:"
  git status --short --branch
}
