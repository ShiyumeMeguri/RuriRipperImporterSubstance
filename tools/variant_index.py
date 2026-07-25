"""Index every compiled variant dump by its keyword set, and find the pair of
variants that differ in exactly one keyword.

Diffing that pair isolates a feature's real implementation with no guessing --
the delta between "keyword off" and "keyword on" IS the feature.

Usage:
    python variant_index.py <shader-dir> list                 # keyword frequency
    python variant_index.py <shader-dir> pair <KEYWORD>       # find an isolating pair
    python variant_index.py <shader-dir> find <KEYWORD> [...] # variants with all of them
"""

import os
import re
import sys

HEADER_RE = re.compile(r"^// Keywords: (.*)$", re.MULTILINE)
NAME_RE = re.compile(r"^Sub(\d+)_Pass(\d+)_(Fragment|Vertex)_b(\d+)\.hlsl$")


def index(directory):
    entries = {}
    for name in sorted(os.listdir(directory)):
        m = NAME_RE.match(name)
        if not m:
            continue
        path = os.path.join(directory, name)
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            head = handle.read(4096)
        found = HEADER_RE.search(head)
        keywords = frozenset(found.group(1).split()) if found else frozenset()
        entries[name] = {"sub": int(m.group(1)), "pass": int(m.group(2)),
                         "stage": m.group(3), "blob": int(m.group(4)),
                         "keywords": keywords, "size": os.path.getsize(path)}
    return entries


def main(argv):
    directory = argv[0]
    command = argv[1] if len(argv) > 1 else "list"
    entries = index(directory)
    fragments = {n: e for n, e in entries.items() if e["stage"] == "Fragment"}

    if command == "list":
        counts = {}
        for entry in fragments.values():
            for kw in entry["keywords"]:
                counts[kw] = counts.get(kw, 0) + 1
        print("{0} fragment variants, {1} vertex".format(
            len(fragments), len(entries) - len(fragments)))
        for kw, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            print("  {0:5d}  {1}".format(n, kw))
        return 0

    if command == "pair":
        target = argv[2]
        with_kw = [(n, e) for n, e in fragments.items() if target in e["keywords"]]
        without = {frozenset(e["keywords"]): n for n, e in fragments.items()
                   if target not in e["keywords"]}
        best = None
        for name, entry in with_kw:
            other = without.get(entry["keywords"] - {target})
            if other is None:
                continue
            score = len(entry["keywords"])
            if best is None or score < best[0]:
                best = (score, other, name, sorted(entry["keywords"] - {target}))
        if best is None:
            print("no isolating pair for", target)
            return 1
        print("OFF: {0}\nON : {1}\nother keywords: {2}".format(
            best[1], best[2], " ".join(best[3]) or "(none)"))
        return 0

    if command == "find":
        wanted = set(argv[2:])
        hits = [(len(e["keywords"]), n) for n, e in fragments.items()
                if wanted <= e["keywords"]]
        for count, name in sorted(hits)[:20]:
            print("{0:3d} keywords  {1}".format(count, name))
        print("total:", len(hits))
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
