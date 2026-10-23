#!/usr/bin/env bash
# gdeyoung.ultrawide-bar — installer.
#
# Copies the bar plugin into ~/.config/omarchy/plugins/, activates it, places
# the width CLI on PATH, and installs the companion per-monitor workspaces
# widget as its own plugin. Idempotent: re-running updates in place. Every
# change is listed in the README's Remove section.
#
#   ./install.sh            bar + width CLI + workspaces widget
#
# (≤1.4.0 offered a --full path that also installed a window-mode helper and
#  a per-monitor workspaces backport; Omarchy 4.5 ships both natively and the
#  --full path is gone. Cleanup of old --full residue is in the README.)
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_id="gdeyoung.ultrawide-bar"
plugin_dir="$HOME/.config/omarchy/plugins/$plugin_id"
bindir="$HOME/.local/bin"

say() { printf '%s\n' "$*"; }

# --- 1. bar plugin files ----------------------------------------------------
mkdir -p "$plugin_dir" "$plugin_dir/bin" "$bindir"
install -m 644 "$repo_dir/Bar.qml"        "$plugin_dir/Bar.qml"
install -m 644 "$repo_dir/BarModel.js"    "$plugin_dir/BarModel.js"
install -m 644 "$repo_dir/manifest.json"  "$plugin_dir/manifest.json"
install -m 755 "$repo_dir/bin/ultrawide-bar-width" "$plugin_dir/bin/ultrawide-bar-width"
if [[ -d "$repo_dir/widgets" ]]; then
  mkdir -p "$plugin_dir/widgets"
  cp -r "$repo_dir/widgets/." "$plugin_dir/widgets/"
fi
if [[ -d "$repo_dir/indicators" ]]; then
  mkdir -p "$plugin_dir/indicators"
  cp -r "$repo_dir/indicators/." "$plugin_dir/indicators/"
fi

# --- 1b. per-monitor workspaces widget (own plugin: ids in the omarchy.*
# namespace are reserved for first-party plugins, so the fork's widget takes a
# gdeyoung.* id and replaces the stock omarchy.workspaces slot) --------------
widget_id="gdeyoung.workspaces"
widget_dir="$HOME/.config/omarchy/plugins/$widget_id"
if [[ -f "$repo_dir/plugins/gdeyoung.workspaces/manifest.json" ]]; then
  mkdir -p "$widget_dir"
  install -m 644 "$repo_dir/plugins/gdeyoung.workspaces/manifest.json"      "$widget_dir/manifest.json"
  install -m 644 "$repo_dir/plugins/gdeyoung.workspaces/Workspaces.qml"     "$widget_dir/Workspaces.qml"
  install -m 644 "$repo_dir/plugins/gdeyoung.workspaces/WorkspacesModel.js" "$widget_dir/WorkspacesModel.js"
fi

# width CLI: plugin-local copy first, PATH symlink second
[[ -x "$plugin_dir/bin/ultrawide-bar-width" ]] || {
  say "WARN: bin/ultrawide-bar-width missing from repo — width CLI not installed"; }

# --- 2. activate the bar ----------------------------------------------------
if command -v omarchy >/dev/null 2>&1; then
  omarchy bar use "$plugin_id" || say "NOTE: activate manually: omarchy bar use $plugin_id"
else
  say "NOTE: omarchy not on PATH — activate with: omarchy bar use $plugin_id"
fi

# --- 3. PATH symlink for the width CLI ---------------------------------------
ln -sf "$plugin_dir/bin/ultrawide-bar-width" "$bindir/ultrawide-bar-width"

say ""
say "installed: $plugin_id"
say "  bar:   omarchy bar use $plugin_id   (already run)"
say "  width: ultrawide-bar-width <20-100>"
say "  undo:  omarchy bar reset; see README Remove section"
