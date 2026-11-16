# Skipping the Decompressor

Harness abstraction and crash fidelity in decompress-then-parse fuzzing.

This project fuzzes a carved Street View depth-map parser with three AFL++
harnesses to measure how **skipping decompression** and **buffer sizing** affect
which crashes are found and whether they are real.

| Harness | Decode | Buffer | Role |
|---|---|---|---|
| `fuzz_A` | through zlib | real 136,072 B | faithful reference |
| `fuzz_B` | skipped | tight `malloc(len)` | the abstraction under test |
| `fuzz_B_fixed` | skipped | real 136,072 B | faithful post-decompression |

## Requirements

- Docker Desktop (with WSL2 integration if on Windows).
- Keep the project on a Linux filesystem (WSL `~/...`, not `/mnt/c`) — AFL++
  does heavy file I/O and the Windows bridge is very slow.

## Build the image

```bash
docker build -t skipd .
```

## Run the container

AFL++ needs the crash handler set on the host, once per boot:

```bash
echo core | sudo tee /proc/sys/kernel/core_pattern   # on the WSL host, not in the container
```

Then start the container (your folder is mounted live, so edits need no rebuild):

```bash
docker run -it --rm -v "$PWD":/skipd -w /skipd \
  --security-opt seccomp=unconfined --cap-add=SYS_PTRACE skipd
```

Everything below runs **inside** the container.

## Build the binaries

```bash
make
```

## Sanity check (known-answer test)

```bash
./runone crash_manufactured.bin tight    # expect: CRASH
./runone crash_manufactured.bin fixed    # expect: CLEAN
./runone crash_real.bin        fixed     # expect: CRASH
```

## Fuzz

```bash
./run.sh smoke              # 60 s per harness — quick check
./run.sh campaign 3600 5    # 1 hour per harness, 5 repeats
```

Crashes are saved live to `out_<harness>_r<n>/default/crashes/`, and crash
counts are written to `results.csv`.

## Classify the crashes

```bash
./triage.sh
```

Reproduces every crash under the real (fixed) and tight buffer models, labels
each **REAL** or **MANUFACTURED**, and writes `triage.csv`.

## Repository layout

```
parse_depth.{cpp,h}     carved parser (the vulnerability)
depthmap_config.h       the real 136,072-byte buffer constant
harness_A.cpp           through-zlib harness
harness_B.cpp           post-decompression harness (tight / -DFIXED_BUFFER)
runone.cpp              standalone reproducer (fixed | tight)
make_seeds.py           generate the seed corpus
compress_seeds.py       zlib-compress seeds for Harness A
make_crashes.py         generate the known-answer crash pair
Makefile  run.sh  triage.sh  Dockerfile
seeds_raw/  seeds_compressed/   fuzzing seed corpus
```

Built binaries and `out_*/` campaign output are not tracked (see `.gitignore`).
