package ast

File :: struct {
	classes: [dynamic]^KotlinClass,
    rootEndpoint: string,
    endpoint: [dynamic]^Endpoint
}

new_file :: proc() -> ^File {
	file := new(File)
    classes := make([dynamic]^KotlinClass)
    endpoint := make([dynamic]^Endpoint)

	file.classes = classes
    file.endpoint = endpoint

	return file
}

// END POINT START

Endpoint :: struct {
    name:           string,
    url:            string,
    param:          QueryParam,
    requestMethod:  HTTP_REQUEST_METHOD,
    body:           string,
    dto:            string,
}

HTTP_REQUEST_METHOD :: enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    PATCH,
    OPTIONS,
    CONNECT,
    TRACE,
    NON_PARSABLE,
}

QueryParam :: enum {
    Firm,
    Engagement,
    Task,
}

// END POINT END

KotlinType :: enum {
    String,
    Int,
    Float,
    Bool,
    Struct,
    Date,
    List,
    TypeParam,
}

KotlinTypeDefinition :: struct {
    kotlinType: KotlinType,
    name: string,
    nullable: bool,
    type_params: [dynamic]string,
}

Field :: struct {
    name: string,
    fieldType: KotlinTypeDefinition
}

KotlinClassType :: enum {
    Class,
    Interface,
    Enum,
}

KotlinClass :: struct {
    name: string,
    classType: KotlinClassType,
    type_params: [dynamic]string, 
    extends: ^KotlinTypeDefinition,
    fields: [dynamic]^Field,
}

KotlinPrimitiveMetadata :: struct {
    enum_value: KotlinType,
    kotlin_name: string,
    lexer_token_name: string,
    typescript_name: string,
    is_lexer_keyword: bool,
}

KOTLIN_PRIMITIVES :: []KotlinPrimitiveMetadata{
    {.String,   "String",           "String",   "string",   true    },
    {.Int,      "Int",              "INT",      "number",   false   },
    {.Float,    "Float",            "FLOAT",    "number",   false   },
    {.Bool,     "Boolean",          "BOOL",     "boolean",  true    },
    {.Date,     "ZonedDateTime",    "DATE",     "Date",     true    },
    {.List,     "List",             "LIST",     "[]",       true    },
}

get_kotlin_type_from_string :: proc(s: string) -> KotlinType {
    if len(s) == 1 { //Usally one word identifies are type params
        return .TypeParam
    }
    
    for prim in KOTLIN_PRIMITIVES {
        if prim.kotlin_name == s {
            return prim.enum_value
        }
    }
    
    return .Struct
}

get_kotlin_string :: proc(kt: KotlinType) -> string {
    for prim in KOTLIN_PRIMITIVES {
        if prim.enum_value == kt {
            return prim.kotlin_name
        }
    }
    
    #partial switch kt {
        case .Struct: return "Struct"
        case .TypeParam: return "TypeParam"
        case: return ""
    }
}

new_kotlin_class :: proc() -> ^KotlinClass {
    k := new(KotlinClass)

    k.type_params = make([dynamic]string)
    k.fields = make([dynamic]^Field)

    k.extends = nil 

    return k
}

new_endpoint :: proc() -> ^Endpoint {
    e := new(Endpoint)

    return e
}

free_endpoint :: proc(e: ^Endpoint) {
    if e == nil do return
    
    free(e)
}

freeKotlinTypeDefinition :: proc(t: ^KotlinTypeDefinition) {
    if t == nil {
        return
    }

    for &tp in t.type_params {
        free(&tp)
    }
    delete(t.type_params)

    delete(t.name)

    free(t)
}

freeField :: proc(f: ^Field) {
    if f == nil {
        return
    }
    freeKotlinTypeDefinition(&f.fieldType)
}

freeKotlinClass :: proc(k: ^KotlinClass) {
    if k == nil {
        return
    }

    for &f in k.fields {
        freeField(f)
    }
    delete(k.fields)

    if k.extends != nil {
        freeKotlinTypeDefinition(k.extends)
    }

    k.type_params = nil

    free(k)
}


