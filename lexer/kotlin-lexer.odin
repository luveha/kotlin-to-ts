#+feature dynamic-literals
package lexer

import "core:fmt"
import "../ast"

ILLEGAL :: "ILLEGAL"
EOF :: "EOF"
// Identifiers and lierals
IDENT :: "IDENT"
INT :: "INT"
STRING_LIT :: "STRING_LIT"

LT :: "<"
GT :: ">"

ATSYMBOL :: "@"

// Delimiters
COMMA :: ","
SEMICOLON :: ";"
LPAREN :: "("
RPAREN :: ")"
LBRACE :: "{"
RBRACE :: "}"
LBRACKET :: "["
RBRACKET :: "]"
COLON :: ":"
QMARK :: "?"
DASH :: "/"
STAR :: "*"
EQUALS :: "="

// Keywords
DATA :: "Data"
INTERFACE :: "Interface"
CLASS :: "Class"
ENUM :: "Enum"
VAL :: "Val"
VAR :: "var"
OVERRIDE :: "Override"

//Kotlin class prims
STRING :: "STRING"
BOOL :: "BOOL"

//Annotation types
RESTCONTROLLER 	:: "RestController"
REQUIREACCESS	:: "RequireAccess"
	//HTML TYPES
REQUESTMAPPING 	:: "RequestMapping"
POSTMAPPING 	:: "PostMapping"

//Ambiguous category, it is an identifier but not in context it is needed
PATH :: "path"

//Kotlin types
DATE :: "DATE"
//Kotlin nested types
LIST :: "LIST"

keywords : map[string]TokenType 
build_keywords_map :: proc() -> map[string]TokenType {
    keywords := map[string]TokenType{
        "data"      = DATA,
        "interface" = INTERFACE,
        "class"     = CLASS,
		"enum"		= ENUM,
        "val"       = VAL,
        "var"       = VAR,
        "override"  = OVERRIDE,
		"RestController" 	= RESTCONTROLLER,
		"RequestMapping" 	= REQUESTMAPPING,
		"PostMapping"		= POSTMAPPING,
		"RequireAccess"		= REQUIREACCESS,
		"path"		= PATH,
		
    }
    
    // Add primitive types from metadata
    for prim in ast.KOTLIN_PRIMITIVES {
        if prim.is_lexer_keyword {
            keywords[prim.kotlin_name] = TokenType(prim.lexer_token_name)
        }
    }
    
    return keywords
}

TokenType :: distinct string

Token :: struct {
	type:    TokenType,
	literal: string,
}

Lexer :: struct {
	input:         	string,
	position:      	int,
	read_position: 	int,
	ch:            	byte,
	illegals:      	[dynamic]string,
	keywords:		map[string]TokenType
}

string_from_byte :: proc(ch: byte) -> string {
	// https://odin-lang.org/docs/overview/#from-u8-to-x
	buf := make([]u8, 1)
	buf[0] = ch
	return transmute(string)buf
}

lookup_ident :: proc(ident: string, l: ^Lexer) -> TokenType {
	if tok, ok := l.keywords[ident]; ok {
		return tok
	}
	return IDENT
}

new_lexer :: proc(input: string) -> ^Lexer {
	l := new(Lexer)
	l.input = input
	l.keywords = build_keywords_map()
	read_char(l)
	return l
}

delete_lexer :: proc(l: ^Lexer) {
	delete(l.illegals)
	free(l)
}

read_char :: proc(l: ^Lexer) {
	if l.read_position >= len(l.input) {
		l.ch = 0
	} else {
		l.ch = l.input[l.read_position]
	}
	l.position = l.read_position
	l.read_position += 1
}


