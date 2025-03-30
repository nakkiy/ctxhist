#!/usr/bin/env bash

# -------------------------------
# install-ctxhist.sh
# Installs the ctxhist plugin for Oh My Zsh
# -------------------------------

# make this script fail early and safely
# -e		Exit immediately if any command returns a non-zero exit status.
# -u		Treat unset variables as an error and exit immediately.
# -o pipefail	If any command in a pipeline fails, the entire pipeline fails.
set -euo pipefail

PLUGIN_NAME="ctxhist"
PLUGIN_SRC_FILE="ctxhist.plugin.zsh"
PLUGIN_TARGET_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$PLUGIN_NAME"
PLUGIN_TARGET_FILE="$PLUGIN_TARGET_DIR/$PLUGIN_NAME.plugin.zsh"

echo "Installing $PLUGIN_NAME plugin to: $PLUGIN_TARGET_DIR"

# 1. Check that the source file exists
if [[ ! -f "$PLUGIN_SRC_FILE" ]]; then
  echo "Error: Plugin source file '$PLUGIN_SRC_FILE' not found in the current directory."
  exit 1
fi

# 2. Create plugin directory if it doesn't exist
echo "Creating target directory"
mkdir -p "$PLUGIN_TARGET_DIR"

# 3. Copy the plugin file
cp "$PLUGIN_SRC_FILE" "$PLUGIN_TARGET_FILE"
echo "Plugin file copied to $PLUGIN_TARGET_FILE"

# 4. Recommend updating .zshrc
if grep -q "^plugins=" "$HOME/.zshrc"; then
  if grep -q "plugins=.*$PLUGIN_NAME" "$HOME/.zshrc"; then
    echo "$PLUGIN_NAME is already listed in your .zshrc plugins. Have fun!"
  else
    echo ""
    echo "To enable the plugin, add '$PLUGIN_NAME' to your plugin list in ~/.zshrc:"
    echo ""
    echo "  plugins=(... $PLUGIN_NAME)"
    echo ""
  fi
else
  echo ""
  echo "No plugins=() entry found in your ~/.zshrc."
  echo "You can add the following line to enable the plugin:"
  echo ""
  echo "  plugins=($PLUGIN_NAME)"
  echo ""
fi

echo "Done."
