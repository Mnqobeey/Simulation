import{M as S,O as se,B as j,F as I,S as T,U as L,V as c,W as z,H as A,N as ie,C as K,a as v,b as w,A as re,c as ae,d as oe,e as le,f as ne,P as he,g as ue,D as fe,h as W,G as ce,i as F,T as N,I as de,j as me,k as pe,l as ge,m as ve}from"./three.module-BZTDV-n9.js";const Y={name:"CopyShader",uniforms:{tDiffuse:{value:null},opacity:{value:1}},vertexShader:`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`,fragmentShader:`

		uniform float opacity;

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );
			gl_FragColor = opacity * texel;


		}`};class y{constructor(){this.isPass=!0,this.enabled=!0,this.needsSwap=!0,this.clear=!1,this.renderToScreen=!1}setSize(){}render(){console.error("THREE.Pass: .render() must be implemented in derived pass.")}dispose(){}}const xe=new se(-1,1,1,-1,0,1);class be extends j{constructor(){super(),this.setAttribute("position",new I([-1,3,0,-1,-1,0,3,-1,0],3)),this.setAttribute("uv",new I([0,2,0,0,2,0],2))}}const we=new be;class X{constructor(e){this._mesh=new S(we,e)}dispose(){this._mesh.geometry.dispose()}render(e){e.render(this._mesh,xe)}get material(){return this._mesh.material}set material(e){this._mesh.material=e}}class Te extends y{constructor(e,s){super(),this.textureID=s!==void 0?s:"tDiffuse",e instanceof T?(this.uniforms=e.uniforms,this.material=e):e&&(this.uniforms=L.clone(e.uniforms),this.material=new T({name:e.name!==void 0?e.name:"unspecified",defines:Object.assign({},e.defines),uniforms:this.uniforms,vertexShader:e.vertexShader,fragmentShader:e.fragmentShader})),this.fsQuad=new X(this.material)}render(e,s,i){this.uniforms[this.textureID]&&(this.uniforms[this.textureID].value=i.texture),this.fsQuad.material=this.material,this.renderToScreen?(e.setRenderTarget(null),this.fsQuad.render(e)):(e.setRenderTarget(s),this.clear&&e.clear(e.autoClearColor,e.autoClearDepth,e.autoClearStencil),this.fsQuad.render(e))}dispose(){this.material.dispose(),this.fsQuad.dispose()}}class G extends y{constructor(e,s){super(),this.scene=e,this.camera=s,this.clear=!0,this.needsSwap=!1,this.inverse=!1}render(e,s,i){const r=e.getContext(),t=e.state;t.buffers.color.setMask(!1),t.buffers.depth.setMask(!1),t.buffers.color.setLocked(!0),t.buffers.depth.setLocked(!0);let a,n;this.inverse?(a=0,n=1):(a=1,n=0),t.buffers.stencil.setTest(!0),t.buffers.stencil.setOp(r.REPLACE,r.REPLACE,r.REPLACE),t.buffers.stencil.setFunc(r.ALWAYS,a,4294967295),t.buffers.stencil.setClear(n),t.buffers.stencil.setLocked(!0),e.setRenderTarget(i),this.clear&&e.clear(),e.render(this.scene,this.camera),e.setRenderTarget(s),this.clear&&e.clear(),e.render(this.scene,this.camera),t.buffers.color.setLocked(!1),t.buffers.depth.setLocked(!1),t.buffers.color.setMask(!0),t.buffers.depth.setMask(!0),t.buffers.stencil.setLocked(!1),t.buffers.stencil.setFunc(r.EQUAL,1,4294967295),t.buffers.stencil.setOp(r.KEEP,r.KEEP,r.KEEP),t.buffers.stencil.setLocked(!0)}}class Me extends y{constructor(){super(),this.needsSwap=!1}render(e){e.state.buffers.stencil.setLocked(!1),e.state.buffers.stencil.setTest(!1)}}class Ce{constructor(e,s){if(this.renderer=e,this._pixelRatio=e.getPixelRatio(),s===void 0){const i=e.getSize(new c);this._width=i.width,this._height=i.height,s=new z(this._width*this._pixelRatio,this._height*this._pixelRatio,{type:A}),s.texture.name="EffectComposer.rt1"}else this._width=s.width,this._height=s.height;this.renderTarget1=s,this.renderTarget2=s.clone(),this.renderTarget2.texture.name="EffectComposer.rt2",this.writeBuffer=this.renderTarget1,this.readBuffer=this.renderTarget2,this.renderToScreen=!0,this.passes=[],this.copyPass=new Te(Y),this.copyPass.material.blending=ie,this.clock=new K}swapBuffers(){const e=this.readBuffer;this.readBuffer=this.writeBuffer,this.writeBuffer=e}addPass(e){this.passes.push(e),e.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}insertPass(e,s){this.passes.splice(s,0,e),e.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}removePass(e){const s=this.passes.indexOf(e);s!==-1&&this.passes.splice(s,1)}isLastEnabledPass(e){for(let s=e+1;s<this.passes.length;s++)if(this.passes[s].enabled)return!1;return!0}render(e){e===void 0&&(e=this.clock.getDelta());const s=this.renderer.getRenderTarget();let i=!1;for(let r=0,t=this.passes.length;r<t;r++){const a=this.passes[r];if(a.enabled!==!1){if(a.renderToScreen=this.renderToScreen&&this.isLastEnabledPass(r),a.render(this.renderer,this.writeBuffer,this.readBuffer,e,i),a.needsSwap){if(i){const n=this.renderer.getContext(),h=this.renderer.state.buffers.stencil;h.setFunc(n.NOTEQUAL,1,4294967295),this.copyPass.render(this.renderer,this.writeBuffer,this.readBuffer,e),h.setFunc(n.EQUAL,1,4294967295)}this.swapBuffers()}G!==void 0&&(a instanceof G?i=!0:a instanceof Me&&(i=!1))}}this.renderer.setRenderTarget(s)}reset(e){if(e===void 0){const s=this.renderer.getSize(new c);this._pixelRatio=this.renderer.getPixelRatio(),this._width=s.width,this._height=s.height,e=this.renderTarget1.clone(),e.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}this.renderTarget1.dispose(),this.renderTarget2.dispose(),this.renderTarget1=e,this.renderTarget2=e.clone(),this.writeBuffer=this.renderTarget1,this.readBuffer=this.renderTarget2}setSize(e,s){this._width=e,this._height=s;const i=this._width*this._pixelRatio,r=this._height*this._pixelRatio;this.renderTarget1.setSize(i,r),this.renderTarget2.setSize(i,r);for(let t=0;t<this.passes.length;t++)this.passes[t].setSize(i,r)}setPixelRatio(e){this._pixelRatio=e,this.setSize(this._width,this._height)}dispose(){this.renderTarget1.dispose(),this.renderTarget2.dispose(),this.copyPass.dispose()}}class Se extends y{constructor(e,s,i=null,r=null,t=null){super(),this.scene=e,this.camera=s,this.overrideMaterial=i,this.clearColor=r,this.clearAlpha=t,this.clear=!0,this.clearDepth=!1,this.needsSwap=!1,this._oldClearColor=new v}render(e,s,i){const r=e.autoClear;e.autoClear=!1;let t,a;this.overrideMaterial!==null&&(a=this.scene.overrideMaterial,this.scene.overrideMaterial=this.overrideMaterial),this.clearColor!==null&&(e.getClearColor(this._oldClearColor),e.setClearColor(this.clearColor)),this.clearAlpha!==null&&(t=e.getClearAlpha(),e.setClearAlpha(this.clearAlpha)),this.clearDepth==!0&&e.clearDepth(),e.setRenderTarget(this.renderToScreen?null:i),this.clear===!0&&e.clear(e.autoClearColor,e.autoClearDepth,e.autoClearStencil),e.render(this.scene,this.camera),this.clearColor!==null&&e.setClearColor(this._oldClearColor),this.clearAlpha!==null&&e.setClearAlpha(t),this.overrideMaterial!==null&&(this.scene.overrideMaterial=a),e.autoClear=r}}const ye={uniforms:{tDiffuse:{value:null},luminosityThreshold:{value:1},smoothWidth:{value:1},defaultColor:{value:new v(0)},defaultOpacity:{value:0}},vertexShader:`

		varying vec2 vUv;

		void main() {

			vUv = uv;

			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`,fragmentShader:`

		uniform sampler2D tDiffuse;
		uniform vec3 defaultColor;
		uniform float defaultOpacity;
		uniform float luminosityThreshold;
		uniform float smoothWidth;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );

			vec3 luma = vec3( 0.299, 0.587, 0.114 );

			float v = dot( texel.xyz, luma );

			vec4 outputColor = vec4( defaultColor.rgb, defaultOpacity );

			float alpha = smoothstep( luminosityThreshold, luminosityThreshold + smoothWidth, v );

			gl_FragColor = mix( outputColor, texel, alpha );

		}`};class M extends y{constructor(e,s,i,r){super(),this.strength=s!==void 0?s:1,this.radius=i,this.threshold=r,this.resolution=e!==void 0?new c(e.x,e.y):new c(256,256),this.clearColor=new v(0,0,0),this.renderTargetsHorizontal=[],this.renderTargetsVertical=[],this.nMips=5;let t=Math.round(this.resolution.x/2),a=Math.round(this.resolution.y/2);this.renderTargetBright=new z(t,a,{type:A}),this.renderTargetBright.texture.name="UnrealBloomPass.bright",this.renderTargetBright.texture.generateMipmaps=!1;for(let f=0;f<this.nMips;f++){const p=new z(t,a,{type:A});p.texture.name="UnrealBloomPass.h"+f,p.texture.generateMipmaps=!1,this.renderTargetsHorizontal.push(p);const b=new z(t,a,{type:A});b.texture.name="UnrealBloomPass.v"+f,b.texture.generateMipmaps=!1,this.renderTargetsVertical.push(b),t=Math.round(t/2),a=Math.round(a/2)}const n=ye;this.highPassUniforms=L.clone(n.uniforms),this.highPassUniforms.luminosityThreshold.value=r,this.highPassUniforms.smoothWidth.value=.01,this.materialHighPassFilter=new T({uniforms:this.highPassUniforms,vertexShader:n.vertexShader,fragmentShader:n.fragmentShader}),this.separableBlurMaterials=[];const h=[3,5,7,9,11];t=Math.round(this.resolution.x/2),a=Math.round(this.resolution.y/2);for(let f=0;f<this.nMips;f++)this.separableBlurMaterials.push(this.getSeperableBlurMaterial(h[f])),this.separableBlurMaterials[f].uniforms.invSize.value=new c(1/t,1/a),t=Math.round(t/2),a=Math.round(a/2);this.compositeMaterial=this.getCompositeMaterial(this.nMips),this.compositeMaterial.uniforms.blurTexture1.value=this.renderTargetsVertical[0].texture,this.compositeMaterial.uniforms.blurTexture2.value=this.renderTargetsVertical[1].texture,this.compositeMaterial.uniforms.blurTexture3.value=this.renderTargetsVertical[2].texture,this.compositeMaterial.uniforms.blurTexture4.value=this.renderTargetsVertical[3].texture,this.compositeMaterial.uniforms.blurTexture5.value=this.renderTargetsVertical[4].texture,this.compositeMaterial.uniforms.bloomStrength.value=s,this.compositeMaterial.uniforms.bloomRadius.value=.1;const _=[1,.8,.6,.4,.2];this.compositeMaterial.uniforms.bloomFactors.value=_,this.bloomTintColors=[new w(1,1,1),new w(1,1,1),new w(1,1,1),new w(1,1,1),new w(1,1,1)],this.compositeMaterial.uniforms.bloomTintColors.value=this.bloomTintColors;const x=Y;this.copyUniforms=L.clone(x.uniforms),this.blendMaterial=new T({uniforms:this.copyUniforms,vertexShader:x.vertexShader,fragmentShader:x.fragmentShader,blending:re,depthTest:!1,depthWrite:!1,transparent:!0}),this.enabled=!0,this.needsSwap=!1,this._oldClearColor=new v,this.oldClearAlpha=1,this.basic=new ae,this.fsQuad=new X(null)}dispose(){for(let e=0;e<this.renderTargetsHorizontal.length;e++)this.renderTargetsHorizontal[e].dispose();for(let e=0;e<this.renderTargetsVertical.length;e++)this.renderTargetsVertical[e].dispose();this.renderTargetBright.dispose();for(let e=0;e<this.separableBlurMaterials.length;e++)this.separableBlurMaterials[e].dispose();this.compositeMaterial.dispose(),this.blendMaterial.dispose(),this.basic.dispose(),this.fsQuad.dispose()}setSize(e,s){let i=Math.round(e/2),r=Math.round(s/2);this.renderTargetBright.setSize(i,r);for(let t=0;t<this.nMips;t++)this.renderTargetsHorizontal[t].setSize(i,r),this.renderTargetsVertical[t].setSize(i,r),this.separableBlurMaterials[t].uniforms.invSize.value=new c(1/i,1/r),i=Math.round(i/2),r=Math.round(r/2)}render(e,s,i,r,t){e.getClearColor(this._oldClearColor),this.oldClearAlpha=e.getClearAlpha();const a=e.autoClear;e.autoClear=!1,e.setClearColor(this.clearColor,0),t&&e.state.buffers.stencil.setTest(!1),this.renderToScreen&&(this.fsQuad.material=this.basic,this.basic.map=i.texture,e.setRenderTarget(null),e.clear(),this.fsQuad.render(e)),this.highPassUniforms.tDiffuse.value=i.texture,this.highPassUniforms.luminosityThreshold.value=this.threshold,this.fsQuad.material=this.materialHighPassFilter,e.setRenderTarget(this.renderTargetBright),e.clear(),this.fsQuad.render(e);let n=this.renderTargetBright;for(let h=0;h<this.nMips;h++)this.fsQuad.material=this.separableBlurMaterials[h],this.separableBlurMaterials[h].uniforms.colorTexture.value=n.texture,this.separableBlurMaterials[h].uniforms.direction.value=M.BlurDirectionX,e.setRenderTarget(this.renderTargetsHorizontal[h]),e.clear(),this.fsQuad.render(e),this.separableBlurMaterials[h].uniforms.colorTexture.value=this.renderTargetsHorizontal[h].texture,this.separableBlurMaterials[h].uniforms.direction.value=M.BlurDirectionY,e.setRenderTarget(this.renderTargetsVertical[h]),e.clear(),this.fsQuad.render(e),n=this.renderTargetsVertical[h];this.fsQuad.material=this.compositeMaterial,this.compositeMaterial.uniforms.bloomStrength.value=this.strength,this.compositeMaterial.uniforms.bloomRadius.value=this.radius,this.compositeMaterial.uniforms.bloomTintColors.value=this.bloomTintColors,e.setRenderTarget(this.renderTargetsHorizontal[0]),e.clear(),this.fsQuad.render(e),this.fsQuad.material=this.blendMaterial,this.copyUniforms.tDiffuse.value=this.renderTargetsHorizontal[0].texture,t&&e.state.buffers.stencil.setTest(!0),this.renderToScreen?(e.setRenderTarget(null),this.fsQuad.render(e)):(e.setRenderTarget(i),this.fsQuad.render(e)),e.setClearColor(this._oldClearColor,this.oldClearAlpha),e.autoClear=a}getSeperableBlurMaterial(e){const s=[];for(let i=0;i<e;i++)s.push(.39894*Math.exp(-.5*i*i/(e*e))/e);return new T({defines:{KERNEL_RADIUS:e},uniforms:{colorTexture:{value:null},invSize:{value:new c(.5,.5)},direction:{value:new c(.5,.5)},gaussianCoefficients:{value:s}},vertexShader:`varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}`,fragmentShader:`#include <common>
				varying vec2 vUv;
				uniform sampler2D colorTexture;
				uniform vec2 invSize;
				uniform vec2 direction;
				uniform float gaussianCoefficients[KERNEL_RADIUS];

				void main() {
					float weightSum = gaussianCoefficients[0];
					vec3 diffuseSum = texture2D( colorTexture, vUv ).rgb * weightSum;
					for( int i = 1; i < KERNEL_RADIUS; i ++ ) {
						float x = float(i);
						float w = gaussianCoefficients[i];
						vec2 uvOffset = direction * invSize * x;
						vec3 sample1 = texture2D( colorTexture, vUv + uvOffset ).rgb;
						vec3 sample2 = texture2D( colorTexture, vUv - uvOffset ).rgb;
						diffuseSum += (sample1 + sample2) * w;
						weightSum += 2.0 * w;
					}
					gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
				}`})}getCompositeMaterial(e){return new T({defines:{NUM_MIPS:e},uniforms:{blurTexture1:{value:null},blurTexture2:{value:null},blurTexture3:{value:null},blurTexture4:{value:null},blurTexture5:{value:null},bloomStrength:{value:1},bloomFactors:{value:null},bloomTintColors:{value:null},bloomRadius:{value:0}},vertexShader:`varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}`,fragmentShader:`varying vec2 vUv;
				uniform sampler2D blurTexture1;
				uniform sampler2D blurTexture2;
				uniform sampler2D blurTexture3;
				uniform sampler2D blurTexture4;
				uniform sampler2D blurTexture5;
				uniform float bloomStrength;
				uniform float bloomRadius;
				uniform float bloomFactors[NUM_MIPS];
				uniform vec3 bloomTintColors[NUM_MIPS];

				float lerpBloomFactor(const in float factor) {
					float mirrorFactor = 1.2 - factor;
					return mix(factor, mirrorFactor, bloomRadius);
				}

				void main() {
					gl_FragColor = bloomStrength * ( lerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) +
						lerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) +
						lerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) +
						lerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) +
						lerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv) );
				}`})}}M.BlurDirectionX=new c(1,0);M.BlurDirectionY=new c(0,1);console.info("[NX] landing-3d.js.js loaded (landing)");const _e=new URLSearchParams(location.search).get("mode")||"";if(!_e){let b=function(){const o=Math.max(1,u.clientWidth),m=Math.max(1,u.clientHeight);t.setSize(o,m,!1),f.setSize(o,m),p.setSize(o,m),n.aspect=o/m,n.updateProjectionMatrix()},O=function(){const o=te.getElapsedTime();n.position.x=.2+D.x*.35,n.position.y=i+-D.y*.18,n.position.z=7.5+Math.sin(o*.15)*.14,n.lookAt(ee),E.rotation.y=o*.65,E.rotation.x=Math.sin(o*.55)*.08,P.rotation.y=-o*.55,P.rotation.z=Math.cos(o*.35)*.1,C.rotation.y=o*.55,C.rotation.x=o*.35;const m=1+Math.sin(o*1.8)*.05;C.scale.setScalar(m);for(const l of V)l.a+=.006*l.s,l.mesh.position.x=Math.cos(l.a)*l.r,l.mesh.position.z=Math.sin(l.a)*l.r,l.mesh.position.y=Math.sin(o*1.1+l.a*2)*.16,l.mesh.rotation.x+=.01*l.s,l.mesh.rotation.y+=.012*l.s;const g=U.attributes.position.array;for(let l=0;l<B;l++)g[l*3+2]+=.012*H[l],g[l*3+2]>2&&(g[l*3+2]=-18-Math.random()*6);U.attributes.position.needsUpdate=!0,f.render(),requestAnimationFrame(O)};const u=document.getElementById("nxLanding3D");if(!u)throw new Error("Missing #nxLanding3D");const e=1.75,s=.55,i=.35,r=0,t=new oe({antialias:!0,alpha:!0,powerPreference:"high-performance"});t.setPixelRatio(Math.min(devicePixelRatio,1.5)),t.setClearColor(0,0),t.domElement.style.width="100%",t.domElement.style.height="100%",t.domElement.style.display="block",u.innerHTML="",u.appendChild(t.domElement);const a=new le;a.fog=new ne(329226,6,22);const n=new he(55,1,.1,120);n.position.set(.2,i,7.5),a.add(new ue(16777215,.18));const h=new fe(16777215,1.05);h.position.set(4,6,3),a.add(h);const _=new W(3900150,2,30,2);_.position.set(-2.6,1.3,1.2),a.add(_);const x=new W(11032055,1.6,30,2);x.position.set(2.8,.8,1.2),a.add(x);const f=new Ce(t);f.addPass(new Se(a,n));const p=new M(new c(1,1),1,.9,.15);p.strength=1.12,p.radius=.72,p.threshold=.1,f.addPass(p),new ResizeObserver(b).observe(u),b();const q=.42,d=new ce;d.position.set(r,e,2),d.scale.setScalar(q),d.rotation.x=-.95,d.rotation.z=.12,d.scale.y*=.55,a.add(d);const J=new F({color:725540,metalness:.65,roughness:.25,emissive:new v(463402),emissiveIntensity:.95}),k=new F({color:3900150,metalness:.35,roughness:.15,emissive:new v(1389482),emissiveIntensity:1.2}),Q=new F({color:11032055,metalness:.35,roughness:.18,emissive:new v(3871849),emissiveIntensity:1.12}),E=new S(new N(1.35,.08,20,90),k);d.add(E);const P=new S(new N(.95,.06,18,80),Q);P.rotation.x=Math.PI/2.3,d.add(P);const C=new S(new de(.55,1),J);C.position.set(0,.05,0),d.add(C);const Z=new me(.18,.18,.18),V=[];for(let o=0;o<14;o++){const m=new S(Z,o%2?k:Q),g=o/14*Math.PI*2,l=1.65+o%3*.12;m.position.set(Math.cos(g)*l,Math.sin(g*2)*.15,Math.sin(g)*l),d.add(m),V.push({mesh:m,a:g,r:l,s:.9+Math.random()*.6})}const B=1300,R=new Float32Array(B*3),H=new Float32Array(B);for(let o=0;o<B;o++)R[o*3+0]=(Math.random()-.5)*22,R[o*3+1]=(Math.random()-.5)*9,R[o*3+2]=-Math.random()*18,H[o]=.2+Math.random()*.6;const U=new j;U.setAttribute("position",new pe(R,3));const $=new ge(U,new ve({size:.012,transparent:!0,opacity:.72,depthWrite:!1}));a.add($);const D={x:0,y:0};window.addEventListener("pointermove",o=>{D.x=o.clientX/window.innerWidth*2-1,D.y=o.clientY/window.innerHeight*2-1});const ee=new w(0,s,0),te=new K;O()}
