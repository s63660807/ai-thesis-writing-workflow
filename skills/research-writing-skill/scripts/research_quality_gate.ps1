param(
    [string]$ProjectPath,
    [switch]$Submission,
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    $warnings.Add($Message) | Out-Null
}

function Get-TextIfExists {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }
    return $null
}

function ConvertFrom-Utf8Base64 {
    param([string]$Value)
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Get-CitationLedgerPath {
    param([string]$Root)

    $candidates = @(
        (Join-Path $Root "refs/citation-verification.csv"),
        (Join-Path $Root "refs/reference-verification.csv")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-ReferenceChapterFiles {
    param([string]$ChaptersPath)

    $files = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $ChaptersPath)) {
        return $files
    }

    foreach ($file in Get-ChildItem -LiteralPath $ChaptersPath -Filter "*.md") {
        if ($file.Name -match '(?i)(references|bibliography)') {
            $files.Add($file) | Out-Null
            continue
        }

        $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ($text -match '(?m)^\s*#\s*(\u53c2\u8003\u6587\u732e|\u6ce8\u91ca|References|Bibliography)\b') {
            $files.Add($file) | Out-Null
        }
    }

    return $files
}

function Test-HasColumns {
    param(
        [string[]]$Headers,
        [string[]]$Required
    )

    foreach ($column in $Required) {
        if ($Headers -notcontains $column) {
            return $false
        }
    }
    return $true
}

function Get-CsvValue {
    param(
        [object]$Row,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ($Row.PSObject.Properties.Name -contains $name) {
            return [string]$Row.$name
        }
    }
    return ""
}

function Count-Regex {
    param(
        [string]$Text,
        [string]$Pattern
    )
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }
    return ([regex]::Matches($Text, $Pattern)).Count
}

function Get-ChapterArchitectureSpecs {
    param([string]$Root)

    $architecturePath = Join-Path $Root "plan/chapter-architecture.md"
    $specs = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $architecturePath)) {
        return $specs
    }

    foreach ($line in Get-Content -LiteralPath $architecturePath -Encoding UTF8) {
        if ($line -match '^\s*-\s*(chapters/[^\s|]+\.md)(.*)$') {
            $rel = $matches[1]
            $rest = $matches[2]
            $minChars = 0
            if ($rest -match 'min_chars=(\d+)') {
                $minChars = [int]$matches[1]
            }
            $specs.Add([pscustomobject]@{
                Rel = $rel
                MinChars = $minChars
                AgentRequired = ($rest -match 'agent=required')
                PlaceholdersAllowed = ($rest -match 'placeholders=yes')
            }) | Out-Null
        }
    }

    return $specs
}

function Get-ProseParagraphCount {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    $paragraphs = [regex]::Split($Text, "(\r?\n\s*){2,}") | Where-Object {
        $p = $_.Trim()
        $p.Length -gt 80 -and
        $p -notmatch '^\s*#' -and
        $p -notmatch '^\s*[-*+]\s+' -and
        $p -notmatch '^\s*\|' -and
        $p -notmatch '^```'
    }
    return @($paragraphs).Count
}

$introFiles = @(
    "chapters/01_Introduction.md",
    "chapters/01-introduction.md",
    "chapters/02_Introduction.md",
    "chapters/02-introduction.md"
)

$relatedFiles = @(
    "chapters/02-related-work.md",
    "chapters/03_Related_Work.md",
    "chapters/03-related-work.md"
)

$citationPattern = '\uFF08[^\uFF09]*(19|20)\d{2}[^\uFF09]*\uFF09|\([A-Z][^)]*(19|20)\d{2}[^)]*\)|\[[A-Za-z]+-?\d+\]'
$listPattern = '(?m)^\s*([-*+]\s+|\d+\.\s+)'
$processPattern = '\u8bf4\u660e\uff1a|\u5b9e\u9a8c\u76ee\u7684|\u8868\u4f4d|\u56fe\u4f4d|\u56de\u586b\u6a21\u677f|\u8ba8\u8bba\u63d0\u793a|\u8bf7\u7528\u6237|\u7528\u6237\u66ff\u6362|\u5199\u4f5c\u8981\u6c42|\u4fee\u6539\u8981\u6c42|this section is a template|discussion prompt|fill later'
$placeholderPattern = '\u5f85\u56de\u586b|\u5f85\u5b9e\u9a8c\u56de\u586b|\u5f85\u771f\u5b9e\u5b9e\u9a8c\u66ff\u6362|\u516c\u5f0f\u5360\u4f4d|\u7b97\u6cd5\u5360\u4f4d|TODO|TBD'
$resultOverclaimPattern = '\u5b9e\u9a8c\u7ed3\u679c\u8868\u660e|results show|verified'

