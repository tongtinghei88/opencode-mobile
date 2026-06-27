param(
  [string]$Password,
  [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "launch-pack-common.ps1")

$Port = 4096
$Hostname = "127.0.0.1"
$Url = "http://127.0.0.1:4096/"
$StateDir = Join-Path $env:TEMP "opencode-local"
$PidFile = Join-Path $StateDir "opencode-local.pid.json"
$StdOutLog = Join-Path $StateDir "opencode-local.out.log"
$StdErrLog = Join-Path $StateDir "opencode-local.err.log"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Wait-ForOpenCodePort($PortValue, $TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $portMap = Get-PortObservationMap -Ports @($PortValue) -TimeoutSec 5
    if ($portMap[$PortValue].State -eq "LISTENING") {
      return $true
    }
    Start-Sleep -Milliseconds 300
  }

  return $false
}

function Write-OpenCodePidFile($Path, $Process, $CommandLine, $LogPath, $AuthMode) {
  [pscustomobject]@{
    name = "opencode-local"
    pid = $Process.Id
    commandLine = $CommandLine
    log = $LogPath
    hostname = $Hostname
    port = $Port
    authMode = $AuthMode
    startedAt = (Get-Date).ToString("o")
  } | ConvertTo-Json | Set-Content -LiteralPath $Path -Encoding ASCII
}

$portMap = Get-PortObservationMap -Ports @($Port) -TimeoutSec 5
if ($portMap[$Port].State -eq "LISTENING") {
  Fail "Port $Port is already listening. Refusing to start."
}

$openCodeExe = Get-OpenCodeExecutablePath
if (-not $openCodeExe) {
  Fail "OpenCode executable not found. Confirm the local opencode installation is available."
}

$effectivePassword = $null
if ($PSBoundParameters.ContainsKey("Password")) {
  $effectivePassword = $Password
} elseif ($env:OPENCODE_SERVER_PASSWORD) {
  $effectivePassword = $env:OPENCODE_SERVER_PASSWORD
}

New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
Remove-Item -LiteralPath $PidFile -ErrorAction SilentlyContinue

$args = @("serve", "--hostname", $Hostname, "--port", [string]$Port, "--print-logs")
$commandLine = "`"$openCodeExe`" $($args -join ' ')"
$authMode = if ($effectivePassword) { "PASSWORD" } else { "UNSECURED" }

$oldPassword = $env:OPENCODE_SERVER_PASSWORD
try {
  if ($effectivePassword) {
    $env:OPENCODE_SERVER_PASSWORD = $effectivePassword
  } else {
    Remove-Item Env:OPENCODE_SERVER_PASSWORD -ErrorAction SilentlyContinue
  }

  $process = Start-Process -FilePath $openCodeExe `
    -ArgumentList $args `
    -WorkingDirectory (Get-Location).Path `
    -RedirectStandardOutput $StdOutLog `
    -RedirectStandardError $StdErrLog `
    -WindowStyle Hidden `
    -PassThru
} finally {
  if ($null -ne $oldPassword -and $oldPassword -ne "") {
    $env:OPENCODE_SERVER_PASSWORD = $oldPassword
  } else {
    Remove-Item Env:OPENCODE_SERVER_PASSWORD -ErrorAction SilentlyContinue
  }
}

if (-not (Wait-ForOpenCodePort -PortValue $Port -TimeoutSeconds 15)) {
  if ($process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
  }
  Fail "OpenCode did not start listening on $Hostname`:$Port. See $StdErrLog"
}

Write-OpenCodePidFile -Path $PidFile -Process $process -CommandLine $commandLine -LogPath $StdErrLog -AuthMode $authMode

Write-Host ""
Write-Host "OpenCode local helper started."
Write-Host "Local URL:   $Url"
Write-Host "PID file:    $PidFile"
Write-Host "Logs:        $StateDir"
Write-Host "Binding:     local-only ($Hostname`:$Port)"
Write-Host "Safety:      no LAN bind, no firewall rule, no read-only status launch pack start"

if ($effectivePassword) {
  Write-Host "Browser auth: username 'opencode' and the password you supplied."
} else {
  Write-Warning "OPENCODE_SERVER_PASSWORD is not set. Local browser access is unsecured."
}

Write-Host "Stop:        .\packages\web-readonly-status\scripts\stop-opencode-local.ps1"

if ($OpenBrowser) {
  Start-Process $Url | Out-Null
}
