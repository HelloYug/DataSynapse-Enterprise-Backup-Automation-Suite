<#
=========================================================================================
    PROJECT:  DataSynapse Enterprise Backup Automation Suite
=========================================================================================
    PURPOSE:
        This PowerShell script automates the complete backup workflow for 
        BUSY Accounting Software (or similar ERP systems) used across multiple companies.

        It performs the following:
          • Copies company data folders from the BUSY data directory
          • Gathers the latest backup files for each mapped company
          • Creates structured ZIP archives (company data + recent backups)
          • Generates detailed execution logs with summary tables
          • Maintains a 3-run rolling log history for quick reference

    VERSION HISTORY:
        v1.0.0    - Initial release

    AUTHOR:
        Yug Agarwal
        Email: yugagarwal704@gmail.com
        GitHub: https://github.com/helloyug
        Project: DataSynapse Enterprise Backup Automation Suite

    LICENSE:
        MIT License – Feel free to use, modify, and distribute with attribution.

    COMPATIBILITY:
        • Windows 10 or later
        • PowerShell 5.1 or later
        • BUSY Accounting Software (or any folder-based data system)

    USAGE:
        1. Configure the directory paths below in the param() block.
        2. Update the $CompanyMap section with your company codes and names.
        3. Run the script in PowerShell:
              PS> .\DataSynapse-Enterprise-Backup-Automation-Suite.ps1
        4. The script will create ZIP backups and append logs automatically.

=========================================================================================
#>

param (
    # ------------------ CONFIGURABLE PATHS ------------------
    [string]$SourceDir = "D:\Path\To\BUSY Software\DATA",                     # Path to BUSY's company DATA directory
    [string]$BackupBase = "D:\Path\To\BUSY Backups",                          # Root path containing daily backup folders
    [string]$DestDir = "D:\Path\To\Final Zipped Backups",                     # Destination path for ZIP archives
    [string]$LogFile = "D:\Path\To\Final Zipped Backups\BackupLog.txt"        # Log file to store run history
)

# ============================================================
# COMPANY NAME MAPPING
# Maps BUSY internal folder names (e.g., COMP0001) to friendly company names.
# Modify these according to your own BUSY company codes.
# ============================================================
$CompanyMap = @{
    "COMP0001" = "Company A"
    "COMP0002" = "Company B"
    "COMP0003" = "Company C"
    "COMP0004" = "Company D"
    "COMP0005" = "Company E"
}

# ============================================================
# COUNTERS AND INITIALIZATIONS
# ============================================================
$totalCompanies = 0
$dataSuccess = 0
$dataFail = 0
$backupSuccess = 0
$backupFail = 0
$zipSuccess = 0
$zipFail = 0
$summaryList = @()
$runLog = New-Object System.Collections.Generic.List[string]

# ============================================================
# HELPER FUNCTION: Write to in-memory log buffer
# ============================================================
function Write-LogLine {
    param([string]$line)
    $runLog.Add($line)
}

# ============================================================
# SCRIPT START
# ============================================================
$startTime = Get-Date
Write-LogLine "========== Backup Run Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) =========="
Write-LogLine ""

# Ensure destination folder exists
if (-not (Test-Path $DestDir)) { 
    New-Item -ItemType Directory -Path $DestDir | Out-Null 
}

