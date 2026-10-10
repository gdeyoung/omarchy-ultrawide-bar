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

**Per-monitor widths**: `bar.widthByMonitor` overrides the global width per
screen — full-width on the laptop panel and 60% on a docked ultrawide at the
same time:

    { "bar": { "widthPercent": 100, "widthByMonitor": { "DP-1": 60 } } }

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
- **Size** — width, per-monitor width for the current screen, bar height
- **Behavior** — transparent bar, fullscreen auto-hide

Everything the popup writes is a documented shell.json key, so all of it is
also scriptable. Toggle it from a keybind too:

    omarchy-shell omarchy.bar toggleSettings

## Why a fork

The stock bar anchors both horizontal edges of its layer-shell surface —
full width is structural, not a setting. This fork un-anchors the left/right
edges when a partial width is requested; an explicit width then makes the
compositor center the surface. Everything else is upstream code, so rebasing
onto stock bar updates stays small.

## Window mode helper (--full installs)

`ultrawide-mode` switches between floating-everything (nice on a huge
ultrawide) and Omarchy's single-window 1:1 tiling:

    ultrawide-mode float [bar-width-%]   # everything floats; optional width
    ultrawide-mode tile                  # snap back to tiles + 1:1 aspect cap
    ultrawide-mode off                   # plain dwindle (default)
    ultrawide-mode status

Windows already floating before `float` ran (1Password popups, meeting
recorder, dialogs) are recorded as protected and never forced into tiles.
State lives in `~/.local/state/ultrawide-mode/` — deliberately outside
Omarchy's toggles dir, which the hyprmoncfg daemon reconciles.

`--full` also binds **Super+U** to toggle window mode. Hyprmoncfg users: the
per-profile `exec` carrier is split shellwords-style (no `&&`, no redirects) —
use `ultrawide-mode float 60` as the exec string.

## Works with Display+

The [**Display+** plugin](https://github.com/gdeyoung/omarchy-displayplus)
(gdeyoung.hyprmoncfg) can drive this bar: its Windows tab exposes a live width
slider and per-profile window mode when both plugins are installed. Neither
plugin requires the other; each works standalone.

## Install

    git clone https://github.com/gdeyoung/omarchy-ultrawide-bar.git
    cd omarchy-ultrawide-bar
    ./install.sh          # bar + width CLI
    # ./install.sh --full # + ultrawide-mode, Super+U, Hyprland include

Requires Omarchy 4.x with the Quickshell shell. No external dependencies
beyond Omarchy itself (hyprctl, jq, python3 — all in a stock install).

Then restart the shell: `omarchy restart shell`.

## Remove

Everything the installer touches, in reverse:

    ultrawide-bar-width 100                 # restore full width first
    omarchy bar reset                       # back to the stock bar
    rm -f ~/.local/bin/ultrawide-bar-width ~/.local/bin/ultrawide-mode
    rm -rf ~/.config/omarchy/plugins/gdeyoung.ultrawide-bar
    rm -f ~/.config/hypr/ultrawide-mode.lua
    rm -rf ~/.local/state/ultrawide-mode
    # then, if you ran --full, delete the two "ultrawide" lines from
    # ~/.config/hypr/hyprland.lua and the Super+U line from ~/.config/hypr/bindings.lua
    omarchy restart shell

## License

MIT — upstream code © Omarchy, modifications © Greg DeYoung.
See UPSTREAM-README.md for the original bar documentation.
