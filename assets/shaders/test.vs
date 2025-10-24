#version 460 core

layout(location=0) in vec3 a_pos;
layout(location=1) in vec3 a_nrm;
layout(location=2) in vec2 a_tex;
layout(location=3) in vec4 a_col;
layout(location=4) in vec4 a_tan;

uniform mat4 u_world;
uniform mat4 u_view;
uniform mat4 u_proj;

out vec3 v_nrm;
out vec2 v_tex;

void main() {
  v_nrm = a_nrm * inverse(mat3(u_world));
  v_tex = a_tex;
  gl_Position = u_proj * u_view * u_world * vec4(a_pos, 1.0);
}