if ($SelfTest) {
    $sample = [string]::Concat(
        [char]0x5b9e, [char]0x9a8c, [char]0x76ee, [char]0x7684,
        "`n",
        [char]0x56de, [char]0x586b, [char]0x6a21, [char]0x677f,
        "`n[",
        [char]0x5f85, [char]0x56de, [char]0x586b,
        "-F1]"
    )
    $processHits = Count-Regex $sample $processPattern
    $placeholderHits = Count-Regex $sample $placeholderPattern
    if ($processHits -ne 2) {
        Add-Failure "SelfTest expected 2 process hits, got $processHits."
    }
    if ($placeholderHits -ne 1) {
        Add-Failure "SelfTest expected 1 placeholder hit, got $placeholderHits."
    }
    if ($failures.Count -gt 0) {
        Write-Host "Research quality gate self-test failed:"
        foreach ($failure in $failures) {
            Write-Host " - $failure"
        }
        exit 1
    }
    Write-Host "Research quality gate self-test passed."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    throw "ProjectPath is required unless -SelfTest is used."
}

$root = (Resolve-Path -LiteralPath $ProjectPath).Path

$chaptersPath = Join-Path $root "chapters"
if (-not (Test-Path -LiteralPath $chaptersPath)) {
    Add-Failure "Missing chapters directory: $chaptersPath"
}

$chapterSpecs = Get-ChapterArchitectureSpecs $root
if ($chapterSpecs.Count -gt 0) {
    if (-not (Test-Path -LiteralPath $chaptersPath)) {
        Add-Failure "Chapter architecture exists but chapters directory is missing."
    } else {
        $expected = @($chapterSpecs | ForEach-Object { $_.Rel })
        $actual = @(Get-ChildItem -LiteralPath $chaptersPath -Filter "*.md" | ForEach-Object { "chapters/$($_.Name)" })

        foreach ($rel in $expected) {
            if ($actual -notcontains $rel) {
                Add-Failure "Chapter architecture requires missing file: $rel"
            }
        }

        foreach ($rel in $actual) {
            if ($expected -notcontains $rel) {
                Add-Failure "Unexpected chapter file not listed in plan/chapter-architecture.md: $rel"
            }
        }

        $provenanceText = Get-TextIfExists (Join-Path $root "plan/chapter-agent-provenance.md")
        foreach ($spec in $chapterSpecs) {
            $filePath = Join-Path $root $spec.Rel
            if (-not (Test-Path -LiteralPath $filePath)) {
                continue
            }

            $text = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
            $charCount = ($text -replace '\s', '').Length
            if ($spec.MinChars -gt 0 -and $charCount -lt $spec.MinChars) {
                Add-Failure "$($spec.Rel) has $charCount non-whitespace characters; required min_chars=$($spec.MinChars)."
            }

            $provenancePattern = "(?m)^.*" + [regex]::Escape($spec.Rel) + ".*status=ACCEPTED.*$"
            if ($spec.AgentRequired -and ([string]::IsNullOrWhiteSpace($provenanceText) -or $provenanceText -notmatch $provenancePattern)) {
                Add-Failure "$($spec.Rel) requires an accepted chapter agent provenance entry."
            }

            $isReferenceLike = $spec.Rel -match 'References|Bibliography'
            $isAbstractLike = $spec.Rel -match 'Abstract'
            $listLines = Count-Regex $text $listPattern
            if (-not $isReferenceLike -and $listLines -gt 3) {
                Add-Failure "$($spec.Rel) has $listLines list-like line/s; full-paper chapters must be prose-led."
            }

            $paragraphCount = Get-ProseParagraphCount $text
            if (-not $isReferenceLike -and -not $isAbstractLike -and $paragraphCount -lt 6) {
                Add-Failure "$($spec.Rel) has only $paragraphCount substantial prose paragraph/s."
            }

            $placeholderHitsInFile = Count-Regex $text $placeholderPattern
            if (-not $spec.PlaceholdersAllowed -and $placeholderHitsInFile -gt 0) {
                Add-Failure "$($spec.Rel) contains unresolved placeholder/s but chapter architecture sets placeholders=no."
            }
        }
    }
}

