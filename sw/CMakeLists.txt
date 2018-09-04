cmake_minimum_required(VERSION 3.3.2)

include(GNUInstallDirs)

project(positarith)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "-Wall -Wextra -fext-numeric-literals")
# set(CMAKE_CXX_FLAGS_DEBUG "-g -DDEBUG=1 -DPOSIT_VERBOSE_OUTPUT")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

set(EXTERNAL_INSTALL_LOCATION ${CMAKE_BINARY_DIR}/external)

link_directories(${CMAKE_CURRENT_SOURCE_DIR}/build)

include(ExternalProject)
ExternalProject_Add(universal
        GIT_REPOSITORY https://github.com/lvandam/universal
        GIT_TAG master
        PREFIX ${EXTERNAL_INSTALL_LOCATION}
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_LOCATION}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        )

find_package(Boost REQUIRED system filesystem)
find_library(LIB_FLETCHER fletcher)
find_library(LIB_ARROW arrow)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../lib)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${LIB_FLETCHER_INCLUDE_DIRS})
include_directories(${LIB_ARROW_INCLUDE_DIRS})

include_directories(${EXTERNAL_INSTALL_LOCATION}/src/universal)

file(GLOB positarith_SRC
        "src/*.hpp"
        "src/*.cpp"
        )

find_package(OpenMP REQUIRED)
if (OPENMP_FOUND)
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()

message("Chose CAPI SNAP as run-time platform.")

if(NOT EXISTS "$ENV{SNAP_ROOT}")
message(FATAL_ERROR "Attempting to CMake with SNAP support, but SNAP_ROOT is not set. Please do something to fix that.")
endif()

set(PLATFORM_INCLUDE_DIRS ${PLATFORM_INCLUDE_DIRS} $ENV{SNAP_ROOT}/software/include)

find_library(LIB_SNAP snap HINTS $ENV{SNAP_ROOT}/software/lib)
message(STATUS "SNAP libsnap.so at: " ${LIB_SNAP})
set(LIB_PLATFORM ${LIB_SNAP})

# target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM=${RUNTIME_PLATFORM})

# target_link_libraries(${PROJECT_NAME}
#   ${REQUIRED}
#   ${LIB_FLETCHER}
#   ${LIB_ARROW}
#   ${LIB_PLATFORM}
# )

add_library(positarith SHARED
    src/positarith.cpp
    src/PositArithUserCore.cpp
    src/scheme.cpp
    src/utils.cpp
)

# add_executable(positarith ${positarith_SRC})
add_dependencies(positarith universal)

target_link_libraries(positarith
  ${REQUIRED}
  ${LIB_FLETCHER}
  ${LIB_ARROW}
  ${LIB_PLATFORM}
)

set_target_properties(positarith PROPERTIES VERSION 0.1)
set_target_properties(positarith PROPERTIES SOVERSION 1)
set_target_properties(positarith PROPERTIES PUBLIC_HEADER include/positarith.h)
target_include_directories(positarith PRIVATE include)
target_include_directories(positarith PRIVATE src)

install(TARGETS positarith
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

configure_file(positarith.pc.in positarith.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/positarith.pc DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/pkgconfig)
