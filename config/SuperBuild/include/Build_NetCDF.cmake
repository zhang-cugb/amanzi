#  -*- mode: cmake -*-

#
# Build TPL: NetCDF 
# 

# --- Define all the directories and common external project flags
define_external_project_args(NetCDF 
                             TARGET netcdf
                             DEPENDS ${MPI_PROJECT} CURL
                            )

# add version version to the autogenerated tpl_versions.h file
amanzi_tpl_version_write(FILENAME ${TPL_VERSIONS_INCLUDE_FILE}
  PREFIX NetCDF
  VERSION ${NetCDF_VERSION_MAJOR} ${NetCDF_VERSION_MINOR} ${NetCDF_VERSION_PATCH})
  
# --- Define the patch command

# Need Perl to patch the files
find_package(Perl)
if (NOT PERL_FOUND)
  message(FATAL_ERROR "Can not locate Perl. Unable to patch and build netCDF")
endif()


# Configure the bash patch script
set(NetCDF_sh_patch ${NetCDF_prefix_dir}/netcdf-patch-step.sh)
configure_file(${SuperBuild_TEMPLATE_FILES_DIR}/netcdf-patch-step.sh.in
               ${NetCDF_sh_patch}
               @ONLY)

# Configure the CMake command file
set(NetCDF_cmake_patch ${NetCDF_prefix_dir}/netcdf-patch-step.cmake)
configure_file(${SuperBuild_TEMPLATE_FILES_DIR}/netcdf-patch-step.cmake.in
               ${NetCDF_cmake_patch}
               @ONLY)
set(NetCDF_PATCH_COMMAND ${CMAKE_COMMAND} -P ${NetCDF_cmake_patch})     

# --- Define the configure command
set(NetCDF_CMAKE_CACHE_ARGS "-DCMAKE_INSTALL_PREFIX:FILEPATH=${TPL_INSTALL_PREFIX}")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DCMAKE_INSTALL_LIBDIR:FILEPATH=${TPL_INSTALL_PREFIX}/lib")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DCMAKE_INSTALL_BINDIR:FILEPATH=${TPL_INSTALL_PREFIX}/bin")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DENABLE_DAP:BOOL=FALSE")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DENABLE_PARALLEL4:BOOL=TRUE")
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DHDF5_PARALLEL:BOOL=TRUE")

# Default is to build with NetCDF4 which depends on HDF5
option(ENABLE_NetCDF4 "Enable netCDF4 build" TRUE)
if (ENABLE_NetCDF4)
  list(APPEND NetCDF_PACKAGE_DEPENDS ${HDF5_BUILD_TARGET})
  list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DENABLE_NETCDF_4:BOOL=TRUE")
endif() 

# share libraries -- disabled by default
list(APPEND NetCDF_CMAKE_CACHE_ARGS "-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}")

# Build compiler flag strings for C, C++ and Fortran
include(BuildWhitespaceString)
build_whitespace_string(netcdf_cflags 
                        -I${TPL_INSTALL_PREFIX}/include ${Amanzi_COMMON_CFLAGS} )

build_whitespace_string(netcdf_cxxflags 
                        -I${TPL_INSTALL_PREFIX}/include ${Amanzi_COMMON_CXXFLAGS} )

set(cpp_flags_list
    -I${TPL_INSTALL_PREFIX}/include
    ${Amanzi_COMMON_CFLAGS})
#    ${Amanzi_COMMON_CXXFLAGS})
list(REMOVE_DUPLICATES cpp_flags_list)
build_whitespace_string(netcdf_cppflags ${cpp_flags_list})

build_whitespace_string(netcdf_fcflags 
                        ${Amanzi_COMMON_FCFLAGS} )

# Add MPI C libraries 
if ( ( NOT BUILD_MPI) AND ( NOT MPI_WRAPPERS_IN_USE ) AND (MPI_C_LIBRARIES) )
  build_whitespace_string(netcdf_ldflags -L${TPL_INSTALL_PREFIX}/lib ${MPI_C_LIBRARIES} ${CMAKE_EXE_LINKER_FLAGS})
else()
  build_whitespace_string(netcdf_ldflags -L${TPL_INSTALL_PREFIX}/lib ${CMAKE_EXE_LINKER_FLAGS})
endif()  


# --- Add external project build and tie to the ZLIB build target
ExternalProject_Add(${NetCDF_BUILD_TARGET}
                    DEPENDS   ${NetCDF_PACKAGE_DEPENDS}   # Package dependency target
                    TMP_DIR   ${NetCDF_tmp_dir}           # Temporary files directory
                    STAMP_DIR ${NetCDF_stamp_dir}         # Timestamp and log directory
                    # -- Download and URL definitions
                    DOWNLOAD_DIR ${TPL_DOWNLOAD_DIR}      # Download directory
                    URL          ${NetCDF_URL}            # URL may be a web site OR a local file
                    URL_MD5      ${NetCDF_MD5_SUM}        # md5sum of the archive file
                    # -- Patch 
                    PATCH_COMMAND ${NetCDF_PATCH_COMMAND}
                    # -- Configure
                    SOURCE_DIR       ${NetCDF_source_dir} # Source directory
                    CMAKE_CACHE_ARGS ${AMANZI_CMAKE_CACHE_ARGS}   # Global definitions from root CMakeList
                                     ${NetCDF_CMAKE_CACHE_ARGS}
                                     ${Amanzi_CMAKE_C_COMPILER_ARGS}  # Ensure uniform build
                                     -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
                                     ${Amanzi_CMAKE_CXX_COMPILER_ARGS}
                                     -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
                    # -- Build
                    BINARY_DIR        ${NetCDF_build_dir}       # Build directory 
                    BUILD_COMMAND     $(MAKE)                   # $(MAKE) enables parallel builds through make
                    BUILD_IN_SOURCE   ${NetCDF_BUILD_IN_SOURCE} # Flag for in source builds
                    # -- Install
                    INSTALL_DIR      ${TPL_INSTALL_PREFIX}      
                    # -- Output control
                    ${NetCDF_logging_args})

# --- Useful variables for packages that depend on NetCDF (Trilinos)
include(BuildLibraryName)
build_library_name(netcdf NetCDF_C_LIBRARY APPEND_PATH ${TPL_INSTALL_PREFIX}/lib)
build_library_name(netcdf_c++ NetCDF_CXX_LIBRARY APPEND_PATH ${TPL_INSTALL_PREFIX}/lib)
set(NetCDF_INCLUDE_DIRS ${TPL_INSTALL_PREFIX}/include)
set(NetCDF_C_LIBRARIES ${NetCDF_C_LIBRARY})
if ( ENABLE_NetCDF4 )
  list(APPEND NetCDF_C_LIBRARIES ${HDF5_LIBRARIES})
  list(APPEND NetCDF_INCLUDE_DIRS ${HDF5_INCLUDE_DIRS})
  list(REMOVE_DUPLICATES NetCDF_INCLUDE_DIRS)
endif()
  

