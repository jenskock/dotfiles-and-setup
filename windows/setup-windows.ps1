# Ensure script stops on errors
$ErrorActionPreference = "Stop"

Write-Host "=== Installing GitHub CLI ==="
winget install --id GitHub.cli -e --source winget -h

Write-Host "=== Installing Oh My Posh ==="
winget install JanDeDobbeleer.OhMyPosh -e --source winget -h

Write-Host "=== Setting up Oh My Posh themes ==="
$poshThemes = "$env:USERPROFILE\.poshthemes"
if (!(Test-Path $poshThemes)) {
    New-Item -ItemType Directory -Path $poshThemes | Out-Null
}
Set-Location $poshThemes

Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -OutFile "themes.zip"
Expand-Archive themes.zip -Force
Remove-Item themes.zip
Get-ChildItem *.omp.json | ForEach-Object { $_.Attributes = 'Normal' }

Write-Host "=== Installing MesloLGS Nerd Font ==="
$fontZip = "$env:TEMP\Meslo.zip"
$fontExtract = "$env:TEMP\Meslo"

Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" -OutFile $fontZip

if (Test-Path $fontZip) {
    Expand-Archive $fontZip -DestinationPath $fontExtract -Force

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem "$fontExtract" -Recurse -Include *.ttf | ForEach-Object {
        $fonts.CopyHere($_.FullName)
    }

    if (Test-Path $fontZip) {
        Remove-Item $fontZip -Force
    }
    if (Test-Path $fontExtract) {
        Remove-Item $fontExtract -Recurse -Force
    }
} else {
    Write-Host "⚠️ Font download failed, skipping cleanup."
}

Write-Host "=== Configuring PowerShell profile ==="

# Ensure $PROFILE is valid
if (-not $PROFILE -or [string]::IsNullOrWhiteSpace($PROFILE)) {
    $PROFILE = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", "PowerShell", "Microsoft.PowerShell_profile.ps1")
}

$profilePath = $PROFILE
$profileDir = [System.IO.Path]::GetDirectoryName($profilePath)

if (!(Test-Path -Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (!(Test-Path -Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

# Add Oh My Posh init line if missing
$initLine = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'
$profileContent = Get-Content -Path $profilePath -ErrorAction SilentlyContinue
if ($null -eq $profileContent -or ($profileContent -notmatch "oh-my-posh init pwsh")) {
    Add-Content -Path $profilePath -Value $initLine
}

Write-Host "=== Adding 'nn' command for quick notes ==="
$nnScriptPath = "$env:USERPROFILE\bin\nn.ps1"
$nnDir = [System.IO.Path]::GetDirectoryName($nnScriptPath)
if (!(Test-Path $nnDir)) {
    New-Item -ItemType Directory -Path $nnDir | Out-Null
}

@'
param(
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

if (-not $Args -or $Args.Count -eq 0) {
    Write-Host "Usage: nn 'Description of note'"
    exit
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
'@ | Out-File -FilePath $nnScriptPath -Encoding UTF8 -Force

# Ensure bin folder is in PATH
$binPath = "$env:USERPROFILE\bin"
if (-not ($env:PATH -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $binPath })) {
    $env:PATH = "$binPath;$env:PATH"
    # Persist in profile
    $pathLine = '$env:PATH = "$env:USERPROFILE\bin;$env:PATH"'
    if ($profileContent -notmatch [Regex]::Escape($pathLine)) {
        Add-Content -Path $profilePath -Value $pathLine
    }
}

# Add nn alias to PowerShell profile if missing
$nnAlias = "Set-Alias nn $nnScriptPath"
$profileContent = Get-Content -Path $profilePath -ErrorAction SilentlyContinue
if ($null -eq $profileContent -or ($profileContent -notmatch "Set-Alias nn")) {
    Add-Content -Path $profilePath -Value $nnAlias
}

Write-Host "=== Setup complete! ==="
Write-Host "👉 Restart PowerShell (or run: . `$PROFILE) and set your terminal font to 'MesloLGS Nerd Font'."
Write-Host "👉 You can now use: nn 'My Note' to create and edit notes."
