// From vertex shader
varying vec2 vUv;

// From CPU
uniform vec3 u_clearColor;

uniform float u_eps;
uniform float u_maxDis;
uniform int u_maxSteps;

uniform vec3 u_camPos;
uniform mat4 u_camToWorldMat;
uniform mat4 u_camInvProjMat;

uniform vec3 u_lightDir;
uniform vec3 u_lightColor;

uniform float u_diffIntensity;
uniform float u_specIntensity;
uniform float u_ambientIntensity;
uniform float u_shininess;

uniform float u_time;

float smin(float a, float b, float k) { // smooth min function
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float cubeSDF(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p + c * 0.5, c) - c * 0.5;
}

float scene(vec3 p) {
  // repeat the scene
  vec3 c = vec3(10.0); // size of the repeating scene
  vec3 rp = repeat(p, c);

  vec3 cubeSize = vec3(0.5);

  // distance to cube
  float cubeDis = cubeSDF(rp, cubeSize);

  // distance to sphere 2
  float sphereDis = distance(rp, vec3(sin(u_time) * atan(u_time), cos(u_time) * sin(u_time), -sin(u_time))) - 0.6;

  float smoothMerge = smin(cubeDis, sphereDis, 0.6);

  // return the minimum distance between the two spheres smoothed by 0.5
  return smoothMerge;
}

float rayMarch(vec3 ro, vec3 rd)
{
    float d = 0.; // total distance travelled
    float cd; // current scene distance
    vec3 p; // current position of ray

    for (int i = 0; i < u_maxSteps; ++i) { // main loop
        p = ro + d * rd; // calculate new position
        cd = scene(p); // get scene distance
        
        // if we have hit anything or our distance is too big, break loop
        if (cd < u_eps || d >= u_maxDis) break;

        // otherwise, add new scene distance to total distance
        d += cd;
    }

    return d; // finally, return scene distance
}

vec3 sceneCol(vec3 p) {
  float sphereDis = distance(p, vec3(sin(u_time) * atan(u_time), cos(u_time) * sin(u_time), -sin(u_time))) - 0.5;
  float cubeDis = cubeSDF(p, vec3(0.5));

  vec3 colorCube = vec3(0.8, 0.2, 0.2);
  vec3 colorSphere = vec3(0.2, 0.2, 0.8); 

  // Smoothly blend colors based on the distance to sphere2 and cube
  float h = clamp(0.5 + 0.5 * (cubeDis - sphereDis) / 0.5, 0.0, 1.0);

  return mix(colorCube, colorSphere, h);
}

vec3 normal(vec3 p) {
    float eps = u_eps * 0.5;
    vec3 n = vec3(
        scene(p + vec3(eps, 0, 0)) - scene(p - vec3(eps, 0, 0)),
        scene(p + vec3(0, eps, 0)) - scene(p - vec3(0, eps, 0)),
        scene(p + vec3(0, 0, eps)) - scene(p - vec3(0, 0, eps))
    );
    return normalize(n);
}

void main()
{
    // Get UV from vertex shader
    vec2 uv = vUv.xy;

    // Get ray origin and direction from camera uniforms
    vec3 ro = u_camPos;
    vec3 rd = (u_camInvProjMat * vec4(uv*2.-1., 0, 1)).xyz;
    rd = (u_camToWorldMat * vec4(rd, 0)).xyz;
    rd = normalize(rd);
    
    // Ray marching and find total distance travelled
    float disTravelled = rayMarch(ro, rd); // use normalized ray

    // Find the hit position
    vec3 hp = ro + disTravelled * rd;
    
    // Get normal of hit point
    vec3 n = normal(hp);

    if (disTravelled >= u_maxDis) { // if ray doesn't hit anything
        gl_FragColor = vec4(u_clearColor,1);
    } else { // if ray hits something
        // Calculate Diffuse model
        float dotNL = dot(n, u_lightDir);
        float diff = max(dotNL, 0.0) * u_diffIntensity;
        float spec = pow(diff, u_shininess) * u_specIntensity;
        float ambient = u_ambientIntensity;
        
        vec3 color = u_lightColor * (sceneCol(hp) * (spec + ambient + diff));
        gl_FragColor = vec4(color,1); // color output
    }
}