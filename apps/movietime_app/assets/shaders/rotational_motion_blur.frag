#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 size;
uniform float angle;
uniform float angleDelta;
uniform float intensity;
uniform sampler2D frame;

out vec4 fragColor;

void main() {
  const int numSteps = 40;
  vec2 uv = FlutterFragCoord().xy / size;
  vec2 p = uv - vec2(0.5, 0.5);

  float span = intensity * angleDelta;
  vec4 pixel = vec4(0.0);

  for (int i = 0; i < numSteps; i++) {
    float t = float(i) / float(numSteps);
    float a = angle - span * t;
    float c = cos(a);
    float s = sin(a);
    vec2 q = vec2(p.x * c + p.y * s, -p.x * s + p.y * c) + vec2(0.5, 0.5);
    pixel += texture(frame, q);
  }

  pixel /= float(numSteps);
  fragColor = pixel;
}