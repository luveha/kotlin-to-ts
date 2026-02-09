#+feature dynamic-literals
package parser

import "../lexer"

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

    if !expect_token(p, lexer.LPAREN){
        return ""
    }

    skip_path_if_present(p)

    return parse_path_value(p)
}

skip_path_if_present :: proc(p: ^Parser) {
    expect_token(p, lexer.PATH)
    expect_token(p, lexer.EQUALS)
    expect_token(p, lexer.LBRACKET)
}

parse_path_value :: proc(p: ^Parser) -> string {
    if !expect_token(p, lexer.CMARK){
        return ""
    }

    if !expect_token(p, lexer.DASH){
        return ""
    }

    val := p.cur_token.literal
    next_token(p)

    if !expect_token(p, lexer.CMARK){
        return ""
    }

    expect_token(p, lexer.RBRACKET)
    if !expect_token(p, lexer.RPAREN){
        return ""
    }

    return val
}