#  -*- mode: cmake -*-

#
# Build TPL:  ZLIB 
#   
# --- Define all the directories and common external project flags
define_external_project_args(ZLIB
                             TARGET zlib
                             BUILD_IN_SOURCE)


# add version version to the autogenerated tpl_versions.h file
amanzi_tpl_version_write(FILENAME ${TPL_VERSIONS_INCLUDE_FILE}
  PREFIX ZLIB
  VERSION ${ZLIB_VERSION_MAJOR} ${ZLIB_VERSION_MINOR} ${ZLIB_VERSION_PATCH})
  
# --- Define the CMake configure parameters
# Note:
#      CMAKE_CACHE_ARGS requires -DVAR:<TYPE>=VALUE syntax
#      CMAKE_ARGS -DVAR=VALUE OK
# NO WHITESPACE between -D and VAR. Parser blows up otherwise.
set(ZLIB_CMAKE_CACHE_ARGS
                  -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
                  -DCMAKE_INSTALL_PREFIX:PATH=${TPL_INSTALL_PREFIX})

# --- Add external project build and tie to the ZLIB build target
ExternalProject_Add(${ZLIB_BUILD_TARGET}
                    DEPENDS   ${ZLIB_PACKAGE_DEPENDS}             # Package dependency target
                    TMP_DIR   ${ZLIB_tmp_dir}                     # Temporary files directory
                    STAMP_DIR ${ZLIB_stamp_dir}                   # Timestamp and log directory
                    # -- Download and URL definitions
                    DOWNLOAD_DIR ${TPL_DOWNLOAD_DIR}              # Download directory
                    URL          ${ZLIB_URL}                      # URL may be a web site OR a local file
                    URL_MD5      ${ZLIB_MD5_SUM}                  # md5sum of the archive file
                    # -- Configure
                    SOURCE_DIR       ${ZLIB_source_dir}
                    CMAKE_CACHE_ARGS ${AMANZI_CMAKE_CACHE_ARGS}   # Global definitions from root CMakeList
                                     ${ZLIB_CMAKE_CACHE_ARGS}
                                     -DCMAKE_C_FLAGS:STRING=${Amanzi_COMMON_CFLAGS}  # Ensure uniform build
                                     -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
                    # -- Build
                    BINARY_DIR       ${ZLIB_build_dir}            # Build directory 
                    BUILD_COMMAND    $(MAKE)                      # $(MAKE) enables parallel builds through make
                    BUILD_IN_SOURCE  ${ZLIB_BUILD_IN_SOURCE}      # Flag for in source builds
                    # -- Install
                    INSTALL_DIR      ${TPL_INSTALL_PREFIX}        # Install directory
                    # -- Output control
                    ${ZLIB_logging_args})

# --- Useful variables that depend on ZlIB (HDF5, NetCDF)
include(BuildLibraryName)
build_library_name(z ZLIB_LIBRARIES APPEND_PATH ${TPL_INSTALL_PREFIX}/lib)
set(ZLIB_DIR ${TPL_INSTALL_PREFIX})
set(ZLIB_INCLUDE_DIRS ${TPL_INSTALL_PREFIX}/include)

