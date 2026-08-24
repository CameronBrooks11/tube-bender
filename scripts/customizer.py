#!/usr/bin/env python3
"""Write the Customizer dropdown annotations in scad/tube_bender.scad from the registries.

A Customizer annotation cannot be computed - it is a literal comment - so the list of tube
sizes and plate thicknesses has to appear in the configuration block as well as in the
registry it came from. That is one fact in two places, which this repo does not allow to
stand on trust. So the annotation is GENERATED here and `just check` fails if the file and
the registries have drifted apart.

Which registry a parameter draws on is a naming convention rather than a table:

    tube_name        -> the tube registry
    <anything>_plate_name -> the plate registry

so adding a plate choice needs no change here.

Usage:  customizer.py            rewrite the file
        customizer.py --check    exit 1 if the file is not what this would write
"""
import os
import re
import subprocess
import tempfile
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(ROOT, "scad", "tube_bender.scad")
DUMP = os.path.join(ROOT, "scripts", "registry_options.scad")

# name = "value"; // [ ... ]
PARAM = re.compile(r'^(?P<head>(?P<var>\w+)\s*=\s*"(?P<val>[^"]*)";\s*//\s*)\[[^\]]*\]\s*$')


def registries():
    """Ask OpenSCAD what is in the registries. Parsing the .scad by hand would be a second
    reader of the same files, and the point of this script is to have only one."""
    env = dict(os.environ)
    # A real .csg path, not /dev/null: OpenSCAD picks the export format off the suffix and
    # refuses a name it cannot read one from.
    with tempfile.TemporaryDirectory() as tmp:
        out = subprocess.run(
            [env.get("OPENSCAD", "openscad"), "-o", os.path.join(tmp, "opts.csg"), DUMP],
            capture_output=True, text=True, env=env,
        )
    found = {}
    for line in out.stderr.splitlines():
        m = re.search(r'OPT\|(\w+)\|([^|]+)\|(.*?)"?$', line)
        if m:
            found.setdefault(m.group(1), []).append((m.group(2), m.group(3)))
    if not found:
        sys.exit("customizer: OpenSCAD returned no registry rows\n" + out.stderr[-2000:])
    return found


def registry_for(var):
    if var == "tube_name":
        return "tube"
    if var.endswith("_plate_name"):
        return "plate"
    return None


def rewrite(text, regs):
    out, problems = [], []
    for line in text.split("\n"):
        m = PARAM.match(line)
        reg = registry_for(m.group("var")) if m else None
        if not reg:
            out.append(line)
            continue
        rows = regs[reg]
        if m.group("val") not in [n for n, _ in rows]:
            problems.append(
                f'{m.group("var")} defaults to "{m.group("val")}", '
                f"which is not in the {reg} registry"
            )
        options = ", ".join(f"{n}:{s}" for n, s in rows)
        out.append(f'{m.group("head")}[{options}]')
    return "\n".join(out), problems


def main():
    check = "--check" in sys.argv
    with open(TARGET, encoding="utf-8") as f:
        before = f.read()
    after, problems = rewrite(before, registries())

    for p in problems:
        print(f"FAIL  {p}")

    if check:
        if after != before:
            print("FAIL  the Customizer dropdowns are stale - run `just customizer`")
        elif not problems:
            print("ok    the Customizer dropdowns match the registries")
        return 1 if (problems or after != before) else 0

    if problems:
        return 1
    if after != before:
        with open(TARGET, "w", encoding="utf-8") as f:
            f.write(after)
        print(f"wrote {os.path.relpath(TARGET, ROOT)}")
    else:
        print("already current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
