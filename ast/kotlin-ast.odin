package ast

File :: struct {
	classes: [dynamic]^KotlinClass,
}

new_file :: proc() -> ^File {
	file := new(File)
    classes := make([dynamic]^KotlinClass)
	file.classes = classes

	return file
}

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

free_kotlin_type_def :: proc(ktd: ^KotlinTypeDefinition) {
    //delete(ktd.type_params)
}

Field :: struct {
    name: string,
    fieldType: KotlinTypeDefinition
}

free_field :: proc(f: ^Field) {
    free_kotlin_type_def(&f.fieldType)
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


