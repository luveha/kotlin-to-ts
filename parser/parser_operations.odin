package parser

import "core:strings"
import "../lexer"
import "../ast"
import "../string_utils"

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

skip_semi_or_comma :: proc(p: ^Parser) {
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

expect_token_and_annotation :: proc(p: ^Parser, type: ast.KotlinAnnotation) -> bool {
    if p.cur_token.type != lexer.ANNOTATION {
        return false
    }
    if (string_utils.string_to_annotation_type(p.cur_token.literal) != type) {
        return false
    }

    next_token(p)
    return true
}

expect_indent_and_lit :: proc(p: ^Parser, lit: string) -> bool {
    if p.cur_token.type != lexer.IDENT {
        return false
    }
    if (p.cur_token.literal != lit) {
        return false
    }

    next_token(p)
    return true
}

expect_token_and_lit :: proc(p: ^Parser, type: lexer.TokenType, lit: string) -> bool {
    if p.cur_token.type == type && p.cur_token.literal == lit {
        next_token(p)
        return true
    }

    return false
}

skip_brackets_type :: proc(p: ^Parser, start: lexer.TokenType, end: lexer.TokenType) {
    paren_depth := 0

    for {
        if cur_token_is(p, start) {
            paren_depth += 1
        } else if cur_token_is(p, end)  {
            paren_depth -= 1
        }

        next_token(p)

        if paren_depth <= 0 || p.cur_token.type == lexer.EOF {
            break
        }
    }
}
skip_paren :: proc(p: ^Parser) {
    skip_brackets_type(p, lexer.LPAREN, lexer.RPAREN)
}
skip_brace :: proc(p: ^Parser) {
    skip_brackets_type(p, lexer.LBRACE, lexer.RBRACE)
}