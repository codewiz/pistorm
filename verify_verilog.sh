#!/bin/bash
#
# Compile + run the pistorm testbench across every HOLD_CLOCKS variant with
# Icarus Verilog (no Quartus/Docker needed). Exits non-zero if any variant's
# testbench does not report PASSED. Run from anywhere.
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR/rtl"

rc=0
# default + shipped values (0/2/3) + 4 (old full-+2, A500-bad on HW but must
# still complete in sim - regression guard that the FSM never wedges).
for d in default 0 2 3 4; do
  if [ "$d" = default ]; then
    m="" ; label="default (ifndef -> 0)"
  else
    m="-DHOLD_CLOCKS=$d" ; label="HOLD_CLOCKS=$d"
  fi
  tb="$(mktemp)"
  iverilog -g2012 $m -o "$tb" pistorm_tb.v pistorm.v
  out="$(vvp "$tb" 2>&1 || true)"
  rm -f "$tb"
  if grep -q '==== PASSED ====' <<<"$out"; then
    echo "PASS  $label"
  else
    echo "FAIL  $label"
    echo "$out" | tail -20
    rc=1
  fi
done
exit $rc
