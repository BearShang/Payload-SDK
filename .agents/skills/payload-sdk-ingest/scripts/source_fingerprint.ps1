[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Path, [string]$Root)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
. (Join-Path $projectRoot 'tools/wiki_common.ps1')
try {
    $rootPath = Resolve-WikiRoot $Root $projectRoot
    Get-WikiFingerprint $rootPath $Path | ConvertTo-Json -Depth 4
} catch { Write-Error $_; exit 1 }
