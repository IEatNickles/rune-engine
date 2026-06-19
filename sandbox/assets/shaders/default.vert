#version 460 core

layout(location=0) in vec3 a_pos;
layout(location=1) in vec3 a_nrm;
layout(location=2) in vec2 a_tex;
layout(location=3) in vec4 a_col;
layout(location=4) in vec4 a_tan;

layout(push_constant) uniform scene_t {
  mat4 u_proj;
  mat4 u_view;
  mat4 u_world;
} scene;

layout(location=0) out vec3 v_nrm;
layout(location=1) out vec2 v_tex;

void main() {
  v_nrm = a_nrm * inverse(mat3(scene.u_world));
  v_tex = a_tex;
  gl_Position = scene.u_proj * scene.u_view * scene.u_world * vec4(a_pos, 1.0);
}
