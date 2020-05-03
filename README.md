# Purpose
This repo is a collection of PowerShell Scripts to aid with a File Server Migration.

Currently there are 3 Scripts.

## 1. Copy-Files.ps1
This script is a wrapper for Robocopy with some sane switches already configured. The script
requires a source path and a destination path and it will then mirror the source path in 
the destination path and copy all NTFS permission along with it.

## 2. Build-Csv.ps1
This script is a co-hort for the 3rd script (Acl-Check.ps1). It generates a CSV file that can then be used
as an input for Acl-Check.ps1. It requires a source and destination path (same as used for the 1st script) 
and an optional -outfile parameter (which by default is set to acl-check-input.csv in the current directory)

## 3. Acl-Check.ps1
This script checks if the ACL's on the destination files/directories are the same as the source.
The script requires a -CsvPath parameter which is the path the CSV file generated by the second script.
There are 2 optional parameters:
1. -ResultFile is a path that will be used to create a CSV file if there are any exceptions (i.e. Files
with non matching ACLs or missing files). This defaults to acl-check-exceptions.csv in the current directory.
2. -SampleSize is the number of files in the total set for which ACLs should be checked. The script will randomise
entries from the total number of entries in the input CSV file. This could be useful if you do a migration with
millions of files and you do not want to wait the time it takes to have all of them checked but still get a good
sample of the fidelity of the migrated files.


