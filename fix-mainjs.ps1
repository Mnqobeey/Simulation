# ============================================================
# fix-mainjs.ps1
# Overwrites src/main.js with a stable version that:
# - calls /api/model
# - renders primitives for sphere/box/extinguisher
# - loads GLB for everything else (cache-busted)
# ============================================================

$ErrorActionPreference = "Stop"

$mainPath = ".\src\main.js"
if (-not (Test-Path $mainPath)) {
  Write-Host "ERROR: src\main.js not found" -ForegroundColor Red
  exit 1
}

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

async function callApi(prompt) {
  const res = await fetch("/api/model", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt })
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || "HTTP " + res.status);
  return data;
}

async function loadGlb(url) {
  return new Promise((resolve, reject) => {
    loader.load(url + "?v=" + Date.now(), g => resolve(g.scene), undefined, reject);
  });
}

function buildPrimitive(file) {
  const f = file.toLowerCase();
  if (f.includes("sphere")) return new THREE.Mesh(
    new THREE.SphereGeometry(0.8, 32, 32),
    new THREE.MeshStandardMaterial({ color: 0x3b82f6 })
  );
  if (f.includes("box")) return new THREE.Mesh(
    new THREE.BoxGeometry(1.4, 1.0, 1.0),
    new THREE.MeshStandardMaterial({ color: 0x22c55e })
  );
  if (f.includes("extinguisher")) {
    const g = new THREE.Group();
    g.add(new THREE.Mesh(
      new THREE.CylinderGeometry(0.45, 0.45, 1.4, 32),
      new THREE.MeshStandardMaterial({ color: 0xff3333 })
    ));
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
    const data = await callApi(prompt);
    jsonEl.textContent = JSON.stringify(data, null, 2);

    const file = data.model.file;
    const url = data.model.url;

    const prim = buildPrimitive(file);
    if (prim) {
      setObject(prim);
    } else {
      const obj = await loadGlb(url);
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

Write-Host "✅ src/main.js fixed successfully" -ForegroundColor Green
