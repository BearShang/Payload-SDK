[CmdletBinding()]
param([string]$Root, [string]$Output = 'wiki/sources/repository-manifest.csv')

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
. (Join-Path $projectRoot 'tools/wiki_common.ps1')
try {
    $rootPath = Resolve-WikiRoot $Root $projectRoot
    Assert-WikiGitRoot $rootPath
    $destination = Resolve-WikiLocalPath $rootPath $Output
    $relativeOutput = Get-WikiRelativePath $rootPath $destination
    if ($relativeOutput -notmatch '^wiki/.+\.csv$') { throw 'Output must be a CSV inside wiki/.' }
    $paths = (Invoke-WikiGit $rootPath 'ls-files -z --cached --others --exclude-standard') -split "`0"
    $rows = @(
        foreach ($relative in @($paths | Where-Object { $_ } | Sort-Object -Unique)) {
            if (-not (Test-WikiSourcePath $relative)) { continue }
            $full = Resolve-WikiLocalPath $rootPath $relative
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Missing or non-file source: $relative" }
            $identity = Get-WikiFingerprint $rootPath $relative
            $category = if ($relative -match '^psdk_lib/lib/|/(drivers|middlewares|3rdparty)/|\.(a|lib|exe|bin)$') { 'vendor-or-binary' }
                elseif (Test-WikiAuthoritativePath $relative) { 'reference' }
                else { 'engineering' }
            [pscustomobject][ordered]@{
                relative_path = $identity.relative_path
                category = $category
                planned_depth = if ($category -eq 'vendor-or-binary') { 'identity-and-summary' } else { 'scoped-review' }
                ingest_status = 'inventoried'
                sha256 = $identity.sha256
                size_bytes = $identity.size_bytes
            }
        }
    )
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
    if ($rows.Count) { $rows | Export-Csv -LiteralPath $destination -NoTypeInformation -Encoding UTF8 }
    else { [IO.File]::WriteAllText($destination, '"relative_path","category","planned_depth","ingest_status","sha256","size_bytes"' + "`r`n", [Text.Encoding]::UTF8) }
    [pscustomobject]@{ output = $relativeOutput; files = $rows.Count } | ConvertTo-Json
} catch { Write-Error $_; exit 1 }
