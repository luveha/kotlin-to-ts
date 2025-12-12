package main

import "core:strings"
import "core:fmt"
import "ast"

generateTypescript :: proc(k: ast.KotlinClass) {
    builder := strings.builder_make()
    
    switch k.classType {
        // This is made under the assumption that only classes can be received in ts since no instance of an interface can be created and sent
        case .Class: strings.write_string(&builder, "export ")
        case .Interface:
        case .Enum:
    }
    strings.write_string(&builder, "interface ")
    strings.write_string(&builder, k.name)
    if(len(k.type_params) != 0) {
        strings.write_string(&builder, "<")
        for i in 0..<len(k.type_params) {
            strings.write_string(&builder, k.type_params[i])
        }
        strings.write_string(&builder, ">")
    }

    if(k.extends != nil) {
        strings.write_string(&builder, " extends ")
        strings.write_string(&builder, k.extends^.name)
    }
    strings.write_string(&builder, " {{\n")

    oneIndent := make_indent(1)
    for t in k.fields {
        strings.write_string(&builder, oneIndent)
        strings.write_string(&builder, t.name)
        strings.write_string(&builder, ": ")
        strings.write_string(&builder, kotlinTypeToTypescriptType(t.fieldType))
        strings.write_string(&builder, ";\n")
    }
    strings.write_string(&builder, "}\n")
    fmt.printfln(strings.to_string(builder))
}
