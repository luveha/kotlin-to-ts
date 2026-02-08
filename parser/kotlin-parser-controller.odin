#+feature dynamic-literals
package parser

import "core:fmt"
import "core:strings"

import "../ast"
import "../lexer"
import "../string_utils"

parse_controller :: proc(p: ^Parser) -> string {
    if !expect_token(p, lexer.RESTCONTROLLER) {
        return ""
    }

    if !expect_token(p, lexer.ATSYMBOL) {
        return ""
    }

    if !expect_token(p, lexer.REQUESTMAPPING) {
        return ""
    }

    return parse_mapping(p)
}

parse_mapping :: proc(p: ^Parser) -> string {


    print_next_x_tokens(p, 4)

    return ""
}