#+feature dynamic-literals
package parser

import "../lexer"

parse_endpoint:: proc(p: ^Parser) -> string {
    print_next_x_tokens(p, 4)
    
    return ""
}
