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
    is_annotation := false
    if cur_token_is(p, lexer.ANNOTATION) {
        is_annotation = true
        #partial switch (string_utils.string_to_annotation_type(p.cur_token.literal)) {
            case .POSTMAPPING:
                next_token(p)
                success = parse_post_mapping(p, endp)
            case .REQUESTMAPPING:
                next_token(p)
                success = parse_request_mapping(p, endp)
        }   
    }

    if !is_annotation{
        ast.free_endpoint(endp)
        return nil
    }
    if !success {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in dto: \n", "    ", string_utils.print_context_window(p.l.input, p.l.position), "\n\n"}))  
        return nil
    }

    skip_require_access(p)
    
    if !parse_function_name(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in function name: \n", "    ", string_utils.print_context_window(p.l.input, p.l.position), "\n\n"}))  
        return nil
    }
    if !parse_constructor(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in constructor: \n", "    ", string_utils.print_context_window(p.l.input, p.l.position), "\n\n"}))
        return nil
    }
    if !parse_dto(p, endp) {
        ast.free_endpoint(endp)
        append(&p.errors, strings.concatenate({"Failed in dto: \n", "    ", string_utils.print_context_window(p.l.input, p.l.position), "\n\n"}))  
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
                if !b { fmt.printfln("Failed-----"); return false }

                def := new(ast.KotlinTypeDefinition)
                def.name = strings.clone(s)
                def.kotlinType = ast.KotlinType.ByteArray
                type_params := make([dynamic]string)

                e.body = def^
                fmt.printfln("Success")
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
            if !b {return false }
            ast.highest_param(s, e)
        }
    }
    if !expect_token(p, lexer.RPAREN) do return false

    return true
}

parse_param :: proc(p: ^Parser) -> (bool, string) {
    if(!expect_token(p, lexer.IDENT)) {
        return false, ""
    }

    if(!expect_token(p, lexer.COLON)) {
        return false, ""
    }

    if(cur_token_is(p, lexer.IDENT) || is_kotlin_primitive(p.cur_token)) {
        v := p.cur_token.literal
        next_token(p)
        
        skip_semi_or_comma(p)
    
        return true, v
    }
    return false, ""
}

parse_dto :: proc(p: ^Parser, e: ^ast.Endpoint) -> bool {

    if(!expect_token(p, lexer.COLON)) {
        if(cur_token_is(p, lexer.LBRACE)) {
            return true
        }
        return false
    }
    contains_response_entity: bool = false
    if(expect_indent_and_lit(p, "ResponseEntity")) {
        contains_response_entity = true
        if(!expect_token(p, lexer.LT)) {
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
                return false
            }
        }

        return true
    }

    return true
}