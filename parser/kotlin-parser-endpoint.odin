#+feature dynamic-literals
package parser

import "core:strings"
import "core:fmt"
import "../lexer"
import "../ast"
import "../string_utils"

parse_endpoint:: proc(p: ^Parser) -> ^ast.Endpoint {
    if !cur_token_is(p, lexer.ANNOTATION) do return nil

    endp := ast.new_endpoint()
    
    skip_require_access(p)

    success := false
    if cur_token_is(p, lexer.ANNOTATION) {
        #partial switch (string_utils.string_to_annotation_type(p.cur_token.literal)) {
            case .POSTMAPPING:
                next_token(p)
                success = parse_post_mapping(p, endp)
            case .REQUESTMAPPING:
                next_token(p)
                success = parse_request_mapping(p, endp)
        }   
    }

    if !success {
        ast.free_endpoint(endp)
        return nil
    }

    skip_require_access(p)
    
    if !parse_function_name(p, endp) {
        ast.free_endpoint(endp)
        return nil
    }
    if !parse_parameters(p, endp) {
        ast.free_endpoint(endp)
        return nil
    }
    
    return endp
}

skip_require_access :: proc(p: ^Parser) -> bool {
    if(expect_token_and_annotation(p, ast.KotlinAnnotation.REQUIREACCESS)) {
        skip_paren(p)
        return true
    }
    return false
}

parse_post_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool{
    e.requestMethod = ast.HTTP_REQUEST_METHOD.POST

    if (!expect_token(p, lexer.LPAREN)) { 
        e.url = "EMPTY - CHANGE LATER"
        return true
    }

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        return false
    }
    e.url = strings.clone(p.cur_token.literal)
    next_token(p)

    if(!expect_token(p, lexer.RPAREN)) {
        return false
    }

    return true
}

parse_request_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.LPAREN)) {
        return false
    }

    skip_path_start_if_present(p)

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        return false
    }
    e.url = p.cur_token.literal
    next_token(p)
    
    if(!expect_token(p, lexer.RBRACKET)) {
        return false
    }
    
    if(!expect_token(p, lexer.COMMA)) {
        return false
    }
    
    return parse_request_method(p, e)
}

parse_request_method :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token_and_lit(p, lexer.IDENT, "method")) {
        return false
    }

    if(!expect_token(p, lexer.EQUALS)) {
        return false
    }

    if(!expect_token(p, lexer.LBRACKET)) {
        return false
    }

    if(!expect_token_and_lit(p, lexer.IDENT, "RequestMethod")) {
        return false
    }

    if(!expect_token(p, lexer.DOT)) {
        return false
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        return false
    }
    e.requestMethod = string_utils.string_to_http_type(p.cur_token.literal)
    next_token(p)

    if(!expect_token(p, lexer.RBRACKET)) {
        return false
    }

    if(!expect_token(p, lexer.RPAREN)) {
        return false
    }
    return true
}

parse_function_name :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.FUN)) {
        return false 
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        return false
    }
    e.name = p.cur_token.literal
    next_token(p)

    return true
}

parse_constructor :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.LPAREN)) {
        return false
    }

    return parse_parameters(p, e)
}

parse_parameters :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    for (!cur_token_is(p, lexer.RPAREN) || cur_token_is(p, lexer.EOF)) {

        if(cur_token_is(p, lexer.ANNOTATION)) {
            if(expect_token_and_annotation(p, .REQUESTBODY)) {
                b, s := parse_param(p)
                if(b) {
                    e.body = s
                } else {
                    return false
                }
            } else {
                next_token(p)
                b, _ := parse_param(p)
                if !b { return false }
            }
        } else {
            next_token(p)
        }
    }

    return true
}

parse_param :: proc(p: ^Parser) -> (bool, string) {
    if(!expect_token(p, lexer.IDENT)) {
        return false, ""
    }

    if(!expect_token(p, lexer.COLON)) {
        return false, ""
    }

    if(cur_token_is(p, lexer.IDENT)) {
        v := p.cur_token.literal
        next_token(p)
        
        skip_optional(p)
    
        return true, v
    }
    else if (is_kotlin_primitive(p.cur_token)) {
        v := p.cur_token.literal
        next_token(p)
        
        skip_optional(p)
    
        return true, v
    }

    return false, ""
}