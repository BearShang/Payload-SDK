[CmdletBinding()]
param([string]$Root)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
. (Join-Path $projectRoot 'tools/wiki_common.ps1')
try {
    $rootPath = Resolve-WikiRoot $Root $projectRoot
    Assert-WikiGitRoot $rootPath
    $known = @{}; $hashPaths = @{}; $gitChanges = @{}; $renamedOld = @{}
    foreach ($page in @(Get-WikiPages $rootPath | Sort-Object FullName)) {
        $meta = (Read-WikiPage $page.FullName).Metadata
        if ($meta['type'] -ne 'source') { continue }
        $path = $meta['source_path']; $hash = $meta['source_hash']
        if ($path -isnot [string] -or -not $path -or $hash -isnot [string] -or $hash -notmatch '^[0-9a-fA-F]{64}$' -or -not (Test-WikiDate $meta['ingested_at'])) {
            throw "Invalid source identity: $($page.FullName)"
        }
        if ([IO.Path]::IsPathRooted($path) -or $path -match '\\|(^|/)\.\.?(/|$)') { throw "Noncanonical source_path: $path" }
        if (-not (Test-WikiSourcePath $path)) { throw "Not an evidence source_path: $path" }
        if ($meta['sources'] -isnot [array] -or $path -notin $meta['sources']) { throw "source_path must occur in sources: $path" }
        if (-not (Test-WikiAuthoritativePath $path)) { continue }
        if (-not $known.ContainsKey($path)) { $known[$path] = @() }
        $known[$path] += @($hash.ToLowerInvariant())
        if (-not $hashPaths.ContainsKey($hash)) { $hashPaths[$hash] = @() }
        $hashPaths[$hash] += @($path)
    }

    # Porcelain -z keeps paths with spaces, tabs, quotes and non-ASCII intact.
    # Rename entries put the destination first, then the original path.
    $entries = (Invoke-WikiGit $rootPath 'status --porcelain=v1 -z --untracked-files=all') -split "`0"
    for ($i = 0; $i -lt $entries.Count; $i++) {
        if (-not $entries[$i]) { continue }
        $code = $entries[$i].Substring(0, 2)
        $path = $entries[$i].Substring(3)
        $old = $null
        if ($code -match '[RC]') {
            $i++
            if ($i -ge $entries.Count -or -not $entries[$i]) { throw 'Malformed Git rename record.' }
            $old = $entries[$i]
        }
        if (-not (Test-WikiAuthoritativePath $path) -and -not ($old -and (Test-WikiAuthoritativePath $old))) { continue }
        $status = if ($code -eq '??') { 'untracked' }
            elseif ($code -in @('DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU')) { 'unmerged' }
            elseif ($code -match 'R') { 'renamed' }
            elseif ($code -match 'D') { 'deleted' }
            elseif ($code -match 'T') { 'type-changed' }
            elseif ($code -match 'A') { 'added' }
            elseif ($code -match 'C') { 'copied' }
            elseif ($code -match 'M') { 'modified' }
            else { 'other' }
        $gitChanges[$path] = [pscustomobject]@{ code = $code; status = $status; old_path = $old }
        if ($status -eq 'renamed') { $renamedOld[$old] = $true }
    }

    $files = @((Invoke-WikiGit $rootPath 'ls-files -z --cached --others --exclude-standard') -split "`0" | Where-Object { $_ -and (Test-WikiAuthoritativePath $_) })
    $paths = @(@($files) + @($known.Keys) + @($gitChanges.Keys) | Sort-Object -Unique)
    $changes = @(
        foreach ($path in $paths) {
            if ($renamedOld.ContainsKey($path) -and -not $gitChanges.ContainsKey($path)) { continue }
            if (-not (Test-WikiSourcePath $path) -and -not $gitChanges.ContainsKey($path) -and -not $known.ContainsKey($path)) { continue }
            $reasons = New-Object 'System.Collections.Generic.List[string]'
            $recorded = @(if ($known.ContainsKey($path)) { $known[$path] })
            $git = if ($gitChanges.ContainsKey($path)) { $gitChanges[$path] } else { $null }
            if ($git) { $reasons.Add($git.status) }
            if ($recorded.Count -gt 1) { $reasons.Add('registry-conflict') }
            $exists = $false; $current = $null
            try {
                $full = Resolve-WikiLocalPath $rootPath $path
                if (Test-Path -LiteralPath $full -PathType Leaf) {
                    $exists = $true
                    $current = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
                } elseif (Test-Path -LiteralPath $full) { $reasons.Add('non-regular-source') }
                elseif ($recorded.Count -and -not ($git -and $git.status -eq 'deleted')) { $reasons.Add('missing-recorded-source') }
                elseif (-not $git) { $reasons.Add('deleted') }
            } catch { $reasons.Add('non-regular-source') }
            $matchingPaths = @()
            if ($exists) {
                if (-not $recorded.Count) {
                    $reasons.Add('not-ingested')
                    if ($hashPaths.ContainsKey($current)) {
                        $matchingPaths = @($hashPaths[$current] | Where-Object { $_ -ne $path } | Sort-Object -Unique)
                        if ($matchingPaths.Count) { $reasons.Add('possible-relocation') }
                    }
                } elseif ($current -notin $recorded) { $reasons.Add('hash-diverged') }
            }
            if (-not $reasons.Count) { continue }
            $decisionReasons = @('deleted', 'renamed', 'unmerged', 'type-changed', 'other', 'registry-conflict', 'missing-recorded-source', 'possible-relocation', 'non-regular-source')
            $needsDecision = @($reasons | Where-Object { $_ -in $decisionReasons }).Count -gt 0
            [pscustomobject][ordered]@{
                path = $path
                status = $reasons[0]
                reasons = @($reasons)
                git_code = if ($git) { $git.code } else { $null }
                old_path = if ($git) { $git.old_path } else { $null }
                current_exists = $exists
                recorded_hashes = @($recorded)
                current_hash = $current
                matching_paths = @($matchingPaths)
                requires_decision = $needsDecision
            }
        }
    )
    $actionable = @($changes | Where-Object { $_.current_exists -and -not $_.requires_decision } | Select-Object -ExpandProperty path)
    [pscustomobject][ordered]@{
        repository = $rootPath
        authoritative_roots = @('doc/', 'hardware/', 'sources/', 'datasheets/', 'test/raw/')
        change_count = $changes.Count
        actionable_count = $actionable.Count
        decision_count = @($changes | Where-Object { $_.requires_decision }).Count
        actionable_paths = $actionable
        changes = $changes
    } | ConvertTo-Json -Depth 6
} catch { Write-Error $_; exit 1 }
