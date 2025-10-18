
# 📦 DataSynapse Enterprise Backup Automation Suite
**Automated Backup Utility for [BUSY Accounting Software](https://busy.in/)**  

---

## 🧩 Overview
The **DataSynapse Enterprise Backup Automation Suite** is a PowerShell-based tool built specifically for **BUSY Accounting Software**.  
It automatically creates a consolidated **ZIP backup folder** that includes both:

1. The company data directories maintained by BUSY (`DATA_COMPXXXX`), and  
2. The daily backup files (`DATA.BKP`, `DISK1.DB`) created by BUSY’s built-in backup service.

This ensures your critical accounting data is stored in a single, structured archive — without altering the original files or directories.

---

## ⚙️ Key Features
- 🧠 Automatically detects the **latest backup** from BUSY’s 7-day rotation (Sunday–Saturday).  
- 🗂️ Combines **company data** and **latest backup files** into a single ZIP archive.  
- 🧾 Creates clearly named backup folders:
    ```
    COMP00XX_Company Name_YYYY-MM-DD_hh-mm-ss.zip
    ```
- 🛡️ Ensures **100% data safety** — original directories remain untouched.  
- 📜 Optionally logs detailed execution summaries for tracking and verification.

---

## 🗂️ Sample Output Folder Structure
When the script runs successfully, the resulting ZIP (or extracted folder) looks like this:

```

Your BackUp Folder
└───COMP00XX_Company Name_YYYY-MM-DD_hh-mm-ss.zip
    ├───DATA_COMP00XX
    │       db.bds
    │       db12024.bds
    │       db12025.bds
    │       locks.sys
    │
    └───Latest Backup
            DATA.BKP
            DISK1.DB

```

---

## 📁 BUSY Accounting Software Directory References

### BUSY Data Directory (Example)
```
D:\Softwares\BUSY Software\DATA
├───COMP0001
├───COMP0002
├───COMP0003
├───COMP0004
└───COMP0005
```

### BUSY Backup Directory (Example)
```
D:\BUSY BackUp\<Company Name>
├───1. SUNDAY
├───2. MONDAY
├───3. TUESDAY
├───4. WEDNESDAY
├───5. THURSDAY
├───6. FRIDAY
└───7. SATURDAY
```

Each weekday folder contains files such as:
```
DATA.BKP
DISK1.DB
````

---

## 🚀 How It Works
1. The script scans your **BUSY Data Directory** for company folders (e.g., `COMP0001`, `COMP0002`, etc.).  
2. It maps each company code to its corresponding name (as defined in the script).  
3. It locates the **latest backup files** from all seven weekday folders.  
4. The script copies:
   - The live company data folder (`DATA_COMPXXXX`), and  
   - The most recent BUSY backup files (`DATA.BKP`, `DISK1.DB`)  
5. Finally, it creates a **timestamped ZIP file** in the output directory.

---

## 🧠 Notes
- This script is designed and **tested exclusively for BUSY Accounting Software**.  
- It may or may not work with other accounting or ERP systems.  
- The process is **non-destructive** — no modification or deletion occurs in BUSY’s original directories.  

---

## 🖥️ Requirements
- **Windows 10 or 11**  
- **PowerShell 5.1 or later**  
- **BUSY Accounting Software** (any standard edition)  
- Read/write access to the directories used for data and backup

---

## 🪄 Usage Instructions
1. Open the file `DataSynapse-Enterprise-Backup-Automation-Suite.ps1` in any text editor.  
2. Update the configuration paths in the parameter section:
   ```powershell
   $SourceDir  = "D:\Softwares\BUSY Software\DATA"
   $BackupBase = "D:\BUSY BackUp"
   $DestDir    = "E:\BUSY Final Backups"
   $LogFile    = "E:\BUSY Final Backups\BackupLog.txt"
    ```

3. Modify the `$CompanyMap` dictionary to include your BUSY company codes and names.
4. Run PowerShell as Administrator and execute:

   ```powershell
   .\DataSynapse-Enterprise-Backup-Automation-Suite.ps1
   ```

---

## 🧾 Output Example

After execution, you’ll get a ZIP file in your destination folder, such as:

```
COMP00XX_Company Name_YYYY-MM-DD_hh-mm-ss.zip
```

When extracted, it contains:

```
├───DATA_COMP00XX
│       db.bds
│       db12025.bds
│       ...
└───Latest Backup
        DATA.BKP
        DISK1.DB
```

---

## ⚖️ License

This project is distributed under the **MIT License**.
You are free to use, modify, and share it with appropriate credit.

---

## 👨‍💻 Author

**Yug Agarwal**

* 📧 [yugagarwal704@gmail.com](mailto:yugagarwal704@gmail.com)
* 🔗 GitHub – [@HelloYug](https://github.com/HelloYug)