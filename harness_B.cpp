#include <climits>
#include <cstdint>
#include <cstdlib>
#include <cstring>
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

#ifdef FIXED_BUFFER
        uint8_t *m = (uint8_t *)calloc(DEPTH_MAP_CAP, 1);
        if (!m) continue;
        size_t n = len < DEPTH_MAP_CAP ? len : DEPTH_MAP_CAP;
        memcpy(m, buf, n);
        parse_depth(m, DEPTH_MAP_CAP);
        free(m);
#else
        uint8_t *m = (uint8_t *)malloc(len ? len : 1);
        if (!m) continue;
        memcpy(m, buf, len);
        parse_depth(m, len);
        free(m);
#endif
    }
    return 0;
}
