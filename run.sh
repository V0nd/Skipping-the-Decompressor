#   ./run.sh smoke                  # 60s each -- sanity-check the setup
#   ./run.sh campaign N x           # N = seconds per fuzz run (default 3600), x = repeats (default 1)
set -uo pipefail

MODE="${1:-smoke}"
DURATION=60; REPEATS=1
if [ "$MODE" = "campaign" ]; then DURATION="${2:-3600}"; REPEATS="${3:-1}"; fi
CORE=0

export AFL_SKIP_CPUFREQ=1
export ASAN_OPTIONS="abort_on_error=1:detect_leaks=0:symbolize=0"

CP="$(cat /proc/sys/kernel/core_pattern 2>/dev/null || echo '?')"
if [ "${CP:0:1}" = "|" ]; then
  echo "!! core_pattern is piped ('$CP'). On the WSL host run, once:"
  echo "!!   echo core | sudo tee /proc/sys/kernel/core_pattern"
  export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
fi

echo "== building =="
make clean && make fuzz_A fuzz_B fuzz_B_fixed || { echo "build failed"; exit 1; }

CONFIGS="fuzz_B:seeds_raw fuzz_B_fixed:seeds_raw fuzz_A:seeds_compressed"
echo "harness,run,crashes" > results.csv

for r in $(seq 1 "$REPEATS"); do
  for cfg in $CONFIGS; do
    H="${cfg%%:*}"; SEEDS="${cfg##*:}"; OUT="out_${H}_r${r}"
    echo "== ${H} (run ${r}/${REPEATS}), ${DURATION}s on core ${CORE}, seeds=${SEEDS} =="
    timeout "${DURATION}" afl-fuzz -m none -b "${CORE}" -i "${SEEDS}" -o "${OUT}" -- "./${H}" || true
    c=$(ls "${OUT}/default/crashes" 2>/dev/null | grep -c '^id:' || true)
    printf '%s,%s,%s\n' "${H}" "${r}" "${c:-0}" >> results.csv
  done
done

echo "== done. crash counts: =="
cat results.csv
