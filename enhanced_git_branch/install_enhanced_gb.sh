#!/bin/bash

# Determine the path to zshrc
ZSHRC="$HOME/.zshrc"

# Create a backup
cp "$ZSHRC" "$ZSHRC.bak"
echo "Created backup at $ZSHRC.bak"

# Install the enhanced gb script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/enhance_gb.sh"

# Update the zshrc file
sed -i '' 's/alias gb="git for-each-ref --sort=-committerdate refs\/heads\/ --format='\''%(HEAD) %(color:dim)%(color:green)%(committerdate:relative)%(color:reset) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) %(color:dim)- %(contents:subject) %(authorname)'\''"/alias gb="'"$SCRIPT_PATH"'"/g' "$ZSHRC"

echo "Updated gb alias in $ZSHRC"
echo "To apply changes, run: source $ZSHRC"
echo ""
echo "Your enhanced 'gb' command will now show:"
echo "- [MERGED] tag for branches merged via PR"
echo "- [CLOSED] tag for PRs that were closed without merging"
echo "- [MERGED-GIT] tag for branches merged directly without a PR"