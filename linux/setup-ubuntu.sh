#!/usr/bin/env bash
# Remove strict error handling to allow script to continue on failures
# set -euo pipefail

# Function to handle errors gracefully
handle_error() {
    local exit_code=$?
    echo "⚠️  Command failed with exit code $exit_code"
    return $exit_code
}

# Set up error handling
trap handle_error ERR

echo "=== Updating system packages ==="
if sudo apt update && sudo apt upgrade -y; then
    echo "✅ System packages updated successfully"
else
    echo "⚠️  System package update failed, continuing..."
fi

echo "=== Installing dependencies (curl, wget, unzip, git, ripgrep, btop, ranger, mc) ==="
if sudo apt install -y curl wget unzip git ripgrep btop ranger mc; then
    echo "✅ Dependencies installed successfully"
else
    echo "⚠️  Some dependencies failed to install, continuing..."
fi

echo "=== Installing FastFetch ==="
# Remove any existing broken FastFetch binary
sudo rm -f /usr/local/bin/fastfetch

# Add FastFetch PPA repository
if sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y; then
    echo "✅ FastFetch PPA added successfully"
else
    echo "⚠️  Failed to add FastFetch PPA, continuing..."
fi

# Update package lists
if sudo apt update; then
    echo "✅ Package lists updated"
else
    echo "⚠️  Package list update failed, continuing..."
fi

# Install FastFetch
if sudo apt install -y fastfetch; then
    echo "✅ FastFetch installed successfully"
    if command -v fastfetch > /dev/null 2>&1; then
        fastfetch --version
    fi
else
    echo "⚠️  FastFetch installation failed, continuing..."
fi

echo "=== Installing GitHub CLI ==="
type -p curl >/dev/null || sudo apt install -y curl
if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
   sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null && \
   sudo apt update && \
   sudo apt install -y gh; then
    echo "✅ GitHub CLI installed successfully"
else
    echo "⚠️  GitHub CLI installation failed, continuing..."
fi

echo "=== Installing Oh My Posh ==="
if curl -s https://ohmyposh.dev/install.sh | bash -s; then
    echo "✅ Oh My Posh installed successfully"
else
    echo "⚠️  Oh My Posh installation failed, continuing..."
fi

# Ensure ~/.local/bin is in PATH
if ! grep -q 'export PATH=.*$HOME/.local/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
  echo "✅ Added ~/.local/bin to PATH"
fi
export PATH=$PATH:$HOME/.local/bin

# Ensure explorer.exe Alias
if ! grep -q "alias ow='explorer.exe'" ~/.bashrc; then
  echo "alias ow='explorer.exe'" >> ~/.bashrc
  echo "✅ Added explorer.exe alias"
fi

# Add ranger_cd function and alias
if ! grep -q "ranger_cd()" ~/.bashrc; then
  cat >> ~/.bashrc << 'EOF'

# Ranger function to change directory
ranger_cd() {
  local tmpfile
  tmpfile=$(mktemp)
  ranger --choosedir="$tmpfile" "$@"
  if [ -f "$tmpfile" ] && dir=$(cat "$tmpfile") && [ -d "$dir" ]; then
    cd "$dir"
  fi
  rm -f "$tmpfile"
}
alias rcd=ranger_cd
EOF
  echo "✅ Added ranger_cd function and rcd alias"
fi

echo "=== Setting up Oh My Posh themes ==="
if mkdir -p ~/.poshthemes && \
   cd ~/.poshthemes && \
   wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip && \
   unzip -o themes.zip && \
   chmod u+rw *.omp.json && \
   rm themes.zip; then
    echo "✅ Oh My Posh themes set up successfully"
else
    echo "⚠️  Oh My Posh themes setup failed, continuing..."
fi

echo "=== Configuring Bash to use Oh My Posh ==="
CONFIG_LINE='eval "$(oh-my-posh init bash --config ~/.poshthemes/jandedobbeleer.omp.json)"'
if ! grep -Fxq "$CONFIG_LINE" ~/.bashrc; then
  echo "$CONFIG_LINE" >> ~/.bashrc
  echo "✅ Oh My Posh bash configuration added"
fi

echo "=== Installing Nerd Font (MesloLGS) ==="
FONT_DIR="$HOME/.local/share/fonts"
if mkdir -p "$FONT_DIR" && \
   cd "$FONT_DIR" && \
   wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -O Meslo.zip && \
   unzip -o Meslo.zip && \
   rm Meslo.zip && \
   fc-cache -fv; then
    echo "✅ Nerd Font installed successfully"