$allChapterText = ""
$allProjectText = ""
$allNonChapterText = ""
if (Test-Path -LiteralPath $chaptersPath) {
    foreach ($file in Get-ChildItem -LiteralPath $chaptersPath -Filter "*.md") {
        $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $allChapterText += "`n" + $text
        $allProjectText += "`n" + $text

        $processHits = Count-Regex $text $processPattern
        if ($processHits -gt 0) {
            Add-Failure "$($file.Name) contains process/user-instruction language ($processHits hit/s)."
        }

        $listLines = Count-Regex $text $listPattern
        if ($listLines -gt 12) {
            Add-Warning "$($file.Name) has many list lines ($listLines); verify this is not report-style prose."
        }
    }
}

foreach ($dir in @("tables", "figures", "plan")) {
    $path = Join-Path $root $dir
    if (Test-Path -LiteralPath $path) {
        foreach ($file in Get-ChildItem -LiteralPath $path -Recurse -File -Include "*.md", "*.csv", "*.json") {
            $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
            $allProjectText += "`n" + $text
            $allNonChapterText += "`n" + $text
        }
    }
}

foreach ($rel in $introFiles) {
    $text = Get-TextIfExists (Join-Path $root $rel)
    if ($null -ne $text) {
        $count = Count-Regex $text $citationPattern
        if ($count -lt 5) {
            Add-Failure "$rel has only $count citation-like marker/s; Introduction requires literature-grounded claims."
        }
    }
}

foreach ($rel in $relatedFiles) {
    $text = Get-TextIfExists (Join-Path $root $rel)
    if ($null -ne $text) {
        $count = Count-Regex $text $citationPattern
        if ($count -lt 8) {
            Add-Failure "$rel has only $count citation-like marker/s; Related Work requires evidence synthesis."
        }
    }
}

$evidenceMapExists =
    (Test-Path -LiteralPath (Join-Path $root "refs/evidence-map.md")) -or
    (Test-Path -LiteralPath (Join-Path $root "plan/evidence-map.md"))
if (-not $evidenceMapExists) {
    Add-Failure "Missing evidence map: expected refs/evidence-map.md or plan/evidence-map.md."
}

$referenceChapterFiles = @(Get-ReferenceChapterFiles $chaptersPath)
if ((Test-Path -LiteralPath $chaptersPath) -and $referenceChapterFiles.Count -eq 0) {
    Add-Failure "Missing final independent references/notes chapter: expected chapters/*references*.md, *bibliography*.md, or a chapter headed References/Notes."
}

