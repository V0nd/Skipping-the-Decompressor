//reads a decompressed buffer from a file and parses it once,
//under a chosen buffer model, with plain ASan for a readable stack trace.
//
//   ./runone <file>          # fixed 136072 buffer (real program's model) [default]
//   ./runone <file> fixed    # explicit fixed model
//   ./runone <file> tight    # tight buffer sized to the file (abstraction model)

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include "parse_depth.h"
#include "depthmap_config.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <decompressed-file> [fixed|tight]\n", argv[0]);
        return 2;
    }
    bool tight = (argc >= 3 && std::string(argv[2]) == "tight");

    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror("fopen"); return 2; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    std::vector<uint8_t> in(n > 0 ? n : 0);
    if (n > 0 && fread(in.data(), 1, n, f) != (size_t)n) { perror("fread"); fclose(f); return 2; }
    fclose(f);

    if (tight) {
        uint8_t *m = (uint8_t *)malloc(in.size() ? in.size() : 1);
        memcpy(m, in.data(), in.size());
        parse_depth(m, in.size());                       //boundary at input length
        free(m);
        printf("parsed ok under TIGHT model (%ld bytes)\n", n);
    } else {
        uint8_t *m = (uint8_t *)calloc(DEPTH_MAP_CAP, 1);
        size_t c = in.size() < DEPTH_MAP_CAP ? in.size() : DEPTH_MAP_CAP;
        memcpy(m, in.data(), c);
        parse_depth(m, DEPTH_MAP_CAP);                   //boundary at 136072
        free(m);
        printf("parsed ok under FIXED model (%ld bytes into %lu-byte buffer)\n", n, DEPTH_MAP_CAP);
    }
    return 0;
}
