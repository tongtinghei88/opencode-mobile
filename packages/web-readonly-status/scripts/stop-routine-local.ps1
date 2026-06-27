param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$StopOpenCodeScript = Join-Path $PSScriptRoot "stop-opencode-local.ps1"
$StopReadOnlyScript = Join-Path $PSScriptRoot "stop-readonly-status.ps1"
$Ports = @(4096, 4173, 8790, 5173, 3000, 8081)

function Invoke-StopScript {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  & $PowerShellExe -ExecutionPolicy Bypass -File $ScriptPath
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    Write-Warning "$Label stop script exited with code $exitCode."
    return $false
  }

  return $true
}

$allStopped = $true

Write-Host "Stopping local OpenCode helper..."
if (-not (Invoke-StopScript -ScriptPath $StopOpenCodeScript -Label "OpenCode local")) {
  $allStopped = $false
}

Write-Host ""
Write-Host "Stopping read-only status launch pack..."
if (-not (Invoke-StopScript -ScriptPath $StopReadOnlyScript -Label "Read-only status")) {
  $allStopped = $false
}

Start-Sleep -Milliseconds 500

Write-Host ""
Write-Host "Routine final port status:"
$portMap = Get-PortObservationMap -Ports $Ports -TimeoutSec 5
foreach ($port in $Ports) {
  $observation = $portMap[$port]
  $addresses = if ($observation.LocalAddresses.Count -gt 0) { $observation.LocalAddresses -join ", " } else { "n/a" }
  $pids = if ($observation.OwningProcesses.Count -gt 0) { $observation.OwningProcesses -join ", " } else { "n/a" }
  Write-Host "Port ${port}: $($observation.State) ($($observation.Details); addresses: $addresses; pids: $pids)"
}

if (-not $allStopped) {
  exit 1
}
