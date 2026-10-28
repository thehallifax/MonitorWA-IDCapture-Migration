#requires -Version 5.1

<#
.SYNOPSIS
    Extract matching student photographs from a legacy
    Monitor WA ID Capture photograph directory.

.DESCRIPTION
    Reads a CSV containing student identifiers in an externalID
    column and copies matching photographs to a separate directory.

    Photographs are matched using their filename without extension.

    Features:
    - Exact student ID matching
    - Supports JPG, JPEG, PNG and BMP
    - Non-destructive copying
    - Duplicate student ID handling
    - Missing photograph reporting
    - Copy error reporting
    - Configurable paths

.NOTES
    Unofficial community migration tool.

    The script searches the top level of the photograph directory.
    It does not recursively search subdirectories.

    Requires Windows PowerShell 5.1.

.EXAMPLE
    .\Export-IDCapturePhotos.ps1 `
        -CsvPath "D:\Export\Students.csv" `
        -PhotoPath "D:\Legacy\Photographs" `
        -OutputPath "D:\Export\SelectedPhotos"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [string]$PhotoPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Validate paths
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) {
    throw "CSV not found: $CsvPath"
}

if (-not (Test-Path -LiteralPath $PhotoPath -PathType Container)) {
    throw "Photograph directory not found: $PhotoPath"
}

$SourceDirectory = (Resolve-Path -LiteralPath $PhotoPath).Path.TrimEnd("\")

$DestinationDirectory = [System.IO.Path]::GetFullPath(
    $OutputPath
).TrimEnd("\")

if ($SourceDirectory -eq $DestinationDirectory) {
    throw "The output directory cannot be the source directory."
}

# Create or validate output directory

if (Test-Path -LiteralPath $OutputPath) {

    $ExistingFiles = @(
        Get-ChildItem -LiteralPath $OutputPath -Force
    )

    if ($ExistingFiles.Count -gt 0) {
        throw "Output directory must be empty to prevent overwriting files."
    }
}
else {

    New-Item `
        -ItemType Directory `
        -Path $OutputPath `
        -Force | Out-Null
}

# ------------------------------------------------------------
# Import student records
# ------------------------------------------------------------

$Students = @(
    Import-Csv -LiteralPath $CsvPath
)

if ($Students.Count -eq 0) {
    throw "The student CSV contains no records."
}

if (-not ($Students[0].PSObject.Properties.Name -contains "externalID")) {
    throw "The CSV must contain an externalID column."
}

# ------------------------------------------------------------
# Build unique student ID lookup
# ------------------------------------------------------------

$StudentIDs = @{}

foreach ($Student in $Students) {

    $ID = ([string]$Student.externalID).Trim()

    if (-not [string]::IsNullOrWhiteSpace($ID)) {

        $StudentIDs[$ID] = $true
    }
}

Write-Host ""
Write-Host "Student records loaded: $($Students.Count)"
Write-Host "Unique student IDs: $($StudentIDs.Count)"

# ------------------------------------------------------------
# Discover photographs
# ------------------------------------------------------------

$SupportedExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".bmp"
)

$Photographs = @(
    Get-ChildItem -LiteralPath $PhotoPath -File |
        Where-Object {
            $_.Extension.ToLowerInvariant() -in $SupportedExtensions
        }
)

Write-Host "Photographs found: $($Photographs.Count)"

# ------------------------------------------------------------
# Extract matching photographs
# ------------------------------------------------------------

$MatchedIDs = @{}

$Copied = 0
$CopyErrors = 0

foreach ($Photograph in $Photographs) {

    $PhotoID = $Photograph.BaseName.Trim()

    if ($StudentIDs.ContainsKey($PhotoID)) {

        $Destination = Join-Path `
            -Path $OutputPath `
            -ChildPath $Photograph.Name

        try {

            Copy-Item `
                -LiteralPath $Photograph.FullName `
                -Destination $Destination `
                -ErrorAction Stop

            $MatchedIDs[$PhotoID] = $true

            $Copied++
        }
        catch {

            $CopyErrors++

            Write-Warning "Failed to copy photograph: $($Photograph.Name)"
        }
    }
}

# ------------------------------------------------------------
# Identify missing photographs
# ------------------------------------------------------------

$Missing = @(
    foreach ($ID in ($StudentIDs.Keys | Sort-Object)) {

        if (-not $MatchedIDs.ContainsKey($ID)) {

            [PSCustomObject]@{
                externalID = $ID
            }
        }
    }
)

# ------------------------------------------------------------
# Export missing photograph report
# ------------------------------------------------------------

$MissingPath = Join-Path `
    -Path $OutputPath `
    -ChildPath "Missing_Photos.csv"

if ($Missing.Count -gt 0) {

    $Missing |
        Export-Csv `
            -LiteralPath $MissingPath `
            -NoTypeInformation `
            -Encoding UTF8
}
else {

    "externalID" |
        Set-Content `
            -LiteralPath $MissingPath `
            -Encoding UTF8
}

# ------------------------------------------------------------
# Results
# ------------------------------------------------------------

Write-Host ""
Write-Host "========== PHOTO EXTRACTION ==========" -ForegroundColor Cyan

Write-Host "Student records: $($Students.Count)"
Write-Host "Unique student IDs: $($StudentIDs.Count)"
Write-Host "Photographs scanned: $($Photographs.Count)"
Write-Host "Photographs copied: $Copied"
Write-Host "Students without photos: $($Missing.Count)"
Write-Host "Copy errors: $CopyErrors"

Write-Host ""
Write-Host "Output folder: $OutputPath"
Write-Host "Missing photo report: $MissingPath"

Write-Host ""
Write-Host "======================================"

if ($CopyErrors -gt 0) {

    throw "Some photograph copies failed. Review the warnings."
}

Write-Host "Photograph extraction complete." -ForegroundColor Green
