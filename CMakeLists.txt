cmake_minimum_required(VERSION 3.15)
project(blackbox-tools VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set static linking for Windows MSVC
if(WIN32 AND MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MT")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
    
    # Add Windows-specific definitions
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-DWIN32)
    add_definitions(-D_WIN32)
endif()

# Find packages - simplified and reliable approach
if(WIN32 AND MSVC)
    message(STATUS "=== Windows MSVC Build with vcpkg ===")
    
    # Set required for graphics libraries - build MUST fail if not found
    find_package(PkgConfig QUIET)
    
    # Find Cairo - try the most common vcpkg target first
    find_package(unofficial-cairo CONFIG REQUIRED)
    set(CAIRO_FOUND TRUE)
    set(CAIRO_LIBRARIES unofficial::cairo::cairo)
    message(STATUS "✓ Cairo found: ${CAIRO_LIBRARIES}")
    
    # Find FreeType - try the most common vcpkg target first  
    find_package(Freetype REQUIRED)
    set(FREETYPE_FOUND TRUE)
    set(FREETYPE_LIBRARIES Freetype::Freetype)
    message(STATUS "✓ FreeType found: ${FREETYPE_LIBRARIES}")
    
else()
    # Use pkg-config on Unix systems
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(CAIRO REQUIRED cairo)
    pkg_check_modules(FREETYPE REQUIRED freetype2)
    message(STATUS "✓ Unix system - using pkg-config for graphics libraries")
endif()

message(STATUS "✓ All graphics dependencies resolved - blackbox_render will be built")

# Source files
set(COMMON_SOURCES
    src/parser.c
    src/tools.c
    src/platform.c
    src/stream.c
    src/decoders.c
    src/units.c
    src/blackbox_fielddefs.c
)

# Windows-specific sources
if(WIN32)
    list(APPEND COMMON_SOURCES lib/getopt_mb_uni/getopt.c)
    include_directories(lib/getopt_mb_uni)
endif()

# Decoder sources
set(DECODER_SOURCES
    ${COMMON_SOURCES}
    src/blackbox_decode.c
    src/gpxwriter.c
    src/imu.c
    src/battery.c
    src/stats.c
)

# Renderer sources
set(RENDERER_SOURCES
    ${COMMON_SOURCES}
    src/blackbox_render.c
    src/datapoints.c
    src/embeddedfont.c
    src/expo.c
    src/imu.c
)

# Encoder testbed sources
set(ENCODER_TESTBED_SOURCES
    ${COMMON_SOURCES}
    src/encoder_testbed.c
    src/encoder_testbed_io.c
)

# Include directories
include_directories(src)

# Blackbox decode executable
add_executable(blackbox_decode ${DECODER_SOURCES})

# Blackbox render executable - graphics libraries are required
add_executable(blackbox_render ${RENDERER_SOURCES})
message(STATUS "✓ blackbox_render target created")
    
# Link graphics libraries to renderer
if(WIN32 AND MSVC)
    # Windows with vcpkg
    target_link_libraries(blackbox_render ${CAIRO_LIBRARIES} ${FREETYPE_LIBRARIES})
    target_link_libraries(blackbox_render gdi32 user32 ole32 oleaut32 uuid)
else()
    # Unix systems with pkg-config
    target_link_libraries(blackbox_render ${CAIRO_LIBRARIES} ${FREETYPE_LIBRARIES})
    target_include_directories(blackbox_render PRIVATE ${CAIRO_INCLUDE_DIRS} ${FREETYPE_INCLUDE_DIRS})
    target_compile_options(blackbox_render PRIVATE ${CAIRO_CFLAGS_OTHER} ${FREETYPE_CFLAGS_OTHER})
endif()

message(STATUS "✓ blackbox_render linking configured")

# Encoder testbed executable
add_executable(encoder_testbed ${ENCODER_TESTBED_SOURCES})

# Common linking for all executables
if(WIN32 AND MSVC)
    # Windows system libraries
    target_link_libraries(blackbox_decode ws2_32)
    target_link_libraries(encoder_testbed ws2_32)
else()
    # Unix-like systems
    target_link_libraries(blackbox_decode m pthread)
    target_link_libraries(encoder_testbed m pthread)
    target_link_libraries(blackbox_render m pthread)
endif()

# Set output directory
set_target_properties(blackbox_decode encoder_testbed blackbox_render PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Version information
if(BLACKBOX_VERSION)
    target_compile_definitions(blackbox_decode PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
    target_compile_definitions(encoder_testbed PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
    target_compile_definitions(blackbox_render PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
endif()