$ledgerPath = Get-CitationLedgerPath $root
$ledgerRows = @()
if ($null -eq $ledgerPath) {
    Add-Failure "Missing citation verification ledger: expected refs/citation-verification.csv."
} else {
    if ([IO.Path]::GetFileName($ledgerPath) -eq "reference-verification.csv") {
        Add-Warning "Using legacy citation ledger refs/reference-verification.csv; new projects should use refs/citation-verification.csv."
    }

    $ledgerHeaders = @()
    $firstLedgerLine = Get-Content -LiteralPath $ledgerPath -TotalCount 1 -Encoding UTF8
    if ($null -ne $firstLedgerLine) {
        $ledgerHeaders = @($firstLedgerLine -split "," | ForEach-Object { $_.Trim().Trim([char]0xFEFF).Trim('"') })
    }

    $colRefId = ConvertFrom-Utf8Base64 "5byV55So57yW5Y+3"
    $colCitation = ConvertFrom-Utf8Base64 "5byV55So5p2l5rqQ"
    $colLocation = ConvertFrom-Utf8Base64 "6K665paH5byV55So5L2N572u"
    $colManual = ConvertFrom-Utf8Base64 "5piv5ZCm5Lq65bel5qCh6aqM"
    $colStatus = ConvertFrom-Utf8Base64 "5qCh6aqM54q25oCB"
    $colDetail = ConvertFrom-Utf8Base64 "5qCh6aqM5oOF5Ya1"
    $colUserResult = ConvertFrom-Utf8Base64 "55So5oi35qCh6aqM57uT5p6c"
    $colAction = ConvertFrom-Utf8Base64 "5aSE55CG5bu66K6u"
    $colUpdated = ConvertFrom-Utf8Base64 "5pyA5ZCO5pu05paw"
    $yesValue = ConvertFrom-Utf8Base64 "5piv"
    $doneValue = ConvertFrom-Utf8Base64 "5bey"
    $manualCheckedValue = ConvertFrom-Utf8Base64 "5bey5Lq65bel5qCh6aqM"
    $manualPassedValue = ConvertFrom-Utf8Base64 "5Lq65bel6YCa6L+H"
    $passedValue = ConvertFrom-Utf8Base64 "6YCa6L+H"
    $notFilledValue = ConvertFrom-Utf8Base64 "5pyq5aGr5YaZ"
    $noneValue = ConvertFrom-Utf8Base64 "5peg"

    $chineseLedgerColumns = @(
        $colRefId,
        $colCitation,
        $colLocation,
        $colManual,
        $colStatus,
        $colDetail,
        $colUserResult,
        $colAction,
        $colUpdated
    )
    $legacyLedgerColumns = @(
        "ref_id",
        "citation_text",
        "source_type",
        "source_url_or_doi",
        "citation_locations",
        "machine_verification_status",
        "machine_verification_method",
        "machine_verification_date",
        "manual_verification_status",
        "manual_verification_by",
        "manual_verification_date",
        "verification_notes",
        "action_if_invalid"
    )

    $usesChineseLedger = Test-HasColumns $ledgerHeaders $chineseLedgerColumns
    $usesLegacyLedger = Test-HasColumns $ledgerHeaders $legacyLedgerColumns
    if (-not $usesChineseLedger) {
        if ($usesLegacyLedger) {
            Add-Warning ("Citation ledger uses legacy English headers; new projects should use: " + ($chineseLedgerColumns -join ","))
        } else {
            foreach ($column in $chineseLedgerColumns) {
                if ($ledgerHeaders -notcontains $column) {
                    Add-Failure "Citation ledger missing required column: $column"
                }
            }
        }
    }

    try {
        $ledgerRows = @(Import-Csv -LiteralPath $ledgerPath -Encoding UTF8)
    } catch {
        Add-Failure "Citation ledger could not be parsed as UTF-8 CSV: $ledgerPath"
    }

    foreach ($row in $ledgerRows) {
        $refId = Get-CsvValue $row @($colRefId, "ref_id")
        $citationText = Get-CsvValue $row @($colCitation, "citation_text")
        $citationLocations = Get-CsvValue $row @($colLocation, "citation_locations")
        $manualStatus = Get-CsvValue $row @($colManual, "manual_verification_status")
        $manualBy = Get-CsvValue $row @("manual_verification_by")
        $userResult = Get-CsvValue $row @($colUserResult, "manual_verification_status")
        $rowText = @(
            (Get-CsvValue $row @($colStatus, "machine_verification_status")),
            (Get-CsvValue $row @($colDetail, "machine_verification_method", "verification_notes")),
            $manualStatus,
            $userResult
        ) -join " "

        if ([string]::IsNullOrWhiteSpace($refId)) {
            Add-Failure "Citation ledger contains a row without citation id."
        }
        if ([string]::IsNullOrWhiteSpace($citationText)) {
            Add-Failure "Citation ledger row $refId lacks citation source."
        }
        if ([string]::IsNullOrWhiteSpace($citationLocations)) {
            Add-Failure "Citation ledger row $refId lacks citation location."
        }

        $manualStatusTrim = $manualStatus.Trim()
        $manualPositiveValues = @($yesValue, $doneValue, $manualCheckedValue, $manualPassedValue, $passedValue, "yes", "true")
        if (($manualPositiveValues -contains $manualStatusTrim) -or $manualStatusTrim -match '(?i)^(manual.*verified|verified|pass)$') {
            if ($usesChineseLedger) {
                $userResultTrim = $userResult.Trim()
                if ([string]::IsNullOrWhiteSpace($userResult) -or (@($notFilledValue, $noneValue, "none", "n/a") -contains $userResultTrim)) {
                    Add-Failure "Citation ledger row $refId marks manual verification as completed but lacks a user verification result."
                }
                if ($userResult -match '(?i)\b(ai|assistant|codex|chatgpt|model)\b') {
                    Add-Failure "Citation ledger row $refId appears to mark AI-side checking as a user verification result."
                }
            } elseif ([string]::IsNullOrWhiteSpace($manualBy) -or $manualBy -match '(?i)\b(ai|assistant|codex|chatgpt|model)\b') {
                Add-Failure "Citation ledger row $refId marks manual verification without a valid user/manual verifier."
            }
        }

        if ($rowText -match '(\u865a\u6784|\u4e0d\u5b58\u5728|\u4e0d\u53ef\u7528|\u4e0d\u5339\u914d|invalid|false|fake|unusable)') {
            $stillUsed = $false
            if (-not [string]::IsNullOrWhiteSpace($refId) -and $allChapterText -match [regex]::Escape($refId)) {
                $stillUsed = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($citationText)) {
                $snippet = $citationText.Trim()
                if ($snippet.Length -gt 24) {
                    $snippet = $snippet.Substring(0, 24)
                }
                if ($snippet.Length -gt 6 -and $allChapterText -match [regex]::Escape($snippet)) {
                    $stillUsed = $true
                }
            }
            if ($stillUsed) {
                Add-Failure "Citation ledger row $refId is marked invalid/unusable but still appears in chapters."
            }
        }
    }
}

