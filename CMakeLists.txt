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

# Find packages - vcpkg first, then pkg-config fallback
if(WIN32 AND MSVC)
    message(STATUS "=== Configuring for Windows MSVC build ===")
    
    # Use vcpkg packages on Windows
    find_package(PkgConfig QUIET)
    
    # Print vcpkg integration status
    if(CMAKE_TOOLCHAIN_FILE)
        message(STATUS "Using vcpkg toolchain: ${CMAKE_TOOLCHAIN_FILE}")
        if(VCPKG_TARGET_TRIPLET)
            message(STATUS "vcpkg target triplet: ${VCPKG_TARGET_TRIPLET}")
        endif()
    else()
        message(WARNING "No vcpkg toolchain file specified!")
    endif()
    
    # Try multiple package discovery methods for Cairo
    find_package(unofficial-cairo CONFIG QUIET)
    if(NOT unofficial-cairo_FOUND)
        find_package(cairo CONFIG QUIET)
    endif()
    if(NOT unofficial-cairo_FOUND AND NOT cairo_FOUND)
        find_package(Cairo QUIET)
    endif()
    
    # Try multiple package discovery methods for FreeType
    find_package(Freetype CONFIG QUIET)
    if(NOT Freetype_FOUND)
        find_package(freetype CONFIG QUIET)
    endif()
    
    # Set Cairo variables with multiple fallbacks
    if(unofficial-cairo_FOUND)
        set(CAIRO_LIBRARIES unofficial::cairo::cairo)
        set(CAIRO_FOUND TRUE)
        message(STATUS "✓ Found Cairo via vcpkg (unofficial): ${CAIRO_LIBRARIES}")
    elseif(cairo_FOUND)
        set(CAIRO_LIBRARIES cairo::cairo)
        set(CAIRO_FOUND TRUE)
        message(STATUS "✓ Found Cairo via vcpkg (cairo::cairo): ${CAIRO_LIBRARIES}")
    elseif(Cairo_FOUND)
        set(CAIRO_LIBRARIES Cairo::Cairo)
        set(CAIRO_FOUND TRUE)
        message(STATUS "✓ Found Cairo via vcpkg (Cairo::Cairo): ${CAIRO_LIBRARIES}")
    else()
        # Fallback to pkg-config if available
        if(PkgConfig_FOUND)
            pkg_check_modules(CAIRO QUIET cairo)
            if(CAIRO_FOUND)
                message(STATUS "✓ Found Cairo via pkg-config: ${CAIRO_LIBRARIES}")
            endif()
        endif()
        if(NOT CAIRO_FOUND)
            message(FATAL_ERROR "❌ Cairo not found! Install via: vcpkg install cairo:x64-windows or cairo:x64-windows-static")
        endif()
    endif()
    
    # Set FreeType variables with multiple fallbacks
    if(Freetype_FOUND)
        set(FREETYPE_LIBRARIES Freetype::Freetype)
        set(FREETYPE_FOUND TRUE)
        message(STATUS "✓ Found Freetype via vcpkg (Freetype::Freetype): ${FREETYPE_LIBRARIES}")
    elseif(freetype_FOUND)
        set(FREETYPE_LIBRARIES freetype::freetype)
        set(FREETYPE_FOUND TRUE)
        message(STATUS "✓ Found Freetype via vcpkg (freetype::freetype): ${FREETYPE_LIBRARIES}")
    else()
        # Fallback to pkg-config if available
        if(PkgConfig_FOUND)
            pkg_check_modules(FREETYPE QUIET freetype2)
            if(FREETYPE_FOUND)
                message(STATUS "✓ Found Freetype via pkg-config: ${FREETYPE_LIBRARIES}")
            endif()
        endif()
        if(NOT FREETYPE_FOUND)
            message(FATAL_ERROR "❌ FreeType not found! Install via: vcpkg install freetype:x64-windows or freetype:x64-windows-static")
        endif()
    endif()
else()
    # Use pkg-config on Unix systems
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(CAIRO REQUIRED cairo)
    pkg_check_modules(FREETYPE REQUIRED freetype2)
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

# Blackbox render executable (REQUIRED - graphics libraries must be available)
if(NOT CAIRO_FOUND OR NOT FREETYPE_FOUND)
    message(FATAL_ERROR "❌ CRITICAL: Graphics libraries are REQUIRED for blackbox_render.exe
    
Cairo found: ${CAIRO_FOUND}
FreeType found: ${FREETYPE_FOUND}

To fix this issue:
1. On Windows: Ensure vcpkg is properly integrated
   vcpkg install cairo:x64-windows freetype:x64-windows
   or
   vcpkg install cairo:x64-windows-static freetype:x64-windows-static

2. On Linux: sudo apt-get install libcairo2-dev libfreetype6-dev
3. On macOS: brew install cairo freetype

The build cannot continue without these dependencies.")
endif()

add_executable(blackbox_render ${RENDERER_SOURCES})
message(STATUS "✓ blackbox_render target created successfully")
    
# Link graphics libraries to renderer
if(TARGET unofficial::cairo::cairo)
    target_link_libraries(blackbox_render unofficial::cairo::cairo)
elseif(TARGET cairo::cairo)
    target_link_libraries(blackbox_render cairo::cairo)
elseif(TARGET Cairo::Cairo)
    target_link_libraries(blackbox_render Cairo::Cairo)
else()
    target_link_libraries(blackbox_render ${CAIRO_LIBRARIES})
    if(CAIRO_INCLUDE_DIRS)
        target_include_directories(blackbox_render PRIVATE ${CAIRO_INCLUDE_DIRS})
    endif()
    if(CAIRO_CFLAGS_OTHER)
        target_compile_options(blackbox_render PRIVATE ${CAIRO_CFLAGS_OTHER})
    endif()
endif()

if(TARGET Freetype::Freetype)
    target_link_libraries(blackbox_render Freetype::Freetype)
elseif(TARGET freetype::freetype)
    target_link_libraries(blackbox_render freetype::freetype)
else()
    target_link_libraries(blackbox_render ${FREETYPE_LIBRARIES})
    if(FREETYPE_INCLUDE_DIRS)
        target_include_directories(blackbox_render PRIVATE ${FREETYPE_INCLUDE_DIRS})
    endif()
    if(FREETYPE_CFLAGS_OTHER)
        target_compile_options(blackbox_render PRIVATE ${FREETYPE_CFLAGS_OTHER})
    endif()
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
