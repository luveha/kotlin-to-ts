package main

import "core:fmt"
import "core:strings"

KotlinType :: enum {
    String,
    Int,
    Float,
    Bool,
    Struct,
    List,
    TypeParam,
}

KotlinTypeDefinition :: struct {
    type: KotlinType,
    name: string,
    nullable: bool,
    sub_type: ^KotlinTypeDefinition
}

Field :: struct {
    name: string,
    type: KotlinTypeDefinition
}

KotlinClass :: struct {
    name: string,
    extends: ^string,
    fields: [dynamic]Field,
}

make_indent :: proc(indent: int, b: ^strings.Builder) -> string {
    defer strings.builder_reset(b)
    for i in 0..<indent {
        strings.write_string(b, "  ")
    }
    return strings.to_string(b^)
}


kotlinTypeToString :: proc(t: KotlinType) -> string {
    switch t {
        case .String: return "String"
        case .Int: return "Int"
        case .Float: return "Float"
        case .Bool: return "Bool"
        case .Struct: return "Struct"
        case .List: return "List"
        case .TypeParam: return "TypeParam"
    }
    return ""
}

printKotlinTypeDefinition :: proc(k: ^KotlinTypeDefinition, indent: int, b: ^strings.Builder) {
    if k == nil {
        return
    }
    nullSuffix := ""
    if k.nullable {
        nullSuffix = "?"
    }
    fmt.printfln("%sType: %s%s", make_indent(indent, b), kotlinTypeToString(k.type), nullSuffix)
    fmt.printfln("%sName: %s", make_indent(indent, b), k.name)
    if k.sub_type != nil {
        fmt.printfln("%sSubType:", make_indent(indent, b))
        printKotlinTypeDefinition(k.sub_type, indent + 1, b)
    }
}

printKotlinClass :: proc(k: KotlinClass) {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    
    fmt.printfln("Name: %s", k.name)
    

    implements := "None"
    if k.extends != nil {
        implements = k.extends^
    }
    fmt.printfln("Extends: %s", implements)

    fmt.printfln("Fields:")
    for i in 0..=len(k.fields)-1 {
        f := k.fields[i]
        fmt.printfln("%sField Name: %s", make_indent(1, &builder), f.name)
        fmt.printfln("%sField Type:", make_indent(1, &builder))
        printKotlinTypeDefinition(&f.type, 2, &builder) 
    }
}
