#include "parse_depth.h"
#include <vector>
#include <cstring>

//Streetview-Explorer Panorama.cpp :: loadXML() original lines 517-533, faithful to the original
struct depthMapPlane { float x, y, z, d; };

void parse_depth(const uint8_t *depth_map, size_t len) {
    if (len < 8) return;

    const int headersize        = depth_map[0];
    const int numPanos          = depth_map[1] | (depth_map[2] << 8);
    const int mapWidth          = depth_map[3] | (depth_map[4] << 8);
    const int mapHeight         = depth_map[5] | (depth_map[6] << 8);
    const int panoIndicesOffset = depth_map[7];

    if (headersize != 8 || panoIndicesOffset != 8)
        return;   //original: throw "Unexpected depth map header"

    std::vector<unsigned char> depthmapIndices(mapHeight * mapWidth);
    memcpy(&depthmapIndices[0], &depth_map[panoIndicesOffset],
           mapHeight * mapWidth);

    std::vector<depthMapPlane> depthmapPlanes(numPanos);
    memcpy(&depthmapPlanes[0],
           &depth_map[panoIndicesOffset + mapHeight * mapWidth],
           numPanos * sizeof(depthMapPlane));
}
