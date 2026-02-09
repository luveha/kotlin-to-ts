package parser

import "core:fmt"

import "../lexer"
import "../ast"

is_kotlin_primitive :: proc(p: lexer.Token) -> bool {
    for prim in ast.KOTLIN_PRIMITIVES {
        if prim.is_lexer_keyword && string(p.type) == prim.lexer_token_name {
            return true
        }
    }
    return false
}

print_next_x_tokens :: proc(p: ^Parser, x: int) {
    fmt.println("--- Debug: Token Stream Start ---")
    
    for i in 0..<x {
        if p.cur_token.type == lexer.EOF {
            fmt.printfln("Token %d: [EOF]", i)
            break
        }

        fmt.printfln("Token %d: Type: %-12s | Literal: \"%s\"", 
            i, p.cur_token.type, p.cur_token.literal)
        
        next_token(p)
    }
    
    fmt.println("--- Debug: Token Stream End ---")
}