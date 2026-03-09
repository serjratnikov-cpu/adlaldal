#version 120

uniform vec4 round;
uniform vec2 size;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;

float alpha(vec2 d, vec2 d1, float round) {
    vec2 v = abs(d) - d1 + round;
    return min(max(v.x, v.y), 0.0) + length(max(v, 0.0)) - round;
}

void main() {
    vec2 coord = gl_TexCoord[0].st * size;
    vec2 centre = size * 0.5;
    float alphaValue;

    if (coord.x < centre.x && coord.y < centre.y) {
        alphaValue = alpha(centre - coord, centre - 1.0, round.x);
    } else if (coord.x >= centre.x && coord.y < centre.y) {
        alphaValue = alpha(coord - centre, centre - 1.0, round.y);
    } else if (coord.x < centre.x && coord.y >= centre.y) {
        alphaValue = alpha(centre - coord, centre - 1.0, round.z);
    } else {
        alphaValue = alpha(coord - centre, centre - 1.0, round.w);
    }

    vec4 topColor = mix(color1, color2, smoothstep(0.0, 1.0, coord.x / size.x));
    vec4 bottomColor = mix(color3, color4, smoothstep(0.0, 1.0, coord.x / size.x));
    vec4 finalColor = mix(topColor, bottomColor, smoothstep(0.0, 1.0, coord.y / size.y));

    gl_FragColor = vec4(finalColor.rgb, finalColor.a * (1.0 - smoothstep(0.0, 1.5, alphaValue)));
}
