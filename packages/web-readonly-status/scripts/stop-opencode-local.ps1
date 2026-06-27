param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$StateDir = Join-Path $env:TEMP "opencode-local"
$PidFile = Join-Path $StateDir "opencode-local.pid.json"
$Port = 4096

function Stop-ManagedOpenCodeProcess($PidFilePath) {
  if (-not (Test-Path -LiteralPath $PidFilePath)) {
    return
  }

  try {
    $entry = Get-Content -LiteralPath $PidFilePath -Raw | ConvertFrom-Json
  } catch {
    Write-Warning "Removing unreadable PID file: $PidFilePath"
    Remove-Item -LiteralPath $PidFilePath -ErrorAction SilentlyContinue
    return
  }

  $processIdValue = [int]$entry.pid
  $processInfo = Get-ManagedProcessInfo -ProcessIdValue $processIdValue
  if (-not $processInfo) {
    Write-Host "OpenCode process $processIdValue is not running; removing stale PID file."
    Remove-Item -LiteralPath $PidFilePath -ErrorAction SilentlyContinue
    return
  }

  $commandLine = [string]$processInfo.CommandLine
  if ($commandLine -notlike "*opencode-ai*opencode.exe*" -or $commandLine -notlike "*serve*") {
    Write-Warning "PID $processIdValue from $PidFilePath does not match expected OpenCode serve command. Leaving process untouched."
    return
  }

  $children = Get-DescendantProcesses -ParentProcessIdValue $processIdValue
  foreach ($child in $children) {
    Write-Host "Stopping child process $($child.ProcessId) for OpenCode local."
    Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue
  }

  Write-Host "Stopping OpenCode local process $processIdValue."
  Stop-Process -Id $processIdValue -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $PidFilePath -ErrorAction SilentlyContinue
}

Stop-ManagedOpenCodeProcess -PidFilePath $PidFile

Start-Sleep -Milliseconds 500

$portMap = Get-PortObservationMap -Ports @($Port) -TimeoutSec 5
$observation = $portMap[$Port]
$addresses = if ($observation.LocalAddresses.Count -gt 0) { $observation.LocalAddresses -join ", " } else { "n/a" }
$pids = if ($observation.OwningProcesses.Count -gt 0) { $observation.OwningProcesses -join ", " } else { "n/a" }

Write-Host ""
Write-Host "Port status:"
Write-Host "Port ${Port}: $($observation.State) ($($observation.Details); addresses: $addresses; pids: $pids)"
