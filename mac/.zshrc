eval "$(oh-my-posh init zsh --config 'https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/huvix.omp.json')"

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

alias ll='ls -la'

if [ ! -f ~/.local/bin/nn ]; then
  mkdir -p ~/.local/bin
  cat > ~/.local/bin/nn <<'EOF'
#!/bin/bash
# If no argument is given, show usage
if [ -z "$1" ]; then
  echo "Usage: nn \"Description of note\""
  exit 1
fi

date_str=$(date +%y-%m-%d)

desc="$*"

safe_desc=$(echo "$desc" | tr ' ' '_')

filename="${date_str} ${safe_desc}.md"

touch "$filename"

nano "$filename"
EOF

  chmod +x ~/.local/bin/nn
fi

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi