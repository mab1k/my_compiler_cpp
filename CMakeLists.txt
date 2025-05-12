cmake_minimum_required(VERSION 3.20)
project(do_while_parser)

find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

BISON_TARGET(Parser grammar.y ${CMAKE_BINARY_DIR}/parser.cpp DEFINES_FILE ${CMAKE_BINARY_DIR}/parser.hpp)
FLEX_TARGET(Lexer lexer.l ${CMAKE_BINARY_DIR}/lexer.cpp)
ADD_FLEX_BISON_DEPENDENCY(Lexer Parser)


add_executable(do_while_parser
    ${BISON_Parser_OUTPUTS}
    ${FLEX_Lexer_OUTPUTS}
)

target_include_directories(do_while_parser PRIVATE ${CMAKE_BINARY_DIR})
