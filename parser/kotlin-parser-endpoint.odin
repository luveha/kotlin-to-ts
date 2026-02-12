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
    success  := false
    entered_post_mapping := false
    entered_request_mapping := false
    is_annotation := false
    if cur_token_is(p, lexer.ANNOTATION) {
        is_annotation = true
        annotation_type := string_utils.string_to_annotation_type(p.cur_token.literal)
        #partial switch (annotation_type) {
            case .POSTMAPPING, .GETMAPPING:
                entered_post_mapping = true
                next_token(p)
                success = parse_get_post_mapping(p, endp, string_utils.kotlin_annotation_to_http_method(annotation_type))
            case .REQUESTMAPPING:
                entered_request_mapping = true
                next_token(p)
                success = parse_request_mapping(p, endp)
            case:
                append(&p.errors, strings.concatenate({"Failed in wrong annotation type: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
                ast.free_endpoint(endp)
                return nil
        }   
    }

    if !is_annotation{
        ast.free_endpoint(endp)
        return nil
    }
    if !(success) {
        if(entered_post_mapping){
            append(&p.errors, strings.concatenate({"Failed in postmapping: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
        }
        else if (entered_request_mapping) {
            append(&p.errors, strings.concatenate({"Failed in requestmapping: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
        } else {
            append(&p.errors, strings.concatenate({"Internal parsing logic failed: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
        }
        ast.free_endpoint(endp)
        return nil
    }

    skip_require_access(p)
    
    if !parse_function_name(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in function name: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
        return nil
    }
    if !parse_constructor(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in constructor: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))
        return nil
    }
    if !parse_dto(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in dto: \n", "    ", string_utils.print_context_window(p.cur_token.literal, p.l.input, p.l.position), "\n\n"}))  
        return nil
    }
    skip_brace(p)
    
    return endp
}

skip_require_access :: proc(p: ^Parser) -> bool {
    if(expect_token_and_annotation(p, ast.KotlinAnnotation.REQUIREACCESS)) {
        skip_paren(p)
        return true
    }
    return false
}

parse_get_post_mapping :: proc(p: ^Parser, e: ^ast.Endpoint, method: ast.HTTP_REQUEST_METHOD) -> bool{
    e.requestMethod = method

    if (!expect_token(p, lexer.LPAREN)) { 
        e.url = "EMPTY - CHANGE LATER"
        append(&p.errors, strings.clone("Empty error, not actual error"))
        return true
    }

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        append(&p.errors, "Post mapping, Expected: STRING_LIT")  
        return false
    }
    e.url = strings.clone(p.cur_token.literal)
    next_token(p)

    if(!expect_token(p, lexer.RPAREN)) {
        append(&p.errors, "Post mapping, Expected: RPAREN")  
        return false
    }

    return true
}

parse_request_mapping :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.LPAREN)) {
        append(&p.errors, "Request mapping, Expected: LPAREN")  
        return false
    }

    skip_path_start_if_present(p)

    if(!cur_token_is(p, lexer.STRING_LIT)) {
        append(&p.errors, "Request mapping, Expected: STRING_LIT")  
        return false
    }
    e.url = p.cur_token.literal
    next_token(p)
    
    if(!expect_token(p, lexer.RBRACKET)) {
        append(&p.errors, "Request mapping, Expected: RBRACKET")
        return false
    }
    
    if(!expect_token(p, lexer.COMMA)) {
        append(&p.errors, "Request mapping, Expected: COMMA")
        return false
    }
    
    return parse_request_method(p, e)
}

parse_request_method :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token_and_lit(p, lexer.IDENT, "method")) {
        append(&p.errors, "Request method, Expected: IDENT->method")
        return false
    }

    if(!expect_token(p, lexer.EQUALS)) {
        append(&p.errors, "Request method, Expected: EQUALS")
        return false
    }

    if(!expect_token(p, lexer.LBRACKET)) {
        append(&p.errors, "Request method, Expected: LBRACKET")
        return false
    }

    if(!expect_token_and_lit(p, lexer.IDENT, "RequestMethod")) {
        append(&p.errors, "Request method, Expected: IDENT->RequestMethod")
        return false
    }

    if(!expect_token(p, lexer.DOT)) {
        append(&p.errors, "Request method, Expected: DOT")
        return false
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        append(&p.errors, "Request method, Expected: IDENT")
        return false
    }
    e.requestMethod = string_utils.string_to_http_type(p.cur_token.literal)
    next_token(p)

    if(!expect_token(p, lexer.RBRACKET)) {
        append(&p.errors, "Request method, Expected: RBRACKET")
        return false
    }

    if(!expect_token(p, lexer.RPAREN)) {
        append(&p.errors, "Request method, Expected: RPAREN")
        return false
    }
    return true
}

parse_function_name :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.FUN)) {
        append(&p.errors, "Function name, Expected: FUN")
        return false 
    }

    if(!cur_token_is(p, lexer.IDENT)) {
        append(&p.errors, "Function name, Expected: IDENT")
        return false
    }
    e.name = p.cur_token.literal
    next_token(p)

    return true
}

