# RuriRipperImporterSubstance

Load Endfield models straight into Substance 3D Painter, with the
`EndField_Uber` shader wired up exactly as the game had it.

The Painter-side twin of the Blender `RuriRipperImporter` add-on, reading from
the same source of truth by the same route: an in-process pythonnet bridge into
`Ruri.RipperHook.dll` boots CoreCLR inside Painter, resolves a cabmap
selection's dependency closure straight out of the game install, and hands back
Unity YAML documents and texture bytes **in memory**. There is no export step
and no folder of pre-split PNGs to build first.

## First run

1. Open the **RuriRipper** dock (it is added automatically; `Window > Views` if
   it is hidden).
2. On first use the plugin pip-installs `pythonnet`, `clr-loader` and `numpy`
   into `<Painter user resources>/python/RuriRipperWorkspace/runtime/<abi>/`.
   It happens in the background and only once per Painter interpreter version.
3. Fill in **RipperHook bin** — the folder that directly contains
   `Ruri.RipperHook.dll` *and* `Ruri.RipperHook.CLI.runtimeconfig.json`
   (typically `<Ruri-RipperHook checkout>/AssetRipper/Source/0Bins/AssetRipper/Debug`).
4. **Refresh hook list**, tick the game's hook (e.g. `EndField_1.3.3`).
5. Set **Game root**, pick a **Cabmap** path, press **Build cabmap** (or
   **Load cabmap** for one that already exists).
6. Browse or search, select an asset row, press
   **Import selected -> new project**.

Every setting is stored in
`<Painter user resources>/python/RuriRipperWorkspace/settings.json`. Nothing in
this package contains an absolute path.

## What the import does

| Stage | Detail |
| --- | --- |
| Mesh | Unity meshes decoded from YAML, bind-pose baked (normals via the inverse transpose), LOD0 only, shadow proxies dropped, static-batch submesh windows honoured, converted Unity -> glTF (negate X + reverse winding + flip V), written as one self-contained `.glb` — the one file Painter needs, because `project.create` takes a mesh path and there is no in-memory geometry API. |
| Texture Sets | Named after the Unity material's own `m_Name`, which is the identity every later stage keys off. |
| Channels | `_BaseMap` -> basecolor + opacity; packed RMOS -> metallic / specularlevel / AO / roughness (`1-smoothness`); `_BumpMap` rebuilt from Unity RG/AG to OpenGL; hair `_SplitNormalMap` RG -> normal, BA -> `_SpecNormalMap`; `_ParallaxTex.r` -> height; `_ClearCoatMask` -> user1. |
| Samplers | Ramps, LUTs, SDF, matcap, stroke/line, fur and VFX maps imported as project resources and bound to the shader's sampler uniforms. |
| Shader | One same-named `EndField_Uber` instance per Texture Set, with the full uniform table (part inference included), then verified. |
| Display | Environment set to `shader/CharCubemap.exr` ([H6]), colour LUT to `shader/CharShowLut3D.tga`, tone mapping forced to Linear ([H9] — the shader applies the HG tonemap itself). |

### Coordinate conversion

Unity and glTF differ in three ways at once, and all three are applied
unconditionally — they are not preferences:

| | Unity | glTF | conversion |
| --- | --- | --- | --- |
| handedness | left | right | negate X, **and** reverse triangle winding |
| texture origin | bottom-left | top-left | `v' = 1 - v` |
| tangent handedness | `B = cross(N,T)·w` | same | `w` is **unchanged** — the reflection would flip it, the V flip flips it back |

The Blender add-on needs none of this: Blender is right-handed with a
bottom-left texture origin, so its path is a straight axis swap. Do not port
assumptions between the two.

### What is deliberately not carried over

Reported per import rather than dropped silently:

- **Blend shapes** — Painter has no morph targets. The mesh is at its neutral
  shape, which is the correct one to texture on.
- **Skin weights / bones** — Painter ignores skinning; the bind-pose bake
  already produces the rest pose the model displays.
- **Non-triangle submeshes** (quads, lines, points) — nothing to texture.
- **Compressed meshes / external `m_StreamData`** — the geometry is not in the
  YAML at all; the import says which of the two it is and what to change.
- **Shader keywords with no fragment-stage meaning** (`_OUTLINE_MASK`,
  `_USE_ALCHEMY_AO`, `_DRAW_UNDER_BROW`, …) — each has a stated reason in
  `unity_material.IGNORED_KEYWORDS`; anything NOT on that list and not mapped
  is named in the report.
- **Disabled renderers / inactive GameObjects** — imported by default (they are
  usually runtime-toggled variants) and counted; untick *Import inactive
  renderers* to match exactly what the game draws.

The whole wiring pass is idempotent: run it again on the same project and it
tops up whatever failed instead of duplicating anything. **Wire open project**
does exactly that stage without touching the mesh.

## Fallback

**Import YAML file...** takes an already-extracted Unity YAML asset from disk —
a `RuriYamlDumper` dump, any text-serialised prefab, or a lone Mesh `.asset`.
A thin `PrefabInstance` wrapper around a binary model carries no YAML geometry
and is reported as such; import it through the cabmap bridge instead.

## Layout

```
RuriRipperImporterSubstance/
  config.py            this plugin's setting keys (the store itself is shared)
  model_builder.py     renderers -> glTF primitives
  gltf_writer.py       .glb writer
  unity_material.py    .mat -> EndField_Uber uniforms + texture jobs
  texture_pipeline.py  channel splits / normal rebuilds (Qt codecs + numpy)
  sp_apply.py          Painter project, channels, fill layer, shader instances
  importer.py          end-to-end orchestration
  ui.py                the dock
  shader/              EndField_Uber.glsl + CharCubemap.exr + CharShowLut3D.tga
  ruri_pybridge/       git submodule -- everything shared with the Blender add-on
    unity/             YAML subset, class-id table, guid resolution, mesh decode,
                       renderer discovery, material property reading, LOD/path
                       rules, clip curves + binding repair, muscle tables
    runtime/           dependency bootstrap, CoreCLR + RipperHook bridge,
                       columnar row table, settings store, workspace
    session/           cabmap browser model, scene-placement model
    math3d/            Unity -> glTF / Unity -> Blender coordinate spaces
```

Clone with the submodule:

```bash
git clone --recurse-submodules https://github.com/ShiyumeMeguri/RuriRipperImporterSubstance.git
# already cloned:
git submodule update --init --recursive
```

Nothing in `ruri_pybridge` may import `substance_painter` or Qt (it also runs
inside Blender, which has neither). It carries its own host-free tests:
`python ruri_pybridge/run_tests.py`.
