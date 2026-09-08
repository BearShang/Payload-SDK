[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'wiki_common.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ('payload-wiki-tests-' + [guid]::NewGuid().ToString('N'))
$hostExe = (Get-Process -Id $PID).Path
$script:checks = 0

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
    Write-Output "PASS: $Message"
}

function Write-Fixture {
    param([string]$Path, [string]$Content)
    $full = Resolve-WikiLocalPath $sandbox $Path
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $full))
    [IO.File]::WriteAllText($full, $Content, (New-Object Text.UTF8Encoding($false)))
}

function New-Note {
    param([string]$Body = '', [string]$Type = 'overview', [string]$Extra = '')
    return "---`ntitle: Test note`ntype: $Type`nstatus: draft`nupdated: 2026-09-08`nsources: []`ntags: []`n$Extra---`n`n$Body`n"
}

function Invoke-Tool {
    param([string]$Name, [string[]]$Extra = @())
    $path = if ($Name -eq 'lint') { Join-Path $PSScriptRoot 'wiki_lint.ps1' }
        else { Join-Path $projectRoot ".agents/skills/payload-sdk-ingest/scripts/$Name.ps1" }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $hostExe
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path, '-Root', $sandbox) + $Extra
    $info.Arguments = ($argsList | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        return [pscustomobject]@{ Code = $process.ExitCode; Text = $stdout.GetAwaiter().GetResult(); Error = $stderr.GetAwaiter().GetResult() }
    } finally { $process.Dispose() }
}

function Get-Scan {
    $result = Invoke-Tool 'changed_authoritative_sources'
    if ($result.Code) { throw "Scan failed: $($result.Error)" }
    return ConvertFrom-Json $result.Text
}

function Set-SourceNote {
    param([string]$Path, [string]$Hash, [string]$Note = 'wiki/sources/evidence.md')
    $content = New-Note '[[wiki/index|Index]]' 'source' "source_path: $Path`nsource_hash: $Hash`ningested_at: 2026-09-08`n"
    Write-Fixture $Note ($content.Replace('sources: []', "sources:`n  - $Path"))
}

function Get-FixtureState {
    return @(Get-ChildItem -LiteralPath $sandbox -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
        (Get-WikiRelativePath $sandbox $_.FullName) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }) -join "`n"
}

try {
    [void][IO.Directory]::CreateDirectory($sandbox)
    $index = New-Note "[[wiki/project-overview|Overview]]`n[[wiki/sources/source-inventory|Inventory]]`n[[wiki/log|Log]]"
    Write-Fixture 'wiki/index.md' $index
    foreach ($path in @('wiki/project-overview.md', 'wiki/sources/source-inventory.md', 'wiki/log.md')) { Write-Fixture $path (New-Note '[[wiki/index|Index]]') }
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -eq 0 -and $result.Text -match 'Warnings: 0') 'Valid initial Wiki has zero errors and warnings'

    $ignored = @'
```markdown
[[wiki/not-real]]
```
~~~text
[[wiki/not-real-either]]
~~~
Inline `[[wiki/example]]` and ``[[wiki/example2]]``.
    [[wiki/indented-code]]
