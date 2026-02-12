package string_utils

import "core:strings"
import "core:fmt"
import "../ast"

copy_string :: proc(value: string, destination: ^string) {
    destination^ = strings.clone(value)
}

wordContainsList :: proc(word: string, list: []string) -> bool {
    for w in list {
        if(strings.contains(word, w)){
            return true;
        }
    }
    return false;
}

make_indent :: proc(indent: int) -> string {
    return strings.repeat("  ", indent)
}

string_to_http_type :: proc(s: string) -> ast.HTTP_REQUEST_METHOD {
    switch s {
        case "GET":     return .GET
        case "HEAD":    return .HEAD
        case "POST":    return .POST
        case "PUT":     return .PUT
        case "DELETE":  return .DELETE
        case "PATCH":   return .PATCH
        case "OPTIONS": return .OPTIONS
        case "CONNECT": return .CONNECT
        case "TRACE":   return .TRACE
    }

    return .NON_PARSABLE
}

string_to_annotation_type :: proc(s: string) -> ast.KotlinAnnotation {
    switch s {
        case "RestController":  return ast.KotlinAnnotation.RESTCONTROLLER
        case "RequireAccess":   return ast.KotlinAnnotation.REQUIREACCESS
        case "RequestMapping":  return ast.KotlinAnnotation.REQUESTMAPPING
        case "PostMapping":     return ast.KotlinAnnotation.POSTMAPPING
        case "GetMapping":      return ast.KotlinAnnotation.GETMAPPING
        case "RequestBody":     return ast.KotlinAnnotation.REQUESTBODY
        case "RequestParam":    return ast.KotlinAnnotation.REQUESTPARAM
    }
    return ast.KotlinAnnotation.UNKNOWN
}

kotlin_annotation_to_http_method :: proc(annotation: ast.KotlinAnnotation) -> ast.HTTP_REQUEST_METHOD {
    #partial switch annotation {
        case .GETMAPPING:   return .GET
        case .POSTMAPPING:  return .POST 
        case:               return ast.HTTP_REQUEST_METHOD.NON_PARSABLE
    }
}

kotlinTypeToString :: proc(t: ^ast.KotlinType) -> string {
    switch t^ {
        case .String:       return "String"
        case .Int:          return "Int"
        case .Float:        return "Float"
        case .Bool:         return "Bool"
        case .Struct:       return "Struct"
        case .List:         return "List"
        case .Date:         return "Date"
        case .TypeParam:    return "TypeParam"
        case .ByteArray:    return "ByteArray"
    }
    return ""
}

kotlinClassTypeToString :: proc(t: ast.KotlinClassType) -> string{
    switch t {
        case .Class: return "Class"
        case .Interface: return "Interface"
        case .Enum: return "Enum"
    }
    return ""
}

printKotlinTypeDefinition :: proc(k: ^ast.KotlinTypeDefinition, indent: int) {
    if k == nil {
        return
    }
    
    fmt.printfln("%sType: %s", make_indent(indent), kotlinTypeToString(&k.kotlinType))
    fmt.printfln("%sName: %s", make_indent(indent), k.name)
    fmt.printfln("%sIs nullable: %t", make_indent(indent), k.nullable)
    fmt.printfln("%sTypeparams: %s", make_indent(indent))
    for i in 0..=len(k.type_params)-1 {
        f := k.type_params[i]
        fmt.printfln("%Param: %s", k.type_params[i])
    }
}

printKotlinClass :: proc(k: ast.KotlinClass) {
    fmt.println("kotlinClass:\n{")
    oneIndent := make_indent(1)
    twoIndent := make_indent(2)
    fmt.printfln("%sName: %s", oneIndent, k.name)
    

    implements := "None"
    if k.extends != nil {
        implements = k.extends.name
    }
    fmt.printfln("%sExtends: %s", oneIndent, implements)
    fmt.printfln("%sClass Type: %s", oneIndent, kotlinClassTypeToString(k.classType))

    fmt.printfln("%sType Params:", oneIndent)
    fmt.printfln("%s[", oneIndent)
    for t in k.type_params {
        fmt.printfln("%s Type: %s", twoIndent, t)
    }
    fmt.printfln("%s]", oneIndent)

    fmt.printfln("%sFields:", oneIndent)
    fmt.printfln("%s[", oneIndent)
    for i in 0..=len(k.fields)-1 {
        f := k.fields[i]
        fmt.printfln("%sField Name: %s", twoIndent, f.name)
        fmt.printfln("%sField Type:", twoIndent)
        fmt.printfln("%s{{", twoIndent)
        printKotlinTypeDefinition(&f.fieldType, 3)
        fmt.printfln("%s}", twoIndent) 
    }
    fmt.printfln("%s]", oneIndent)
    fmt.println("},")
}

print_context_window :: proc(lit: string, s: string, index: int) -> string {
    if len(s) == 0 {
        fmt.println("String is empty.")
        return ""
    }

    safe_index := clamp(index, 0, len(s) - 1)

    start := max(0, safe_index - 10)
    end   := min(len(s), safe_index + 11)

    prev_part := s[start:safe_index] //
    
    next_part := s[safe_index + 1:end]
    
    return strings.concatenate({prev_part, "||", lit, "||", next_part})
}