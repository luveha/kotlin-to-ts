#+feature dynamic-literals
package parser

import "core:strings"
import "../lexer"
import "../ast"

parse_endpoint:: proc(p: ^Parser) -> ^ast.Endpoint {
    
    if(!(p.cur_token.type == lexer.REQUIREACCESS || p.cur_token.type == lexer.POSTMAPPING)) {
        return nil
    }
    endp := ast.new_endpoint()

    skip_require_access(p)
    
    switch p.cur_token.literal {
        case lexer.POSTMAPPING:
            next_token(p)
            parse_post_mapping(p, endp)
        case lexer.REQUESTMAPPING:
            
        case: return nil
    }

    skip_require_access(p)

    //print_next_x_tokens(p, 4)
    
    return nil
}

skip_require_access :: proc(p: ^Parser) {
    if(expect_token(p, lexer.REQUIREACCESS)) {
        skip_paren(p)
    }
}

parse_post_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) {
    e.requestMethod = ast.HTTP_REQUEST_METHOD.POST

    if (!expect_token(p, lexer.LPAREN)) { 
        e.url = "EMPTY - CHANGE LATER"
        return 
    }

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        return
    }
    e.url = strings.clone(p.cur_token.literal)

    expect_token(p, lexer.RPAREN)
}

parse_request_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) {
    
}