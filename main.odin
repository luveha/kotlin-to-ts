package main

import "core:fmt"
import os "core:os/os2"
import "core:bufio"
import "core:strings"
import "core:mem"
import "base:runtime"
import "ast"
import "lexer"
import "parser"
import set "data_structs"
import "string_utils"

ProjectInfo :: struct {
    rootPath: string,
    dtoDirectory: string,
    controllerDirectory: string,
    ignoreDirectories: []string,
    ktClasses: [dynamic]ast.KotlinClass,
    controllers: [dynamic]ast.Controller,
    definedTypes: set.string_set,
    undefinedTypes: set.string_set,
}


main :: proc() {
    dir := ".";
    ignoreList := ""
    if len(os.args) > 1 {
        dir = os.args[1];
    }
    if len(os.args) > 2 {
        ignoreList = os.args[2]
    }
    
    path, err := os.join_path({dir, "build.gradle.kts"}, context.allocator);
    f, open_err := os.open(path, os.File_Flags{.Read});
    if open_err != nil {
        dir, dir_err := os.get_absolute_path(dir, context.allocator);
        if dir_err != nil {
            fmt.println("Not in a kotlin gradle project:", err, "(also failed to get directory:", dir, ")");
        } else {
            fmt.println("Not in a kotlin gradle project\nCurrent directory:", dir);
        }
        return;
    }
    defer os.close(f);

    s := os.to_stream(f);

    reader := bufio.Reader{};
    buffer: [1024]u8;
    bufio.reader_init_with_buf(&reader, s, buffer[:]);

    pInfo := new(ProjectInfo)
    if(len(ignoreList) > 0) {
        pInfo.ignoreDirectories = strings.split(ignoreList, "|")
    }
    ktClasses   := make([dynamic]ast.KotlinClass);  pInfo.ktClasses         = ktClasses
    controllers := make([dynamic]ast.Controller);   pInfo.controllers       = controllers
    def_sets    := set.make_set();                  pInfo.definedTypes      = def_sets
    undef_sets  := set.make_set();                  pInfo.undefinedTypes    = undef_sets 
    set.add_kotlin_types(&pInfo.definedTypes)

    defer mem.free(pInfo);

    /*
    Nothing certain can be said about the group value in a build gradle.But this says something
    sourceSets {
        main {
            kotlin.srcDirs("does/not/exist")
        }
    }
        so if this does not exists it should use the standard
    for {
        line, err := bufio.reader_read_string(&reader, '\n', context.allocator)
        if err != nil { //Special case fo EOF
            if len(line) > 0 {
                //Currently it fails if the group variable is on the last line
                //not sure how gradle build files are setup but it shouldn't really happend
                fmt.println("Fails, the group variable was on the last line:", line)
                delete(line, context.allocator)
            }

            // Exists if it couldn't find the group
            fmt.printfln("Couldn't find the \'group = \"...\" \'")
            return
        }
        if (strings.contains(line, "group = \"")) {
            stringFindBetween(line, pInfo)
            if(pInfo.rootPath == nil) {
                fmt.printfln("Could not extract group value")
                return
            }
            break
        }
        delete(line, context.allocator)
    }
        */
    findDto(dir, pInfo)

    findControllers(dir, pInfo)

    parseKotlinFiles(pInfo)
    parseControllers(pInfo)

    findMissingEnums(dir,pInfo)

    if !os.is_dir("generated") {
        os.make_directory("generated")
    }

    generateDTOs(pInfo.ktClasses)


    for c in pInfo.controllers {
        generate_typescript_api(c)
    }
}

stringFindBetween :: proc(line: string, info: ^ProjectInfo) {
    start := strings.index(line, `"`);
    if start >= 0 {
        start += 1;
        end := strings.index(line[start:], `"`);
        if end >= 0 {
            end += start;
            group := line[start:end];

            string_utils.copy_string(group, &info.rootPath)
        }
    }
}

findDto :: proc(startDir: string, infoStruct: ^ProjectInfo) {
    //Hard coded for kotlin project file structure
    projectDir := "/src/main/kotlin/"
    path, _ := os.join_path({startDir, "src", "main", "kotlin"}, context.temp_allocator)

    w := os.walker_create(path)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            fmt.eprintfln("failed walking %s: %s", path, err)
            continue
        }
        if info.type == os.File_Type.Directory && strings.has_prefix(info.name, "dto") {
            string_utils.copy_string(info.fullpath, &infoStruct.dtoDirectory)
        }
    }
}

findControllers :: proc(startDir: string, infoStruct: ^ProjectInfo) {
    //Hard coded for kotlin project file structure
    projectDir := "/src/main/kotlin/"
    path := strings.join({startDir, projectDir}, "")

    w := os.walker_create(path)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            fmt.eprintfln("failed walking %s: %s", path, err)
            continue
        }
        if info.type == os.File_Type.Directory && strings.has_prefix(info.name, "controller") {
            string_utils.copy_string(info.fullpath, &infoStruct.controllerDirectory)
        }
    }
}

