"""Account for EVERY property and keyword of the 1.4.4 characternpr family
against the Painter port, and print only what is unaccounted for.

Classification, in order:
  channel      -- unity_material.CHANNEL_SOURCES (a Painter engine channel)
  sampler      -- unity_material.TEXTURE_PARAMS (a shader sampler uniform)
  uniform      -- the name exists in EndField_Uber.glsl
  float/color  -- unity_material FLOAT_IDENTITY / COLOR_IDENTITY
  bool         -- unity_material.BOOL_MAP
  ignored      -- unity_material.IGNORED_TEXTURES
  internal     -- [HideInInspector] / blend-state plumbing
  section      -- a Float declared only as an inspector section/feature header
  GAP          -- everything else
"""

import importlib.util
import json
import os
import re
import sys

REF = ("E:/AllShader_1.4.4/Assets/packages/com.hg.render-pipelines/runtime/"
       "shaders/materials/characternpr")
PLUGIN = ("D:/Tools/Users/Administrator/Documents/Adobe/Adobe Substance 3D Painter/"
          "python/plugins/RuriRipperImporterSubstance")
GLSL = os.path.join(PLUGIN, "shader", "EndField_Uber.glsl")

# Import unity_material standalone (it only needs ruri_pybridge on sys.path).
sys.path.insert(0, PLUGIN)
spec = importlib.util.spec_from_file_location("unity_material",
                                              os.path.join(PLUGIN, "unity_material.py"))
um = importlib.util.module_from_spec(spec)
spec.loader.exec_module(um)

glsl_text = open(GLSL, encoding="utf-8", errors="replace").read()
glsl_names = set(re.findall(r"\b(_\w+|u_\w+|v_\w+|f_\w+|i_\w+)\b", glsl_text))

CHANNEL_PROPS = set(um.CHANNEL_SOURCES)
SAMPLER_PROPS = set(um.TEXTURE_PARAMS)
FLOATS = set(um.FLOAT_IDENTITY)
COLORS = set(um.COLOR_IDENTITY)
BOOLS = set(um.BOOL_MAP.values())
IGNORED = set(um.IGNORED_TEXTURES)

# Engine-side keywords with no fragment meaning in a Painter port.
ENGINE_KEYWORDS = {
    "SRP_INSTANCING_ON", "HG_ENABLE_PER_OBJECT_MV", "HG_ENABLE_SCREEN_SPACE_SHADOW_MASK",
    "BAKED_SKINNING_ANIMATION_TEXTURE", "DITHER", "DITHER_SPHERE", "_PUPPET",
    "_PUPPET_PROCEDURAL_DCURVE", "_ALPHATEST_ON", "_ALPHABLEND_ON",
    "_CUSTOMIZE_AVATAR", "_PLANAR_REFLECTION", "_UV2_COLOR",
}


def property_entries(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    start = text.index("Properties {")
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                block = text[start:i + 1]
                break
    entries = []
    for line in block.splitlines():
        m = re.match(r"\s*((?:\[[^\]]*\]\s*)*)(_\w+)\s*\(\s*\"(.*?)\"\s*,\s*(\w+)", line)
        if m:
            entries.append({"attrs": m.group(1), "name": m.group(2),
                            "label": m.group(3), "type": m.group(4)})
    return entries


def keywords(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    out = set()
    for line in re.findall(r"#pragma (?:multi_compile_local|shader_feature_local|"
                           r"multi_compile|shader_feature)\s+(.+)", text):
        for tok in line.split():
            if tok != "_":
                out.add(tok)
    return sorted(out)


def classify(entry):
    name, attrs, label, ptype = (entry["name"], entry["attrs"],
                                 entry["label"], entry["type"])
    if name in CHANNEL_PROPS:
        return "channel"
    if name in SAMPLER_PROPS:
        return "sampler"
    if name in IGNORED:
        return "ignored"
    if name in FLOATS or name in COLORS:
        return "float/color"
    if name in glsl_names:
        return "uniform"
    if "HideInInspector" in attrs:
        return "internal"
    if ptype == "Float" and re.search(r"\{(Section|Feature):", label):
        return "section"
    for uniform, unity_name in um.BOOL_MAP.items():
        if unity_name == name:
            return "bool"
    return "GAP"


report = {}
for shader in sorted(os.listdir(REF)):
    if not shader.endswith(".shader"):
        continue
    path = os.path.join(REF, shader)
    variant = shader[:-7]
    entries = property_entries(path)
    buckets = {}
    for entry in entries:
        buckets.setdefault(classify(entry), []).append(entry)
    kws = keywords(path)
    kw_gap = [k for k in kws
              if k not in um.KEYWORD_MAP and k not in um.IGNORED_KEYWORDS
              and k not in ENGINE_KEYWORDS]
    report[variant] = {
        "counts": {k: len(v) for k, v in sorted(buckets.items())},
        "property_gap": [(e["name"], e["type"], e["label"][:70])
                         for e in buckets.get("GAP", [])],
        "keyword_gap": kw_gap,
    }

for variant, data in report.items():
    print("\n=== {0}".format(variant))
    print("   ", data["counts"])
    if data["keyword_gap"]:
        print("    keywords not handled ({0}):".format(len(data["keyword_gap"])))
        for k in data["keyword_gap"]:
            print("      -", k)
    if data["property_gap"]:
        print("    properties not accounted for ({0}):".format(len(data["property_gap"])))
        for name, ptype, label in data["property_gap"]:
            print("      - {0:38s} {1:8s} {2}".format(name, ptype, label))

json.dump(report, open("shader_gap.json", "w", encoding="utf-8"),
          indent=1, ensure_ascii=False)
print("\nwritten shader_gap.json")
