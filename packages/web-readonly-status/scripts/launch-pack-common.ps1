Set-StrictMode -Version 2

function Invoke-NativeCommandWithTimeout {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$Arguments,
    [ValidateRange(1, 30)]
    [int]$TimeoutSec = 5
  )

  $process = New-Object System.Diagnostics.Process
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $FilePath
  $startInfo.Arguments = $Arguments
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.CreateNoWindow = $true
  $process.StartInfo = $startInfo
  $null = $process.Start()

  if (-not $process.WaitForExit($TimeoutSec * 1000)) {
    try {
      $process.Kill()
      $process.WaitForExit()
    } catch {
      # Ignore timeout cleanup errors.
    }

    return [pscustomobject]@{
      TimedOut = $true
      ExitCode = $null
      StdOut = ""
      StdErr = "Timed out after $TimeoutSec second(s)."
    }
  }

  return [pscustomobject]@{
    TimedOut = $false
    ExitCode = $process.ExitCode
    StdOut = $process.StandardOutput.ReadToEnd()
    StdErr = $process.StandardError.ReadToEnd()
  }
}

function Convert-TcpEndpoint {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Endpoint
  )

  if ($Endpoint -match "^\[(.+)\]:(\d+)$") {
    return [pscustomobject]@{
      Address = $matches[1]
      Port = [int]$matches[2]
    }
  }

  if ($Endpoint -match "^(.*):(\d+)$") {
    return [pscustomobject]@{
      Address = $matches[1]
      Port = [int]$matches[2]
    }
  }

  return $null
}

function Get-TcpSnapshot {
  try {
    $properties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    return [pscustomobject]@{
      Error = $null
      Listeners = @($properties.GetActiveTcpListeners())
      Connections = @($properties.GetActiveTcpConnections())
    }
  } catch {
    return [pscustomobject]@{
      Error = $_.Exception.Message
      Listeners = @()
      Connections = @()
    }
  }
}

function Normalize-TcpStateName {
  param(
    [Parameter(Mandatory = $true)]
    [string]$State
  )

  switch ($State.ToUpperInvariant()) {
    "TIMEWAIT" { return "TIME_WAIT" }
    "CLOSEWAIT" { return "CLOSE_WAIT" }
    "FINWAIT1" { return "FIN_WAIT_1" }
    "FINWAIT2" { return "FIN_WAIT_2" }
    "LASTACK" { return "LAST_ACK" }
    "SYNRECEIVED" { return "SYN_RECEIVED" }
    "SYNSENT" { return "SYN_SENT" }
    default { return $State.ToUpperInvariant() }
  }
}

function Get-PortObservation {
  param(
    [Parameter(Mandatory = $true)]
    [int]$Port,
    [Parameter(Mandatory = $true)]
    [object[]]$Listeners,
    [Parameter(Mandatory = $true)]
    [object[]]$Connections
  )

  $listenMatches = @($Listeners | Where-Object { $_.Port -eq $Port })
  if ($listenMatches.Count -gt 0) {
    $listenerProcesses = @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique)
    return [pscustomobject]@{
      Port = $Port
      State = "LISTENING"
      IsListening = $true
      LocalAddresses = @($listenMatches | ForEach-Object { $_.Address.ToString() } | Select-Object -Unique)
      OwningProcesses = $listenerProcesses
      Details = "Listening"
    }
  }

  $connectionMatches = @($Connections | Where-Object { $_.LocalEndPoint.Port -eq $Port })
  if ($connectionMatches.Count -eq 0) {
    return [pscustomobject]@{
      Port = $Port
      State = "NOT LISTENING"
      IsListening = $false
      LocalAddresses = @()
      OwningProcesses = @()
      Details = "No TCP entries"
    }
  }

  $states = @($connectionMatches | ForEach-Object { Normalize-TcpStateName -State $_.State.ToString() } | Select-Object -Unique)
  $nonTimeWaitStates = @($states | Where-Object { $_ -ne "TIME_WAIT" })
  $allTimeWait = ($states.Count -gt 0) -and ($nonTimeWaitStates.Count -eq 0)
  if ($allTimeWait) {
    return [pscustomobject]@{
      Port = $Port
      State = "TIME_WAIT ONLY"
      IsListening = $false
      LocalAddresses = @($connectionMatches | ForEach-Object { $_.LocalEndPoint.Address.ToString() } | Select-Object -Unique)
      OwningProcesses = @()
      Details = "TCP state(s): TIME_WAIT"
    }
  }

  return [pscustomobject]@{
    Port = $Port
    State = "NOT LISTENING"
    IsListening = $false
    LocalAddresses = @($connectionMatches | ForEach-Object { $_.LocalEndPoint.Address.ToString() } | Select-Object -Unique)
    OwningProcesses = @()
    Details = "TCP state(s): $($states -join ', ')"
  }
}

