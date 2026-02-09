#+feature dynamic-literals
package parser

import "core:fmt"
import "core:strings"

import "../ast"
import "../lexer"

parse_class :: proc(p: ^Parser) -> ^ast.KotlinClass {
    kt := ast.new_kotlin_class()

    if p.cur_token.type == lexer.DATA {
        next_token(p)
    }

    switch p.cur_token.type {
    case lexer.INTERFACE:
        kt.classType = ast.KotlinClassType.Interface
    case lexer.CLASS:
        kt.classType = ast.KotlinClassType.Class  
    case lexer.ENUM:
        kt.classType = ast.KotlinClassType.Enum
    case:
        ast.freeKotlinClass(kt)
        return nil
    }

    next_token(p)

    if kt != nil {
        parse_class_name(p, kt)
    }

    return kt
}

parse_class_name :: proc(p: ^Parser, kt: ^ast.KotlinClass) {
    if(kt.classType == .Enum && p.cur_token.type == lexer.CLASS) {
        next_token(p)
    }

    switch p.cur_token.type {
        case lexer.IDENT:
            kt.name = strings.clone(p.cur_token.literal)
            parse_generic_impl_or_values(p, kt)
        case:
            next_token(p)
            //ast.freeKotlinClass(kt)
    }
}

parse_generic_impl_or_values :: proc(p: ^Parser, kt: ^ast.KotlinClass) {
    switch p.peek_token.type {
        case lexer.LT:
            next_token(p)
            switch parse_generic(p, &kt.type_params) {
                case 1:
                    parse_impl(p, kt)
                case 2:
                    parse_content(p, kt)
                case 0:
                    fmt.printfln("Failed parsing generics")
                    return
            }
        case lexer.COLON:
            next_token(p)
            parse_impl(p,kt)
        case lexer.LBRACE:
            next_token(p)
            if(kt.classType == .Enum) {
                next_token(p)
                parse_enum(p, kt)
            } else {
                parse_content(p, kt)
            }
        case lexer.LPAREN:
            next_token(p)
            if(kt.classType == .Enum) {
                skip_paren(p)
                if(!expect_token(p, lexer.LBRACE)) {
                    return
                }
                parse_enum(p, kt)
            } else {
                parse_content(p, kt)
            }
        case:
            next_token(p)
            //ast.freeKotlinClass(kt)
    }
}

parse_enum :: proc(p: ^Parser, kt: ^ast.KotlinClass) {
    if(p.cur_token.type == lexer.RBRACE) {
        return
    }

    if(p.cur_token.type != lexer.IDENT) {
        return
    }
    field := new(ast.Field)
    field.name = strings.clone("Enum type")
    def: ast.KotlinTypeDefinition = {}

    def.kotlinType = .String
    def.name = strings.clone(p.cur_token.literal)
    def.nullable = false
    
    field.fieldType = def
    append(&kt.fields, field)

    next_token(p)
    if(p.cur_token.type == lexer.LPAREN) {
        skip_paren(p)
    }
    if(p.cur_token.type == lexer.COMMA) {
        next_token(p)
    }
    
    parse_enum(p,kt)
}

parse_generic :: proc(p: ^Parser, type_params: ^[dynamic]string) -> int {
    next_token(p)
    append(type_params, strings.clone(p.cur_token.literal))
    if(p.peek_token.type == lexer.GT) {
        next_token(p)
        switch p.peek_token.type {
            case lexer.COLON:
                next_token(p)
                return 1
            case lexer.LBRACE, lexer.LPAREN:
                next_token(p)
                return 2
            case:
                return 0
                //ast.freeKotlinClass(kt)
        }
    } else if (p.peek_token.type == lexer.COMMA) {
        next_token(p)
        return parse_generic(p,type_params)
    }
    return 0
}