parseKotlinFiles :: proc(pInfo: ^ProjectInfo) {
    if pInfo.dtoDirectory == "" {
        fmt.println("Warning: dtoDirectory is empty, skipping parse.")
        return
    }
    w := os.walker_create(pInfo.dtoDirectory)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            continue
        }
        if info.type == os.File_Type.Directory && string_utils.wordContainsList(info.name, pInfo.ignoreDirectories){
            os.walker_skip_dir(&w)
            continue
        }

        if info.type == os.File_Type.Regular && strings.has_suffix(info.name, ".kt") {
            data, okFile := os.read_entire_file_from_path(info.fullpath, context.allocator)
            if okFile != nil {
                // could not read file
                continue
            }
            //defer delete(data, context.allocator)
            it := string(data)
            l := lexer.new_lexer(it)
            p := parser.new_parser(l)
            file := parser.parse_file(p)
            process_parsed_classes(pInfo, file.classes)
        }
    }
}

parseControllers :: proc(pInfo: ^ProjectInfo) {
    if pInfo.controllerDirectory == "" {
        fmt.println("Warning: dtoDirectory is empty, skipping parse.")
        return
    }
    w := os.walker_create(pInfo.controllerDirectory)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            continue
        }
        if info.type == os.File_Type.Directory && string_utils.wordContainsList(info.name, pInfo.ignoreDirectories){
            os.walker_skip_dir(&w)
            continue
        }

        if info.type == os.File_Type.Regular && strings.has_suffix(info.name, ".kt") {
            data, okFile := os.read_entire_file_from_path(info.fullpath, context.allocator)
            if okFile != nil {
                // could not read file
                continue
            }
            //defer delete(data, context.allocator)
            it := string(data)
            l := lexer.new_lexer(it)
            p := parser.new_parser(l)
            file := parser.parse_file(p)
            process_parsed_classes(pInfo, file.classes)
            process_parsed_controllers(pInfo, file.controller)
            for e in p.errors {
                fmt.printfln("%s", e)
            }
        }
    }
}

findMissingEnums :: proc(startDir: string, pInfo: ^ProjectInfo) {
    projectDir := "/src/main/kotlin/"
    path := strings.join({startDir, projectDir}, "")

    w := os.walker_create(path)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            continue
        }
        if info.type == os.File_Type.Directory && (string_utils.wordContainsList(info.name, pInfo.ignoreDirectories) || strings.contains(info.name, "dto")){
            os.walker_skip_dir(&w)
            continue
        }

        if info.type == os.File_Type.Regular && strings.has_suffix(info.name, ".kt") {
            data, okFile := os.read_entire_file_from_path(info.fullpath, context.allocator)
            if okFile != nil {
                // could not read file
                continue
            }
            for x in pInfo.undefinedTypes {
                if(strings.contains(string(data), strings.concatenate({"enum class ", x}))) {
                    //Needs to be optimized to not parse entire file
                    it := string(data)
                    l := lexer.new_lexer(it)
                    p := parser.new_parser(l)
                    ktClasses := parser.parse_file(p)
                    for k in ktClasses.classes {
                        if(set.contains(pInfo.undefinedTypes, k.name)) {
                            set.remove(&pInfo.undefinedTypes, k.name)
                            set.add(&pInfo.definedTypes, k.name)
                            append(&pInfo.ktClasses, k^)
                        }
                    }
                    break
                }
            }
            
            //defer delete(data, context.allocator)
        }
    }
}

process_parsed_classes :: proc(pInfo: ^ProjectInfo, ktClasses: [dynamic]^ast.KotlinClass) {
    for kt in ktClasses {
        append(&pInfo.ktClasses, kt^)

        if set.contains(pInfo.undefinedTypes, kt.name) {
            set.remove(&pInfo.undefinedTypes, kt.name)
        }
        set.add(&pInfo.definedTypes, kt.name)

        if kt.extends != nil {
            if !(set.contains(pInfo.definedTypes, kt.extends.name)) {
                set.add(&pInfo.undefinedTypes, kt.extends.name)
            }
            for tp in kt.extends.type_params {
                type := ast.get_kotlin_type_from_string(tp)
                if !(set.contains(pInfo.definedTypes, tp) && type != .TypeParam) {
                    set.add(&pInfo.undefinedTypes, tp)
                }
            }
        }

        for f in kt.fields {
            if !(set.contains(pInfo.definedTypes, f.fieldType.name)) {
                if f.fieldType.kotlinType == ast.KotlinType.TypeParam {
                    continue
                }
                set.add(&pInfo.undefinedTypes, f.fieldType.name)
            }
        }
    }
}

process_parsed_controllers:: proc(pInfo: ^ProjectInfo, controller: ^ast.Controller) {
    append(&pInfo.controllers, controller^)

    for endp in controller.endpoints {
        
        if(endp.body.kotlinType == .Struct) {
            if !set.contains(pInfo.definedTypes, endp.body.name) {
                set.add(&pInfo.undefinedTypes, endp.body.name)
            }
        }
        if(endp.dto.kotlinType == .Struct) {
            if !set.contains(pInfo.definedTypes, endp.dto.name) {
                set.add(&pInfo.undefinedTypes, endp.dto.name)
            }
        }
    }
}


