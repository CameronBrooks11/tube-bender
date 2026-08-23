OPENSCAD    := env("OPENSCAD", "openscad")
LIBRARIES   := env("OPENSCADPATH", env("HOME") + "/.local/share/OpenSCAD/libraries")
NOPSCADLIB  := LIBRARIES + "/NopSCADlib"

# List available recipes.
default:
    @just --list

# Everything CI runs.
check: check-scad

# Evaluate every SCAD file and report anything that does not build.
check-scad:
    #!/usr/bin/env bash
    # A failing CSG export still exits 0 and writes a 1 byte file, so nothing here may be gated
    # on $?. ERROR on stderr is the signal; the file size is the backstop.
    #
    # Files are checked in both directions. The ones listed below are meant to render on their
    # own and must emit geometry. Every other file is include'd or use'd by something and must
    # emit none - a registry that draws its own example draws it into every consumer. A new
    # entry file therefore fails until it is listed, which is the point: the list is the record
    # of what renders.
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    entry=(
        scad/tube_bender.scad
    )
    tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
    failed=0
    while read -r f; do
        renders=0
        for e in "${entry[@]}"; do [ "$e" = "$f" ] && renders=1; done
        out="$tmp/$(echo "$f" | tr / _).csg"
        {{OPENSCAD}} -o "$out" "$f" 2>"$tmp/err"
        size=$(stat -c%s "$out" 2>/dev/null || echo 0)
        if grep -q '^ERROR' "$tmp/err"; then
            echo "FAIL  $f"
            grep '^ERROR' "$tmp/err" | sed 's/^/        /'
            failed=1
        elif [ "$renders" = 1 ] && [ "$size" -le 1 ]; then
            echo "FAIL  $f  renders nothing"
            failed=1
        elif [ "$renders" = 0 ] && [ "$size" -gt 1 ]; then
            echo "FAIL  $f  emits $size bytes into every consumer; add it to entry if it renders"
            failed=1
        else
            printf 'ok    %-46s %s\n' "$f" "$([ "$renders" = 1 ] && echo "$size bytes" || echo 'no geometry')"
        fi
    done < <(find scad -name '*.scad' -not -path '*/_archive/*' | sort)
    exit $failed

# Build the BOM, DXFs, STLs, assembly views and the manual (NopSCADlib make_all).
build:
    #!/usr/bin/env bash
    set -euo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    python3 "{{NOPSCADLIB}}/scripts/make_all.py"

# Just the BOM, without re-rendering every view.
bom:
    #!/usr/bin/env bash
    set -euo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    python3 "{{NOPSCADLIB}}/scripts/bom.py"
    cat bom/bom.txt

# Report what the current configuration implies, without drawing anything.
report:
    #!/usr/bin/env bash
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    {{OPENSCAD}} -o "$(mktemp -d)/report.csg" scad/tube_bender.scad 2>&1 | grep '^ECHO' | sed 's/^ECHO: "//; s/"$//'

# Remove everything make_all generates.
clean:
    rm -rf assemblies bom deps dxfs stls tmp readme.html printme.html \
           cmd_times.txt openscad.echo openscad.log