parse_impl :: proc(p: ^Parser, kt: ^ast.KotlinClass) {
    next_token(p)
    def := new(ast.KotlinTypeDefinition)
    if(p.cur_token.type != lexer.IDENT) {
        fmt.printfln("Failed with impl not being an identifier: %s", p.cur_token.literal)
        free(def)
        return
    }
    
    def.name = strings.clone(p.cur_token.literal)
    def.kotlinType = ast.get_kotlin_type_from_string(def.name)
    
    next_token(p) 
    
    if p.cur_token.type == lexer.LT {
        switch parse_generic(p,&def.type_params) {
            case 1:
                fmt.printfln("Shouldn't be impl 2 classes")
                free(def)
                return
            case 2:
                kt.extends = def
                parse_content(p, kt)
            case 0:
                kt.extends = def
                return
        }
    }
    if p.cur_token.type == lexer.LBRACE || p.cur_token.type == lexer.LPAREN {
        kt.extends = def
        parse_content(p, kt)
    } 
}

parse_type_definition :: proc(p: ^Parser) -> ast.KotlinTypeDefinition {
    if (!(p.cur_token.type == lexer.IDENT || is_kotlin_primitive(p.cur_token))) {
        return ast.KotlinTypeDefinition{}
    }

    def: ast.KotlinTypeDefinition = {}
    if(p.cur_token.type == lexer.LIST) {
        next_token(p)

        if(p.cur_token.type != lexer.LT) {
            return ast.KotlinTypeDefinition{}
        }
        next_token(p)

        if(p.cur_token.type != lexer.IDENT) {
            return ast.KotlinTypeDefinition{}
        }
        
        def.kotlinType = ast.KotlinType.List
        def.name = strings.clone(p.cur_token.literal)
        next_token(p)
        if(p.cur_token.type != lexer.GT) {
            return ast.KotlinTypeDefinition{}
        }
    } else {
        def.name = strings.clone(p.cur_token.literal)
        def.kotlinType = ast.get_kotlin_type_from_string(def.name)
    }
    

    if peek_token_is(p, lexer.QMARK) {
        next_token(p)
        def.nullable = true
    }
    
    if peek_token_is(p, lexer.LT) {
        next_token(p)
        
        for p.cur_token.type != lexer.GT && p.cur_token.type != lexer.EOF {
            next_token(p) 
        }
        
        if p.cur_token.type == lexer.GT {
            // next_token(p) // The caller (parse_field) advances the token after this function returns
        }
    }
    
    return def
}

parse_field :: proc(p: ^Parser, skip_save := false) -> ^ast.Field {
    field := new(ast.Field)

    next_token(p)

    if p.cur_token.type != lexer.IDENT {
        fmt.printfln("Failed 1st indent check: %s", p.cur_token.literal)
        free(field) 
        return nil
    }
    
    field.name = strings.clone(p.cur_token.literal)
    next_token(p)

    if p.cur_token.type != lexer.COLON {
        fmt.printfln("Failed colon check: %s", p.cur_token.literal)
        free(raw_data(field.name))
        free(field)
        return nil
    }
    next_token(p)

    if (!(p.cur_token.type == lexer.IDENT || is_kotlin_primitive(p.cur_token))) {
        fmt.printfln("Failed 2nd type check. Found: %s", p.cur_token.literal)
        free(raw_data(field.name))
        free(field)
        return nil
    }

    field.fieldType = parse_type_definition(p)
    next_token(p)

    if skip_save {
        //Not the cleanest logic since it makes and then are freeing it
        free(raw_data(field.name))
        if field.fieldType.name != "" {
            free(raw_data(field.fieldType.name))
        }
        free(field)
        return nil
    }

    return field
}

parse_content :: proc(p: ^Parser, kt: ^ast.KotlinClass) {
    next_token(p)

    for {
        if p.cur_token.type == lexer.OVERRIDE {
            next_token(p)
            parse_field(p,true)
            skip_semi_or_comma(p)
            continue
        }

        if p.cur_token.type == lexer.RPAREN || p.cur_token.type == lexer.RBRACE {
            if(p.peek_token.type == lexer.COLON) {
                next_token(p)
                parse_impl(p,kt)
            } else {
                //Should just log
                //fmt.printfln("Exited correctly")
            }
            return 
        }

        if !(p.cur_token.type == lexer.VAR || p.cur_token.type == lexer.VAL) {
            return
        }

        field := parse_field(p)
        if field == nil {
            return 
        }
        append(&kt.fields, field)

        skip_semi_or_comma(p)
    }
}