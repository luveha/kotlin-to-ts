package main

import "core:strings"
import "core:fmt"
import os "core:os/os2"
import "ast"
import "string_utils"

defition: string = "export const baseUrl = import.meta.env.VITE_API_URL || \"https://api.revidocs.dk\";"

generateDTOs :: proc(kList: [dynamic]ast.KotlinClass) {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    for kt in kList {
        generateTypescript(kt, &builder)
    }
    ok := os.write_entire_file("./generated/dto.ts", strings.to_string(builder))
    if ok != nil {
        fmt.eprintln("Failed to write file")
    }

    ok2 := os.write_entire_file("./generated/definition.ts", defition)
    if ok2 != nil {
        fmt.eprintln("Failed to write file")
    }
}

generateTypescript :: proc(k: ast.KotlinClass, b: ^strings.Builder) {
    switch k.classType {
        case .Class, .Interface:
            is_type_alias := len(k.fields) == 0 && k.extends != nil

            if(is_type_alias) {
                generate_type_alias(b, k)
            } else {
                generate_interface(b, k)
            }
        case .Enum:
            generate_enum(b, k)
    }
    
}

generate_export_type :: proc(b: ^strings.Builder, k: ast.KotlinClass) {
    // Legacy, but kept so it is possible to change if needed
    switch k.classType {
        case .Class:     strings.write_string(b, "export ")
        case .Interface: strings.write_string(b, "export ")
        case .Enum:      strings.write_string(b, "export ")
    }
}

generate_enum :: proc(b: ^strings.Builder, k: ast.KotlinClass) {
    strings.write_string(b, "type ")
    strings.write_string(b, k.name)
    generateGenerics(b, k.type_params)
    if(k.extends != nil) {
        strings.write_string(b, " extends ")
        strings.write_string(b, k.extends^.name)
        generateGenerics(b, k.extends.type_params)
    }
    strings.write_string(b, " = ")
    for i in 0..<len(k.fields) {
        strings.write_string(b, `"`)
        strings.write_string(b, k.fields[i].fieldType.name)
        strings.write_string(b, `"`)
        if(i != len(k.fields) - 1) {
            strings.write_string(b, ` | `)
        }
    }
    strings.write_string(b, "\n")
}

generate_interface :: proc(b: ^strings.Builder, k: ast.KotlinClass) {
    generate_export_type(b, k)
    strings.write_string(b, "interface ")
    strings.write_string(b, k.name)
    generateGenerics(b, k.type_params)

    if(k.extends != nil) {
        strings.write_string(b, " extends ")
        strings.write_string(b, k.extends^.name)
        generateGenerics(b, k.extends.type_params)
    }
    strings.write_string(b, " {\n")

    oneIndent := string_utils.make_indent(1)
    for t in k.fields {
        strings.write_string(b, oneIndent)
        strings.write_string(b, t.name)
        strings.write_string(b, ": ")
        strings.write_string(b, generate_type(t.fieldType))
        strings.write_string(b, ";\n")
    }
    strings.write_string(b, "}\n")
}

generate_type_alias :: proc(b: ^strings.Builder, k: ast.KotlinClass) {
    generate_export_type(b, k)

    strings.write_string(b, "type ")
    strings.write_string(b, k.name)
    generateGenerics(b, k.type_params)
    strings.write_string(b, " = ")
    strings.write_string(b, k.extends^.name)
    generateGenerics(b, k.extends.type_params)
    strings.write_string(b, ";\n")

}

generateGenerics :: proc(b: ^strings.Builder, t_params: [dynamic]string) {
    if(len(t_params) != 0) {
        strings.write_string(b, "<")
        for i in 0..<len(t_params) {
            strings.write_string(b, t_params[i])
        }
        strings.write_string(b, ">")
    }
}

generate_type :: proc(t: ast.KotlinTypeDefinition) -> string {
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
            strings.write_string(&builder, t.name)
            strings.write_string(&builder, "[]")
        case .Date:
            strings.write_string(&builder, "Date")
        case .TypeParam:
            strings.write_string(&builder, t.name) 
        case .ByteArray:
            strings.write_string(&builder, "ERR") 
    }

    if t.nullable {
        strings.write_string(&builder, " | null")
    }

    return strings.to_string(builder)   
}