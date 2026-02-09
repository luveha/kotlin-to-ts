#+feature dynamic-literals
package parser

import "../lexer"
import "../string_utils"
import "core:fmt"

parse_controller :: proc(p: ^Parser) -> string {
    if (string_utils.string_to_annotation_type(p.cur_token.literal) != .REQUESTMAPPING) {
        return ""
    }
    next_token(p)

    return parse_mapping(p)
}

parse_mapping :: proc(p: ^Parser) -> string {

    if !expect_token(p, lexer.LPAREN){
        return ""
    }

    skip_path_start_if_present(p)

    return parse_path_value(p)
}

skip_path_start_if_present :: proc(p: ^Parser) {
    expect_token(p, lexer.PATH)
    expect_token(p, lexer.EQUALS)
    expect_token(p, lexer.LBRACKET)
}

parse_path_value :: proc(p: ^Parser) -> string {
    if !cur_token_is(p, lexer.STRING_LIT){
        return ""
    }

    val := p.cur_token.literal
    next_token(p)

    expect_token(p, lexer.RBRACKET)
    if !expect_token(p, lexer.RPAREN){
        return ""
    }

    return val
}