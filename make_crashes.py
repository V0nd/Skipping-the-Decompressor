#!/usr/bin/env python3
#   crash_manufactured.bin: mapWidth*mapHeight = 65536, in a 2072-byte body.
#       Overreads a TIGHT buffer (fires at 2072) but is in bound in the real
#       136072-byte buffer (8 + 65536 = 65544 < 136072). => tight crash, fixed clean.
#
#   crash_real.bin: mapWidth=mapHeight=512 -> product 262144.
#       8 + 262144 = 262152 > 136072, so it overreads the real fixed buffer too.
#       => crashes under both tight and fixed models

import pathlib, struct

CAP = 512 * 256 + 5000        # 136072
PLANE = 16

def header(num_panos, w, h):
    return bytes([8,
                  num_panos & 0xFF, (num_panos >> 8) & 0xFF,
                  w & 0xFF, (w >> 8) & 0xFF,
                  h & 0xFF, (h >> 8) & 0xFF,
                  8])

#manufactured: valid 64x32 body (2072 bytes) but header lies: mapHeight=1024 ---
w, h, np_ = 64, 32, 1
body = header(np_, w, h)
body = header(np_, w, 1024)                   #claim 1024 rows, which is a lie
body += bytes((i & 0xFF) for i in range(w * h))          #only 64*32 index bytes present
body += b"".join(struct.pack("<ffff", float(p), 0, 0, 1) for p in range(np_))
pathlib.Path("crash_manufactured.bin").write_bytes(body)
print(f"crash_manufactured.bin: {len(body)} bytes, header claims {w}x1024 "
      f"(product {w*1024} -> in bounds of {CAP}, over bounds of {len(body)})")

#real: header claims 512x512, overflows even the fixed 136072 buffer
real = header(1, 512, 512)                    # product 262144 > 136064
pathlib.Path("crash_real.bin").write_bytes(real)
print(f"crash_real.bin: {len(real)} bytes, header claims 512x512 "
      f"(product {512*512} -> over bounds of {CAP})")
