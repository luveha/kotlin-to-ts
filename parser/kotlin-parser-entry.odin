package parser

import "core:fmt"
import "../ast"
import "../lexer"


Parser :: struct {
	l:                ^lexer.Lexer,
	errors:           [dynamic]string,
	cur_token:        lexer.Token,
	peek_token:       lexer.Token,
}

new_parser :: proc(l: ^lexer.Lexer) -> ^Parser {

	p := new(Parser)
	p.l = l
	p.errors = make([dynamic]string)

	// Read two tokens, so cur_token and peek_token are both set
	next_token(p)
	next_token(p)

	return p
}

delete_parser :: proc(p: ^Parser) {
	delete(p.errors)
	free(p)
}

errors :: proc(p: ^Parser) -> [dynamic]string {
	return p.errors
}

parse_file :: proc(p: ^Parser) -> ^ast.File {
	file := ast.new_file()

	for p.cur_token.type != lexer.EOF {
        if(cur_token_is(p, lexer.ATSYMBOL)) {
            next_token(p)
            if(file.rootEndpoint == "") {
                file.rootEndpoint = parse_controller(p)
            } else {
                parse_endpoint(p)
            }
        } 
        else {
            ktClass := parse_class(p)
            if ktClass != nil {
                append(&file.classes, ktClass)
            }
        }
		next_token(p)
	}

	return file
}