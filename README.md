<div align="center">

# ✨ NexEra — AI Demos

**NexEra** is a polished demo app showcasing two real-time AI-style interaction pipelines:

🧱 **Prototype 1 — Text-to-3D**  
Type an object prompt → generate/update a 3D asset in the scene.

🧍‍♂️ **Prototype 2 — NL → Avatar**  
Type natural-language commands → drive a live avatar with smooth actions.

</div>

---

## 🧠 What’s inside

### Prototype 1 — Text-to-3D
- Prompt input + example chips
- Updates the object in-scene
- Controls: reset view, center object, snap-to-grid
- Status + progress feedback

### Prototype 2 — NL → Avatar
- Same premium UI layout as Prototype 1
- Commands like:
  - `Walk to the desk`
  - `Walk to the screen`
  - `Point at the screen`
  - `Wave hello`
  - `Walk back`
- Clean run log + explanation panel
- No top-level await (stable Vite/Vercel builds)

---

## 🚀 Live modes

The app uses URL query routing:

- Landing (default):  
  `/`

- Prototype 1 (Text-to-3D):  
  `/?mode=asset`

- Prototype 2 (Avatar demo):  
  `/?mode=avatar`

---

## 🧩 Tech stack
- **Vite** (build + dev server)
- **Three.js** (rendering)
- Vanilla JS UI (fast, minimal overhead)
- Deploy-ready for **Vercel**

---

## ✅ Getting started (local)

### 1) Install dependencies
```bash
npm install
