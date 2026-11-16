#pragma once
#include <cstddef>
#include <cstdint>
//carved depth-map parser, feed it the decompressed buffer
void parse_depth(const uint8_t *depth_map, size_t len);
