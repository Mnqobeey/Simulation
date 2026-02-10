# ============================================================
# enable-colors.ps1
# Adds color parsing to src/main.js (prompt-driven colors)
# ============================================================

$ErrorActionPreference = "Stop"
$mainPath = ".\src\main.js"
if (-not (Test-Path $mainPath)) { throw "src/main.js not found" }

@"
import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";

const promptEl = document.getElementById("prompt");
const runBtn = document.getElementById("run");
const statusEl = document.getElementById("status");
const jsonEl = document.getElementById("json");
const mount = document.getElementById("app");

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0b0f1a);

const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 500);
camera.position.set(0, 0, 4);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
mount.innerHTML = "";
mount.appendChild(renderer.domElement);

scene.add(new THREE.AmbientLight(0xffffff, 1.0));
const dir = new THREE.DirectionalLight(0xffffff, 1.2);
dir.position.set(3, 4, 6);
scene.add(dir);

let currentObj = null;

function fitCameraToObject(object, offset = 1.35) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z);
  const fov = camera.fov * (Math.PI / 180);
  let cameraZ = Math.abs((maxDim / 2) / Math.tan(fov / 2));
  cameraZ *= offset;
  camera.position.set(center.x, center.y, cameraZ + center.z);
  camera.lookAt(center);
}

function centerObject(object) {
  const box = new THREE.Box3().setFromObject(object);
  const center = box.getCenter(new THREE.Vector3());
  object.position.sub(center);
}

function setObject(obj) {
  if (currentObj) scene.remove(currentObj);
  currentObj = obj;
  scene.add(currentObj);
  centerObject(currentObj);
  fitCameraToObject(currentObj);
}

const loader = new GLTFLoader();

function animate() {
  requestAnimationFrame(animate);
  if (currentObj) currentObj.rotation.y += 0.01;
  renderer.render(scene, camera);
}
animate();

window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

async function callApi(prompt) {
  const res = await fetch("/api/model", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt })
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || ("HTTP " + res.status));
  return data;
}

async function loadGlb(url) {
  return new Promise((resolve, reject) => {
    loader.load(url + "?v=" + Date.now(), g => resolve(g.scene), undefined, reject);
  });
}

/** -------------- COLOR PARSING -------------- **/
const COLOR_WORDS = {
  red: 0xef4444,
  green: 0x22c55e,
  blue: 0x3b82f6,
  yellow: 0xfacc15,
  orange: 0xf97316,
  purple: 0xa855f7,
  pink: 0xec4899,
  white: 0xffffff,
  black: 0x111827,
  gray: 0x9ca3af,
  silver: 0xc0c0c0,
  gold: 0xf59e0b,
  cyan: 0x06b6d4
};

function pickColorFromPrompt(prompt) {
  const t = (prompt || "").toLowerCase();
  for (const key of Object.keys(COLOR_WORDS)) {
    if (t.includes(key)) return COLOR_WORDS[key];
  }
  return null; // no color specified
}

function applyColorToObject(obj, hex) {
  if (!hex || !obj) return;
  obj.traverse((n) => {
    if (n.isMesh && n.material) {
      const mats = Array.isArray(n.material) ? n.material : [n.material];
      mats.forEach((m) => {
        if (m && "color" in m) {
          m.color = new THREE.Color(hex);
          m.needsUpdate = true;
        }
      });
    }
  });
}
/** ------------------------------------------ **/

function buildPrimitive(file, hexColor) {
  const f = (file || "").toLowerCase();

  if (f.includes("sphere")) {
    return new THREE.Mesh(
      new THREE.SphereGeometry(0.8, 32, 32),
      new THREE.MeshStandardMaterial({ color: hexColor ?? 0x3b82f6 })
    );
  }

  if (f.includes("box")) {
    return new THREE.Mesh(
      new THREE.BoxGeometry(1.4, 1.0, 1.0),
      new THREE.MeshStandardMaterial({ color: hexColor ?? 0x22c55e })
    );
  }

  if (f.includes("extinguisher")) {
    const g = new THREE.Group();
    g.add(new THREE.Mesh(
      new THREE.CylinderGeometry(0.45, 0.45, 1.4, 32),
      new THREE.MeshStandardMaterial({ color: hexColor ?? 0xef4444 })
    ));
    // little handle
    const handle = new THREE.Mesh(
      new THREE.TorusGeometry(0.25, 0.05, 16, 32),
      new THREE.MeshStandardMaterial({ color: 0x111827 })
    );
    handle.position.set(0, 0.65, 0.2);
    g.add(handle);
    return g;
  }

  return null;
}

async function run() {
  const prompt = promptEl.value.trim();
  if (!prompt) return;

  runBtn.disabled = true;
  statusEl.textContent = "Generating...";
  jsonEl.textContent = "{}";

  try {
    const hexColor = pickColorFromPrompt(prompt);

    const data = await callApi(prompt);
    jsonEl.textContent = JSON.stringify(data, null, 2);

    const file = data?.model?.file;
    const url = data?.model?.url;

    // Prefer primitives for our demo objects (reliable + colorable)
    const prim = buildPrimitive(file, hexColor);
    if (prim) {
      setObject(prim);
    } else {
      // GLB path: load and tint (optional but nice)
      const obj = await loadGlb(url);
      applyColorToObject(obj, hexColor);
      setObject(obj);
    }

    statusEl.textContent = "100% • Rendered";
  } catch (e) {
    statusEl.textContent = "Error • " + e.message;
  } finally {
    runBtn.disabled = false;
  }
}

runBtn.addEventListener("click", run);
promptEl.addEventListener("keydown", e => e.key === "Enter" && run());
"@ | Set-Content -Encoding UTF8 $mainPath

Write-Host "✅ Color support enabled in src/main.js" -ForegroundColor Green