next_token :: proc(l: ^Lexer) -> Token {
	tok: Token

	skip_whitespace(l)

	switch l.ch {
	case 0:
        tok.type = EOF
        tok.literal = ""
	case ':':
		tok.type = COLON
		tok.literal = ":"
	case '<':
		tok.type = LT
		tok.literal = "<"
	case '>':
		tok.type = GT
		tok.literal = ">"
	case '{':
		tok.type = LBRACE
		tok.literal = "{"
	case '}':
		tok.type = RBRACE
		tok.literal = "}"
	case '(':
		tok.type = LPAREN
		tok.literal = "("
	case ')':
		tok.type = RPAREN
		tok.literal = ")"
	case '?':
		tok.type = QMARK
		tok.literal = "?"
	case '[':
		tok.type = LBRACKET
		tok.literal = "["
	case ']':
		tok.type = RBRACKET
		tok.literal = "]"
	case ',':
		tok.type = COMMA
		tok.literal = ","
	case '/':
		tok.type = DASH
		tok.literal = "/"
	case '*':
		tok.type = STAR
		tok.literal = "*"
	case '=':
		tok.type = EQUALS
		tok.literal = "="
	case '"':
		tok.type = STRING_LIT
		tok.literal = read_string(l)
	case '@':
		tok.type = ATSYMBOL
		tok.literal = "@"
	case:
		if is_letter(l.ch) {
			tok.literal = read_identifier(l)
			tok.type = lookup_ident(tok.literal, l)
			return tok
		} else if is_digit(l.ch) {
			tok.literal = read_number(l)
			tok.type = INT
			return tok
		} else {
			tok.literal = string_from_byte(l.ch)
			tok.type = ILLEGAL
			append(&l.illegals, tok.literal)
		}
	}

	read_char(l)

	return tok
}

read_identifier :: proc(l: ^Lexer) -> string {
	position := l.position
	for is_letter_or_digit(l.ch) {
		read_char(l)
	}
	return l.input[position:l.position]
}

read_number :: proc(l: ^Lexer) -> string {
	position := l.position
	for is_digit(l.ch) {
		read_char(l)
	}
	return l.input[position:l.position]
}

read_string :: proc(l: ^Lexer) -> string {
	position := l.position + 1
	for {
		read_char(l)
		if l.ch == 0 {
            break 
        }
        if l.ch == '\\' {
            read_char(l)
            continue
        }
        if l.ch == '"' {
            break
        }
	}
	content := l.input[position:l.position]
    return content
}

is_letter_or_digit:: proc(ch: byte) -> bool {
	return ('a' <= ch && ch <= 'z') || ('A' <= ch && ch <= 'Z' || ch == '_') || ('0' <= ch && ch <= '9')
}

is_letter :: proc(ch: byte) -> bool {
	return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

is_digit :: proc(ch: byte) -> bool {
	return '0' <= ch && ch <= '9'
}

peek_char :: proc(l: ^Lexer) -> byte {
	if l.read_position >= len(l.input) {
		return 0
	} else {
		return l.input[l.read_position]
	}
}

skip_single_line_comment :: proc(l: ^Lexer) {
    for l.ch != '\n' && l.ch != 0 {
        read_char(l)
    }
}

skip_multi_line_comment :: proc(l: ^Lexer) {
    comment_depth := 1

    for comment_depth > 0 && l.ch != 0 {
        read_char(l)
        if l.ch == '*' && peek_char(l) == '/' {
            read_char(l)
            read_char(l)
            comment_depth -= 1
        } else if l.ch == '/' && peek_char(l) == '*' {
            read_char(l)
            read_char(l)
            comment_depth += 1
        }
    }
}

skip_whitespace :: proc(l: ^Lexer) {
    for {
        if l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' {
            read_char(l)
        } else if l.ch == '/' {
            next_ch := peek_char(l)
            if next_ch == '/' {
                read_char(l)
                read_char(l)
                skip_single_line_comment(l)
            } else if next_ch == '*' {
                read_char(l)
                read_char(l)
                skip_multi_line_comment(l)
            } else {
                break
            }
        } else {
            break
        }
    }
}