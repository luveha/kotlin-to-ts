package main

KotlinType :: enum {
    String,
    Int,
    Float,
    Bool,
    Struct,
    List,
    TypeParam,
}

KotlinTypeDefinition :: struct {
    kotlinType: KotlinType,
    name: string,
    nullable: bool,
    type_params: [dynamic]KotlinTypeDefinition,
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
    type_params: []string, 
    extends: ^KotlinTypeDefinition,
    fields: [dynamic]Field,
}