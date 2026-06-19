#version 460 core

layout(location=0) in vec3 v_nrm;
layout(location=1) in vec2 v_tex;

layout(binding=0)  uniform sampler u_sampler;
layout(binding=32) uniform texture2D u_texture;

layout(location=0) out vec4 o_color;

void main() {
  vec3 tint = vec3(55.0 / 255.0, 180.0 / 255.0, 180.0 / 255.0) * 0.2;
  vec3 light_dir = -normalize(vec3(0.333, -0.2, -0.333));
  float ndotl = max(dot(v_nrm, light_dir), 0.1);
  o_color = vec4(texture(sampler2D(u_texture, u_sampler), v_tex).rgb * ndotl + tint, 1.0);
}