# ============================================================
# MAIN LOOP: Process Each Company Folder in SourceDir
# ============================================================
foreach ($companyFolder in Get-ChildItem -Path $SourceDir -Directory) {
    $totalCompanies++
    $compName = $companyFolder.Name
    $dataStatus = "Skipped"
    $backupStatus = "Skipped"
    $zipStatus = "Skipped"
    $remark = ""
    $latestFileDate = "N/A"

    if ($CompanyMap.ContainsKey($compName)) {
        $friendlyName = $CompanyMap[$compName]
        Write-LogLine "[$compName - $friendlyName]"

        # Generate timestamp and zip file path
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $zipName = "${compName}_${friendlyName}_$timestamp.zip"
        $zipPath = Join-Path $DestDir $zipName

        # Temporary folder for ZIP preparation
        $tempFolder = Join-Path $env:TEMP ("ZipTemp_" + $compName)
        if (Test-Path $tempFolder) { Remove-Item -Recurse -Force $tempFolder }
        New-Item -ItemType Directory -Path $tempFolder | Out-Null

        # ============================================================
        # STEP 1: COPY COMPANY DATA
        # ============================================================
        try {
            $dataFolder = Join-Path $tempFolder ("DATA_" + $compName)
            Copy-Item -Path $companyFolder.FullName -Destination $dataFolder -Recurse -Force
            $dataStatus = "Success"
            $dataSuccess++
            Write-LogLine "  DATA copied: Success"
        }
        catch {
            $dataStatus = "Failed"
            $dataFail++
            $remark += "DATA copy failed; "
            Write-LogLine "  DATA copied: Failed"
        }

        # ============================================================
        # STEP 2: COLLECT LATEST BACKUP FILES
        # ============================================================
        $latestBackupFolder = Join-Path $tempFolder "Latest Backup"
        New-Item -ItemType Directory -Path $latestBackupFolder | Out-Null
        $latestCount = 0
        $latestDate = $null
        
        try {
            $backupFolder = Join-Path $BackupBase $friendlyName
            if (Test-Path $backupFolder) {
                $allFiles = @{}

                foreach ($weekdayDir in Get-ChildItem -Path $backupFolder -Directory) {
                    foreach ($file in Get-ChildItem -Path $weekdayDir.FullName -File) {
                        # Keep latest file version if duplicates found
                        if (-not $allFiles.ContainsKey($file.Name)) {
                            $allFiles[$file.Name] = $file
                        } elseif ($file.LastWriteTime -gt $allFiles[$file.Name].LastWriteTime) {
                            $allFiles[$file.Name] = $file
                        }
                    }
                }

                foreach ($f in $allFiles.Values) {
                    Copy-Item -Path $f.FullName -Destination (Join-Path $latestBackupFolder $f.Name) -Force
                    $latestCount++
                    if ($null -eq $latestDate -or $f.LastWriteTime -gt $latestDate) {
                        $latestDate = $f.LastWriteTime
                    }
                }

                if ($latestDate) { $latestFileDate = $latestDate.ToString("yyyy-MM-dd HH:mm") }

                $backupStatus = "Success ($latestCount files)"
                $backupSuccess++
                Write-LogLine "  Latest Backup: $latestCount files collected"
                Write-LogLine "  Latest File Date: $latestFileDate"
            }
            else {
                $backupStatus = "Failed"
                $backupFail++
                $remark += "Backup folder missing; "
                Write-LogLine "  Latest Backup: Failed (Folder missing)"
            }
        }
        catch {
            $backupStatus = "Failed"
            $backupFail++
            $remark += "Backup read error; "
            Write-LogLine "  Latest Backup: Failed (Error)"
        }

        # ============================================================
        # STEP 3: REMOVE OLD ZIPS AND CREATE NEW ZIP
        # ============================================================
        Get-ChildItem -Path $DestDir -Filter "${compName}_*.zip" | Remove-Item -Force -ErrorAction SilentlyContinue

        try {
            Compress-Archive -Path (Join-Path $tempFolder "*") -DestinationPath $zipPath -Force
            $zipStatus = "Success"
            $zipSuccess++
            Write-LogLine "  ZIP created: $zipName"
        }
        catch {
            $zipStatus = "Failed"
            $zipFail++
            $remark += "ZIP creation failed; "
            Write-LogLine "  ZIP creation: Failed"
        }

        if ($remark -ne "") { Write-LogLine "  REMARK: $remark" }

        # Cleanup
        if (Test-Path $tempFolder) { Remove-Item -Recurse -Force $tempFolder }
        Write-LogLine ""
    } 
    else {
        # Skip folders without mapping
        Write-LogLine "[$compName - No mapping found]"
        Write-LogLine "  Skipped"
        Write-LogLine ""
        $friendlyName = "No mapping found"
    }

    # Add to summary list
    $summaryList += [PSCustomObject]@{
        Company = "$compName - $friendlyName"
        DATA_Copy = $dataStatus
        Latest_Backup = $backupStatus
        Latest_File_Date = $latestFileDate
        ZIP_Created = $zipStatus
        Remarks = $remark
    }
}

# ============================================================
# SUMMARY TABLE
# ============================================================
Write-LogLine "Summary (per company):"
Write-LogLine ""

