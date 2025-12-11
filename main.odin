package main

import "core:fmt"
import os "core:os/os2"
import "core:bufio"
import "core:strings"
import "core:mem"
import "base:runtime"

InfoStruct :: struct {
    rootPath: ^string,
    dtoDirectory: ^string
}

allocString :: proc(value: string, destination: ^^string ) {
    temp := new(string)
    bytes := make([]u8, len(value))
    runtime.copy_from_string(bytes, value)
    temp^ = string(bytes)
    destination^ = temp
}

main :: proc() {
    dir := ".";
    if len(os.args) > 1 {
        dir = os.args[1];
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

    x := new(InfoStruct)
    defer mem.free(x);

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
            stringFindBetween(line, x)
            if(x.rootPath == nil) {
                fmt.printfln("Could not extract group value")
                return
            }
            break
        }
        delete(line, context.allocator)
    }
    findDto(dir, x)
    enterFirstFile(x)
}

stringFindBetween :: proc(line: string, info: ^InfoStruct) {
    start := strings.index(line, `"`);
    if start >= 0 {
        start += 1;
        end := strings.index(line[start:], `"`);
        if end >= 0 {
            end += start;
            group := line[start:end];

            allocString(group, &info.rootPath)
        }
    }
}

findDto :: proc(startDir: string, infoStruct: ^InfoStruct) {
    //Hard coded for kotlin project file structure
    projectDir := "/src/main/kotlin/"
    group, ok := strings.replace(infoStruct.rootPath^, ".", "/", -1, context.allocator)
    if(!ok) {
        fmt.printfln("Alloc error in string replace")
        runtime.exit(2)
    }
    path := strings.join({startDir, projectDir, group}, "")

    w := os.walker_create(path)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            fmt.eprintfln("failed walking %s: %s", path, err)
            continue
        }
        if info.type == os.File_Type.Directory && strings.has_prefix(info.name, "dto") {
            allocString(info.fullpath, &infoStruct.dtoDirectory)
        }
    }
}

enterFirstFile :: proc(infoStruct: ^InfoStruct) {
    w := os.walker_create(infoStruct.dtoDirectory^)
    defer os.walker_destroy(&w)

    for info in os.walker_walk(&w) {
        if path, err := os.walker_error(&w); err != nil {
            continue
        }
        if info.type == os.File_Type.Regular && strings.has_suffix(info.name, ".kt") {
            parseKotlin(info.fullpath)
            break;
        }
    }
}