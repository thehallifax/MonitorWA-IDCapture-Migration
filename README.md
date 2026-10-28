# Monitor WA ID Capture — Legacy Database Migration Toolkit

Unofficial PowerShell tools for exporting historical student records and photographs from legacy Monitor WA ID Capture installations.

Designed for IT administrators migrating away from older ID Capture systems, recovering historical records, or consolidating student photographs.

> **Disclaimer:** This is an independent, community-maintained project. It is not affiliated with, endorsed by, or supported by Monitor WA. Database structures and field mappings may differ between installations.

## Overview

Legacy Monitor WA ID Capture installations may store student information in a Microsoft Access database (`IDCapture.mdb`), with photographs maintained separately.

This toolkit provides two PowerShell scripts:

| Script | Purpose |
|---|---|
| `Export-IDCaptureDatabase.ps1` | Extract student records from the legacy Access database into CSV |
| `Export-IDCapturePhotos.ps1` | Identify and copy photographs matching exported student identifiers |

Both scripts are designed to preserve the original source data.

## Features

### Database export

- Connects to legacy Microsoft Access MDB databases.
- Uses Microsoft ACE OLEDB 16.0.
- Extracts records from the `Details` table.
- Converts Australian date formats to ISO 8601 (`YYYY-MM-DD`).
- Detects duplicate student identifiers.
- Validates student identifiers and dates.
- Verifies the exported CSV record count.
- Preserves duplicate records for manual review.
- Does not modify the source database.

### Photograph extraction

- Matches photograph filenames against exported student identifiers.
- Supports JPG, JPEG, PNG and BMP.
- Copies matching photographs to a separate directory.
- Preserves original photographs.
- Generates a report identifying students without photographs.
- Prevents overwriting files in an existing populated destination directory.

## Requirements

### Operating system

Windows with Windows PowerShell 5.1.

The scripts were developed against a legacy Windows Server installation.

### Database provider

Microsoft ACE OLEDB 16.0 must be installed and available to PowerShell.

The provider architecture must match the PowerShell process architecture.

### Access permissions

The account executing the scripts requires:

- Read access to the legacy MDB database.
- Read access to the photograph directory.
- Write access to the export destination.

Administrative privileges are not inherently required.

## Repository structure

```text
MonitorWA-IDCapture-Migration/
│
├── README.md
│
├── scripts/
│   ├── Export-IDCaptureDatabase.ps1
│   └── Export-IDCapturePhotos.ps1
│
├── docs/
│   ├── Database-Export.md
│   ├── Photo-Export.md
│   └── Troubleshooting.md
│
├── LICENSE
└── .gitignore
```

## 1. Locate the legacy database

Identify the location of the ID Capture database.

In the installation used to develop this toolkit, the database was named:

```text
IDCapture.mdb
```

The database was located within the application's photograph directory.

Other installations may use different locations.

Back up the database before proceeding.

## 2. Export student records

Open Windows PowerShell 5.1.

Navigate to the directory containing the scripts.

Run:

```powershell
.\scripts\Export-IDCaptureDatabase.ps1 `
    -MdbPath "D:\Legacy\IDCapture.mdb" `
    -CsvPath "D:\Export\Students.csv"
```

The destination directory must already exist.

The script will:

1. Connect to the Access database.
2. Read records from the `Details` table.
3. Convert date-of-birth values.
4. Validate student identifiers.
5. Identify duplicate identifiers.
6. Export the records to CSV.
7. Verify the exported record count.

The original database is not modified.

### Exported CSV fields

| CSV field | Legacy database field |
|---|---|
| externalID | Field1 |
| firstNames | Field2 |
| lastName | Field3 |
| dob (YYYY-MM-DD) | Field4 |
| street | Field5 |
| suburb | Field6 |
| state | State |
| postcode | Field7 |
| curriculum | Blank |
| custom1 | Blank |
| custom2 | Blank |
| custom3 | Blank |
| yearGroup | Blank |

**Important:** These mappings were established from one legacy installation.

ID Capture uses generic database field names, so administrators must verify mappings against their own database and application configuration.

Do not assume these mappings are universal.

