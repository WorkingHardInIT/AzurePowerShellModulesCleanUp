
# Detect Windows PowerShell vs PowerShell Core
$IsWindowsPowerShell = $PSVersionTable.PSEdition -eq 'Desktop'
$UseEmoji = -not $IsWindowsPowerShell

# Emoji to ANSI fallback for Windows PowerShell

#We need this ANSI Code based emoji and a translation table to [label] to use in Windows PowerShell.
$EmojiMap = @{
    'info'      = @{ Emoji = "`u{2139}"; Label = '[INFO]' }  # ℹ️
    'warn'      = @{ Emoji = "`u{26A0}"; Label = '[WARNING]' }  # ⚠️
    'fail'      = @{ Emoji = "`u{274C}"; Label = '[FAIL]' }  # ❌
    'success'   = @{ Emoji = "`u{2705}"; Label = '[OK]' }  # ✅
    'hourglass' = @{ Emoji = "`u{23F3}"; Label = '[WAIT]' }  # ⏳
    'search'    = @{ Emoji = "`u{1F50D}"; Label = '[CHECK]' }  # 🔍
    'gear'      = @{ Emoji = "`u{2699}"; Label = '[ACTION]' }  # ⚙️
    'pin'       = @{ Emoji = "`u{1F4CC}"; Label = '[MODULE]' }  # 📌
    'puzzle'    = @{ Emoji = "`u{1F9E9}"; Label = '[VERSIONS]' }  # 🧩
    'list'      = @{ Emoji = "`u{1F4CB}"; Label = '[LIST]' }  # 📋
    'lock'      = @{ Emoji = "`u{26D4}"; Label = '[LOCKED]' }  # ⛔
    'skip'      = @{ Emoji = "`u{27A1}"; Label = '[SKIP]' }  # ➡️
    'delete'    = @{ Emoji = "`u{2757}"; Label = '[DELETE]' }  # ❗
}

function Get-EmojiLabel {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('info', 'warn', 'fail', 'success', 'hourglass', 'search', 'gear', 'pin', 'puzzle', 'list', 'lock', 'skip', 'delete')]
        [string]$type
    )
    if ($UseEmoji) {
        return $EmojiMap[$type].Emoji
    }
    else {
        return $EmojiMap[$type].Label
    }
}

# Initialize logging 
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$logDir = Join-Path $ScriptPath "AzModuleCleanupLogs"
$mdLog = Join-Path $logDir "AzCleanup_$timestamp.md"
$htmlLog = Join-Path $logDir "AzCleanup_$timestamp.html"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Msg {
    param (
        [string]$msg,
        [string]$color = "White",
        [switch]$isHeading
    )
    Write-Host $msg -ForegroundColor $color

    $mdLine = $msg
    if ($isHeading) { $mdLine = "### $msg" }
    Add-Content -Path $mdLog -Value $mdLine

    $htmlLine = "<p style='color:$color;'>$msg</p>"
    if ($isHeading) { $htmlLine = "<h3 style='color:$color;'>$msg</h3>" }
    Add-Content -Path $htmlLog -Value $htmlLine
}

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $IsAdmin) {
    Write-Msg "`n$(Get-EmojiLabel 'warn') This script is not running in an elevated console. AllUsers module cleanup will be skipped." Yellow
    $choice = Read-Host "Do you want to restart this script with administrative privileges? (Y/N)"
    if ($choice -match '^[Yy]$') {
        $escapedScript = ($MyInvocation.MyCommand.Path).Replace('"', '""')
        if (Get-Command "pwsh.exe" -ErrorAction SilentlyContinue) {
            $wtArgs = "pwsh.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$escapedScript`""
            #FOR TESTING ONLY ==> FORCE WINDOWS POWERSHELL
            #$wtArgs = "powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$escapedScript`""
        }
        else {
            $wtArgs = "powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$escapedScript`""
        }
        Start-Process -FilePath "wt.exe" -ArgumentList $wtArgs -Verb RunAs
        Exit
    }
    else {
        Write-Msg "`n$(Get-EmojiLabel 'success') Running non-elevated console. CurrentUser module cleanup will be performed and AllUsers module cleanup will be skipped." Green
    }
}
else {
    Write-Msg "`n$(Get-EmojiLabel 'success') Running elevated console. CurrentUser module cleanup and AllUsers module cleanup will be performed." Green
}

Write-Msg "`n$(Get-EmojiLabel 'hourglass') Gathering all Az module versions installed on this device" -Color Green -isHeading
Write-Msg "   This takes a while ... please be patient!" -Color Green

$azModules = Get-Module -ListAvailable | Where-Object {
    $_.Name -eq 'Az' -or $_.Name -like 'Az.*'
}


