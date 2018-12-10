cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # -std=c++11 instead of -std=gnu++11
set(CUCKOO_CXX_COMPILE_FEATURES cxx_generic_lambdas cxx_range_for cxx_strong_enums)

project(cmake_and_cuda LANGUAGES CXX CUDA)
 
include(CTest)

include_directories(${CMAKE_SOURCE_DIR}/src)

project(cuckoo_win_bundle)

add_library(cuckoo_win_bundle STATIC
	src/crypto/blake2b-ref.c
	src/windows/getopt.c
)
 
target_compile_features(cuckoo_win_bundle PUBLIC ${CUCKOO_CXX_COMPILE_FEATURES})
 
set_target_properties(cuckoo_win_bundle PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
set_target_properties(cuckoo_win_bundle PROPERTIES POSITION_INDEPENDENT_CODE ON)
 
add_executable(cuda29 src/cuckoo/mean.cu)
 
set_property(TARGET cuda29 PROPERTY CUDA_SEPARABLE_COMPILATION ON)
set_property(TARGET cuda29 PROPERTY POSITION_INDEPENDENT_CODE ON)
			 
target_link_libraries(cuda29 PRIVATE cuckoo_win_bundle)