else
    echo "⚠️  Nerd Font installation failed, continuing..."
fi

echo "=== Setting up 'nn' command for quick notes ==="
if mkdir -p ~/.local/bin; then
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
    echo "✅ 'nn' command set up successfully"
else
    echo "⚠️  'nn' command setup failed, continuing..."
fi

echo "=== Configuring Nano with line numbers ==="
# Create or update ~/.nanorc to enable line numbers permanently
if mkdir -p ~/.config 2>/dev/null; then
    if echo "set linenumbers" >> ~/.nanorc; then
        echo "✅ Nano line numbers configuration added to ~/.nanorc"
    else
        echo "⚠️  Failed to configure Nano line numbers, continuing..."
    fi
else
    echo "⚠️  Failed to create config directory, continuing..."
fi

echo "=== Installing Docker ==="
# Install Docker dependencies
if sudo apt install -y apt-transport-https ca-certificates gnupg lsb-release; then
    echo "✅ Docker dependencies installed"
else
    echo "⚠️  Docker dependencies installation failed, continuing..."
fi

# Add Docker's official GPG key
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
    echo "✅ Docker GPG key added"
else
    echo "⚠️  Docker GPG key addition failed, continuing..."
fi

# Add Docker repository
if echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    echo "✅ Docker repository added"
else
    echo "⚠️  Docker repository addition failed, continuing..."
fi

# Update package list and install Docker
if sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    echo "✅ Docker installed successfully"
else
    echo "⚠️  Docker installation failed, continuing..."
fi

# Create docker group and add user (if not already exists)
if ! getent group docker > /dev/null 2>&1; then
    if sudo groupadd docker; then
        echo "✅ Docker group created"
    else
        echo "⚠️  Docker group creation failed, continuing..."
    fi
fi

# Add current user to docker group
if sudo usermod -aG docker "$USER"; then
    echo "✅ User added to docker group"
else
    echo "⚠️  Failed to add user to docker group, continuing..."
fi

# Start and enable Docker service
if sudo systemctl start docker && sudo systemctl enable docker; then
    echo "✅ Docker service started and enabled"
else
    echo "⚠️  Docker service setup failed, continuing..."
fi

echo "=== Installing Lazy-Docker ==="
# Get the latest version of lazy-docker
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')

if [ -z "$LAZYDOCKER_VERSION" ]; then
    echo "⚠️  Failed to get lazy-docker version, continuing..."
else
    echo "📦 Installing lazy-docker version: $LAZYDOCKER_VERSION"

    # Download and install lazy-docker
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    if curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" && \
       [ -f lazydocker.tar.gz ]; then
        
        # Extract and install
        if tar xf lazydocker.tar.gz && \
           sudo mv lazydocker /usr/local/bin/ && \
           sudo chmod +x /usr/local/bin/lazydocker; then
            echo "✅ Lazy-docker installed successfully"
            if command -v lazydocker > /dev/null 2>&1; then
                lazydocker --version
            fi
        else
            echo "⚠️  Lazy-docker installation failed, continuing..."
        fi
    else
        echo "⚠️  Failed to download lazy-docker, continuing..."
    fi

    # Clean up
    rm -rf "$TEMP_DIR"
fi

echo "=== Installing LazyGit ==="
# Get the latest version of lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')

if [ -z "$LAZYGIT_VERSION" ]; then
    echo "⚠️  Failed to get lazygit version, continuing..."
else
    echo "📦 Installing lazygit version: $LAZYGIT_VERSION"

    # Download and install lazygit
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    if curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
       [ -f lazygit.tar.gz ]; then
        
        # Extract and install
        if tar xf lazygit.tar.gz && \
           sudo mv lazygit /usr/local/bin/ && \
           sudo chmod +x /usr/local/bin/lazygit; then
            echo "✅ LazyGit installed successfully"
            if command -v lazygit > /dev/null 2>&1; then
                lazygit --version
            fi
        else
            echo "⚠️  LazyGit installation failed, continuing..."
        fi
    else
        echo "⚠️  Failed to download lazygit, continuing..."
    fi

    # Clean up
    rm -rf "$TEMP_DIR"
fi

echo "=== Setup complete! ==="
echo "👉 Restart your terminal and set the font to 'MesloLGS Nerd Font' in your terminal settings."
echo "👉 You can now use 'nn \"My Note\"' to create and edit notes."
echo "👉 Docker is installed and configured. You may need to log out and back in for group changes to take effect."
echo "👉 Use 'lazydocker' to manage Docker containers with a TUI interface."

