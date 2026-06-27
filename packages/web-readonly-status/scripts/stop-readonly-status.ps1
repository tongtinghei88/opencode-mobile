param()

$ErrorActionPreference = "Stop"

$StateDir = Join-Path $env:TEMP "web-readonly-status"
$PidFiles = @(
  (Join-Path $StateDir "preview.pid.json"),
  (Join-Path $StateDir "adapter.pid.json")
)
$Ports = @(4173, 8790, 5173, 4096, 3000, 8081)

function Get-ProcessCommandLine($ProcessIdValue) {
  return Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessIdValue" -ErrorAction SilentlyContinue
}

function Get-DescendantProcesses($ParentProcessIdValue) {
  $all = @()
  $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $ParentProcessIdValue" -ErrorAction SilentlyContinue
  foreach ($child in $children) {
    $all += Get-DescendantProcesses $child.ProcessId
    $all += $child
  }
  return $all
}

function Stop-LaunchPackProcess($PidFile) {
  if (-not (Test-Path -LiteralPath $PidFile)) {
    return
  }

  try {
    $entry = Get-Content -LiteralPath $PidFile -Raw | ConvertFrom-Json
  } catch {
    Write-Warning "Removing unreadable PID file: $PidFile"
    Remove-Item -LiteralPath $PidFile -ErrorAction SilentlyContinue
    return
  }

  $pidValue = [int]$entry.pid
  $name = [string]$entry.name
  $processInfo = Get-ProcessCommandLine $pidValue
  if (-not $processInfo) {
    Write-Host "$name process $pidValue is not running; removing stale PID file."
    Remove-Item -LiteralPath $PidFile -ErrorAction SilentlyContinue
    return
  }

  $commandLine = [string]$processInfo.CommandLine
  $isExpected = $false
  if ($name -eq "adapter" -and $commandLine -like "*opencode-local-adapter-spike3O*server.mjs*") {
    $isExpected = $true
  }
  if ($name -eq "preview" -and $commandLine -like "*web-readonly-status*" -and $commandLine -like "*preview*") {
    $isExpected = $true
  }

  if (-not $isExpected) {
    Write-Warning "PID $pidValue from $PidFile does not match expected $name command. Leaving process untouched."
    return
  }

  $children = Get-DescendantProcesses $pidValue
  foreach ($child in $children) {
    Write-Host "Stopping child process $($child.ProcessId) for $name."
    Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue
  }

  Write-Host "Stopping $name process $pidValue."
  Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $PidFile -ErrorAction SilentlyContinue
}

foreach ($pidFile in $PidFiles) {
  Stop-LaunchPackProcess $pidFile
}

Start-Sleep -Milliseconds 500

Write-Host ""
Write-Host "Port status:"
foreach ($port in $Ports) {
  $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
  if ($listener) {
    $pids = ($listener | Select-Object -ExpandProperty OwningProcess -Unique) -join ", "
    Write-Host "Port $port listening (PID: $pids)"
  } else {
    Write-Host "Port $port free"
  }
}
