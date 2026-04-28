package renderer

Create_Pipeline_Proc :: #type proc(ctx: rawptr, info: ^Pipeline_Create_Info) -> Pipeline
Destroy_Pipeline_Proc :: #type proc(ctx: rawptr, pipeline: Pipeline)
Create_Shader_Proc :: #type proc(ctx: rawptr, info: ^Shader_Create_Info) -> Shader
Destroy_Shader_Proc :: #type proc(ctx: rawptr, shader: Shader)
Create_Texture_Proc :: #type proc(ctx: rawptr, info: ^Texture_Create_Info) -> Texture
Destroy_Texture_Proc :: #type proc(ctx: rawptr, texture: Texture)
Create_Buffer_Proc :: #type proc(ctx: rawptr, info: ^Buffer_Create_Info) -> Buffer
Destroy_Buffer_Proc :: #type proc(ctx: rawptr, buffer: Buffer)

Bind_Pipeline_Proc :: #type proc(ctx: rawptr, pipeline: Pipeline)
Bind_Vertex_Buffers_Proc :: #type proc(ctx: rawptr, buffers: []Buffer)
Bind_Index_Buffer_Proc :: #type proc(ctx: rawptr, buffer: Buffer)
Draw_Proc :: #type proc(ctx: rawptr, element_count: int, first_element := 0, instance_count := 1, first_instance := 0)

Shader_Set_Push_Constants_Proc :: #type proc(ctx: rawptr, shader: Shader, name: string, data: rawptr, size: int, offset := 0)

Get_Texture_Descriptor_Proc :: #type proc(ctx: rawptr, texture: Texture) -> u64

Begin_Pass_Proc :: #type proc(ctx: rawptr, info: ^Pass_Info)
End_Pass_Proc :: #type proc(ctx: rawptr)
