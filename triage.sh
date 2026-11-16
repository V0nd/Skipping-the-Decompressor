#!/usr/bin/env bash
# Classify and dedup AFL++ crashes
#
# For each saved crash, reproduce it under runone's fixed (real-program) buffer model
# and, if clean there, under the tight model. Verdict per crash:
#   REAL          crashes the faithful 136072-byte model -> a genuine bug
#   MANUFACTURED  clean under fixed, crashes only the tight buffer -> abstraction artifact
#   NO_REPRO      neither reproduces it
#   TOOL_ERROR    runone failed to run (e.g. missing ASan runtime) -- NOT counted as a crash
#   DECOMP_FAIL   a Harness-A (compressed) crash could not be decompressed
#
# Output: triage.csv (one row per crash) + printed summary tables.
set -uo pipefail

[ -x ./runone ] || { echo "build runone first:  make runone"; exit 1; }

# fail loudly if we cannot write the output, instead of running on stale data
if ! : > triage.csv 2>/dev/null; then
    echo "ERROR: cannot write triage.csv (permission?). Fix ownership and re-run:"
    echo "  sudo chown \$USER:\$USER triage.csv  (or: sudo rm -f triage.csv)"
    exit 1
fi

classify() {   # $1=decompressed-crash-file  $2=fixed|tight
    local out
    out=$(ASAN_OPTIONS=detect_leaks=0 ./runone "$1" "$2" 2>&1)
    if printf '%s' "$out" | grep -q "parsed ok"; then
        echo "CLEAN"
    elif printf '%s' "$out" | grep -q "AddressSanitizer"; then   #a real ASan crash
        local site
        site=$(printf '%s' "$out" | grep -oE 'parse_depth\.cpp:[0-9]+' | head -1)
        echo "CRASH:${site:-unknown}"
    else
        echo "TOOLERR"                                           #runone didn't run
    fi
}

echo "harness,crash_file,verdict,site" > triage.csv
shopt -s nullglob
for f in out_*/default/crashes/id:*; do
    harness=${f%%/*}
    input="$f"
    tmp=""

    #harness A crashes are compressed, they first need decompression
    if [[ $harness == *_A_* ]]; then
        tmp=$(mktemp)
        if python3 -c "import zlib,sys; open(sys.argv[2],'wb').write(zlib.decompress(open(sys.argv[1],'rb').read()))" "$f" "$tmp" 2>/dev/null; then
            input="$tmp"
        else
            echo "$harness,\"$(basename "$f")\",DECOMP_FAIL,-" >> triage.csv
            rm -f "$tmp"; continue
        fi
    fi

    fx=$(classify "$input" fixed)
    if [[ $fx == CRASH:* ]]; then
        verdict=REAL;        site=${fx#CRASH:}
    elif [[ $fx == TOOLERR ]]; then
        verdict=TOOL_ERROR;  site="-"
    else
        tt=$(classify "$input" tight)
        if   [[ $tt == CRASH:* ]];  then verdict=MANUFACTURED; site=${tt#CRASH:}
        elif [[ $tt == TOOLERR ]];  then verdict=TOOL_ERROR;   site="-"
        else                             verdict=NO_REPRO;     site="-"; fi
    fi
    echo "$harness,\"$(basename "$f")\",$verdict,$site" >> triage.csv
    [ -n "$tmp" ] && rm -f "$tmp"
done

#abort if the tool was broken
if grep -q ',TOOL_ERROR,' triage.csv; then
    echo "WARNING: some crashes returned TOOL_ERROR -- runone did not execute properly."
    echo "         Fix runone (e.g. rebuild with clang++, or install libasan) and re-run."
fi

echo
echo "=== per-harness summary (crash files) ==="
awk -F, 'NR>1{t[$1]++; v[$1"|"$(NF-1)]++}
END{ for(h in t) printf "%-26s total=%-4d REAL=%-4d MANUF=%-4d NOREPRO=%-3d TOOLERR=%-3d\n",
       h, t[h], v[h"|REAL"]+0, v[h"|MANUFACTURED"]+0, v[h"|NO_REPRO"]+0, v[h"|TOOL_ERROR"]+0 }' triage.csv | sort

echo
echo "=== unique bugs (verdict + source site), deduped across all crashes ==="
awk -F, 'NR>1{k=sprintf("%-13s %s",$(NF-1),$NF); c[k]++} END{for(k in c) printf "  %s  x%d\n", k, c[k]}' triage.csv | sort

echo
echo "=== RQ2 headline: fidelity of the tight post-decompression harness ==="
awk -F, 'NR>1 && $1 ~ /_B_r/ {n++; if($(NF-1)=="MANUFACTURED") m++}
END{ if(n) printf "  tight-B crashes: %d total, %d manufactured (%.0f%% could not occur in the real program)\n", n, m+0, 100*(m+0)/n; else print "  (no tight-B crashes found)" }' triage.csv

echo
echo "full per-crash detail -> triage.csv"