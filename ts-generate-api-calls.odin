package main

import "core:strings"
import "ast"

generate_typescript_endpoint :: proc(endpoint: ^ast.Endpoint) -> string {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    
    strings.write_string(&builder, "export async function ")
    strings.write_string(&builder, endpoint.name)
    strings.write_string(&builder, "(")
    
    generate_constructor(&builder, endpoint)
    
    strings.write_string(&builder, "): ")
    
    generate_return_type(&builder, endpoint)
    
    strings.write_string(&builder, " {\n")
    
    generate_function_body(&builder, endpoint)
    
    strings.write_string(&builder, "}\n")
    
    return strings.clone(strings.to_string(builder))
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

    if len(endpoint.body) > 0 {
        strings.write_string(b, ", body: ")
        strings.write_string(b, endpoint.body)
    }
}

generate_return_type :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, "Promise<")
    
    if len(endpoint.dto) > 0 {
        strings.write_string(b, endpoint.dto)
    } else {
        strings.write_string(b, "void")
    }
    
    strings.write_string(b, ">")
}

generate_function_body :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, "  return await Axios.")
    
    method_name := get_axios_method(endpoint.requestMethod)
    strings.write_string(b, method_name)
    
    strings.write_string(b, "(`${url}")
    generate_url_path(b, endpoint)
    strings.write_string(b, "`")
    
    has_body := len(endpoint.body) > 0
    
    if has_body {
        strings.write_string(b, ", body")
    }
    
    strings.write_string(b, ", {\n")
    strings.write_string(b, "    headers: {\n")
    strings.write_string(b, "      Authorization: `Bearer ${kc}`,\n")
    strings.write_string(b, "    },\n")
    strings.write_string(b, "  })")
    
    if len(endpoint.dto) > 0 {
        strings.write_string(b, ".then(x => x.data);\n")
    } else {
        strings.write_string(b, ".then(() => {});\n")
    }
}

generate_url_path :: proc(b: ^strings.Builder, endpoint: ^ast.Endpoint) {
    strings.write_string(b, endpoint.url)
    
    switch endpoint.param {
        case .Firm:
            strings.write_string(b, "?firmId={firmId}")
        case .Engagement:
            strings.write_string(b, "?engagementId={engagementId}")
        case .Task:
            strings.write_string(b, "?taskId={taskId}")
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

// Generate all endpoints from a controller
generate_all_endpoints :: proc(controller: ^ast.Controller) -> string {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    
    for endpoint in controller.endpoints {
        endpoint_code := generate_typescript_endpoint(endpoint)
        strings.write_string(&builder, endpoint_code)
        strings.write_string(&builder, "\n")
    }
    
    return strings.clone(strings.to_string(builder))
}