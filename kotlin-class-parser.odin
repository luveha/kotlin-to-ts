package main

import "core:fmt"
import os "core:os/os2"
import "core:bufio"
import "core:strings"
import r "core:text/regex"

parseKotlin :: proc(path: string) {
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
    regex, err := r.create("\\b(?:class|interface)\\s+([A-Za-z_]\\w*)") //Captures class or interface name
    if err != nil {
        return
    }
    
    className: string
    for {
        line, err := bufio.reader_read_string(&reader, '\n', context.allocator)
        if err != nil { //Special case fo EOF
            if len(line) > 0 {
                delete(line, context.allocator)
            }
            return
        }
        capture, success := r.match_and_allocate_capture(regex, line);
        defer r.destroy_capture(capture)
        if success {
            className = capture.groups[1]
            break
        }
            
        delete(line, context.allocator)
    }
    
    fields := make([dynamic]Field);
    k := KotlinClass{
        name = className,
        extends = nil,
        fields = fields,
    }
    collectedLines := make([dynamic]string)

    for {
        line, err := bufio.reader_read_string(&reader, '\n', context.allocator)
        if err != nil { //Special case fo EOF
            if len(line) > 0 {
                delete(line, context.allocator)
            }
            return
        }
        append(&collectedLines, line)
        if(strings.contains(line, ")")) {
            break;
        }
    }

    regex_field, err_regex := r.create(`\b(var|val)\s+([A-Za-z_]\w*)\s*:\s*([A-Za-z_][\w<>?]*)`)
    if err_regex != nil {
        return
    }

    for l in collectedLines {
        capture, success := r.match_and_allocate_capture(regex_field, l)
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
                default: 
                    if strings.starts_with(typeName, "List<") && strings.ends_with(typeName, ">") { //Nested type is not struct, struct is when a costume type. Here it needs to read and parse it
                        kotlinType = KotlinType.List
                        sub := &KotlinTypeDefinition{}
                        sub.type = KotlinType.Struct
                        sub.name = typeName[5:len(typeName)-1]
                        sub.nullable = false
                        subType = sub
                    } else { //Look at this assumption
                        kotlinType = KotlinType.Struct
                    }
            }
            field := Field{
                name = fieldName,
                type = KotlinTypeDefinition{
                    type = kotlinType,
                    name = typeName,
                    nullable = nullable,
                    sub_type = subType,
                },
            }
            append(&k.fields, field)
        }
    }
    printKotlinClass(k)
}