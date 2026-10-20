-- Per-monitor workspaces hook (gdeyoung.ultrawide-bar).
--
-- Loads Omarchy's per-monitor workspaces engine as a backport while the
-- installed Omarchy (4.0.4) lacks it, and binds the workspace keys exactly the
-- way the quattro release binds them, so this machine behaves like the
-- upcoming platform default today.
--
--   Engine:  omacom/omarchy default/hypr/monitor-workspaces.lua
--            @ f61be3fd4009 (2026-10-18), copied unmodified to
--            ~/.config/hypr/monitor-workspaces.lua
--   Keys:    quattro default/hypr/bindings/tiling.lua pattern
--
-- When the Omarchy package ships its own engine, the guard below turns this
-- whole hook inert and the platform's engine and bindings take over. The
-- state file format is identical, so monitors keep their blocks across the
-- handoff. After that, remove this file and its include line (README Remove).

-- The platform owns per-monitor workspaces from here on: stand down.
local shipped = io.open((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy")
  .. "/default/hypr/monitor-workspaces.lua", "r")
if shipped then
  shipped:close()
  return
end

-- quattro helpers.lua API (o.bind_expressions = {}), absent in 4.0.4.
-- No-op once the package ships it.
o.bind_expressions = o.bind_expressions or {}

-- Load the engine once per Lua state: config reloads re-run this hook, and a
-- bare dofile would stack a fresh set of hl.on handlers per reload.
if not (type(o.workspaces) == "table" and type(o.workspaces.reconcile) == "function") then
  dofile((os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config")
    .. "/hypr/monitor-workspaces.lua")
end

-- Each monitor owns a block of ten workspaces; SUPER+N acts on the focused
-- monitor's block. Same chords as 4.0.4, quattro semantics (bindings/tiling.lua).
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace .. " on this monitor", o.workspaces.focus(workspace))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace .. " on this monitor", o.workspaces.move_window(workspace))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace .. " on this monitor", o.workspaces.move_window(workspace, false))
end

-- Monitor-direction chords: same SUPER+SHIFT+ALT+arrow chords as 4.0.4, now
-- block-aware, plus SUPER+SHIFT+CTRL+arrows for the window, as quattro binds
-- them. Single monitor: silent no-op (the engine checks the direction).
for _, direction in ipairs({ "l", "r", "u", "d" }) do
  local name = ({ l = "left", r = "right", u = "up", d = "down" })[direction]
  hl.unbind("SUPER + SHIFT + ALT + " .. name:upper())
  o.bind("SUPER + SHIFT + ALT + " .. name:upper(), "Move workspace to " .. name .. " monitor", o.workspaces.move_to_monitor(direction))
  hl.unbind("SUPER + SHIFT + CTRL + " .. name:upper())
  o.bind("SUPER + SHIFT + CTRL + " .. name:upper(), "Move window to " .. name .. " monitor", o.workspaces.move_window_to_monitor(direction))
end
