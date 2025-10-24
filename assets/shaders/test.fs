#version 460 core

in vec3 v_nrm;
in vec2 v_tex;

uniform sampler2D u_texture;

out vec4 o_color;

void main() {
  vec3 tint = vec3(55.0 / 255.0, 180.0 / 255.0, 180.0 / 255.0) * 0.2;
  vec3 light_dir = -normalize(vec3(0.333, -0.2, -0.333));
  o_color = vec4(texture(u_texture, v_tex).rgb * max(dot(v_nrm, light_dir) * 2.0, 0.1) + tint, 1.0);
}
