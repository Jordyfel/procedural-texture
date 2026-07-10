float sd_circle(vec2 p) {
    return length(p) - 0.5;
}

float sd_rect(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x ,d.y), 0.0);
}
