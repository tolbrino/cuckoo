EXECUTABLES = \
	mean29-generic \
	mean29-avx2 \
	lean29-generic \
	lean29-avx2 \
	mean15-generic \
	lean15-generic

BINEXECS = $(addprefix $(BIN)/, $(EXECUTABLES))

BIN = bin
CUCKOO = src/cuckoo

# This assumes the build runs under msys/mingw and with VS2017
CMAKE ?= /c/Program Files (x86)/Microsoft Visual Studio/2017/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe
CMAKE_BUILD_PATH ?= build
MSBUILD ?= /c/Program Files (x86)/Microsoft Visual Studio/2017/Community/MSBuild/15.0/Bin/MSBuild.exe

HDRS=$(CUCKOO)/cuckoo.h $(CUCKOO)/../crypto/siphash.h

# Flags from upstream makefile
OPT ?= -O3

GPP_ARCH_FLAGS ?= -m64 -x c++

# -Wno-deprecated-declarations shuts up Apple OSX clang
FLAGS ?= -Wall -Wno-format -Wno-deprecated-declarations -D_POSIX_C_SOURCE=200112L $(OPT) -DPREFETCH -I. $(CPPFLAGS) -pthread
GPP ?= g++ $(GPP_ARCH_FLAGS) -std=c++11 $(FLAGS)
BLAKE_2B_SRC ?= ../crypto/blake2b-ref.c
NVCC ?= nvcc -std=c++11

# end Flags from upstream

REPO = https://github.com/aeternity/cuckoo.git
COMMIT = a66b88ab8514b7232b1e148a4760f9258d5457f0

.PHONY: all
all: $(EXECUTABLES)
	@: # Silence the `Nothing to be done for 'all'.` message when running `make all`.

.PHONY: clean
clean:
	@if [ -d $(BIN) ]; then (cd $(BIN); rm -f $(EXECUTABLES)); fi
	@if [ -d $(CUCKOO) ]; then (cd $(CUCKOO); rm -f $(EXECUTABLES)); fi

.PHONY: distclean
distclean:
	rm -rf "${BIN}" "${CMAKE_BUILD_PATH}"

# We want rules also for cuda29/lcuda29
EXECUTABLES += lcuda29 cuda29

.SECONDEXPANSION:
.PHONY: $(EXECUTABLES)
$(EXECUTABLES): | $(BIN)
$(EXECUTABLES): $(CUCKOO)/$$@ $(BIN)/$$@

# One rule to copy them all
$(BINEXECS): $(CUCKOO)/$$(@F)
	cp $(CUCKOO)/$(@F) $(BIN)

# The args vary slightly so spell out the compilation rules
$(CUCKOO)/lean15-generic: $(HDRS) $(CUCKOO)/lean.hpp $(CUCKOO)/lean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DATOMIC -DEDGEBITS=15 lean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/lean29-generic: $(HDRS) $(CUCKOO)/lean.hpp $(CUCKOO)/lean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DATOMIC -DEDGEBITS=29 lean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/lean29-avx2: $(HDRS) $(CUCKOO)/lean.hpp $(CUCKOO)/lean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DATOMIC -mavx2 -DNSIPHASH=8 -DEDGEBITS=29 lean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/mean15-generic: $(HDRS) $(CUCKOO)/mean.hpp $(CUCKOO)/mean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DSAVEEDGES -DXBITS=0 -DNSIPHASH=1 -DEDGEBITS=15 mean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/mean29-generic: $(HDRS) $(CUCKOO)/mean.hpp $(CUCKOO)/mean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DSAVEEDGES -DNSIPHASH=1 -DEDGEBITS=29 mean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/mean29-avx2: $(HDRS) $(CUCKOO)/mean.hpp $(CUCKOO)/mean.cpp
	(cd $(CUCKOO); $(GPP) -o $(@F) -DSAVEEDGES -mavx2 -DNSIPHASH=8 -DEDGEBITS=29 mean.cpp $(BLAKE_2B_SRC))

$(CUCKOO)/lcuda29:	$(CUCKOO)/../crypto/siphash.cuh $(CUCKOO)/lean.cu
	(cd $(CUCKOO); $(NVCC) -o $(@F) -DEDGEBITS=29 -arch sm_35 lean.cu $(BLAKE_2B_SRC))

$(CUCKOO)/cuda29:		$(CUCKOO)/../crypto/siphash.cuh $(CUCKOO)/mean.cu
	(cd $(CUCKOO); $(NVCC) -o $(@F) -DEDGEBITS=29 -arch sm_35 mean.cu $(BLAKE_2B_SRC))

# Create the private dir
$(BIN):
	mkdir -p "$@"

$(CMAKE_BUILD_PATH):
	mkdir -p "$@"
	cd "$@" && \
		"${CMAKE}" -G "Visual Studio 15 Win64" -DCMAKE_CUDA_FLAGS="-arch=sm_35" ..

build_windows: MSBUILD_CONF=Debug
build_windows: ${CMAKE_BUILD_PATH}
	cd "${CMAKE_BUILD_PATH}" && \
		"${MSBUILD}" ALL_BUILD.vcxproj -p:Configuration=${MSBUILD_CONF} -p:Platform=x64
