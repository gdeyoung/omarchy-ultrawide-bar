#!/usr/bin/env bash
# Runs WorkspacesModel.js helpers under node: monitor ordering, visible slots,
# labels, markup stripping, and the engine state-file block lookup.
# Cases ported from vladgabrielboca/omarchy-monitor-workspaces model-test.sh
# (@ 3ae76b2) with gdeyoung.ultrawide-bar additions.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v node >/dev/null || { echo "SKIP: node not installed"; exit 0; }
node - "$ROOT/widget/WorkspacesModel.js" <<'JS'
const fs = require("fs")
const src = fs.readFileSync(process.argv[2], "utf8")
const M = new Function(src + "; return { BLOCK, ALWAYS_SHOWN, firstWorkspace, visibleIds, slotLabel, plain, parseBlocks, builtinFirst }")()
const assert = require("assert")

// -- position-order fallback (no engine state file) --
const monitors = [
  { name: "DP-1", x: 1920, y: -140 },
  { name: "DP-2", x: 0, y: 0 },
  { name: "HDMI-A-1", x: 4480, y: 0 },
  { name: "MIRROR", x: -5000, y: 0, mirror: true },
]
assert.strictEqual(M.firstWorkspace(monitors, "DP-2"), 1)
assert.strictEqual(M.firstWorkspace(monitors, "DP-1"), 11)
assert.strictEqual(M.firstWorkspace(monitors, "HDMI-A-1"), 21)
assert.strictEqual(M.firstWorkspace(monitors, "unknown"), 1)

// -- visible slots --
assert.deepStrictEqual(M.visibleIds(11, [1, 12, 18, 20, 21]), [11, 12, 13, 14, 15, 18, 20])
// A workspace left over from an unplugged monitor is shown after the block.
assert.deepStrictEqual(M.visibleIds(11, [1, 11, 22], [11, 22, -98]), [11, 12, 13, 14, 15, 22])
// Single monitor, fresh boot: exactly the stock widget's 1..5.
assert.deepStrictEqual(M.visibleIds(1, [1], []), [1, 2, 3, 4, 5])

// -- slot labels --
assert.strictEqual(M.slotLabel(11, 22), "(2)")
assert.strictEqual(M.slotLabel(1, 30), "(0)")
assert.strictEqual(M.slotLabel(11, 12), "2")
assert.strictEqual(M.slotLabel(11, 20), "0")
assert.strictEqual(M.slotLabel(11, 3), "(3)")

// -- markup stripping --
assert.strictEqual(M.plain('<img src="https://example.invalid/x">DP-1'), "img src=https://example.invalid/xDP-1")

// -- engine state file, as default/hypr/monitor-workspaces.lua writes it --
const blocks = M.parseBlocks("0\tDP-1\tGIGA-BYTE M27Q3 0x01\n1\tDP-2\tASUS VG248 J9L\nbad line\nx\tHDMI-A-1\tY\n")
assert.deepStrictEqual(blocks, { "DP-1": 0, "DP-2": 1 })
assert.strictEqual(M.builtinFirst(blocks, "DP-2", 1), 11)
assert.strictEqual(M.builtinFirst(blocks, "DP-1", 3), 1)
// Before the file exists, the shown workspace decides.
assert.strictEqual(M.builtinFirst({}, "DP-1", 13), 11)
assert.strictEqual(M.builtinFirst({}, "DP-1", -1), 1)
// The G9 docked right of the laptop panel: second block.
assert.strictEqual(M.builtinFirst({ "eDP-1": 0, "HDMI-A-2": 1 }, "HDMI-A-2", 11), 11)
assert.strictEqual(M.slotLabel(11, 11), "1")

console.log("ok")
JS
