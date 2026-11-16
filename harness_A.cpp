#include <climits>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <zlib.h>
#include <unistd.h> 
#include "parse_depth.h"
#include "depthmap_config.h"

__AFL_FUZZ_INIT();

int main(void) {
#ifdef __AFL_HAVE_MANUAL_CONTROL
    __AFL_INIT();
#endif
    const uint8_t *buf = __AFL_FUZZ_TESTCASE_BUF;

    while (__AFL_LOOP(UINT_MAX)) {
        size_t len = __AFL_FUZZ_TESTCASE_LEN;

        //real program: vector<unsigned char> depth_map(136072), zero-initialised.
        uint8_t *depth_map = (uint8_t *)calloc(DEPTH_MAP_CAP, 1);
        if (!depth_map) continue;

        unsigned long outlen = DEPTH_MAP_CAP;
        int rc = uncompress(depth_map, &outlen, buf, len);

        if (rc == Z_OK) {
            parse_depth(depth_map, DEPTH_MAP_CAP);
        }
        free(depth_map);
    }
    return 0;
}
