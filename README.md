
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

Run the script directly in a Windows Terminal PowerShell session:

```powershell
.\CleanupOldAzurePowerShellModulesWorkingHardInIT.ps1
```

> 💡 If not run as Administrator, the script will prompt to elevate. If declined, only `CurrentUser` modules will be cleaned.
> ❗ If you don't have Windows Terminal, get it or adapt the script to launch Powershell.exe or pwsh.exe directly
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

- Deletion of modules is attempted first via `Uninstall-Module`. If that fails, the script tries to remove directories manually.
- To force elevation in PowerShell Core, `wt.exe` (Windows Terminal) is used to relaunch with admin rights.

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).

---

## 🙌 Credits

Crafted with care by [Didier Van Hoye](https://github.com/WorkingHardInIT)
