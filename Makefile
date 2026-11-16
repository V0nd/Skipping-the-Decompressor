CXX    ?= clang++
AFLCXX ?= afl-clang-fast++
HDRS    = parse_depth.h depthmap_config.h

.PHONY: all clean

all: fuzz_A fuzz_B fuzz_B_fixed runone

#version A: through zlib, faithful fixed 136072 buffer
fuzz_A: parse_depth.cpp harness_A.cpp $(HDRS)
	AFL_USE_ASAN=1 $(AFLCXX) -g -O1 parse_depth.cpp harness_A.cpp -o fuzz_A -lz

#version B (tight): post-decompression, malloc(len), the abstraction under test
fuzz_B: parse_depth.cpp harness_B.cpp $(HDRS)
	AFL_USE_ASAN=1 $(AFLCXX) -g -O1 parse_depth.cpp harness_B.cpp -o fuzz_B

#version B (fixed): post-decompression, fixed 136072 buffer, faithful memory model
fuzz_B_fixed: parse_depth.cpp harness_B.cpp $(HDRS)
	AFL_USE_ASAN=1 $(AFLCXX) -g -O1 -DFIXED_BUFFER parse_depth.cpp harness_B.cpp -o fuzz_B_fixed


#standalone ASan repro
runone: parse_depth.cpp runone.cpp $(HDRS)
	$(CXX) -g -O0 -fsanitize=address parse_depth.cpp runone.cpp -o runone

clean:
	rm -f fuzz_A fuzz_B fuzz_B_fixed runone