function Get-PortObservationMap {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports,
    [ValidateRange(1, 30)]
    [int]$TimeoutSec = 5
  )

  $snapshot = Get-TcpSnapshot
  $map = @{}
  foreach ($port in $Ports) {
    if ($snapshot.Error) {
      $map[$port] = [pscustomobject]@{
        Port = $port
        State = "CHECK FAILED"
        IsListening = $false
        LocalAddresses = @()
        OwningProcesses = @()
        Details = $snapshot.Error
      }
      continue
    }

    $map[$port] = Get-PortObservation -Port $port -Listeners $snapshot.Listeners -Connections $snapshot.Connections
  }

  return $map
}

function Invoke-HttpStatusCheck {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url,
    [ValidateRange(1, 30)]
    [int]$TimeoutSec = 5
  )

  try {
    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = "GET"
    $request.Timeout = $TimeoutSec * 1000
    $request.ReadWriteTimeout = $TimeoutSec * 1000
    $request.KeepAlive = $false
    $request.Proxy = $null
    $request.AllowAutoRedirect = $false
    $response = [System.Net.HttpWebResponse]$request.GetResponse()
    try {
      return [pscustomobject]@{
        State = "OK"
        StatusCode = [int]$response.StatusCode
        Detail = "HTTP $([int]$response.StatusCode)"
      }
    } finally {
      $response.Close()
    }
  } catch [System.Net.WebException] {
    $webException = $_.Exception
    if ($webException.Status -eq [System.Net.WebExceptionStatus]::Timeout) {
      return [pscustomobject]@{
        State = "TIMEOUT"
        StatusCode = $null
        Detail = "Timed out after $TimeoutSec second(s)"
      }
    }

    if ($webException.Response) {
      $statusResponse = [System.Net.HttpWebResponse]$webException.Response
      try {
        return [pscustomobject]@{
          State = "OK"
          StatusCode = [int]$statusResponse.StatusCode
          Detail = "HTTP $([int]$statusResponse.StatusCode)"
        }
      } finally {
        $statusResponse.Close()
      }
    }

    return [pscustomobject]@{
      State = "FAILED"
      StatusCode = $null
      Detail = $webException.Message
    }
  } catch {
    return [pscustomobject]@{
      State = "FAILED"
      StatusCode = $null
      Detail = $_.Exception.Message
    }
  }
}

function Get-ManagedProcessInfo {
  param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessIdValue
  )

  return Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessIdValue" -ErrorAction SilentlyContinue
}

function Get-PidFileObservation {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$ExpectedPattern,
    [string]$DefaultLogPath
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return [pscustomobject]@{
      Label = $Label
      State = "PID FILE MISSING"
      Path = $Path
      ProcessId = $null
      LogPath = $DefaultLogPath
      Detail = "PID file not found"
    }
  }

  try {
    $entry = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    return [pscustomobject]@{
      Label = $Label
      State = "PID FILE UNREADABLE"
      Path = $Path
      ProcessId = $null
      LogPath = $DefaultLogPath
      Detail = $_.Exception.Message
    }
  }

  $processIdValue = [int]$entry.pid
  $logPath = if ($entry.log) { [string]$entry.log } else { $DefaultLogPath }
  $processInfo = Get-ManagedProcessInfo -ProcessIdValue $processIdValue
  if (-not $processInfo) {
    return [pscustomobject]@{
      Label = $Label
      State = "STALE PID FILE"
      Path = $Path
      ProcessId = $processIdValue
      LogPath = $logPath
      Detail = "Process $processIdValue is not running"
    }
  }

  $commandLine = [string]$processInfo.CommandLine
  if ($ExpectedPattern -and $commandLine -notlike $ExpectedPattern) {
    return [pscustomobject]@{
      Label = $Label
      State = "PID REUSED / UNEXPECTED COMMAND"
      Path = $Path
      ProcessId = $processIdValue
      LogPath = $logPath
      Detail = $commandLine
    }
  }

  return [pscustomobject]@{
    Label = $Label
    State = "PID RUNNING"
    Path = $Path
    ProcessId = $processIdValue
    LogPath = $logPath
    Detail = $commandLine
  }
}

function Get-LogObservation {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return [pscustomobject]@{
      State = "LOG MISSING"
      Path = $Path
      Detail = "Log file not found"
    }
  }

  $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
  if (-not $item) {
    return [pscustomobject]@{
      State = "LOG UNREADABLE"
      Path = $Path
      Detail = "Unable to read log metadata"
    }
  }

  return [pscustomobject]@{
    State = "LOG PRESENT"
    Path = $Path
    Detail = "$($item.Length) byte(s), updated $($item.LastWriteTime.ToString('s'))"
  }
}