if ($referenceChapterFiles.Count -gt 0) {
    $referenceText = ""
    $referenceFileNames = @($referenceChapterFiles | ForEach-Object { $_.FullName })
    foreach ($file in $referenceChapterFiles) {
        $referenceText += "`n" + (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    }

    $referenceNumbers = @([regex]::Matches($referenceText, '(?m)^\s*\[(\d+)\]') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    $bodyTextForCitationCheck = ""
    if (Test-Path -LiteralPath $chaptersPath) {
        foreach ($file in Get-ChildItem -LiteralPath $chaptersPath -Filter "*.md") {
            if ($referenceFileNames -contains $file.FullName) {
                continue
            }
            $bodyTextForCitationCheck += "`n" + (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
        }
    }

    $bodyCitationNumbers = @([regex]::Matches($bodyTextForCitationCheck, '\[(\d+)\]') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    foreach ($number in $bodyCitationNumbers) {
        if ($referenceNumbers.Count -gt 0 -and $referenceNumbers -notcontains $number) {
            Add-Failure "Body citation [$number] is missing from the final references/notes chapter."
        }
    }

    if ($referenceNumbers.Count -gt 0 -and $ledgerRows.Count -lt $referenceNumbers.Count) {
        Add-Failure "Citation ledger has $($ledgerRows.Count) row/s but final references chapter has $($referenceNumbers.Count) numbered reference/s."
    }
    if ($bodyCitationNumbers.Count -gt 0 -and $ledgerRows.Count -lt $bodyCitationNumbers.Count) {
        Add-Failure "Citation ledger has fewer rows than distinct numbered body citations."
    }
}

$hasResults = $false
if (Test-Path -LiteralPath $chaptersPath) {
    $hasResults = $null -ne (Get-ChildItem -LiteralPath $chaptersPath -Filter "*.md" | Where-Object { $_.Name -match "Results|results|06_" })
}
if ($hasResults) {
    $requiredResultArtifacts = @(
        "plan/experiment-protocol.md",
        "plan/review/method-experiment-traceability.md",
        "tables/table-schema.md",
        "figures/data-manifest.md"
    )
    foreach ($artifact in $requiredResultArtifacts) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $artifact))) {
            Add-Failure "Results section exists but $artifact is missing."
        }
    }

    $overclaimHits = Count-Regex $allChapterText $resultOverclaimPattern
    if ($overclaimHits -gt 0 -and (Count-Regex $allProjectText 'mock_|synthetic_|PLANNING DATA') -gt 0) {
        Add-Failure "Results text contains real-result language while mock/synthetic planning data is present."
    }
}

$mockFiles = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(mock_|synthetic_)' }
foreach ($mockFile in $mockFiles) {
    $mockText = Get-Content -LiteralPath $mockFile.FullName -Raw -Encoding UTF8
    if ($mockText -notmatch 'PLANNING DATA - replace before submission') {
        Add-Failure "Mock/synthetic file lacks required planning-data marker: $($mockFile.FullName)"
    }
}

$chapterPlaceholders = Count-Regex $allChapterText $placeholderPattern
$nonChapterPlaceholders = Count-Regex $allNonChapterText $placeholderPattern
$placeholders = $chapterPlaceholders + $nonChapterPlaceholders
if ($placeholders -gt 0) {
    if ($Submission) {
        Add-Failure "Submission mode forbids unresolved placeholders; found $placeholders."
    } else {
        if ($chapterPlaceholders -gt 0) {
            Add-Warning "Chapter drafts contain $chapterPlaceholders unresolved placeholder/s."
        }
        if ($nonChapterPlaceholders -gt 0) {
            Add-Warning "Planning artifacts contain $nonChapterPlaceholders placeholder/s."
        }
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:"
    foreach ($warning in $warnings) {
        Write-Host " - $warning"
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Research quality gate failed:"
    foreach ($failure in $failures) {
        Write-Host " - $failure"
    }
    exit 1
}

Write-Host "Research quality gate passed."
