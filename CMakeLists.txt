project (lfetch)  # project here actually means solution in premake

#add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/vendor/mbedtls/ EXCLUDE_FROM_ALL)

file(GLOB mbed_compat_sources ./mbedtls.c)
SET(mbed_compat ${mbed_compat_sources})

ADD_LIBRARY (mbed_compat ${mbed_compat})
TARGET_LINK_LIBRARIES (mbed_compat)

file(GLOB fetch_sources ./**.c)
SET(fetch ${fetch_sources})

ADD_LIBRARY (fetch ${fetch})
TARGET_LINK_LIBRARIES (fetch)

#add_executable (test test.c)
#target_link_libraries(test fetch mbed_compat mbedx509 mbedtls mbedcrypto "-static")
