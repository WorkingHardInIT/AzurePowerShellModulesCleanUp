# 🔍 Az PowerShell Module Cleanup Script

A PowerShell utility for cleaning up old or duplicate versions of Azure PowerShell (`Az`) modules across **Windows PowerShell** and **PowerShell Core**. It ensures that only the **latest version** of each `Az` module is retained—keeping your environment clean, fast, and free from version conflicts.

---

## ⚙️ Features

- ✅ Detects all installed `Az` and `Az.*` modules
- 🧩 Groups by PowerShell edition and installation scope (`CurrentUser` vs `AllUsers`)
- ⛔ Skips removal of `AllUsers` modules if not run as Administrator
- 🔄 Keeps only the latest version of each module
- 📋 Logs results to both **Markdown** and **HTML**
- 🎨 Color-coded output with emoji support in PowerShell Core, fallback labels in Windows PowerShell
- 🏃‍♂️ **Dry Run** mode to simulate the cleanup process without making any changes
- 🔧 Automatically switches between `Uninstall-Module` and `Uninstall-PSResource` based on PowerShell edition

---

## 🧰 Requirements

- PowerShell 5.1 (Windows PowerShell) or PowerShell Core (7+)
- Administrator privileges (for full cleanup including `AllUsers` modules)
- `Az` modules already installed via `Install-Module`

---

## 🛠️ Installation

Clone this repo or download the `.ps1` script:

```bash
git clone https://github.com/yourusername/az-module-cleanup.git
```

Or simply download [`CleanupOldAzurePowerShellModulesWorkingHardInIT.ps1`](./CleanupOldAzurePowerShellModulesWorkingHardInIT.ps1).

---

## 🚀 Usage

Run the script directly in a PowerShell session:

```powershell
.\CleanupOldAzurePowerShellModulesWorkingHardInIT.ps1
```

### 💡 **Dry Run Mode**

The script includes a `-DryRun` parameter that simulates the cleanup process without making any actual changes to your system. To run the script in dry run mode, use:

```powershell
.\CleanupOldAzurePowerShellModulesWorkingHardInIT.ps1 -DryRun $true
```

In dry run mode:

- No modules will be uninstalled.
- The script will output what **would** happen, but no changes will be made to your environment.

> 💡 If not run as Administrator, the script will prompt to elevate. If declined, only `CurrentUser` modules will be cleaned.

---

## 📝 Logs

After execution, logs are saved in the following directory:

```
<Script Directory>\AzModuleCleanupLogs\
```

Each run creates:

- `AzCleanup_<timestamp>.md` – Markdown log (GitHub friendly)
- `AzCleanup_<timestamp>.html` – HTML log (colored, styled)

---

## 📦 Example Output

```powershell
🔍 Scanning for duplicate Az module versions by scope and edition...

📌 Az.Accounts (PowerShellCore in AllUsers):
🧩 Versions Installed: 3
❗ Versions to Remove: 2
📋 All Versions: 2.2.0, 2.1.0, 1.9.5

✅ Successfully uninstalled Az.Accounts version 2.1.0
✅ Successfully uninstalled Az.Accounts version 1.9.5

✅ Cleanup complete. Only the latest versions of Az modules are retained.
```

---

## ⚠️ Notes

- **Dry Run Mode**: When the `-DryRun` parameter is used, the script simulates the cleanup, showing what would happen without making any changes to the system.
- Deletion of modules done via either  `Uninstall-Module` or `Uninstall-PSResource` depending on whether that is available and appropriate (it can only be used for PowerShell Core modules).
- To force elevation in PowerShell Core, `wt.exe` (Windows Terminal) is used to relaunch with admin rights. This also takes the DryRun parameter into account.

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).

---

## 🙌 Credits

Crafted with care by [Didier Van Hoye](https://github.com/WorkingHardInIT)
