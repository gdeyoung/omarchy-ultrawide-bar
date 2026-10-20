#!/usr/bin/env bash
# gdeyoung.ultrawide-bar — installer.
#
# Copies the bar plugin into ~/.config/omarchy/plugins/, activates it, places
# the helper CLIs on PATH, and (optionally) wires Hyprland for window-mode
# switching (float-all / tile+aspect). Idempotent: re-running updates in
# place. Every change is listed in the README's Remove section.
#
#   ./install.sh            bar + width CLI only
#   ./install.sh --full     also install ultrawide-mode + Super+U binding +
#                           Hyprland include (dock switching), and the
#                           per-monitor workspaces backport (Omarchy quattro
#                           engine + guarded hook, workspace keys)
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_id="gdeyoung.ultrawide-bar"
plugin_dir="$HOME/.config/omarchy/plugins/$plugin_id"
bindir="$HOME/.local/bin"
state_include="$HOME/.config/hypr/ultrawide-mode.lua"
hypr_user_conf="$HOME/.config/hypr/hyprland.lua"

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
if [[ -f "$repo_dir/widget/manifest.json" ]]; then
  mkdir -p "$widget_dir"
  install -m 644 "$repo_dir/widget/manifest.json"      "$widget_dir/manifest.json"
  install -m 644 "$repo_dir/widget/Workspaces.qml"     "$widget_dir/Workspaces.qml"
  install -m 644 "$repo_dir/widget/WorkspacesModel.js" "$widget_dir/WorkspacesModel.js"
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

# --- 4. optional: window-mode tooling (--full) ------------------------------
if [[ "${1:-}" == "--full" ]]; then
  install -m 755 "$repo_dir/bin/ultrawide-mode" "$plugin_dir/bin/ultrawide-mode"
  ln -sf "$plugin_dir/bin/ultrawide-mode" "$bindir/ultrawide-mode"

  # state include loaded by hyprland.lua (source of truth: the plugin's copy)
  mkdir -p "$HOME/.config/hypr"
  cat > "$state_include" <<'LUA'
-- Ultrawide window-mode state (gdeyoung.ultrawide-bar). Loads float-all /
-- aspect-cap flags from the plugin's own state dir. Deliberately OUTSIDE
-- ~/.local/state/omarchy/toggles/hypr/ — hyprmoncfgd owns and reconciles
-- that directory; our own dir survives profile applies.
local state_dir = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/ultrawide-mode"
local function file_exists(p) local f = io.open(p, "r"); if f then f:close() return true end return false end
if file_exists(state_dir .. "/float-default.lua") then dofile(state_dir .. "/float-default.lua") end
if file_exists(state_dir .. "/single-window-aspect-ratio.lua") then dofile(state_dir .. "/single-window-aspect-ratio.lua") end
LUA

  # hyprland.lua: add the dofile include if missing (idempotent)
  if ! grep -q "ultrawide-mode.lua" "$hypr_user_conf" 2>/dev/null; then
    if [[ ! -f "$hypr_user_conf" ]]; then
      say "WARN: $hypr_user_conf not found — this doesn't look like an Omarchy Hyprland config."
      say "      Add manually:  dofile(os.getenv(\"HOME\") .. \"/.config/hypr/ultrawide-mode.lua\")"
    else
      printf '%s\n' \
        '' \
        '-- Ultrawide window-mode state (gdeyoung.ultrawide-bar plugin).' \
        'dofile((os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/ultrawide-mode.lua")' \
        >> "$hypr_user_conf"
    fi
  fi

  # Super+U binding (idempotent): raw append guarded by grep
  if [[ ! -f "$HOME/.config/hypr/bindings.lua" ]]; then
    say "WARN: ~/.config/hypr/bindings.lua not found — add manually:"
    say "      o.bind(\"SUPER + U\", \"Toggle window mode\", \"ultrawide-mode toggle\")"
  elif ! grep -q "ultrawide-mode toggle" "$HOME/.config/hypr/bindings.lua" 2>/dev/null; then
    printf '\n-- Window mode toggle (gdeyoung.ultrawide-bar plugin, --full install)\no.bind("SUPER + U", "Toggle window mode (float / tile+aspect)", "ultrawide-mode toggle")\n' >> "$HOME/.config/hypr/bindings.lua"
  fi

  # --- 5. optional: per-monitor workspaces backport ---------------------------
  # Omarchy quattro engine (default/hypr/monitor-workspaces.lua @ f61be3fd4009),
  # copied unmodified, plus a guarded hook that loads it and binds the quattro
  # workspace keys ONLY while the installed Omarchy lacks the engine. The day
  # the package ships it, the hook goes inert and the platform takes over
  # (same state file), and both files + the include line can be removed.
  if [[ -f "$repo_dir/hypr/monitor-workspaces.lua" && -f "$repo_dir/hypr/monitor-workspaces-hook.lua" ]]; then
    install -m 644 "$repo_dir/hypr/monitor-workspaces.lua" "$HOME/.config/hypr/monitor-workspaces.lua"
    install -m 644 "$repo_dir/hypr/monitor-workspaces-hook.lua" "$HOME/.config/hypr/monitor-workspaces-hook.lua"
    if ! grep -q "monitor-workspaces-hook" "$hypr_user_conf" 2>/dev/null; then
      if [[ ! -f "$hypr_user_conf" ]]; then
        say "WARN: $hypr_user_conf not found — add manually:"
        say "      dofile(\".../hypr/monitor-workspaces-hook.lua\")"
      else
        printf '%s\n' \
          '' \
          '-- Per-monitor workspaces backport (gdeyoung.ultrawide-bar plugin, --full install).' \
          'do local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/monitor-workspaces-hook.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end' \
          >> "$hypr_user_conf"
        say "per-monitor workspaces: installed (run: hyprctl reload)"
      fi
    fi
  else
    say "WARN: hypr/ missing from repo — per-monitor workspaces backport not installed"
  fi
fi

say ""
say "installed: $plugin_id"
say "  bar:   omarchy bar use $plugin_id   (already run)"
say "  width: ultrawide-bar-width <20-100>"
[[ "${1:-}" == "--full" ]] && say "  mode:  ultrawide-mode float|tile|off|status   (Super+U toggles)"
say "  undo:  omarchy bar reset; see README Remove section"
