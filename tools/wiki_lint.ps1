[CmdletBinding()]
param([string]$Root)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
. (Join-Path $PSScriptRoot 'wiki_common.ps1')

try {
    $rootPath = Resolve-WikiRoot $Root (Split-Path -Parent $PSScriptRoot)
    $errors = New-Object 'System.Collections.Generic.List[string]'
    $warnings = New-Object 'System.Collections.Generic.List[string]'
    $pages = @(Get-WikiPages $rootPath | Sort-Object FullName)
    $byPath = @{}; $byStem = @{}; $outbound = @{}; $inbound = @{}; $parsed = @{}; $registry = @{}
    $types = @('architecture', 'concept', 'component', 'decision', 'experiment', 'source', 'overview')
    foreach ($required in @('index', 'log', 'project-overview', 'sources/source-inventory')) {
        if (-not (Test-Path -LiteralPath (Join-Path $rootPath "wiki/$required.md") -PathType Leaf)) {
            $errors.Add("Missing required page: wiki/$required.md")
        }
    }
    foreach ($page in $pages) {
        $relative = Get-WikiRelativePath $rootPath $page.FullName
        $key = $relative.Substring(0, $relative.Length - 3)
        $byPath[$key] = $relative
        $stem = $page.BaseName
        if (-not $byStem.ContainsKey($stem)) { $byStem[$stem] = @() }
        $byStem[$stem] += @($key)
        $outbound[$key] = @(); $inbound[$key] = 0
        try {
            $note = Read-WikiPage $page.FullName
            $parsed[$key] = $note
            $meta = $note.Metadata
            foreach ($field in @('title', 'type', 'status', 'updated', 'sources', 'tags')) {
                if (-not $meta.ContainsKey($field)) { $errors.Add("Missing field '$field': $relative") }
            }
            if ($meta.title -isnot [string] -or -not $meta.title.Trim()) { $errors.Add("Invalid title: $relative") }
            if ($meta.type -notin $types) { $errors.Add("Invalid type: $relative") }
            if ($meta.status -notin @('draft', 'verified', 'superseded')) { $errors.Add("Invalid status: $relative") }
            if (-not (Test-WikiDate $meta.updated)) { $errors.Add("Invalid updated date: $relative") }
            foreach ($field in @('sources', 'tags')) {
                if ($meta[$field] -isnot [array]) { $errors.Add("Expected list '$field': $relative") }
            }
            foreach ($source in @($meta.sources)) {
                if (-not $source) { continue }
                try {
                    if ([IO.Path]::IsPathRooted($source)) { throw 'Use repository-relative sources.' }
                    if ($source -match '\\|(^|/)\.\.?(/|$)') { throw 'Use canonical forward-slash source paths.' }
                    $full = Resolve-WikiLocalPath $rootPath $source
                    $sourceRelative = Get-WikiRelativePath $rootPath $full
                    if (-not (Test-WikiSourcePath $sourceRelative)) { throw 'Not an evidence path.' }
                    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw 'Missing evidence file.' }
                } catch { $errors.Add("Invalid source '$source' in ${relative}: $_") }
            }
            if ($meta.type -eq 'source') {
                if ($meta.source_path -isnot [string] -or -not $meta.source_path) { $errors.Add("Missing source_path: $relative") }
                elseif ($meta.source_path -notin @($meta.sources)) { $errors.Add("source_path is absent from sources: $relative") }
                if ($meta.source_hash -isnot [string] -or $meta.source_hash -notmatch '^[0-9a-fA-F]{64}$') { $errors.Add("Invalid source_hash: $relative") }
                if (-not (Test-WikiDate $meta.ingested_at)) { $errors.Add("Invalid ingested_at: $relative") }
                if ($meta.source_path) {
                    if ($registry.ContainsKey($meta.source_path)) { $errors.Add("Duplicate source registration: $relative") }
                    $registry[$meta.source_path] = $key
                }
            }
        } catch { $errors.Add("Cannot parse ${relative}: $_") }
    }
    foreach ($key in @($parsed.Keys | Sort-Object)) {
        $body = Get-WikiProse $parsed[$key].Body
        foreach ($link in [regex]::Matches($body, '(?<!!)\[\[([^\]\r\n]+)\]\]|!\[\[([^\]\r\n]+)\]\]')) {
            $raw = if ($link.Groups[1].Success) { $link.Groups[1].Value } else { $link.Groups[2].Value }
            $target = (($raw -split '\|', 2)[0] -split '[#^]', 2)[0].Trim().Replace('\', '/') -replace '\.md$', ''
            $resolved = $null
            if (-not $target) { $resolved = $key }
            elseif ($byPath.ContainsKey($target)) { $resolved = $target }
            elseif (-not $target.Contains('/') -and $byStem.ContainsKey($target)) {
                if ($byStem[$target].Count -gt 1) { $errors.Add("Ambiguous wikilink in ${key}: [[$raw]]"); continue }
                $resolved = $byStem[$target][0]
            }
            if (-not $resolved) { $errors.Add("Broken wikilink in ${key}: [[$raw]]"); continue }
            if ($target -and -not $target.StartsWith('wiki/')) { $errors.Add("Use full wiki/ path in ${key}: [[$raw]]") }
            if ($resolved -ne $key) { $inbound[$resolved]++; $outbound[$key] += @($resolved) }
        }
    }
    $reachable = @{}; $queue = New-Object 'System.Collections.Generic.Queue[string]'
    if ($byPath.ContainsKey('wiki/index')) { $queue.Enqueue('wiki/index'); $reachable['wiki/index'] = $true }
    while ($queue.Count) {
        foreach ($target in $outbound[$queue.Dequeue()]) {
            if (-not $reachable.ContainsKey($target)) { $reachable[$target] = $true; $queue.Enqueue($target) }
        }
    }
    foreach ($key in @($byPath.Keys | Sort-Object)) {
        if ($key -ne 'wiki/index' -and $inbound[$key] -eq 0) { $warnings.Add("Orphan page: $key") }
        if (-not $reachable.ContainsKey($key)) { $warnings.Add("Page is not reachable from wiki/index.md: $key") }
    }
    Write-Output "Wiki pages: $($pages.Count)"
    Write-Output "Errors: $($errors.Count)"
    foreach ($message in $errors) { Write-Output "ERROR: $message" }
    Write-Output "Warnings: $($warnings.Count)"
    foreach ($message in $warnings) { Write-Output "WARN: $message" }
    if ($errors.Count) { exit 1 }
    exit 0
} catch { Write-Error $_; exit 1 }
