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
endif()

# Find packages using vcpkg
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(CAIRO QUIET cairo)
    pkg_check_modules(FREETYPE QUIET freetype2)
endif()

# Fallback to find_package for vcpkg
if(NOT CAIRO_FOUND)
    find_package(unofficial-cairo QUIET)
    if(unofficial-cairo_FOUND)
        set(CAIRO_LIBRARIES unofficial::cairo::cairo)
        set(CAIRO_FOUND TRUE)
    endif()
endif()

if(NOT FREETYPE_FOUND)
    find_package(Freetype QUIET)
    if(Freetype_FOUND)
        set(FREETYPE_LIBRARIES Freetype::Freetype)
        set(FREETYPE_FOUND TRUE)
    endif()
endif()

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

# Blackbox render executable (only if graphics libraries are found)
if(CAIRO_FOUND AND FREETYPE_FOUND)
    add_executable(blackbox_render ${RENDERER_SOURCES})
    
    # Link graphics libraries to renderer
    if(TARGET unofficial::cairo::cairo)
        target_link_libraries(blackbox_render unofficial::cairo::cairo)
    else()
        target_link_libraries(blackbox_render ${CAIRO_LIBRARIES})
        target_include_directories(blackbox_render PRIVATE ${CAIRO_INCLUDE_DIRS})
        target_compile_options(blackbox_render PRIVATE ${CAIRO_CFLAGS_OTHER})
    endif()
    
    if(TARGET Freetype::Freetype)
        target_link_libraries(blackbox_render Freetype::Freetype)
    else()
        target_link_libraries(blackbox_render ${FREETYPE_LIBRARIES})
        target_include_directories(blackbox_render PRIVATE ${FREETYPE_INCLUDE_DIRS})
        target_compile_options(blackbox_render PRIVATE ${FREETYPE_CFLAGS_OTHER})
    endif()
    
    # Windows-specific linking for renderer
    if(WIN32 AND MSVC)
        target_link_libraries(blackbox_render 
            gdi32 
            user32
            ole32 
            oleaut32 
            uuid
        )
    endif()
else()
    message(WARNING "Graphics libraries (Cairo/FreeType) not found. Renderer will not be built.")
endif()

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
    if(TARGET blackbox_render)
        target_link_libraries(blackbox_render m pthread)
    endif()
endif()

# Set output directory
set_target_properties(blackbox_decode encoder_testbed PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

if(TARGET blackbox_render)
    set_target_properties(blackbox_render PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    )
endif()

# Version information
if(BLACKBOX_VERSION)
    target_compile_definitions(blackbox_decode PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
    target_compile_definitions(encoder_testbed PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
    if(TARGET blackbox_render)
        target_compile_definitions(blackbox_render PRIVATE BLACKBOX_VERSION=${BLACKBOX_VERSION})
    endif()
endif()
