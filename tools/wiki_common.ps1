Set-StrictMode -Version 2.0

function Resolve-WikiRoot {
    param([string]$Root, [string]$DefaultRoot)
    if (-not $Root) { $Root = $DefaultRoot }
    $item = Get-Item -LiteralPath $Root -Force -ErrorAction Stop
    if (-not $item.PSIsContainer) { throw "Not a directory: $Root" }
    return $item.FullName.TrimEnd('\', '/')
}

function Resolve-WikiLocalPath {
    param([string]$Root, [string]$Path)
    if (-not $Path) { throw 'Empty local path.' }
    $full = if ([IO.Path]::IsPathRooted($Path)) {
        [IO.Path]::GetFullPath($Path)
    } else {
        [IO.Path]::GetFullPath((Join-Path $Root $Path))
    }
    $prefix = $Root + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the repository: $Path"
    }
    # Check every existing ancestor, including the root, before following a path.
    $cursor = $full
    while ($cursor.Length -ge $Root.Length) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Linked paths are not supported: $Path"
            }
        }
        if ($cursor -eq $Root) { break }
        $cursor = Split-Path -Parent $cursor
    }
    return $full
}

function Get-WikiRelativePath {
    param([string]$Root, [string]$FullPath)
    return $FullPath.Substring($Root.Length + 1).Replace('\', '/')
}

function Test-WikiAuthoritativePath {
    param([string]$Path)
    return $Path -match '^(doc|hardware|sources|datasheets|test/raw)/'
}

function Test-WikiSourcePath {
    param([string]$Path)
    if ($Path -match '(^|/)(\.git|\.agents|\.obsidian|\.vscode|\.idea|\.vs|\.cache|\.tmp|\.pytest_cache|wiki|node_modules|__pycache__|\.venv|build|dist|target|cmake-build[^/]*|CMakeFiles|objects|listings)(/|$)') { return $false }
    if ($Path -match '(^|/)(wiki_[^/]*|test_wiki_tools)\.ps1$|\.(o|obj|pyc|pdb|map|axf|elf|crf|lnp)$|\.uvguix\.') { return $false }
    return (Test-WikiAuthoritativePath $Path) -or
        $Path -match '^(psdk_lib|samples|tools|test/scripts)/' -or
        $Path -in @('README.md', 'CMakeLists.txt', 'LICENSE.txt', 'EULA.txt', 'LLM Wiki.md')
}

function Get-WikiFingerprint {
    param([string]$Root, [string]$Path)
    $full = Resolve-WikiLocalPath $Root $Path
    $relative = Get-WikiRelativePath $Root $full
    if (-not (Test-WikiSourcePath $relative)) { throw "Not an ingestible source: $relative" }
    $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
    if ($item.PSIsContainer) { throw "Expected a regular file: $relative" }
    return [pscustomobject][ordered]@{
        relative_path = $relative
        sha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
        size_bytes = $item.Length
    }
}

function Invoke-WikiGit {
    param([string]$Root, [string]$Arguments)
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = 'git'
    $info.WorkingDirectory = $Root
    $info.Arguments = '--no-optional-locks ' + $Arguments
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object System.Text.UTF8Encoding($false)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $output = $stdout.GetAwaiter().GetResult()
        $errorText = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "git $Arguments failed: $errorText" }
        return $output
    } finally { $process.Dispose() }
}

function Assert-WikiGitRoot {
    param([string]$Root)
    $top = (Invoke-WikiGit $Root 'rev-parse --show-toplevel').Trim()
    if ([IO.Path]::GetFullPath($top).TrimEnd('\', '/') -ne $Root) {
        throw 'Root must be the Git repository root, not a subdirectory.'
    }
}

function ConvertFrom-WikiScalar {
    param([string]$Value)
    $value = $Value.Trim()
    if ($value.StartsWith('"')) {
        $result = ConvertFrom-Json -InputObject $value -ErrorAction Stop
        if ($result -isnot [string]) { throw 'Expected a quoted string.' }
        return $result
    }
    if ($value -match "^'(?:[^']|'')*'$" ) { return $value.Substring(1, $value.Length - 2).Replace("''", "'") }
    if (-not $value -or $value -match "^[\[\]{}&*!|>'%@``]|(^|\s)#|:\s") {
        throw "Unsupported frontmatter scalar; use a quoted single-line string: $Value"
    }
    return $value
}

function Read-WikiPage {
    param([string]$Path)
    $content = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    $match = [regex]::Match($content, '\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)', 'Singleline')
    if (-not $match.Success) { throw "Missing or malformed frontmatter: $Path" }
    # This deliberately parses only the documented flat schema, rejecting YAML
    # constructs it cannot interpret rather than silently losing source identity.
    $meta = @{}
    $listKey = $null
    foreach ($line in ($match.Groups[1].Value -split '\r?\n')) {
        if ($line -match '^\s*(#.*)?$') { continue }
        if ($line -match '^  +-[ ]+(.+)$') {
            if (-not $listKey) { throw "Unexpected list item: $Path" }
            $meta[$listKey] += @(ConvertFrom-WikiScalar $Matches[1])
            continue
        }
        if ($line -notmatch '^([a-z_]+):(?:[ ]+(.*))?$') { throw "Unsupported frontmatter line in ${Path}: $line" }
        $key = $Matches[1]
        $value = $Matches[2]
        if ($meta.ContainsKey($key)) { throw "Duplicate frontmatter key '$key': $Path" }
        $listKey = $null
        if (-not $value -or $value -eq '[]') {
            $meta[$key] = @()
            if (-not $value) { $listKey = $key }
        } else { $meta[$key] = ConvertFrom-WikiScalar $value }
    }
    return [pscustomobject]@{ Metadata = $meta; Body = $content.Substring($match.Length) }
}

function Test-WikiDate {
    param($Value)
    $date = [datetime]::MinValue
    return $Value -is [string] -and $Value -match '^\d{4}-\d{2}-\d{2}$' -and
        [datetime]::TryParseExact($Value, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)
}

function Get-WikiPages {
    param([string]$Root)
    $wiki = Resolve-WikiLocalPath $Root 'wiki'
    if (-not (Test-Path -LiteralPath $wiki -PathType Container)) { throw 'Missing wiki directory.' }
    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    $queue.Enqueue($wiki)
    while ($queue.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $queue.Dequeue() -Force) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked Wiki path: $($item.FullName)" }
            if ($item.PSIsContainer) {
                if ($item.Name -notin @('.tmp', '.git', '__pycache__')) { $queue.Enqueue($item.FullName) }
            } elseif ($item.Extension -eq '.md') { $item }
        }
    }
}

function Get-WikiProse {
    param([string]$Body)
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $fence = ''; $length = 0
    foreach ($line in ($Body -split '\r?\n')) {
        if ($fence) {
            if ($line -match ('^ {0,3}' + [regex]::Escape($fence) + '{' + $length + ',}\s*$')) { $fence = '' }
            continue
        }
        if ($line -match '^ {0,3}(`{3,}|~{3,})') { $fence = $Matches[1].Substring(0, 1); $length = $Matches[1].Length; continue }
        if ($line -match '^( {4}|\t)') { continue }
        $lines.Add($line)
    }
    $text = $lines -join "`n"
    $text = [regex]::Replace($text, '<!--.*?-->|%%.*?%%', '', 'Singleline')
    return [regex]::Replace($text, '(`+)(?!`)(.*?)\1(?!`)', '', 'Singleline')
}
