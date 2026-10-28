# Legacy ID Capture Photograph Extraction

## Overview

This guide explains how to identify and extract student photographs from a legacy Monitor WA ID Capture installation.

The process uses student identifiers exported from the legacy database.

Original photographs are preserved.

## Prerequisites

- Windows PowerShell 5.1
- CSV containing an `externalID` column
- Read access to the photograph directory
- Write access to an export directory

## 1. Understand photograph naming

In the installation used during development, photographs were named using student identifiers.

Example:

```text
123456.jpg
123457.jpg
123458.jpg
```

The filename without its extension corresponds to the student's `externalID`.

Other installations may use different naming conventions.

## 2. Run the extraction

```powershell
.\scripts\Export-IDCapturePhotos.ps1 `
    -CsvPath "D:\Export\Students.csv" `
    -PhotoPath "D:\Legacy\Photographs" `
    -OutputPath "D:\Export\SelectedPhotos"
```

The script automatically creates the destination directory if required.

If the destination already exists, it must be empty.

## 3. Supported formats

The script supports:

- JPG
- JPEG
- PNG
- BMP

The script searches only the top level of the photograph directory.

Subdirectories are not searched.

## 4. Photograph matching

Matching uses the complete filename without the extension.

Example:

```text
Student ID: 123456
Photograph: 123456.jpg
```

This is a match.

However:

```text
123456_old.jpg
```

is not an exact match.

Multiple supported photographs with the same filename stem but different extensions may be copied.

## 5. Missing photograph report

The script generates:

`Missing_Photos.csv`

This contains student identifiers for which no matching photograph was successfully copied.

The report is stored in the output directory.

Move or remove the report before uploading photographs to a replacement application.

## 6. Results

The script reports:

- Student records processed
- Unique student identifiers
- Photographs scanned
- Photographs copied
- Students without photographs
- Copy errors

## 7. Validation

Before importing photographs:

1. Confirm the number of files copied.
2. Review missing photographs.
3. Verify that filenames match student identifiers.
4. Spot-check photographs against student records.
5. Confirm the destination application's naming requirements.

## Security

Student photographs are sensitive personal information.

Store extracted photographs securely.

Do not upload photographs to public repositories or issue reports.
