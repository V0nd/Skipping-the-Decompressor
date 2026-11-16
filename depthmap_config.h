#pragma once
//the real StreetView-Explorer Panorama.cpp allocates a fixed depth-map buffer:
//unsigned long length = 512 * 256 + 5000; (= 136072)
static const unsigned long DEPTH_MAP_CAP = 512UL * 256 + 5000;   // 136072
