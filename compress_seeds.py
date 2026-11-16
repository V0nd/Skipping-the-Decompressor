#!/usr/bin/env python3

import pathlib
import zlib

def main() -> None:
    src_dir = pathlib.Path("seeds_raw")
    out_dir = pathlib.Path("seeds_compressed")
    out_dir.mkdir(exist_ok=True)

    raw = sorted(src_dir.glob("*.bin"))
    if not raw:
        print("no *.bin in seeds_raw/ -- run make_seeds.py first")
        return

    for p in raw:
        data = p.read_bytes()
        blob = zlib.compress(data, level=6)
        out = out_dir / (p.stem + ".z")
        out.write_bytes(blob)
        #confirm to the exact original
        assert zlib.decompress(blob) == data, f"round-trip mismatch for {p.name}"
        print(f"wrote {out}  ({len(data)} -> {len(blob)} bytes)")

if __name__ == "__main__":
    main()
