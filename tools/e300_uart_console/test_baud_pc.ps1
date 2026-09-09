param(
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$true)][string]$RemoteScript,
    [Parameter(Mandatory=$true)][Security.SecureString]$SudoPassword,
    [string]$PortName = 'COM5',
    [ValidateSet('/dev/ttyS0','/dev/ttyMT4')][string]$Device = '/dev/ttyS0',
    [ValidateSet(115200,460800,921600)][int]$Baud = 115200
)
$ErrorActionPreference = 'Stop'
if ($Target -notmatch '^[\w.-]+@[\w.-]+$' -or $RemoteScript -notmatch '^/[\w./-]+$') {
    throw 'Invalid remote target or path'
}
$port = New-Object System.IO.Ports.SerialPort($PortName,$Baud,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$port.Handshake = [System.IO.Ports.Handshake]::None
$port.DtrEnable = $false
$port.RtsEnable = $false
$port.ReadTimeout = 500
$port.WriteTimeout = 5000
$port.ReadBufferSize = 16384
$process = New-Object Diagnostics.Process
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = 'ssh'
$start.Arguments = "-T -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 $Target `"sudo -k -S -p '' timeout --kill-after=3s 30s python3 $RemoteScript --baud $Baud --device $Device`""
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$process.StartInfo = $start
$started = $false
try {
    $port.Open()
    $port.DiscardInBuffer()
    $port.DiscardOutBuffer()
    [void]$process.Start()
    $started = $true
    $stderr = $process.StandardError.ReadToEndAsync()
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SudoPassword)
    try { $process.StandardInput.WriteLine([Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    $process.StandardInput.Close()
    $lineTask = $process.StandardOutput.ReadLineAsync()
    if (-not $lineTask.Wait(15000)) { throw 'Remote readiness timeout' }
    $line = $lineTask.Result
    Write-Output $line
    if ($line -notlike 'UART_TEST_READY*') { throw 'Remote test refused or failed' }
    $rest = $process.StandardOutput.ReadToEndAsync()
    $payload = New-Object byte[] 4096
    for ($i=0; $i -lt $payload.Length; $i++) { $payload[$i] = $i % 256 }
    $port.Write($payload,0,$payload.Length)
    $received = New-Object byte[] 8192
    $count = 0
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($count -lt 4096 -and $timer.Elapsed.TotalSeconds -lt 20) {
        try { $count += $port.Read($received,$count,$received.Length-$count) }
        catch [System.TimeoutException] { }
    }
    $match = $count -eq 4096
    for ($i=0; $i -lt $count -and $match; $i++) {
        if ($received[$i] -ne (($i % 256) -bxor 0xa5)) { $match = $false }
    }
    if ($match) { $port.Write([byte[]]@(0x5a),0,1) }
    if (-not $process.WaitForExit(10000)) { throw 'Remote completion timeout' }
    Write-Output $rest.Result
    Write-Output $stderr.Result
    [pscustomobject]@{baud=$Baud;pc_tx_bytes=4096;pc_rx_bytes=$count;e300_to_pc_exact=$match;remote_exit=$process.ExitCode} | ConvertTo-Json -Compress
    $result = if ($match -and $process.ExitCode -eq 0) {0} else {1}
} finally {
    if ($started -and -not $process.HasExited) { [void]$process.WaitForExit(35000) }
    if ($port.IsOpen) { $port.Close() }
    $port.Dispose()
    $process.Dispose()
}
exit $result
