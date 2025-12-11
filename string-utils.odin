package main

import "core:strings"
import "core:fmt"

make_indent :: proc(indent: int) -> string {
    return strings.repeat("  ", indent)
}

wordContainsList :: proc(word: string, list: []string) -> bool {
    for w in list {
        if(strings.contains(word, w)){
            return true;
        }
    }
    return false;
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

kotlinClassTypeToString :: proc(t: KotlinClassType) -> string{
    switch t {
        case .Class: return "Class"
        case .Interface: return "Interface"
        case .Enum: return "Enum"
    }
    return ""
}

printKotlinTypeDefinition :: proc(k: ^KotlinTypeDefinition, indent: int) {
    if k == nil {
        return
    }
    nullSuffix := ""
    if k.nullable {
        nullSuffix = "?"
    }
    fmt.printfln("%sType: %s%s", make_indent(indent), kotlinTypeToString(k.kotlinType), nullSuffix)
    fmt.printfln("%sName: %s", make_indent(indent), k.name)
    fmt.printfln("%sIs nullable: %t", make_indent(indent), k.nullable)
    if k.sub_type != nil {
        fmt.printfln("%sSubType:", make_indent(indent))
        printKotlinTypeDefinition(k.sub_type, indent + 1)
    }
}

printKotlinClass :: proc(k: KotlinClass) {
    fmt.println("kotlinClass:\n{")
    oneIndent := make_indent(1)
    twoIndent := make_indent(2)
    fmt.printfln("%sName: %s", oneIndent, k.name)
    

    implements := "None"
    if k.extends != nil {
        implements = k.extends^
    }
    fmt.printfln("%sExtends: %s", oneIndent, implements)
    fmt.printfln("%sClass Type: %s", oneIndent, kotlinClassTypeToString(k.classType))

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

kotlinTypeToTypescriptType :: proc(t: KotlinTypeDefinition) -> string {
    builder := strings.builder_make()
    switch t.kotlinType {
        case .String:
            strings.write_string(&builder, "string")
        case .Int, .Float:
            strings.write_string(&builder, "number")
        case .Bool:
            strings.write_string(&builder, "boolean")
        case .Struct:
            strings.write_string(&builder, t.name)
        case .List:
            //DOESN'T WORK
            strings.write_string(&builder, "any[]")
        case .TypeParam:
            //DOESN'T WORK
            strings.write_string(&builder, t.name) 
    }

    if t.nullable {
        strings.write_string(&builder, " | null")
    }

    return strings.to_string(builder)   
}