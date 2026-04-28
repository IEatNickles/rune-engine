#version 460 core

@shader vs
layout(location=0) in vec3 a_pos;
layout(location=1) in vec3 a_nrm;
layout(location=2) in vec2 a_tex;
layout(location=3) in vec4 a_col;
layout(location=4) in vec4 a_tan;

layout(std140, binding=0) uniform Camera {
  mat4 u_viewproj;
};
uniform mat4 u_world;

out vec3 v_nrm;
out vec2 v_tex;

void main() {
  v_nrm = a_nrm * inverse(mat3(u_world));
  v_tex = a_tex;
  gl_Position = u_viewproj * u_world * vec4(a_pos, 1.0);
}

@shader fs
in vec3 v_nrm;
in vec2 v_tex;

uniform sampler2D u_texture;

out vec4 o_color;

void main() {
  vec3 tint = vec3(55.0 / 255.0, 180.0 / 255.0, 180.0 / 255.0) * 0.2;
  vec3 light_dir = -normalize(vec3(0.333, -0.2, -0.333));
  o_color = vec4(texture(u_texture, v_tex).rgb * max(dot(v_nrm, light_dir) * 2.0, 0.1) + tint, 1.0);
  // o_color = vec4(v_tex, 0.0, 1.0);
}

@program vs fs
