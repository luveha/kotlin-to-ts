#+feature dynamic-literals
package parser

import "core:strings"
import "core:fmt"
import "../lexer"
import "../ast"
import "../string_utils"

parse_endpoint:: proc(p: ^Parser) -> ^ast.Endpoint {
    if(!(cur_token_is(p, lexer.ANNOTATION))) {
        return nil
    }
    endp := ast.new_endpoint()

    skip_require_access(p)

    if(cur_token_is(p, lexer.ANNOTATION)) {
        #partial switch (string_utils.string_to_annotation_type(p.cur_token.literal)) {
            case .POSTMAPPING:
                next_token(p)
                parse_post_mapping(p, endp)
            case .REQUESTMAPPING:
                next_token(p)
                parse_request_mapping(p, endp)
            case:
                ast.free_endpoint(endp); return nil
        }   
    } else {
        ast.free_endpoint(endp); return nil
    }

    skip_require_access(p)
    
    parse_function_name(p, endp)
    
    return endp
}

skip_require_access :: proc(p: ^Parser) -> bool {
    if(expect_token_and_annotation(p, ast.KotlinAnnotation.REQUIREACCESS)) {
        skip_paren(p)
        return true
    }
    return false
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
    next_token(p)

    expect_token(p, lexer.RPAREN)
}

parse_request_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) {
    if(!expect_token(p, lexer.LPAREN)) {
        return
    }

    skip_path_start_if_present(p)

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        return
    }
    e.url = p.cur_token.literal
    next_token(p)
    
    if(!expect_token(p, lexer.RBRACKET)) {
        return
    }
    
    if(!expect_token(p, lexer.COMMA)) {
        return
    }
    
    parse_request_method(p, e)
}

parse_request_method :: proc(p: ^Parser, e: ^ast.Endpoint) {
    if(!expect_token_and_lit(p, lexer.IDENT, "method")) {
        return
    }

    if(!expect_token(p, lexer.EQUALS)) {
        return
    }

    if(!expect_token(p, lexer.LBRACKET)) {
        return
    }

    if(!expect_token_and_lit(p, lexer.IDENT, "RequestMethod")) {
        return
    }

    if(!expect_token(p, lexer.DOT)) {
        return
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        return
    }
    e.requestMethod = string_utils.string_to_http_type(p.cur_token.literal)
    next_token(p)

    if(!expect_token(p, lexer.RBRACKET)) {
        return
    }

    if(!expect_token(p, lexer.RPAREN)) {
        return
    }
}

parse_function_name :: proc(p: ^Parser, e: ^ast.Endpoint) {
    if(!expect_token(p, lexer.FUN)) {
        return
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        return
    }
    e.name = p.cur_token.literal
    next_token(p)

}