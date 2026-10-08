# Ultrawide Bar (gdeyoung.ultrawide-bar)

Fork of the stock Omarchy bar with an **opt-in partial width**, for ultrawide
monitors where a full-width bar puts widgets several feet apart.

## What it changes

Nothing, by default. At `widthPercent: 100` (or unset) it is behaviorally
identical to the stock `omarchy.bar` — same anchoring, same exclusion strip,
same rendering.

Set `bar.widthPercent` in `~/.config/omarchy/shell.json` to shrink the bar to
that fraction of screen width, **centered on the screen's horizontal
midpoint**: at 50%, 25% of the screen on each side of center is bar-free.

    { "bar": { "widthPercent": 60 } }

Or from the CLI (writes the same key, live reloads):

    omarchy bar use gdeyoung.ultrawide-bar
    ultrawide-bar-width 60

Range is clamped to 20-100. Vertical bars ignore it.

## Why a fork

The stock bar anchors both horizontal edges of its layer-shell surface —
full width is structural, not a setting. This fork un-anchors the left/right
edges when a partial width is requested; an explicit width then makes the
compositor center the surface. Everything else is upstream code, so rebasing
onto stock bar updates stays small.

## Undo

    ultrawide-bar-width 100   # full width again
    omarchy bar reset         # back to the stock bar entirely

The `widthPercent` key is ignored by the stock bar, so switching bars never
leaves stale behavior behind.

## License

MIT — upstream code © Omarchy, modifications © Greg DeYoung.
See UPSTREAM-README.md for the original bar documentation.
