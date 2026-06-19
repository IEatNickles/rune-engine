package renderer

import "rendering"

Pipeline     :: rendering.Pipeline
Shader       :: rendering.Shader
Texture      :: rendering.Texture
Buffer       :: rendering.Buffer
Sampler      :: rendering.Sampler
Image        :: rendering.Image
View         :: rendering.View
Image_View   :: rendering.Image_View
Buffer_View  :: rendering.Buffer_View
Bindings     :: rendering.Bindings

Pipeline_Create_Info   :: rendering.Pipeline_Create_Info
Shader_Create_Info     :: rendering.Shader_Create_Info
Texture_Create_Info    :: rendering.Texture_Create_Info
Buffer_Create_Info     :: rendering.Buffer_Create_Info
Image_Create_Info      :: rendering.Image_Create_Info
Image_View_Create_Info :: rendering.Image_View_Create_Info
Bindings_Create_Info   :: rendering.Bindings_Create_Info

Shader_Reflection_Data :: rendering.Shader_Reflection_Data

Pass_Info :: rendering.Pass_Info

Feature_Flags :: rendering.Renderer_Feature_Flags
Feature_Flag  :: rendering.Renderer_Feature_Flag

GL_Renderer_Create_Info :: rendering.GL_Renderer_Create_Info
Vk_Renderer_Create_Info :: rendering.Vk_Renderer_Create_Info

GL_Swapchain :: rendering.GL_Swapchain
Vk_Swapchain :: rendering.Vk_Swapchain
Swapchain :: rendering.Swapchain

Create_Pipeline_Proc :: #type proc(info: ^Pipeline_Create_Info) -> Pipeline
Destroy_Pipeline_Proc :: #type proc(pipeline: Pipeline)
Create_Shader_Proc :: #type proc(info: ^Shader_Create_Info) -> Shader
Destroy_Shader_Proc :: #type proc(shader: Shader)
Create_Texture_Proc :: #type proc(info: ^Texture_Create_Info) -> Texture
Destroy_Texture_Proc :: #type proc(texture: Texture)
Create_Buffer_Proc :: #type proc(info: ^Buffer_Create_Info) -> Buffer
Destroy_Buffer_Proc :: #type proc(buffer: Buffer)
Create_Image_Proc :: #type proc(info: ^Image_Create_Info) -> Image
Destroy_Image_Proc :: #type proc(image: Image)
Create_Image_View_Proc :: #type proc(info: ^Image_View_Create_Info) -> Image_View
Destroy_Image_View_Proc :: #type proc(view: Image_View)
Create_Bindings_Proc :: #type proc(info: ^Bindings_Create_Info) -> Bindings
Destroy_Bindings_Proc :: #type proc(bindings: Bindings)

Bind_Pipeline_Proc :: #type proc(pipeline: Pipeline)
Bind_Vertex_Buffers_Proc :: #type proc(buffers: []Buffer)
Bind_Index_Buffer_Proc :: #type proc(buffer: Buffer)
Draw_Proc :: #type proc(element_count: int, first_element := 0, instance_count := 1, first_instance := 0)

Shader_Set_Push_Constants_Proc :: #type proc(shader: Shader, name: string, data: rawptr, size: int, offset := 0)

Get_Texture_Descriptor_Proc :: #type proc(texture: Texture) -> u64

Begin_Pass_Proc :: #type proc(info: ^Pass_Info)
End_Pass_Proc :: #type proc()
Get_Render_Target_Proc :: #type proc() -> Image_View
Submit_Proc :: #type proc()
Present_Proc :: #type proc()
