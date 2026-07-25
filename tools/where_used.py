"""For every still-unported property, report WHERE the reference actually reads
it: which stage (Vertex/Fragment), which pass, and how many real (non-cbuffer-
declaration) uses.

This is what turns "out of scope" from an assertion into something checkable.
A Substance Painter shader is a single Pass0 FRAGMENT program -- it has no
vertex hook and no second pass -- so anything this tool reports as
vertex-only, or as living in Pass1+, is not something the port chose to skip;
it is somewhere the shader cannot reach.

Usage: python tools/where_used.py <shader-dump-root> <prop> [<prop> ...]
       python tools/where_used.py <shader-dump-root> --gap shader_gap.json
"""

import json
import os
import re
import sys

NAME_RE = re.compile(r"^Sub(\d+)_Pass(\d+)_(Fragment|Vertex)_b(\d+)\.hlsl$")


def scan(root, props):
    hits = {p: {} for p in props}
    for variant in sorted(os.listdir(root)):
        vdir = os.path.join(root, variant)
        if not os.path.isdir(vdir):
            continue
        for name in os.listdir(vdir):
            m = NAME_RE.match(name)
            if not m:
                continue
            stage, pass_no = m.group(3), int(m.group(2))
            path = os.path.join(vdir, name)
            with open(path, "r", encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            for prop in props:
                if prop not in text:
                    continue
                real = sum(1 for line in text.split("\n")
                           if re.search(r"\b" + re.escape(prop) + r"\b", line)
                           and "packoffset" not in line)
                if real:
                    key = "{0} Pass{1}".format(stage, pass_no)
                    bucket = hits[prop].setdefault(variant, {})
                    bucket[key] = bucket.get(key, 0) + real
    return hits


def main(argv):
    root = argv[0]
    if len(argv) > 2 and argv[1] == "--gap":
        report = json.load(open(argv[2], encoding="utf-8"))
        props = sorted({name for data in report.values()
                        for name, _t, _l in data["property_gap"]})
    else:
        props = argv[1:]
    hits = scan(root, props)
    for prop in props:
        where = hits[prop]
        if not where:
            print("{0:38s} NEVER READ by any compiled shader".format(prop))
            continue
        summary = {}
        for _variant, buckets in where.items():
            for key, n in buckets.items():
                summary[key] = summary.get(key, 0) + n
        print("{0:38s} {1}".format(
            prop, "  ".join("{0}x{1}".format(k, v) for k, v in sorted(summary.items()))))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
