Write-Host "=== Adding Quick Notes function 'nn' to PowerShell profile ==="

$profilePath = $PROFILE.CurrentUserAllHosts

$profileDir = Split-Path $profilePath
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$nnFunction = @'
# === Quick Notes function 'nn' ===
function nn {
    param(
        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    if (-not $Args -or $Args.Count -eq 0) {
        Write-Host "Usage: nn 'Description of note'"
        return
    }

    # Get current date in YY-MM-DD format
    $dateStr = Get-Date -Format "yy-MM-dd"

    # Join all arguments as description
    $desc = $Args -join " "

    # Replace spaces with underscores (safer for filenames)
    $safeDesc = $desc -replace " ", "_"

    # Construct filename
    $filename = "$dateStr $safeDesc.md"

    # Create the file if it doesn't exist
    if (-not (Test-Path $filename)) {
        New-Item -ItemType File -Path $filename | Out-Null
    }

    # Open the file in default editor (VS Code if available, otherwise Notepad)
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $filename
    } else {
        notepad $filename
    }
}
'@

Add-Content -Path $profilePath -Value $nnFunction

Write-Host "✅ nn function added to $profilePath"
Write-Host "👉 Restart PowerShell and run: nn 'My Note'"