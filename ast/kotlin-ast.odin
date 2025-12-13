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

get_kotlin_type_from_string :: proc(s: string) -> KotlinType {
    if len(s) == 1 { // Simple heuristic for a generic type parameter (like T, E, V)
        return KotlinType.TypeParam
    }

    switch s {
        case "String":
            return KotlinType.String
        case "Int":
            return KotlinType.Int
        case "Float":
            return KotlinType.Float
        case "Boolean":
            return KotlinType.Bool
        case "List":
            return KotlinType.List
        case "ZonedDateTime":
            return KotlinType.Date
        case:
            return KotlinType.Struct
    }
}

new_kotlin_class :: proc() -> ^KotlinClass {
    k := new(KotlinClass)

    k.type_params = make([dynamic]string)
    k.fields = make([dynamic]^Field)

    k.extends = nil 

    return k
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


