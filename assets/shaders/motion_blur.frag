#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 size;
uniform vec2 prevSize;
uniform vec2 deltaPosition;
uniform float intensity;
uniform sampler2D frame;

out vec4 fragColor;

void main() {
  const int numSteps = 60;
  vec2 uv = FlutterFragCoord().xy/size;
  vec2 deltaPositionUv = deltaPosition/size;
  vec2 sizeRatio = size/prevSize;
  vec4 pixel = vec4(0);

  for(int i=0;i<int(numSteps);i++){
    vec2 scaled = uv+(uv*sizeRatio-uv)*float(i)/float(numSteps)*intensity;
    vec2 translated = scaled - intensity*deltaPositionUv*sizeRatio*float(i)/float(numSteps);
    pixel+=texture(frame,translated);
  }

  pixel/=numSteps;
  fragColor = pixel;
}