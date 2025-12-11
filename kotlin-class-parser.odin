package main

import "core:fmt"
import os "core:os/os2"
import "core:bufio"
import "core:strings"
import r "core:text/regex"

parseKotlin :: proc(path: string, p: ^ProjectInfo) {
    f, open_err := os.open(path, os.File_Flags{.Read});
    if open_err != nil {
        fmt.printfln("Could not parse: %s", path)
        return;
    }
    defer os.close(f);

    s := os.to_stream(f);

    reader := bufio.Reader{};
    buffer: [1024]u8;
    bufio.reader_init_with_buf(&reader, s, buffer[:]);

    // Finds class
        //Should also find interfaces
        // missing enums, might need to parse differently
    regex_class, err := r.create(`\b(class|interface)\s+([A-Za-z_]\w*)\s*(?::\s*([A-Za-z_]\w*))?`) //Captures class or interface name
    if err != nil {
        return
    }

    regex_field, err_regex := r.create(`\b(var|val)\s+([A-Za-z_]\w*)\s*:\s*([A-Za-z_][\w<>?]*)`)
    if err_regex != nil {
        return
    }
    regex_end_impls, err_regex2 := r.create(`:\s*([A-Za-z_]\w*)`)
    if err_regex2 != nil {
        return
    }

    for {
        ok := parseKotlinClass(&reader, regex_class, regex_field, regex_end_impls, p)
        if (!ok) {
            break;
        }
    }
    
}

//Needs to cleanup if early exit
parseKotlinClass :: proc(
    reader: ^bufio.Reader, regex_class: 
    r.Regular_Expression, regex_field: 
    r.Regular_Expression, regex_end: 
    r.Regular_Expression, 
    p: ^ProjectInfo
) -> bool {
    className: string
    classType: KotlinClassType
    classExtends: ^string
    isEOF := false;

    for {
        if(isEOF) {
            return false
        }
        line, err := bufio.reader_read_string(reader, '\n', context.allocator)
        defer delete(line, context.allocator)
        if err != nil { //Special case fo EOF
            if len(line) > 0 {
                isEOF = true
            } else {
                return false
            }
        }
        capture, success := r.match_and_allocate_capture(regex_class, line);
        defer r.destroy_capture(capture)
        if success {
            switch capture.groups[1] {
                case "class":
                    classType = KotlinClassType.Class
                case "interface":
                    classType = KotlinClassType.Interface
            }
            className = capture.groups[2]
            if(len(capture.groups) > 3) {
                classExtends = &capture.groups[3]
            }
            break
        }
    }
    
    fields := make([dynamic]Field);
    k := KotlinClass{
        name = className,
        extends = classExtends,
        fields = fields,
    }
    collectedLines := make([dynamic]string)

    for {
        if(isEOF) {
            return false
        }
        line, err := bufio.reader_read_string(reader, '\n', context.allocator)
        defer delete(line, context.allocator)
        if err != nil { //Special case fo EOF
            if len(line) > 0 {
                isEOF = true
            } else {
                return false
            }
        }
        append(&collectedLines, line)
        if(strings.contains(line, ")") || strings.contains(line, `}`)) {
            capture, success := r.match_and_allocate_capture(regex_end, line);
            defer r.destroy_capture(capture)
            if(success) {
                k.extends = &capture.groups[1]
            }

            break;
        }
    }

    containsStruct := false;
    extractKotlinFields(collectedLines[:], regex_field, &k, &containsStruct)
    //printKotlinClass(k)
    if(k.extends != nil) {
        append(&p.classesExtends, k)
    } else if (containsStruct) {
        append(&p.classesDynamic, k)
    } else {
        append(&p.classesPrimitive, k)
    }
    return true
}
extractKotlinFields :: proc(collectedLines: []string, regex: r.Regular_Expression, k: ^KotlinClass, c: ^bool) {
    for l in collectedLines {
        capture, success := r.match_and_allocate_capture(regex, l)
        defer r.destroy_capture(capture)
        if success {
            fieldName := capture.groups[2]
            typeName := capture.groups[3]

            nullable := strings.ends_with(typeName, "?")
            if nullable {
                typeName = strings.trim_suffix(typeName, "?")
            }

            kotlinType: KotlinType
            subType: ^KotlinTypeDefinition = nil
            
            switch typeName {
                case "String":
                    kotlinType = KotlinType.String
                case "Int":
                    kotlinType = KotlinType.Int
                case "Float":
                    kotlinType = KotlinType.Float
                case "Boolean":
                    kotlinType = KotlinType.Bool
                case: //default
                    if strings.starts_with(typeName, "List<") && strings.ends_with(typeName, ">") { //Nested type is not struct, struct is when a costume type. Here it needs to read and parse it
                        kotlinType = KotlinType.List
                        sub := &KotlinTypeDefinition{}
                        sub.kotlinType = KotlinType.Struct //This is wrong
                        sub.name = typeName[5:len(typeName)-1]
                        sub.nullable = false
                        subType = sub
                    } else { //Look at this assumption
                        if(!c^){
                            c^ = true;
                        }
                        kotlinType = KotlinType.Struct
                    }
            }
            field := Field{
                name = fieldName,
                fieldType = KotlinTypeDefinition{
                    kotlinType = kotlinType,
                    name = typeName,
                    nullable = nullable,
                    sub_type = subType,
                },
            }
            append(&k.fields, field)
        }
    }
}