parse_constructor :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    if(!expect_token(p, lexer.LPAREN)) {
        append(&p.errors, "Constructor, Expected: LPAREN")
        return false
    }

    return parse_parameters(p, e)
}

parse_parameters :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {
    for (!cur_token_is(p, lexer.RPAREN) && !cur_token_is(p, lexer.EOF)) {
        if(cur_token_is(p, lexer.ANNOTATION)) {
            if(expect_token_and_annotation(p, .REQUESTBODY)) {
                b, s := parse_param(p)
                if !b { return false }

                def := new(ast.KotlinTypeDefinition)

                def.name = strings.clone(s)
                def.kotlinType = ast.get_kotlin_type_from_string(def.name)
                def.nullable = false
                type_params := make([dynamic]string)
                if p.cur_token.type == lexer.LT {
                    next_token(p)
                    for (!cur_token_is(p, lexer.GT) && !cur_token_is(p, lexer.EOF)) {
                        append(&type_params, p.cur_token.literal)
                        next_token(p)
                    }
                    def.type_params = type_params
                }
                
                e.body = def^
            } 
            else if (expect_token_and_annotation(p, .REQUESTPARAM)) {
                if(cur_token_is(p, lexer.LPAREN)) {
                    skip_paren(p)
                }
                b, s := parse_param(p)
                if !b { append(&p.errors, "Failed to parse param, not specific annotation: "); return false }

                def := new(ast.KotlinTypeDefinition)
                def.name = strings.clone(s)
                def.kotlinType = ast.KotlinType.ByteArray
                type_params := make([dynamic]string)

                e.body = def^
            } else {
                next_token(p)
                if(cur_token_is(p, lexer.LPAREN)) {
                    skip_paren(p)
                }
                b, _ := parse_param(p)
                if !b { return false }
            }
        } else {
            b, s := parse_param(p)
            if !b {append(&p.errors, "Failed to parse param, not annotation: "); return false }
            ast.highest_param(s, e)
        }
    }
    if !expect_token(p, lexer.RPAREN) do return false

    return true
}

parse_param :: proc(p: ^Parser) -> (bool, string) {
    if(!expect_token(p, lexer.IDENT)) {
        append(&p.errors, "Param, Expected: IDENT")
        return false, ""
    }

    if(!expect_token(p, lexer.COLON)) {
        append(&p.errors, "Param, Expected: COLON")
        return false, ""
    }

    if(cur_token_is(p, lexer.IDENT) || is_kotlin_primitive(p.cur_token)) {
        v := p.cur_token.literal
        next_token(p)
        
        skip_semi_or_comma(p)
    
        return true, v
    }
    append(&p.errors, "Param, Expected: IDENT or KOTLIN_PRIM")
    return false, ""
}

parse_dto :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {

    if(!expect_token(p, lexer.COLON)) {
        if(cur_token_is(p, lexer.LBRACE)) {
            return true
        }
        append(&p.errors, "Param, Expected: LBRACE")
        return false
    }
    contains_response_entity: bool = false
    if(expect_indent_and_lit(p, "ResponseEntity")) {
        contains_response_entity = true
        if(!expect_token(p, lexer.LT)) {
            append(&p.errors, "Param, Expected: LT")
            return false
        }
    }


    if(cur_token_is(p, lexer.IDENT) || is_kotlin_primitive(p.cur_token) || cur_token_is(p, lexer.BYTEARRAY)) {
        def := new(ast.KotlinTypeDefinition)
        defer free(def)

        def.name = strings.clone(p.cur_token.literal)
        if(contains_response_entity){
            def.kotlinType = .ByteArray
        }else {
            def.kotlinType = ast.get_kotlin_type_from_string(def.name)
        }
        def.nullable = false //Huristic for that it should never return null if it can
        type_params := make([dynamic]string)
        

        next_token(p)
        
        if p.cur_token.type == lexer.LT {
            next_token(p)
            
            for (!cur_token_is(p, lexer.GT) || cur_token_is(p, lexer.EOF)) {
                append(&type_params, p.cur_token.literal) //Some assumptions made here about what is inside the < >
                next_token(p)
            }
            def.type_params = type_params
        }
        e.dto = def^

        if(contains_response_entity) {
            if(!expect_token(p, lexer.GT)) {
                append(&p.errors, "Param, Expected: GT")
                return false
            }
        }

        return true
    }

    return true
}