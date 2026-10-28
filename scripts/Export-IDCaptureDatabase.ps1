#requires -Version 5.1

<#
.SYNOPSIS
    Export student records from a legacy Monitor WA ID Capture database.

.DESCRIPTION
    Connects to a Microsoft Access MDB database using the
    Microsoft ACE OLEDB provider.

    Extracts student records from the Details table and exports
    them into a CSV suitable for migration.

    Features:
    - Read-only database access
    - Australian date conversion to YYYY-MM-DD
    - Duplicate student ID detection
    - Record validation
    - CSV export verification
    - Configurable file paths

.NOTES
    Unofficial community migration tool.

    Database field mappings were established against one legacy
    ID Capture installation and should be verified before use.

    Requires Windows PowerShell 5.1 and Microsoft ACE OLEDB 16.0.

.EXAMPLE
    .\Export-IDCaptureDatabase.ps1 `
        -MdbPath "D:\Legacy\IDCapture.mdb" `
        -CsvPath "D:\Export\Students.csv"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MdbPath,

    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Validate paths
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $MdbPath -PathType Leaf)) {
    throw "Database not found: $MdbPath"
}

if (Test-Path -LiteralPath $CsvPath) {
    throw "Output CSV already exists. Refusing to overwrite: $CsvPath"
}

$OutputDirectory = Split-Path -Parent $CsvPath

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Output directory does not exist: $OutputDirectory"
}

# ------------------------------------------------------------
# Connect to database
# ------------------------------------------------------------

$ConnectionString = "Provider=Microsoft.ACE.OLEDB.16.0;Data Source=$MdbPath;Mode=Read;"

$Connection = New-Object System.Data.OleDb.OleDbConnection($ConnectionString)

$Records = New-Object 'System.Collections.Generic.List[object]'
$ValidationErrors = New-Object 'System.Collections.Generic.List[string]'

try {

    $Connection.Open()

    Write-Host "Connected to ID Capture database." -ForegroundColor Green

    $Command = $Connection.CreateCommand()

    try {

        $Command.CommandText = @"
SELECT
    RecordNo,
    Field1,
    Field2,
    Field3,
    Field4,
    Field5,
    Field6,
    [State],
    Field7
FROM Details
ORDER BY RecordNo
"@

        $Reader = $Command.ExecuteReader()

        try {

            while ($Reader.Read()) {

                $Row = @{}

                for ($i = 0; $i -lt $Reader.FieldCount; $i++) {

                    $ColumnName = $Reader.GetName($i)

                    if ($Reader.IsDBNull($i)) {
                        $Row[$ColumnName] = ""
                    }
                    else {
                        $Row[$ColumnName] = [string]$Reader.GetValue($i)
                    }
                }

                $RecordNumber = $Row["RecordNo"]

                # Student identifier
                $StudentID = $Row["Field1"].Trim()

                if ([string]::IsNullOrWhiteSpace($StudentID)) {
                    $ValidationErrors.Add(
                        "Record $RecordNumber has no student identifier."
                    )
                }

                # Australian DOB conversion
                $RawDOB = $Row["Field4"].Trim()

                $ParsedDate = [datetime]::MinValue

                $DateValid = [datetime]::TryParseExact(
                    $RawDOB,
                    [string[]]@(
                        "d/M/yyyy",
                        "dd/MM/yyyy"
                    ),
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$ParsedDate
                )

                if (-not $DateValid) {

                    $ValidationErrors.Add(
                        "Record $RecordNumber contains an invalid DOB."
                    )

                    $FormattedDOB = ""
                }
                else {

                    $FormattedDOB = $ParsedDate.ToString("yyyy-MM-dd")
                }

                # Build destination CSV record
                $Record = [PSCustomObject][ordered]@{

                    externalID = $StudentID

                    firstNames = $Row["Field2"]

                    lastName = $Row["Field3"]

                    'dob (YYYY-MM-DD)' = $FormattedDOB

                    street = $Row["Field5"]

                    suburb = $Row["Field6"]

                    state = $Row["State"]

                    postcode = $Row["Field7"]

                    curriculum = ""

                    custom1 = ""

                    custom2 = ""

                    custom3 = ""

                    yearGroup = ""
                }

                $Records.Add($Record)
            }
        }
        finally {

            $Reader.Close()
            $Reader.Dispose()
        }
    }
    finally {

        $Command.Dispose()
    }
}
finally {

    $Connection.Close()
    $Connection.Dispose()
}

# ------------------------------------------------------------
# Validate extracted records
# ------------------------------------------------------------

$DuplicateGroups = @(
    $Records |
        Where-Object { $_.externalID } |
        Group-Object externalID |
        Where-Object { $_.Count -gt 1 }
)

Write-Host ""
Write-Host "========== EXPORT VALIDATION ==========" -ForegroundColor Cyan

Write-Host "Records extracted: $($Records.Count)"
Write-Host "Validation errors: $($ValidationErrors.Count)"
Write-Host "Duplicate student ID groups: $($DuplicateGroups.Count)"

if ($DuplicateGroups.Count -gt 0) {

    Write-Warning "Duplicate student identifiers detected."
    Write-Warning "Duplicate records have been retained."
}

if ($ValidationErrors.Count -gt 0) {

    foreach ($ErrorMessage in ($ValidationErrors | Select-Object -First 20)) {

        Write-Warning $ErrorMessage
    }

    throw "Export cancelled because validation errors were detected."
}

if ($Records.Count -eq 0) {

    throw "No student records were found."
}

# ------------------------------------------------------------
# Export CSV
# ------------------------------------------------------------

$Records |
    Export-Csv `
        -LiteralPath $CsvPath `
        -NoTypeInformation `
        -Encoding UTF8

# ------------------------------------------------------------
# Verify export
# ------------------------------------------------------------

$ExportedRecords = @(Import-Csv -LiteralPath $CsvPath)

if ($ExportedRecords.Count -ne $Records.Count) {

    throw "CSV verification failed. Record counts do not match."
}

Write-Host ""
Write-Host "CSV successfully created." -ForegroundColor Green

Write-Host "Location: $CsvPath"
Write-Host "Records exported: $($ExportedRecords.Count)"
Write-Host "DOB format: YYYY-MM-DD"
Write-Host "Source database: Unmodified"

Write-Host ""
Write-Host "========== COMPLETE ==========" -ForegroundColor Green
