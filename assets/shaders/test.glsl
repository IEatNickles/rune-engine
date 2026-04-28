@vs vs
in vec3 a_pos;
in vec3 a_nrm;
in vec2 a_tex;
in vec4 a_col;
in vec4 a_tan;

layout(push_constant) uniform scene_t {
  mat4 u_proj;
  mat4 u_view;
  mat4 u_world;
} scene;

out vec3 v_nrm;
out vec2 v_tex;

void main() {
  v_nrm = a_nrm * inverse(mat3(scene.u_world));
  v_tex = a_tex;
  gl_Position = scene.u_proj * scene.u_view * scene.u_world * vec4(a_pos, 1.0);
}
@end

@fs fs
in vec3 v_nrm;
in vec2 v_tex;

layout(binding=0) uniform sampler2D u_texture;

out vec4 o_color;

void main() {
  vec3 tint = vec3(55.0 / 255.0, 180.0 / 255.0, 180.0 / 255.0) * 0.2;
  vec3 light_dir = -normalize(vec3(0.333, -0.2, -0.333));
  o_color = vec4(texture(u_texture, v_tex).rgb * max(dot(v_nrm, light_dir) * 2.0, 0.1) + tint, 1.0);
}
@end

@program test vs fs
