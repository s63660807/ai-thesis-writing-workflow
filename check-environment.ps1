$ErrorActionPreference = "Stop"

$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $bundleRoot "logs"
$logFile = Join-Path $logDir "environment-check.md"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Get-CommandStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$VersionArgs
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return [PSCustomObject]@{
            Name = $Name
            Status = "missing"
            Path = ""
            Version = ""
        }
    }

    $version = ""
    try {
        $parts = $VersionArgs -split " "
        $output = & $cmd.Source @parts 2>&1 | Select-Object -First 1
        if ($output) {
            $version = ($output | Out-String).Trim()
        }
    } catch {
        $version = "version check failed: " + $_.Exception.Message
    }

    return [PSCustomObject]@{
        Name = $Name
        Status = "ok"
        Path = $cmd.Source
        Version = $version
    }
}

function Test-PathStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if (Test-Path -LiteralPath $PathValue) {
        return [PSCustomObject]@{
            Name = $Name
            Status = "ok"
            Path = $PathValue
            Version = ""
        }
    }

    return [PSCustomObject]@{
        Name = $Name
        Status = "missing"
        Path = $PathValue
        Version = ""
    }
}

$checks = @()
$checks += Get-CommandStatus -Name "python" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "py" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "node" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "npm" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "npx" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "git" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "pandoc" -VersionArgs "--version"
$checks += Get-CommandStatus -Name "winget" -VersionArgs "--version"

$chromePaths = @(
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe")
) | Where-Object { $_ -and $_.Trim().Length -gt 0 }

$edgePaths = @(
    (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe")
) | Where-Object { $_ -and $_.Trim().Length -gt 0 }

$chromeFound = $chromePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$edgeFound = $edgePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ($chromeFound) {
    $checks += Test-PathStatus -Name "chrome" -PathValue $chromeFound
} else {
    $checks += [PSCustomObject]@{ Name = "chrome"; Status = "missing"; Path = ($chromePaths -join " | "); Version = "" }
}

if ($edgeFound) {
    $checks += Test-PathStatus -Name "edge" -PathValue $edgeFound
} else {
    $checks += [PSCustomObject]@{ Name = "edge"; Status = "missing"; Path = ($edgePaths -join " | "); Version = "" }
}

$skillsDir = Join-Path $bundleRoot "skills"
$skillCount = 0
if (Test-Path -LiteralPath $skillsDir) {
    $skillCount = @(Get-ChildItem -LiteralPath $skillsDir -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md")
    }).Count
    $checks += [PSCustomObject]@{ Name = "bundled-skills"; Status = "ok"; Path = $skillsDir; Version = "count=$skillCount" }
} else {
    $checks += [PSCustomObject]@{ Name = "bundled-skills"; Status = "missing"; Path = $skillsDir; Version = "" }
}

$lines = @()
$lines += "# Environment Check"
$lines += ""
$lines += "- Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$lines += "- Bundle root: " + $bundleRoot
$lines += "- PowerShell: " + $PSVersionTable.PSVersion.ToString()
$lines += ""
$lines += "| Item | Status | Version | Path |"
$lines += "| :--- | :--- | :--- | :--- |"

foreach ($check in $checks) {
    $safeVersion = ($check.Version -replace "\|", "/")
    $safePath = ($check.Path -replace "\|", "/")
    $lines += "| $($check.Name) | $($check.Status) | $safeVersion | $safePath |"
}

$lines += ""
$lines += "## Notes"
$lines += ""
$lines += "- This script only checks the environment. It does not install software."
$lines += "- Missing Python, Node.js, Git, Pandoc, Chrome, or Edge may be acceptable if the current AI tool provides equivalent built-in capabilities."
$lines += "- CNKI, Google Scholar, Zotero, paid databases, captcha, and login sessions may still require manual user action."

Set-Content -LiteralPath $logFile -Value $lines -Encoding UTF8

$okCount = @($checks | Where-Object { $_.Status -eq "ok" }).Count
$missingCount = @($checks | Where-Object { $_.Status -ne "ok" }).Count

Write-Output "environment_check_log=$logFile"
Write-Output "ok_count=$okCount"
Write-Output "missing_count=$missingCount"
Write-Output "bundled_skill_count=$skillCount"
foreach ($check in $checks) {
    Write-Output ("check=" + $check.Name + ";status=" + $check.Status)
}