Write-Msg "`n$(Get-EmojiLabel 'success') Ready gathering info, now we'll analyze it for duplicates..." -Color Green

$moduleGroups = @{}
foreach ($module in $azModules) {
    $name = $module.Name
    $version = $module.Version
    $path = $module.ModuleBase
    $scope = if ($path -match [regex]::Escape($env:USERPROFILE)) { 'CurrentUser' }
    elseif ($path -match 'Program Files.*WindowsPowerShell' -or $path -match 'Program Files.*PowerShell') { 'AllUsers' }
    else { 'Unknown' }

    $edition = if ($path -match '\\WindowsPowerShell\\') {
        'WindowsPowerShell'
    }
    elseif ($path -match '\\PowerShell\\') {
        'PowerShellCore'
    }
    else {
        throw "Unable to determine PowerShell edition for module path: $path"
    }

    $key = "$name|$edition|$scope"
    if (-not $moduleGroups.ContainsKey($key)) {
        $moduleGroups[$key] = @()
    }
    $moduleGroups[$key] += $module
}

$hasDuplicates = $false
Write-Msg "`n$(Get-EmojiLabel 'search') Scanning for duplicate Az module versions by scope and edition..." -Color Yellow -isHeading

foreach ($key in ($moduleGroups.Keys | Sort-Object)) {
    $group = $moduleGroups[$key] | Sort-Object Version -Descending
    $name, $editionVal, $scopeVal = $key -split '\|'
    $uniqueVersions = $group | Select-Object -ExpandProperty Version -Unique

    if ($uniqueVersions.Count -gt 1) {
        $hasDuplicates = $true
        Write-Msg "`n$(Get-EmojiLabel 'pin') $name ($editionVal in $scopeVal):" -Color Magenta -isHeading
        Write-Msg "`n$(Get-EmojiLabel 'puzzle') Versions Installed: $($uniqueVersions.Count)" -Color Gray
        Write-Msg "`n$(Get-EmojiLabel 'delete') Versions to Remove: $($uniqueVersions.Count - 1)" -Color Red
        Write-Msg "`n$(Get-EmojiLabel 'list') All Versions: $($uniqueVersions -join ', ')" -Color DarkCyan
    }
}

if (-not $hasDuplicates) {
    Write-Msg "`n$(Get-EmojiLabel 'success') No duplicate module versions found. Cleanup not required." Green
    return
}
else {
    Write-Msg "`n$(Get-EmojiLabel 'gear') Starting cleanup of duplicate versions..." -Color Yellow
}

foreach ($key in ($moduleGroups.Keys | Sort-Object)) {
    $group = $moduleGroups[$key] | Sort-Object Version -Descending
    $name, $editionVal, $scopeVal = $key -split '\|'
    $latest = $group[0]
    $olderVersions = $group | Select-Object -Skip 1
    $totalOld = $olderVersions.Count
    $currentIndex = 0

    foreach ($old in $olderVersions) {
        $currentIndex++
        $version = $old.Version
        $path = $old.ModuleBase
        $color = if ($scopeVal -eq 'CurrentUser') { 'Magenta' } elseif ($scopeVal -eq 'AllUsers') { 'Cyan' } else { 'Yellow' }

        Write-Msg "`n$(Get-EmojiLabel 'hourglass') [$currentIndex/$totalOld] Uninstalling $name version $version from path: $path" -Color $color
        Write-Msg "$(Get-EmojiLabel 'search') Scope: $scopeVal | Edition: $editionVal" -Color $color

        if ($scopeVal -eq 'AllUsers' -and -not $IsAdmin) {
            Write-Msg "$(Get-EmojiLabel 'lock') Skipping $name version $version (AllUsers scope requires admin rights)" -Color Yellow
            continue
        }

        try {
            Uninstall-Module -Name $name -RequiredVersion $version -Force -ErrorAction Stop
            Write-Msg "$(Get-EmojiLabel 'success') Successfully uninstalled $name version $version from $path" -Color $color
        }
        catch {
            Write-Msg "$(Get-EmojiLabel 'fail') Failed to uninstall $name version $version from $($path): $_" -Color Red

            if (Test-Path $path) {
                try {
                    #When you absolutely need to 'shut up' remove-item feedback interfering with your custom outpout!
                    [System.IO.Directory]::Delete($path, $true)
                    Write-Msg "$(Get-EmojiLabel 'delete') Manually deleted $path" -Color $color
                }
                catch {
                    Write-Msg "$(Get-EmojiLabel 'fail') Failed to delete $($path): $_" -Color Red
                }
            }
        }
    }
}

Write-Msg "$(Get-EmojiLabel 'success') Cleanup complete. Only the latest versions of Az modules are retained." -Color Green
Write-Msg "Logs can be found in $($logDir)."
