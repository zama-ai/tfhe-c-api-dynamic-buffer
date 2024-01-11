cmake_minimum_required(VERSION 3.16)

project(tfhe-c-api-tests C)
set(SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
enable_testing()

if(NOT CARGO_PROFILE)
    set(CARGO_PROFILE release)
endif()
set(TFHE_C_API_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/../target/${CARGO_PROFILE}")

include_directories(${TFHE_C_API_RELEASE})
add_library(TfheDynamicBuffer STATIC IMPORTED)
set_target_properties(TfheDynamicBuffer PROPERTIES IMPORTED_LOCATION ${TFHE_C_API_RELEASE}/libtfhe_c_api_dynamic_buffer.a)

file(GLOB TEST_CASES test_*.c)
foreach (testsourcefile ${TEST_CASES})
    get_filename_component(testname ${testsourcefile} NAME_WLE)
    get_filename_component(groupname ${testsourcefile} DIRECTORY)
    add_executable(${testname} ${testsourcefile})
    add_test(
            NAME ${testname}
            COMMAND ${testname}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/Testing
    )
    target_include_directories(${testname} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(${testname} LINK_PUBLIC TfheDynamicBuffer m pthread dl)
    target_compile_options(${testname} PRIVATE -Werror)
    # Enabled asserts even in release mode
    add_definitions(-UNDEBUG)
endforeach (testsourcefile ${TEST_CASES})
