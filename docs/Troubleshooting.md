# Troubleshooting

Common issues encountered when extracting legacy Monitor WA ID Capture records and photographs.

## Microsoft ACE OLEDB provider not registered

### Symptoms

PowerShell reports:

`The Microsoft.ACE.OLEDB.16.0 provider is not registered on the local machine.`

### Resolution

Confirm that Microsoft ACE OLEDB 16.0 is installed.

Ensure the provider architecture matches the PowerShell process.

A 32-bit provider cannot be loaded by a 64-bit PowerShell process.

## Cannot connect to database

### Possible causes

- Incorrect MDB path
- Insufficient file permissions
- Missing ACE provider
- Database corruption
- Database locking
- Password-protected database

### Resolution

Verify the database path and permissions.

Work from a backup if the original database is in use.

Do not modify the original database.

## Unexpected student information

### Symptoms

Names, addresses or other values appear in incorrect CSV columns.

### Cause

Legacy ID Capture installations may use generic database fields differently.

### Resolution

Inspect the database structure and application configuration.

Verify the mappings before importing into another system.

The supplied field mappings are not guaranteed to apply universally.

## Invalid date of birth

### Symptoms

The database export reports validation errors.

### Cause

The script expects Australian day-first dates.

Supported examples:

```text
1/02/2010
01/02/2010
```

### Resolution

Inspect the original date format.

Do not change the parser without confirming how the source application stores dates.

## Duplicate student identifiers

### Symptoms

The export reports duplicate student identifier groups.

### Cause

Multiple records share the same student identifier.

### Resolution

Investigate the records in the original application.

The export script preserves duplicates.

A replacement system may require unique identifiers.

## No photographs found

### Possible causes

- Incorrect photograph directory
- Unsupported file extensions
- Photographs stored in subdirectories
- Different photograph naming conventions

### Resolution

Confirm the photograph location and file extensions.

The script searches only the top level of the specified directory.

## Students without photographs

### Cause

No photograph filename exactly matches the student's identifier, or a matching file could not be copied.

### Resolution

Review `Missing_Photos.csv`.

Check for:

- Different student identifiers
- Historical photographs
- Alternative filename conventions
- Unsupported image formats
- Photographs stored elsewhere

## Output directory is not empty

### Cause

The photograph script refuses to copy into a populated directory.

### Resolution

Use a new output directory.

Alternatively, securely relocate the existing export before running the script again.

This behaviour prevents accidental overwriting.

## CSV already exists

### Cause

The database export script refuses to overwrite an existing CSV.

### Resolution

Specify a new destination filename or securely relocate the previous export.

## Public repository security

Never publish:

- Student databases
- Student CSV exports
- Student photographs
- Credentials
- Personal information
- Screenshots containing identifiable student records

Use synthetic examples when reporting issues.
