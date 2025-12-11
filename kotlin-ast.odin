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
    sub_type: ^KotlinTypeDefinition
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
    extends: ^string,
    fields: [dynamic]Field,
}