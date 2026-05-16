#!/bin/bash
#
# Build the PiStorm Zorro II hold-variant bitstreams for both CPLDs.
#
# Nhold = HOLD_CLOCKS = N half-c7m steps of extra S6 hold (see rtl/pistorm.v):
#   0hold stock   2hold +1 c7m (~long_hold)   3hold +1.5 c7m (~longer_hold)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC=pistorm            # source project basename (.qpf/.qsf)
REV=pistorm_build
FAMS=(EPM240 EPM570)
HOLDS=(0 2 3)          # HOLD_CLOCKS values = half-c7m steps
RESET=$'\033[0m'       # Quartus leaves the terminal recoloured; undo it

cd "$BASE_DIR/rtl"

# Temp project file = the real one with only the revision name swapped.
sed "s/^PROJECT_REVISION = .*/PROJECT_REVISION = \"$REV\"/" "$SRC.qpf" > "$REV.qpf"

for fam in "${FAMS[@]}"; do
  for n in "${HOLDS[@]}"; do
    svf="${fam}_${n}hold.svf"
    sed "s/^\(set_global_assignment -name DEVICE \).*/\1${fam}T100C5/" "$SRC.qsf" > "$REV.qsf"
    echo -e "\nset_global_assignment -name VERILOG_MACRO \"HOLD_CLOCKS=$n\"" >> "$REV.qsf"
    rm -rf db incremental_db output_files
    echo
    echo "${RESET}Building $svf.gz..."
    ../quartus_docker_run.sh quartus_sh --flow compile "$REV"
    ../quartus_docker_run.sh quartus_cpf -c -q 100KHz -g 3.3 -n p "output_files/$REV.pof" "$svf"
    gzip -f "$svf"
  done
done