# Calculate column widths dynamically
$colWidths = @{
    Company = ($summaryList | ForEach-Object { $_.Company.Length } | Measure-Object -Maximum).Maximum
    DATA_Copy = ($summaryList | ForEach-Object { $_.DATA_Copy.Length } | Measure-Object -Maximum).Maximum
    Latest_Backup = ($summaryList | ForEach-Object { $_.Latest_Backup.Length } | Measure-Object -Maximum).Maximum
    Latest_File_Date = ($summaryList | ForEach-Object { $_.Latest_File_Date.Length } | Measure-Object -Maximum).Maximum
    ZIP_Created = ($summaryList | ForEach-Object { $_.ZIP_Created.Length } | Measure-Object -Maximum).Maximum
    Remarks = ($summaryList | ForEach-Object { $_.Remarks.Length } | Measure-Object -Maximum).Maximum
}

# Apply minimum readable widths
$colWidths.Company = [Math]::Max($colWidths.Company, 25)
$colWidths.DATA_Copy = [Math]::Max($colWidths.DATA_Copy, 12)
$colWidths.Latest_Backup = [Math]::Max($colWidths.Latest_Backup, 18)
$colWidths.Latest_File_Date = [Math]::Max($colWidths.Latest_File_Date, 16)
$colWidths.ZIP_Created = [Math]::Max($colWidths.ZIP_Created, 12)
$colWidths.Remarks = [Math]::Max($colWidths.Remarks, 20)

# Table Header
$header = ("| {0,-$($colWidths.Company)} | {1,-$($colWidths.DATA_Copy)} | {2,-$($colWidths.Latest_Backup)} | {3,-$($colWidths.Latest_File_Date)} | {4,-$($colWidths.ZIP_Created)} | {5,-$($colWidths.Remarks)} |" -f "Company","DATA Copy","Latest Backup","Latest File Date","ZIP Created","Remarks")
$separator = "+" + ("-" * ($colWidths.Company + 2)) + "+" + ("-" * ($colWidths.DATA_Copy + 2)) + "+" + ("-" * ($colWidths.Latest_Backup + 2)) + "+" + ("-" * ($colWidths.Latest_File_Date + 2)) + "+" + ("-" * ($colWidths.ZIP_Created + 2)) + "+" + ("-" * ($colWidths.Remarks + 2)) + "+"

Write-LogLine $separator
Write-LogLine $header
Write-LogLine $separator

foreach ($row in $summaryList) {
    $line = ("| {0,-$($colWidths.Company)} | {1,-$($colWidths.DATA_Copy)} | {2,-$($colWidths.Latest_Backup)} | {3,-$($colWidths.Latest_File_Date)} | {4,-$($colWidths.ZIP_Created)} | {5,-$($colWidths.Remarks)} |" -f $row.Company, $row.DATA_Copy, $row.Latest_Backup, $row.Latest_File_Date, $row.ZIP_Created, $row.Remarks)
    Write-LogLine $line
}
Write-LogLine $separator
Write-LogLine ""

# ============================================================
# TOTAL SUMMARY
# ============================================================
Write-LogLine "Totals:"
Write-LogLine "  Total Companies: $totalCompanies"
Write-LogLine "  DATA copy success: $dataSuccess / Failed: $dataFail"
Write-LogLine "  Latest Backup success: $backupSuccess / Failed: $backupFail"
Write-LogLine "  ZIP creation success: $zipSuccess / Failed: $zipFail"
Write-LogLine ""

# ============================================================
# END FOOTER + LOG ROTATION
# ============================================================
$endTime = Get-Date
Write-LogLine "========== Backup Run Finished: $($endTime.ToString('yyyy-MM-dd HH:mm:ss')) =========="
Write-LogLine ""

# Ensure log directory exists
if (-not (Test-Path (Split-Path $LogFile -Parent))) { 
    New-Item -ItemType Directory -Path (Split-Path $LogFile -Parent) | Out-Null 
}

$currentRunText = $runLog -join "`r`n"

# Rotate logs (keep last 3 runs)
if (Test-Path $LogFile) {
    $existingContent = Get-Content -Path $LogFile -Raw
    if ([string]::IsNullOrWhiteSpace($existingContent)) {
        Set-Content -Path $LogFile -Value $currentRunText -Force
    } else {
        $runs = [regex]::Split($existingContent.Trim(), "(?=========== Backup Run Started: )")
        $nonEmptyRuns = $runs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $previousRunsToKeep = $nonEmptyRuns | Select-Object -Last 2
        $newContent = (@($currentRunText) + $previousRunsToKeep) -join "`r`n`r`n"
        Set-Content -Path $LogFile -Value $newContent -Force
    }
} else {
    Set-Content -Path $LogFile -Value $currentRunText -Force
}
