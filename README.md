# Ultrawide Bar (gdeyoung.ultrawide-bar)

Fork of the stock Omarchy bar built for ultrawide monitors — partial-width
centered bar, per-monitor geometry, height control, fullscreen auto-hide with
edge-peek, and a built-in settings popup.

## What it changes

Nothing, by default. At `widthPercent: 100` (or unset) it is behaviorally
identical to the stock `omarchy.bar` — same anchoring, same exclusion strip,
same rendering.

### Width

Set `bar.widthPercent` in `~/.config/omarchy/shell.json` to shrink the bar to
that fraction of screen width, **centered on the screen's horizontal
midpoint**: at 50%, 25% of the screen on each side of center is bar-free.

    { "bar": { "widthPercent": 60 } }

Or from the CLI (writes the same key, live reloads):

    ultrawide-bar-width 60

Range is clamped to 20–100. Vertical bars ignore it.

**Per-monitor widths and heights**: `bar.widthByMonitor` /
`bar.heightByMonitor` override the global width and height per screen —
full-width 26px bar on the laptop panel, 60% 40px bar on a docked ultrawide,
at the same time:

    { "bar": { "widthPercent": 100, "widthByMonitor": { "DP-1": 60 },
               "heightByMonitor": { "DP-1": 40 } } }

### Height

`bar.barHeight` sets bar thickness in pixels (16–64), for big monitors where
the 26px default feels thin — or small screens where every pixel counts:

    { "bar": { "barHeight": 40 } }

Unset = theme default (26px horizontal / 28px vertical).

### Fullscreen auto-hide with edge-peek

Always on for partial-width bars: when a window on the bar's screen goes
truly fullscreen, the bar parks itself leaving a 2-pixel strip at the screen
edge and drops its exclusion zone so the window owns the whole display. Move
the pointer to that edge strip and the bar slides back in as an overlay (the
fullscreen window keeps its space); move away and it re-parks. Maximized
windows do **not** trigger it — only real fullscreen. At 100% width the
stock behavior (bar drawn over fullscreen) is unchanged unless
`bar.fullscreenAutoHide` is set.

### Settings popup

**Right-click empty bar space** (or click the hover-revealed gear at the end
of the indicator group, left of the clock) for a themed settings panel:

- **Position** — top / bottom / left / right
- **Size** — width, per-monitor width, bar height, per-monitor height
- **Behavior** — transparent bar, fullscreen auto-hide

Everything the popup writes is a documented shell.json key, so all of it is
also scriptable. Toggle it from a keybind too:

    omarchy-shell omarchy.bar toggleSettings

### Per-monitor workspaces widget

Ships the bar's Workspaces widget as its own plugin, `gdeyoung.workspaces`
(the `omarchy.*` widget namespace is reserved for first-party plugins); it
replaces the stock widget in the bar. Every monitor gets its own workspaces
1–10: `Super+1..0` acts on the monitor you're on, and each monitor's bar
shows only its own block, labeled 1–9, 0, lit while that monitor has focus.

Since Omarchy 4.5 the per-monitor engine is **native** — the widget reads the
platform's own `~/.local/state/omarchy/monitor-workspaces` block file
directly. Window rules that name a workspace number use the real id: `15` is
the second monitor's 5. (Pre-4.5 this fork also backported the engine via
`hypr/` files behind a `--full` install path; v1.4.1 removed both. Modeled on
[vladgabrielboca/omarchy-monitor-workspaces](https://github.com/vladgabrielboca/omarchy-monitor-workspaces)
and [omacom/omarchy#10372](https://github.com/omacom/omarchy/issues/10372).)

## Why a fork

The stock bar anchors both horizontal edges of its layer-shell surface —
full width is structural, not a setting. This fork un-anchors the left/right
edges when a partial width is requested; an explicit width then makes the
compositor center the surface. Everything else is upstream code, so rebasing
onto stock bar updates stays small.

## Works with Display+

The [**Display+** plugin](https://github.com/gdeyoung/omarchy-displayplus)
(gdeyoung.hyprmoncfg) can drive this bar: its Windows tab exposes a live width
slider when both plugins are installed. Neither
plugin requires the other; each works standalone.

## Install

    git clone https://github.com/gdeyoung/omarchy-ultrawide-bar.git
    cd omarchy-ultrawide-bar
    ./install.sh          # bar + width CLI + workspaces widget

Requires Omarchy 4.x with the Quickshell shell. No external dependencies
beyond Omarchy itself (hyprctl, jq, python3 — all in a stock install).

Then restart the shell: `omarchy restart shell`.

## What this plugin runs

No sudo, no network calls, no package installs. Everything stays in
`~/.config` and `~/.local`:

| Piece | What it executes |
| --- | --- |
| `install.sh` | `cp` of QML files, `omarchy plugin enable/add`, `omarchy bar use`, one PATH symlink |
| Bar + widgets (Quickshell) | Hyprland IPC via Quickshell's Hyprland service; reads `~/.local/state/omarchy/monitor-workspaces` (plain text); width/height settings via `omarchy bar set` |
| `bin/ultrawide-bar-width` | `hyprctl`/`jq` one-shot writing the bar width key |

## Remove

Everything the installer touches, in reverse:

    ultrawide-bar-width 100                 # restore full width first
    omarchy bar reset                       # back to the stock bar
    rm -f ~/.local/bin/ultrawide-bar-width
    rm -rf ~/.config/omarchy/plugins/gdeyoung.ultrawide-bar
    # companion widget: back to the stock workspaces widget
    omarchy plugin enable omarchy.workspaces
    omarchy plugin remove gdeyoung.workspaces --yes
    omarchy bar put omarchy.workspaces --after omarchy.menu
    omarchy restart shell

Legacy residue from ≤1.4.0 `--full` installs (window-mode helper and the
pre-4.5 workspaces backport — both superseded by Omarchy 4.5's native
floating workspaces and per-monitor engine):

    rm -f ~/.local/bin/ultrawide-mode ~/.config/hypr/ultrawide-mode.lua
    rm -rf ~/.local/state/ultrawide-mode
    rm -f ~/.config/hypr/monitor-workspaces.lua ~/.config/hypr/monitor-workspaces-hook.lua
    # delete the "ultrawide"/"monitor-workspaces" include lines from
    # ~/.config/hypr/hyprland.lua and the Super+U line from
    # ~/.config/hypr/bindings.lua, then: hyprctl reload

## License

MIT — upstream code © Omarchy, modifications © Greg DeYoung.
See UPSTREAM-README.md for the original bar documentation.
