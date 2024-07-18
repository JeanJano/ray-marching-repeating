import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import GUI from 'lil-gui'
import testVertexShader from './shaders/test/vertex.glsl'
import testFragmentShader from './shaders/test/fragment.glsl'
import { uniform } from 'three/examples/jsm/nodes/Nodes.js'

/**
 * Base
 */
// Debug
const gui = new GUI()

// Canvas
const canvas = document.querySelector('canvas.webgl')

// Scene
const scene = new THREE.Scene()

/**
 * Sizes
 */
const sizes = {
    width: window.innerWidth,
    height: window.innerHeight
}

// Handle window resize
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
  
    const nearPlaneWidth = camera.near * Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * camera.aspect * 2;
    const nearPlaneHeight = nearPlaneWidth / camera.aspect;
    rayMarchPlane.scale.set(nearPlaneWidth, nearPlaneHeight, 1);
  
    if (renderer) renderer.setSize(window.innerWidth, window.innerHeight);
  });

/**
 * Camera
 */
// Base camera
const camera = new THREE.PerspectiveCamera(75, sizes.width / sizes.height, 0.1, 100)
camera.position.z = 5
scene.add(camera)

// Controls
const controls = new OrbitControls(camera, canvas)
controls.enableDamping = true

/**
 * Renderer
 */
const renderer = new THREE.WebGLRenderer({
    canvas: canvas
})
renderer.setSize(sizes.width, sizes.height)
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

// Set background color
const backgroundColor = new THREE.Color(0x3399ee);
renderer.setClearColor(backgroundColor, 1);

/**
 * Lights
 */
const light = new THREE.DirectionalLight(0xffffff, 1)
light.position.set(0, 0, 1)
scene.add(light)

/**
 * Screen Plane
 */
const geometry = new THREE.PlaneGeometry()
const material = new THREE.ShaderMaterial({
    vertexShader: testVertexShader,
    fragmentShader: testFragmentShader,
    uniforms: {
        u_eps: { value: 0.001 },
        u_maxDis: { value: 1000 },
        u_maxSteps: { value: 100 },

        u_clearColor: { value: backgroundColor },
      
        u_camPos: { value: camera.position },
        u_camToWorldMat: { value: camera.matrixWorld },
        u_camInvProjMat: { value: camera.projectionMatrixInverse },
      
        u_lightDir: { value: light.position },
        u_lightColor: { value: light.color },
      
        u_diffIntensity: { value: 0.5 },
        u_specIntensity: { value: 3 },
        u_ambientIntensity: { value: 0.15 },
        u_shininess: { value: 16 },
      
        u_time: { value: 0 },
      }
})
const rayMarchPlane = new THREE.Mesh(geometry, material)

const nearPlaneWidth = camera.near * Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * camera.aspect * 2
const nearPlaneHeight = nearPlaneWidth / camera.aspect
rayMarchPlane.scale.set(nearPlaneWidth, nearPlaneHeight, 1)

scene.add(rayMarchPlane)

/**
 * Animate
 */
let cameraForwardPos = new THREE.Vector3(0,0,-1)
const VECTOR3ZERO = new THREE.Vector3(0,0,0)

let time = Date.now()

const tick = () =>
{
     // Update screen plane position and rotation
    cameraForwardPos = camera.position.clone().add(camera.getWorldDirection(VECTOR3ZERO).multiplyScalar(camera.near));
    rayMarchPlane.position.copy(cameraForwardPos);
    rayMarchPlane.rotation.copy(camera.rotation);

    // uniforms.u_time.value = (Date.now() - time) / 1000
    // time
    material.uniforms.u_time.value = (Date.now() - time) / 1000

    // Render
    renderer.render(scene, camera)

    // Update controls
    controls.update()


    // Call tick again on the next frame
    window.requestAnimationFrame(tick)
}

tick()