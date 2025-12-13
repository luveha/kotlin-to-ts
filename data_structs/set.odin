package data_structs

import "core:fmt"
void :: struct{}

string_set :: map[string]void

_void :: void{}

make_set :: proc() -> string_set {
    m := make_map(map[string]void)
    return m
}

add :: proc(s: ^string_set, element: string) -> bool {
    ok := element in s
    if !ok {
        s[element] = _void
        return true
    }
    return false
}

contains :: proc(s: string_set, element: string) -> bool {
    ok := element in s
    return ok
}

remove :: proc(s: ^string_set, element: string) -> bool {
    ok := element in s
    if ok {
        delete_key(s, element)
        return true
    }
    return false
}

size :: proc(s: string_set) -> int {
    return len(s)
}

clear_set :: proc(s: ^string_set) {
    clear(s)
}

print_set :: proc(s: string_set) {
    for key, _ in s {
	    fmt.printfln("%s, len: %i", key, len(key))
    }
}

to_slice :: proc(s: string_set) -> [dynamic]string {
    r := make([dynamic]string, len(s))
    for key, _ in s {
	    append(&r, key)
    }
    return r
}

add_kotlin_types :: proc(s: ^string_set) {
    s["String"] = _void
    s["Int"] = _void
    s["Boolean"] = _void
    s["ZonedDateTime"] = _void
}