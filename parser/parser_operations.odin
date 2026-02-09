package parser

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