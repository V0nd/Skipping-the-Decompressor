#!/usr/bin/env python3
# layout:
#   byte 0      headersize        == 8   (guard: must be 8)
#   bytes 1-2   numPanos          little-endian
#   bytes 3-4   mapWidth          little-endian
#   bytes 5-6   mapHeight         little-endian
#   byte 7      panoIndicesOffset == 8   (guard: must be 8)
#   [8 ..]      mapWidth*mapHeight index bytes
#   [..]        numPanos * 16 plane bytes  (depthMapPlane = 4 floats)

import pathlib
import struct

PLANE_SIZE = 16  # sizeof(depthMapPlane)

DIMS = [
    # (numPanos, mapWidth, mapHeight)
    (1,  8,   8),
    (1,  16,  16),
    (2,  32,  16),
    (1,  64,  32),
    (3,  32,  32),
    (1,  128, 64),
]

def build(num_panos: int, map_w: int, map_h: int) -> bytes:
    header = bytes([
        8,                        # headersize
        num_panos & 0xFF, (num_panos >> 8) & 0xFF,
        map_w & 0xFF,     (map_w >> 8) & 0xFF,
        map_h & 0xFF,     (map_h >> 8) & 0xFF,
        8,                        # panoIndicesOffset
    ])
    indices = bytes((i & 0xFF) for i in range(map_w * map_h))
    #plane bytes: num_panos planes of 4 floats each; content is arbitrary
    planes = b"".join(
        struct.pack("<ffff", float(p), 0.0, 0.0, 1.0) for p in range(num_panos)
    )
    buf = header + indices + planes
    assert len(buf) == 8 + map_w * map_h + num_panos * PLANE_SIZE
    return buf

def main() -> None:
    out_dir = pathlib.Path("seeds_raw")
    out_dir.mkdir(exist_ok=True)
    for num_panos, map_w, map_h in DIMS:
        buf = build(num_panos, map_w, map_h)
        name = f"panos{num_panos}_{map_w}x{map_h}.bin"
        (out_dir / name).write_bytes(buf)
        print(f"wrote {out_dir / name}  ({len(buf)} bytes)")

if __name__ == "__main__":
    main()
