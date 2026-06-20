param(
    [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Split-Path -Parent $ScriptDir
$TemplateDir = Join-Path $SkillDir "plan-template"
$PlanDir = Join-Path $ProjectRoot "plan"
$ChaptersDir = Join-Path $ProjectRoot "chapters"
$RefsDir = Join-Path $ProjectRoot "refs"

New-Item -ItemType Directory -Path $PlanDir -Force | Out-Null
New-Item -ItemType Directory -Path $ChaptersDir -Force | Out-Null
New-Item -ItemType Directory -Path $RefsDir -Force | Out-Null

$copied = 0
$created = 0
$names = @(
    "project-overview.md",
    "progress.md",
    "notes.md",
    "outline.md",
    "stage-gates.md"
)

foreach ($name in $names) {
    $src = Join-Path $TemplateDir $name
    $dst = Join-Path $PlanDir $name

    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[WARN] template missing: $src"
        continue
    }

    if (Test-Path -LiteralPath $dst) {
        Write-Host "[SKIP] exists: $dst"
    } else {
        Copy-Item -LiteralPath $src -Destination $dst
        Write-Host "[ADD]  $dst"
        $copied += 1
    }
}

$ledgerPath = Join-Path $RefsDir "citation-verification.csv"
if (Test-Path -LiteralPath $ledgerPath) {
    Write-Host "[SKIP] exists: $ledgerPath"
} else {
    $ledgerHeader = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("5byV55So57yW5Y+3LOW8leeUqOadpea6kCzorrrmloflvJXnlKjkvY3nva4s5piv5ZCm5Lq65bel5qCh6aqMLOagoemqjOeKtuaAgSzmoKHpqozmg4XlhrUs55So5oi35qCh6aqM57uT5p6cLOWkhOeQhuW7uuiurizmnIDlkI7mm7TmlrA="))
    Set-Content -LiteralPath $ledgerPath -Value $ledgerHeader -Encoding UTF8
    Write-Host "[ADD]  $ledgerPath"
    $created += 1
}

$refsReadmePath = Join-Path $RefsDir "README.md"
if (Test-Path -LiteralPath $refsReadmePath) {
    Write-Host "[SKIP] exists: $refsReadmePath"
} else {
    $refsReadme = @(
        "# Citation Verification Rules",
        "",
        "- Every new, deleted, or modified citation must update the final references/notes chapter and refs/citation-verification.csv.",
        "- The machine-check status/details columns record DOI, database, web, or local PDF checks; they are not manual verification.",
        "- Mark the manual-check column as completed only after the user explicitly confirms manual verification.",
        "- If the user confirms that a citation is fabricated, unusable, or mismatched, remove or replace it in the body, final references chapter, and ledger, then tell the user."
    )
    Set-Content -LiteralPath $refsReadmePath -Value $refsReadme -Encoding UTF8
    Write-Host "[ADD]  $refsReadmePath"
    $created += 1
}

$referencesChapterPath = Join-Path $ChaptersDir "07-references.md"
if (Test-Path -LiteralPath $referencesChapterPath) {
    Write-Host "[SKIP] exists: $referencesChapterPath"
} else {
    $referencesChapter = @(
        "# References and Notes",
        "",
        "> Keep all references, notes, and source records here. Do not create per-chapter reference lists unless the user, school, journal, or venue explicitly requires them.",
        ""
    )
    Set-Content -LiteralPath $referencesChapterPath -Value $referencesChapter -Encoding UTF8
    Write-Host "[ADD]  $referencesChapterPath"
    $created += 1
}

Write-Host "[DONE] plan bootstrap finished. files_copied=$copied files_created=$created plan_dir=$PlanDir"
