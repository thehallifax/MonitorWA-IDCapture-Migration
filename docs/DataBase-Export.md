# Legacy ID Capture Database Export

## Overview

This guide explains how to extract historical student records from a legacy Monitor WA ID Capture Microsoft Access database.

The process is read-only and does not modify the source database.

## Prerequisites

- Windows PowerShell 5.1
- Microsoft ACE OLEDB 16.0
- Read access to the legacy MDB database
- Write access to an export directory

## 1. Locate the database

Locate the legacy database, typically named:

`IDCapture.mdb`

Back up the database before proceeding.

## 2. Confirm the ACE provider

Run the following in Windows PowerShell:

```powershell
[System.Data.OleDb.OleDbEnumerator]::GetRootEnumerator() |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_["SOURCES_NAME"]
            Description = $_["SOURCES_DESCRIPTION"]
        }
    } |
    Where-Object Name -like "*ACE*"
```

Confirm that `Microsoft.ACE.OLEDB.16.0` is available.

If it is missing, install the appropriate Microsoft Access Database Engine components.

The provider architecture must match the PowerShell process.

## 3. Understand the database structure

The legacy installation used during development contained a `Details` table.

Student information was stored in generic fields.

| Database field | Exported field |
|---|---|
| Field1 | externalID |
| Field2 | firstNames |
| Field3 | lastName |
| Field4 | dob (YYYY-MM-DD) |
| Field5 | street |
| Field6 | suburb |
| State | state |
| Field7 | postcode |

Additional destination fields are exported as blank.

These mappings are installation-specific and must be verified.

## 4. Execute the export

```powershell
.\scripts\Export-IDCaptureDatabase.ps1 `
    -MdbPath "D:\Legacy\IDCapture.mdb" `
    -CsvPath "D:\Export\Students.csv"
```

The output directory must already exist.

The script refuses to overwrite an existing CSV.

## 5. Validation

The script checks:

- Total records extracted
- Missing student identifiers
- Invalid dates of birth
- Duplicate student identifier groups
- Exported CSV record count

If validation errors are detected, the export is cancelled.

Duplicate identifiers are reported but retained.

## 6. Date conversion

Australian day-first dates are converted into ISO 8601 format.

Example:

`15/08/2012`

Becomes:

`2012-08-15`

The script supports one-digit or two-digit days and months with a four-digit year.

## 7. Verify the CSV

Before importing into another system:

1. Confirm the record count.
2. Review duplicate identifiers.
3. Verify field mappings.
4. Check dates of birth.
5. Confirm the destination application's required CSV structure.

## Security

The exported CSV may contain personal student information.

Store it securely and do not commit it to a public repository.
