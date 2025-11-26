float warp = 0.4;
float scan = 0.7;
float screenSaverSpeed = 1.0;

float rectSDF(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + min(max(d.x, d.y), 0.0);
}

float pingpong(float t, float length) {
    float r = mod(t, 2.0 * length);
    return (r < length) ? r : (2.0 * length - r);
}

vec3 renderLinear(vec2 fragCoord, vec2 R) {
    // Background
    vec2 uv = fragCoord / R;
    vec3 color = texture(iChannel0, uv).rgb;

    // Bouncing DVD logo
    vec2 logoSize = vec2(120.0, 60.0);
    vec2 speed    = vec2(180.0, 130.0) * screenSaverSpeed;

    float px = pingpong(iTime * speed.x, R.x - logoSize.x);
    float py = pingpong(iTime * speed.y, R.y - logoSize.y);

    vec2 logoPos = vec2(px, py) + logoSize * 0.5;
    vec2 rel = fragCoord - logoPos;

    float d = rectSDF(rel, logoSize * 0.5);
    float edge = smoothstep(3.0, 0.5, d);

    float t = iTime * 0.5;
    vec3 logoColor = 0.4 + 0.6 * sin(vec3(0.8, 1.3, 2.0) * t);

    // --- SOFT BLEND INTO EXISTING SCREEN CONTENT ---
    float alpha = edge * 0.1;       // (adjust 0.7 for more/less blending)
    color = mix(color, logoColor, alpha);

    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 R = iResolution.xy;

    // UV before warp
    vec2 uv = fragCoord / R;
    vec2 dc = abs(uv - 0.5);
    dc *= dc;

    // CRT warp
    uv.x = (uv.x - 0.5) * (1.0 + dc.y * (warp * 0.3)) + 0.5;
    uv.y = (uv.y - 0.5) * (1.0 + dc.x * (warp * 0.4)) + 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Warp back into linear framebuffer coords
    vec2 warpedCoord = uv * R;

    // Linear image → warped to CRT
    vec3 color = renderLinear(warpedCoord, R);

    // Scanlines last (correct for CRT)
    float scanMix = abs(sin(fragCoord.y / 2.5)) * 0.5 * scan;
    color = mix(color, vec3(0.0), scanMix);

    fragColor = vec4(color, 0.9);
}
