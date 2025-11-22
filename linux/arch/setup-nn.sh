#!/usr/bin/env bash
# Script to set up the 'nn' command for quick notes on Arch Linux

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
    
    # Ensure ~/.local/bin is in PATH (check common shell config files)
    if [ -n "$BASH_VERSION" ]; then
        if [ -f ~/.bashrc ] && ! grep -q 'export PATH=.*$HOME/.local/bin' ~/.bashrc; then
            echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
            echo "Added ~/.local/bin to PATH in ~/.bashrc"
        fi
    fi
    
    if [ -n "$ZSH_VERSION" ]; then
        if [ -f ~/.zshrc ] && ! grep -q 'export PATH=.*$HOME/.local/bin' ~/.zshrc; then
            echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.zshrc
            echo "Added ~/.local/bin to PATH in ~/.zshrc"
        fi
    fi
    
    # Also add to current session
    export PATH=$PATH:$HOME/.local/bin
    
    echo "'nn' command set up successfully"
    echo "You can now use 'nn \"My Note\"' to create and edit notes."
    echo "Note: You may need to restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) for the command to be available."
else
    echo "'nn' command setup failed, continuing..."
    exit 1
fi

