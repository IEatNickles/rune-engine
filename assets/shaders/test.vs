#version 460 core

layout(location=0) in vec3 a_pos;
layout(location=1) in vec3 a_nrm;
layout(location=2) in vec2 a_tex;

out vec2 v_tex;

void main() {
  v_tex = a_tex;
  gl_Position = vec4(a_pos, 1.0);
}
