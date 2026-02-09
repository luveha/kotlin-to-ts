package main

import "core:fmt"
import "core:strings"
import "ast"
import os "core:os/os2"

generate_typescript_api :: proc(controller: ast.Controller) {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)

    generate_imports(controller.rootEndpoint, &builder)

    strings.write_string(&builder, strings.concatenate({"const rootApi = \"", controller.rootEndpoint, "\"\n\n"}))

    for endpoint in controller.endpoints {
        generate_typescript_endpoint(endpoint, &builder)
        strings.write_string(&builder, "\n")
    }
    ok := os.write_entire_file(strings.concatenate({"./generated/", controller.rootEndpoint,".ts"}), strings.to_string(builder))
    if ok != nil {
        fmt.eprintln("Failed to write file")
    }
}

generate_imports :: proc(s: string, b: ^strings.Builder) {
    strings.write_string(b, "import * as DTO from \"./dto.ts\";\n")
    strings.write_string(b, "import Axios from 'axios';\n")
    
    strings.write_string(b, "\n")
}

generate_typescript_endpoint :: proc(endpoint: ^ast.Endpoint, b: ^strings.Builder){    
    strings.write_string(b, "export async function ")
    strings.write_string(b, endpoint.name)
    strings.write_string(b, "(")
    
    generate_constructor(b, endpoint)
    
    strings.write_string(b, "): ")
    
    generate_return_type(b, endpoint)
    
    strings.write_string(b, " {\n")
    
    generate_function_body(b, endpoint)
    
    strings.write_string(b, "}\n")
}

generate_constructor :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, "kc: string")
    
    switch endpoint.param {
        case .Firm:
            strings.write_string(b, ", firmId: string")
        case .Engagement:
            strings.write_string(b, ", engagementId: string")
        case .Task:
            strings.write_string(b, ", taskId: string")
        case .None:
    }
    
    if len(endpoint.body.name) > 0 {
        strings.write_string(b, ", body: DTO.")
        strings.write_string(b, endpoint.body.name)
    }
}

generate_return_type :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, "Promise<")
    
    if len(endpoint.dto.name) > 0 {
        strings.write_string(b, "DTO.")
        if(endpoint.dto.kotlinType == .List) {
            strings.write_string(b, endpoint.dto.type_params[0]) //List should always only have one typeparam, under the assumption that there is no nested
            strings.write_string(b, "[]")
        }
        else {
            strings.write_string(b, endpoint.dto.name)
        }
    } else {
        strings.write_string(b, "void")
    }
    
    strings.write_string(b, ">")
}

generate_function_body :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, "  return await Axios.")
    
    method_name := get_axios_method(endpoint.requestMethod)
    strings.write_string(b, method_name)
    
    strings.write_string(b, "(`${rootApi}")
    generate_url_path(b, endpoint)
    strings.write_string(b, "`")
    
    has_body := len(endpoint.body.name) > 0
    
    if has_body {
        strings.write_string(b, ", body")
    }
    
    strings.write_string(b, ", {\n")
    strings.write_string(b, "    headers: {\n")
    strings.write_string(b, "      Authorization: `Bearer ${kc}`,\n")
    strings.write_string(b, "    },\n")
    strings.write_string(b, "  })")
    
    if len(endpoint.dto.name) > 0 {
        strings.write_string(b, ".then(x => x.data);\n")
    } else {
        strings.write_string(b, ".then(() => {});\n")
    }
}

generate_url_path :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, endpoint.url)
    
    switch endpoint.param {
        case .Firm:
            strings.write_string(b, "?firmId=${firmId}")
        case .Engagement:
            strings.write_string(b, "?engagementId=${engagementId}")
        case .Task:
            strings.write_string(b, "?taskId=${taskId}")
        case .None:
    }
}

get_axios_method :: proc(method: ast.HTTP_REQUEST_METHOD) -> string {
    switch method {
        case .GET:
            return "get"
        case .POST:
            return "post"
        case .PUT:
            return "put"
        case .DELETE:
            return "delete"
        case .PATCH:
            return "patch"
        case .HEAD:
            return "head"
        case .OPTIONS:
            return "options"
        case .CONNECT, .TRACE, .NON_PARSABLE:
            return "get" // Default fallback
    }
    return "get"
}