$ErrorActionPreference = "Stop"

$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceSkills = Join-Path $bundleRoot "skills"

if (-not (Test-Path -LiteralPath $sourceSkills)) {
    throw "Missing skills directory: $sourceSkills"
}

if ($env:CODEX_HOME -and $env:CODEX_HOME.Trim().Length -gt 0) {
    $codexHome = $env:CODEX_HOME
} else {
    $codexHome = Join-Path $HOME ".codex"
}

$targetSkills = Join-Path $codexHome "skills"
New-Item -ItemType Directory -Path $targetSkills -Force | Out-Null

$skillDirs = @(Get-ChildItem -LiteralPath $sourceSkills -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") } |
    Sort-Object Name)

if ($skillDirs.Count -eq 0) {
    throw "No skill directories with SKILL.md were found in: $sourceSkills"
}

$installed = @()
foreach ($skill in $skillDirs) {
    $target = Join-Path $targetSkills $skill.Name
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Get-ChildItem -LiteralPath $skill.FullName -Force |
        Copy-Item -Destination $target -Recurse -Force
    $installed += $skill.Name
}

Write-Output "source=$sourceSkills"
Write-Output "target=$targetSkills"
Write-Output ("installed_count=" + $installed.Count)
$installed | ForEach-Object { Write-Output ("installed=" + $_) }