### Date conversion

The script accepts Australian day-first dates such as:

```text
1/02/2010
01/02/2010
```

Both are exported as:

```text
2010-02-01
```

Records containing invalid or unexpected date formats cause the export to stop.

## 3. Extract student photographs

Once the CSV has been generated, run:

```powershell
.\scripts\Export-IDCapturePhotos.ps1 `
    -CsvPath "D:\Export\Students.csv" `
    -PhotoPath "D:\Legacy\Photographs" `
    -OutputPath "D:\Export\SelectedPhotos"
```

The script reads student identifiers from the CSV.

It then searches the photograph directory for files whose names match those identifiers.

For example:

```text
Student identifier: 123456

Matching photographs:

123456.jpg
123456.jpeg
123456.png
```

Matching files are copied to the destination directory.

Original photographs remain untouched.

### Photograph matching behaviour

Matching is based on the complete filename without its extension.

For example:

```text
123456.jpg
```

matches:

```text
externalID = 123456
```

However:

```text
123456_old.jpg
```

does not match.

The script searches only the top level of the photograph directory.

Subdirectories are not searched.

### Missing photographs

The script creates:

```text
Missing_Photos.csv
```

This report contains student identifiers that did not have matching photographs.

The report is saved in the photograph export directory.

Remove or relocate the report before importing the photograph directory into another application.

## 4. Validate the migration

Before importing into a replacement system:

1. Confirm the exported record count.
2. Verify student identifiers against the original application.
3. Verify first names, surnames and dates of birth.
4. Review duplicate student identifiers.
5. Confirm photographs correspond to the correct students.
6. Review the missing-photograph report.
7. Confirm the destination application's required CSV format.

Do not import records until field mappings have been verified.

## Example migration results

During development, the scripts were used to extract records and photographs from a legacy installation.

| Metric | Result |
|---|---:|
| Student records exported | 1,910 |
| Unique student identifiers | 1,908 |
| Duplicate identifier groups | 2 |
| Photographs scanned | 10,265 |
| Photographs copied | 1,853 |
| Students without matching photographs | 55 |
| Photograph copy errors | 0 |

These figures are included to demonstrate the process.

No actual student records, photographs or identifying information are included in this repository.

## Troubleshooting

### Microsoft ACE OLEDB provider not registered

Confirm Microsoft ACE OLEDB 16.0 is installed.

Check that the provider architecture matches the PowerShell process.

### Database cannot be opened

Check:

- File permissions.
- Database location.
- Database locking.
- ACE provider availability.

### Unexpected CSV field values

Verify the legacy application's field configuration.

The database may use generic columns such as `Field1`, `Field2` and `Field3` differently.

### Missing photographs

Check:

- Photograph filename conventions.
- Supported image extensions.
- Whether photographs are stored in subdirectories.
- Whether student identifiers match the filename exactly.

### Duplicate student identifiers

Duplicate records are preserved during export.

Administrators should investigate duplicates before importing into a destination system that requires unique identifiers.

## Security and privacy

Student information is sensitive.

The scripts operate locally and do not transmit data to external services.

Administrators should:

- Restrict access to exported CSV files.
- Secure photograph exports.
- Avoid uploading student information to public repositories.
- Follow applicable privacy and records-management requirements.
- Remove temporary exports when they are no longer required.

Never commit actual MDB databases, student CSV files or photographs to this repository.

## Limitations

- Tested against one legacy ID Capture database structure.
- Field mappings may differ between installations.
- Database export requires Microsoft ACE OLEDB 16.0.
- Photograph extraction is not recursive.
- The scripts do not import data into a replacement application.
- Duplicate student records are reported but not automatically resolved.
- Output CSV compatibility with a destination system must be verified separately.

## Contributions

Contributions, bug reports and improvements are welcome.

If your installation uses a different database structure or field mapping, consider opening an issue documenting the differences.

Do not include real student information in issues or pull requests.

## Licence

Released under the MIT Licence.

## Acknowledgement

Developed following a successful migration of historical student records and photographs from a legacy Monitor WA ID Capture installation.

Published to assist other IT administrators working with poorly documented legacy systems.
