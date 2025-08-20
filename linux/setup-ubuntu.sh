#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing dependencies (curl, wget, unzip, git, ripgrep) ==="
sudo apt install -y curl wget unzip git ripgrep

echo "=== Installing GitHub CLI ==="
type -p curl >/dev/null || sudo apt install -y curl
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" |
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update
sudo apt install -y gh

echo "=== Installing Oh My Posh ==="
curl -s https://ohmyposh.dev/install.sh | bash -s

# Ensure ~/.local/bin is in PATH
if ! grep -q 'export PATH=.*$HOME/.local/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
fi
export PATH=$PATH:$HOME/.local/bin

echo "=== Setting up Oh My Posh themes ==="
mkdir -p ~/.poshthemes
cd ~/.poshthemes
wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip
unzip -o themes.zip
chmod u+rw *.omp.json
rm themes.zip

echo "=== Configuring Bash to use Oh My Posh ==="
CONFIG_LINE='eval "$(oh-my-posh init bash --config ~/.poshthemes/jandedobbeleer.omp.json)"'
if ! grep -Fxq "$CONFIG_LINE" ~/.bashrc; then
  echo "$CONFIG_LINE" >> ~/.bashrc
fi

echo "=== Installing Nerd Font (MesloLGS) ==="
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cd "$FONT_DIR"
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -O Meslo.zip
unzip -o Meslo.zip
rm Meslo.zip
fc-cache -fv

echo "=== Setting up 'nn' command for quick notes ==="
mkdir -p ~/.local/bin

cat > ~/.local/bin/nn <<'EOF'
#!/bin/bash

# If no argument is given, show usage
if [ -z "$1" ]; then
  echo "Usage: nn \"Description of note\""
  exit 1
fi

# Get current date in YY-MM-DD format
date_str=$(date +%y-%m-%d)

# Join all arguments as description
desc="$*"

# Replace spaces with underscores (safer for filenames)
safe_desc=$(echo "$desc" | tr ' ' '_')

# Construct filename
filename="${date_str} ${safe_desc}.md"

# Create the file if it doesn't exist
touch "$filename"

# Open the file in nano
nano "$filename"
EOF

chmod +x ~/.local/bin/nn

echo "=== Setup complete! ==="
echo "👉 Restart your terminal and set the font to 'MesloLGS Nerd Font' in your terminal settings."
echo "👉 You can now use 'nn \"My Note\"' to create and edit notes."
