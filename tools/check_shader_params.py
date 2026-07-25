"""Validate every ``//: param`` declaration in EndField_Uber.glsl.

Painter reports a malformed declaration only as "参数自动'...'未知" and then
refuses to create the shader at all, with no line number -- so a single typo
costs a full round trip through the application. This catches the whole class
statically:

* ``param auto`` takes a BARE known name (``channel_user1``, ``main_light``,
  ...). A JSON payload after it is the mistake Painter reports as "unknown".
* ``param custom`` takes JSON, which must actually parse.
* every ``uniform sampler2D`` needs a ``"usage": "texture"`` custom param
  directly above it, or it silently never receives a texture.

Usage:  python tools/check_shader_params.py [path/to/shader.glsl]
"""

import json
import os
import re
import sys

AUTO_RE = re.compile(r"\s*//:\s*param\s+(\w+)\s*(.*)$")
SAMPLER_RE = re.compile(r"\s*uniform\s+sampler2D\s+(\w+)\s*;")


def check(path):
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.read().split("\n")

    problems = []
    for index, line in enumerate(lines, 1):
        match = AUTO_RE.match(line)
        if not match:
            continue
        kind, rest = match.group(1), match.group(2).strip()
        if kind == "auto":
            if rest.startswith("{"):
                problems.append((index, "param auto with a JSON payload -- Painter only "
                                        "accepts a bare auto name here", line.strip()))
        elif kind == "custom":
            if not rest.startswith("{"):
                continue  # no payload on this line at all
            if rest == "{":
                # Multi-line block: gather the following "//:" continuation
                # lines and validate the whole thing.
                payload = ["{"]
                for follow in lines[index:]:
                    stripped = follow.strip()
                    if not stripped.startswith("//:"):
                        break
                    payload.append(stripped[3:])
                rest = "\n".join(payload)
            try:
                json.loads(rest)
            except ValueError as exc:
                problems.append((index, "invalid JSON ({0})".format(exc), line.strip()))
        else:
            problems.append((index, "unknown param kind '{0}'".format(kind), line.strip()))

    for index, line in enumerate(lines):
        match = SAMPLER_RE.match(line)
        if not match:
            continue
        previous = lines[index - 1].strip() if index else ""
        if '"usage": "texture"' not in previous:
            problems.append((index + 1,
                             "sampler2D {0} has no 'usage: texture' param above it".format(
                                 match.group(1)), previous))

    for index, why, text in problems:
        print("{0}:{1}: {2}\n    {3}".format(os.path.basename(path), index, why, text[:100]))
    print("problems:", len(problems))
    return 1 if problems else 0


if __name__ == "__main__":
    default = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "shader", "EndField_Uber.glsl")
    sys.exit(check(sys.argv[1] if len(sys.argv) > 1 else default))
