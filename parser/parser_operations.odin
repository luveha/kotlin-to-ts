package parser

import "core:strings"
import "../lexer"

next_token :: proc(p: ^Parser) {
	p.cur_token = p.peek_token
	p.peek_token = lexer.next_token(p.l)
}

cur_token_is :: proc(p: ^Parser, t: lexer.TokenType) -> bool {
	return p.cur_token.type == t
}

peek_token_is :: proc(p: ^Parser, t: lexer.TokenType) -> bool {
	return p.peek_token.type == t
}

skip_optional :: proc(p: ^Parser) {
    if p.cur_token.type == lexer.COMMA {
        next_token(p)
    } 
    if p.cur_token.type == lexer.SEMICOLON {
        next_token(p)
    }
}

expect_token :: proc(p: ^Parser, type: lexer.TokenType) -> bool {
    if p.cur_token.type != type {
        return false
    }
    next_token(p)
    return true
}

skip_paren :: proc(p: ^Parser) {
    paren_depth := 0

    for {
        if cur_token_is(p, lexer.LPAREN) {
            paren_depth += 1
        } else if cur_token_is(p, lexer.RPAREN)  {
            paren_depth -= 1
        }

        next_token(p)

        if paren_depth <= 0 || p.cur_token.type == lexer.EOF {
            break
        }
    }
}