<!-- [[wiki/comment]] -->
%% [[wiki/obsidian-comment]] %%
[[#Local heading]]
'@
    Write-Fixture 'wiki/.tmp/unparsed.md' 'Not a Wiki page'
    Write-Fixture '.agents/skills/example/assets/template.md' '[[wiki/template-placeholder]]'
    Write-Fixture 'wiki/index.md' ($index + $ignored)
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -eq 0 -and $result.Text -match 'Warnings: 0') 'Code examples, comments, local anchors and temporary files are ignored'
    Write-Fixture 'wiki/index.md' ($index + '[[wiki/missing]]')
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -ne 0 -and $result.Text -match 'Broken wikilink') 'Missing target fails lint'
    Write-Fixture 'wiki/index.md' ($index + '[[topic]]')
    Write-Fixture 'wiki/a/topic.md' (New-Note '[[wiki/index]]')
    Write-Fixture 'wiki/b/topic.md' (New-Note '[[wiki/index]]')
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -ne 0 -and $result.Text -match 'Ambiguous wikilink') 'Ambiguous short target fails lint'
    Write-Fixture 'wiki/index.md' $index
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -eq 0 -and $result.Text -match 'Orphan page' -and $result.Text -match 'not reachable') 'Unreachable and orphan pages produce warnings'
    Write-Fixture 'wiki/index.md' ($index + "`n[[wiki/a/topic]]`n[[wiki/b/topic]]")
    $linkedIndex = [IO.File]::ReadAllText((Join-Path $sandbox 'wiki/index.md'))
    foreach ($case in @(
        @{ Name = 'Missing field'; Value = $linkedIndex.Replace("title: Test note`n", ''); Expected = 'Missing field' },
        @{ Name = 'Impossible calendar date'; Value = $linkedIndex.Replace('2026-09-08', '2026-02-30'); Expected = 'Invalid updated date' },
        @{ Name = 'Invalid type'; Value = $linkedIndex.Replace('type: overview', 'type: invalid'); Expected = 'Invalid type' },
        @{ Name = 'Invalid status'; Value = $linkedIndex.Replace('status: draft', 'status: done'); Expected = 'Invalid status' },
        @{ Name = 'Duplicate metadata key'; Value = $linkedIndex.Replace('type: overview', "type: overview`ntype: concept"); Expected = 'Duplicate' },
        @{ Name = 'Unsupported YAML structure'; Value = $linkedIndex.Replace('tags: []', 'tags: [one, two]'); Expected = 'Unsupported' }
    )) {
        Write-Fixture 'wiki/index.md' $case.Value
        $result = Invoke-Tool 'lint'
        Assert-That ($result.Code -ne 0 -and $result.Text -match $case.Expected) $case.Name
    }
    Write-Fixture 'wiki/index.md' $linkedIndex
    $sourcePath = 'hardware/' + [char]0x4E2D + [char]0x6587 + ' source.txt'
    Write-Fixture $sourcePath 'original evidence'
    $hash = (Get-WikiFingerprint $sandbox $sourcePath).sha256
    Set-SourceNote $sourcePath $hash
    Write-Fixture 'wiki/index.md' ($linkedIndex + "`n[[wiki/sources/evidence]]")
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -eq 0 -and $result.Text -match 'Warnings: 0') 'Valid source identity and Chinese path pass lint'
    Set-SourceNote $sourcePath 'bad-hash'
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -ne 0 -and $result.Text -match 'Invalid source_hash') 'Invalid source hash fails lint'
    Set-SourceNote ('hardware/../' + $sourcePath) $hash
    $result = Invoke-Tool 'lint'
    Assert-That ($result.Code -ne 0 -and $result.Text -match 'canonical') 'Noncanonical source paths fail lint consistently with the scanner'
    Set-SourceNote $sourcePath $hash

    [void](Invoke-WikiGit $sandbox 'init -q')
    [void](Invoke-WikiGit $sandbox 'config user.name Wiki-Test')
    [void](Invoke-WikiGit $sandbox 'config user.email wiki-test@example.invalid')
    [void](Invoke-WikiGit $sandbox 'config core.autocrlf false')
    Write-Fixture 'doc/unregistered.txt' 'unregistered document'
    Write-Fixture 'samples/example.c' 'example implementation'
    Write-Fixture 'samples/.vscode/settings.json' '{}'
    Write-Fixture 'samples/.cache/local.txt' 'cache artifact'
    Write-Fixture 'psdk_lib/lib/example.a' 'vendor archive fixture'
    Write-Fixture 'build/ignored.o' 'build artifact'
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { $_.status -eq 'untracked' }).Count -eq 2) 'Unborn Git repository reports untracked authoritative sources only'
    [void](Invoke-WikiGit $sandbox 'add .')
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { $_.status -eq 'added' }).Count -eq 2) 'Staged additions are distinguished from untracked files'
    [void](Invoke-WikiGit $sandbox '-c commit.gpgsign=false commit -qm baseline')
    $scan = Get-Scan
    Assert-That ($scan.change_count -eq 1 -and $scan.changes[0].status -eq 'not-ingested') 'Committed unregistered source remains discoverable'
    $before = Get-FixtureState
    $first = Invoke-Tool 'changed_authoritative_sources'
    $second = Invoke-Tool 'changed_authoritative_sources'
    $fingerprint = Invoke-Tool 'source_fingerprint' @('-Path', $sourcePath)
    Assert-That ($first.Code -eq 0 -and $first.Text -eq $second.Text) 'Repeated scans are deterministic'
    Assert-That ($fingerprint.Code -eq 0 -and (ConvertFrom-Json $fingerprint.Text).sha256 -eq $hash -and (ConvertFrom-Json $fingerprint.Text).relative_path -eq $sourcePath) 'Fingerprint handles Chinese and space-containing paths'
    Assert-That ((Get-FixtureState) -eq $before) 'Scan and fingerprint leave every fixture file, including Git metadata, unchanged'

    Write-Fixture $sourcePath 'modified evidence'
    $scan = Get-Scan
    $change = @($scan.changes | Where-Object { $_.path -eq $sourcePath })[0]
    Assert-That ($change.status -eq 'modified' -and 'hash-diverged' -in $change.reasons) 'Working-tree modification retains Git and registry evidence'
    [void](Invoke-WikiGit $sandbox 'add hardware')
    [void](Invoke-WikiGit $sandbox '-c commit.gpgsign=false commit -qm source-update')
    $scan = Get-Scan
    $change = @($scan.changes | Where-Object { $_.path -eq $sourcePath })[0]
    Assert-That ($change.status -eq 'hash-diverged') 'Committed source revision is detected by hash'
    Set-SourceNote $sourcePath $hash 'wiki/sources/duplicate.md'
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { 'registry-conflict' -in $_.reasons -and $_.requires_decision }).Count -eq 1) 'Duplicate registration requires confirmation even alongside a changed source'
    Write-Fixture 'wiki/sources/duplicate.md' (New-Note '[[wiki/index]]')
    Set-SourceNote $sourcePath ((Get-WikiFingerprint $sandbox $sourcePath).sha256)
    $renameArgs = 'mv -- "' + $sourcePath + '" "hardware/renamed source.txt"'
    [void](Invoke-WikiGit $sandbox $renameArgs)
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { $_.status -eq 'renamed' -and $_.old_path -eq $sourcePath -and $_.requires_decision }).Count -eq 1) 'Staged rename preserves old path and requires confirmation'
    [void](Invoke-WikiGit $sandbox '-c commit.gpgsign=false commit -qm rename-source')
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { 'possible-relocation' -in $_.reasons }).Count -eq 1 -and $scan.decision_count -ge 2) 'Committed rename reports possible relocation and missing registration'
    Set-SourceNote 'hardware/renamed source.txt' ((Get-WikiFingerprint $sandbox 'hardware/renamed source.txt').sha256)
    [void](Invoke-WikiGit $sandbox 'rm -- "hardware/renamed source.txt"')
    $scan = Get-Scan
    Assert-That (@($scan.changes | Where-Object { $_.status -eq 'deleted' -and $_.requires_decision }).Count -eq 1) 'Deleted source requires confirmation'
    Write-Fixture 'wiki/sources/evidence.md' (New-Note '[[wiki/index]]')
    Set-SourceNote 'doc/unregistered.txt' 'bad-hash'
    $result = Invoke-Tool 'changed_authoritative_sources'
    Assert-That ($result.Code -ne 0) 'Malformed registry fails scanning rather than silently skipping a source'
    Write-Fixture 'wiki/sources/evidence.md' (New-Note '[[wiki/index]]')

    $result = Invoke-Tool 'repository_manifest'
    Assert-That ($result.Code -eq 0) 'Explicit manifest command writes CSV inside Wiki'
    $manifest = @(Import-Csv -LiteralPath (Join-Path $sandbox 'wiki/sources/repository-manifest.csv'))
    Assert-That ($manifest.Count -eq 3 -and @($manifest | Where-Object { $_.ingest_status -ne 'inventoried' -or $_.sha256 -notmatch '^[0-9a-f]{64}$' }).Count -eq 0) 'Manifest has independent hashes and inventoried-only status'
    Assert-That (@($manifest | Where-Object { $_.relative_path -like 'wiki/*' -or $_.relative_path -like '.agents/*' -or $_.relative_path -like 'build/*' }).Count -eq 0) 'Manifest excludes maintenance files and build artifacts'
    Assert-That (@($manifest | Where-Object { $_.relative_path -match '/\.(vscode|cache)/' }).Count -eq 0) 'Manifest excludes nested editor state and caches'
    Assert-That (@($manifest | Where-Object { $_.category -eq 'vendor-or-binary' }).Count -eq 1) 'Vendor binaries are classified for identity and summary only'
    $result = Invoke-Tool 'repository_manifest' @('-Output', 'doc/overwrite.csv')
    Assert-That ($result.Code -ne 0 -and -not (Test-Path -LiteralPath (Join-Path $sandbox 'doc/overwrite.csv'))) 'Manifest refuses source-directory output'
    $result = Invoke-Tool 'source_fingerprint' @('-Path', '../outside.txt')
    Assert-That ($result.Code -ne 0) 'Fingerprint refuses repository escape'
    $result = Invoke-Tool 'source_fingerprint' @('-Path', 'wiki/index.md')
    Assert-That ($result.Code -ne 0) 'Fingerprint refuses derived Wiki files'
    Write-Output "All $script:checks checks passed."
} finally {
    # Delete only this invocation's GUID-named fixture directory under system temp.
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
    $resolved = [IO.Path]::GetFullPath($sandbox)
    if ((Split-Path -Parent $resolved) -ne $tempRoot -or (Split-Path -Leaf $resolved) -notmatch '^payload-wiki-tests-[0-9a-f]{32}$') {
        throw "Refusing cleanup outside the isolated test directory: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) {
        if ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing linked test directory cleanup.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
