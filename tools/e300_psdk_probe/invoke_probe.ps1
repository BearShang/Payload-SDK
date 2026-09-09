param(
    [Parameter(Mandatory=$true)][string]$AppInfoPath,
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$true)][string]$RemoteRoot,
    [ValidateSet('check', 'run')][string]$Mode = 'check',
    [ValidateSet('legacy', 'usb-ch340', 'usb-cp210x')][string]$Transport = 'legacy',
    [Security.SecureString]$SudoPassword
)
$ErrorActionPreference = 'Stop'
if ($Target -notmatch '^[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+$' -or
    $RemoteRoot -notmatch '^/[a-zA-Z0-9_./-]+$') { throw 'Invalid SSH target/path' }
$names = @('APP_NAME', 'APP_ID', 'APP_KEY', 'APP_LICENSE', 'DEVELOPER_ACCOUNT', 'BAUD_RATE')
$fields = @{}
foreach ($line in (Get-Content -LiteralPath $AppInfoPath)) {
    if ($line -match '^\s*#define\s+USER_(\w+)\s+"([^"\\]*)"\s*(?://.*|/\*.*\*/\s*)?$') {
        $name = $Matches[1]
        if ($names -contains $name) {
            if ($fields.ContainsKey("PSDK_$name")) { throw "Duplicate field: $name" }
            $fields["PSDK_$name"] = $Matches[2]
        }
    }
}
if ($fields.Count -ne $names.Count) { throw 'Expected six simple literal application macros; no code is evaluated' }
$payload = @{mode=$Mode; transport=$Transport; fields=$fields} | ConvertTo-Json -Compress
$command = "python3 $RemoteRoot/tools/e300_psdk_probe/remote_probe.py"
if ($Mode -eq 'run') {
    if (-not $SudoPassword) { throw 'Run requires a sudo password supplied in memory' }
    $command = "sudo -k -S -p '' $command"
}
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = 'ssh'
$start.Arguments = "-T -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 $Target `"$command`""
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$process = New-Object Diagnostics.Process
$process.StartInfo = $start
[void]$process.Start()
$output = $process.StandardOutput.ReadToEndAsync()
$errors = $process.StandardError.ReadToEndAsync()
try {
    if ($Mode -eq 'run') {
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SudoPassword)
        try { $process.StandardInput.WriteLine([Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    $process.StandardInput.WriteLine($payload)
    $process.StandardInput.Close()
    if (-not $process.WaitForExit(90000)) {
        $process.Kill()
        $process.WaitForExit()
        throw 'SSH probe exceeded local 90-second deadline'
    }
    $result = $output.Result + $errors.Result
    foreach ($name in $names) {
        $value = $fields["PSDK_$name"]
        if ($name -ne 'BAUD_RATE' -and $value) { $result = $result.Replace($value, '[redacted]') }
    }
    Write-Output $result
    Write-Output "ssh_exit=$($process.ExitCode)"
    exit $process.ExitCode
} finally {
    $payload = $null
    $fields.Clear()
    $process.Dispose()
}
