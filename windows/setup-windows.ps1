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
Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" -OutFile $fontZip
Expand-Archive $fontZip -DestinationPath $env:TEMP\Meslo -Force
$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
Get-ChildItem "$env:TEMP\Meslo" -Recurse -Include *.ttf | ForEach-Object {
    $fonts.CopyHere($_.FullName)
}
Remove-Item $fontZip -Force
Remove-Item "$env:TEMP\Meslo" -Recurse -Force

Write-Host "=== Configuring PowerShell profile ==="
$profilePath = $PROFILE
if (!(Test-Path -Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$initLine = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'
if (-not (Select-String -Path $profilePath -Pattern "oh-my-posh init pwsh" -Quiet)) {
    Add-Content -Path $profilePath -Value $initLine
}

Write-Host "=== Setup complete! ==="
Write-Host "👉 Restart PowerShell and set your terminal font to 'MesloLGS Nerd Font'."
