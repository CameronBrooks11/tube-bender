OPENSCAD    := env("OPENSCAD", "openscad")
LIBRARIES   := env("OPENSCADPATH", env("HOME") + "/.local/share/OpenSCAD/libraries")
NOPSCADLIB  := LIBRARIES + "/NopSCADlib"

# List available recipes.
default:
    @just --list

# Everything CI runs.
check: check-scad check-customizer check-sizes check-report

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

# Rewrite the Customizer dropdowns in tube_bender.scad from the registries.
customizer:
    #!/usr/bin/env bash
    set -euo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    python3 scripts/customizer.py

# Fail if those dropdowns no longer match the registries.
check-customizer:
    #!/usr/bin/env bash
    # A Customizer annotation is a literal comment - it cannot be computed - so the list of
    # sizes appears in the configuration block as well as in the registry it came from.
    # That is one fact in two places, and this is what stops the copy going stale.
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    python3 scripts/customizer.py --check

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
report units="metric":
    #!/usr/bin/env bash
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    {{OPENSCAD}} -o "$(mktemp -d)/report.csg" -D 'units="{{units}}"' scad/tube_bender.scad 2>&1 | grep '^ECHO' | sed 's/^ECHO: "//; s/"$//'

# Remove everything make_all generates.
clean:
    rm -rf assemblies bom deps dxfs stls tmp readme.html printme.html \
           cmd_times.txt openscad.echo openscad.log

# Build the whole machine at every registered tube size, not just the selected one.
check-sizes:
    #!/usr/bin/env bash
    # check-scad renders each file once, at its defaults, so anything that only breaks at
    # one end of the size range is never evaluated. This drives the real model with -D,
    # so every size gets the full derivation - pins, links, die and all - and is checked
    # for build errors, departures and undef alike.
    #
    # It FAILS both ways: an unexpected result is a regression, and an expected failure
    # that stopped happening means the list has gone stale and a fix went unnoticed.
    # Shrinking `expected` is the work.
    #
    # Metric only, deliberately. undef reaches the report whatever units are in force, so
    # this catches a size-specific fault either way, and a units-specific one does not
    # depend on the size - check-report drives both systems instead, for two renders
    # rather than thirty.
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    expected=(
        "tube_0p375x0p049"  # Swagelok's only 3/8 in radius is 2.5 D, tighter than the floor
        "tube_0p625x0p049"  # neither catalogue reaches 5/8 in
    )
    tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
    printf 'include <%s/scad/purchased/tubes.scad>\nfor (t = tubes) echo(str("NAME|", tube_name(t)));\n' "$PWD" > "$tmp/names.scad"
    {{OPENSCAD}} -o "$tmp/names.csg" "$tmp/names.scad" 2>"$tmp/names.err" >/dev/null
    names=$(grep -o 'NAME|[a-z0-9_]*' "$tmp/names.err" | cut -d'|' -f2)
    if [ -z "$names" ]; then echo "FAIL  could not read the tube registry"; exit 1; fi
    failed=0
    for n in $names; do
        listed=0
        for e in "${expected[@]}"; do [ "$e" = "$n" ] && listed=1; done
        # Driven through tube_name, the way the Customizer drives it, so the sweep also
        # exercises the by-name lookup rather than reaching past it to the row.
        {{OPENSCAD}} -D "tube_name=\"$n\"" -o "$tmp/s.csg" scad/tube_bender.scad 2>"$tmp/err" >/dev/null
        problem=""
        if grep -q '^ERROR' "$tmp/err"; then
            problem="$(grep -m1 '^ERROR' "$tmp/err" | sed 's/.*failed: //; s/ in file.*//' | cut -c1-72)"
        elif grep '^ECHO' "$tmp/err" | grep -qiE 'undef|nan'; then
            problem="a reported value is not a number"
        elif grep -q 'DEPARTURE' "$tmp/err"; then
            problem="$(grep -m1 'DEPARTURE' "$tmp/err" | sed 's/^ECHO: "DEPARTURE: //; s/"$//' | cut -c1-72)"
        fi
        if [ -n "$problem" ] && [ "$listed" = 0 ]; then
            echo "FAIL  $n  $problem"; failed=1
        elif [ -z "$problem" ] && [ "$listed" = 1 ]; then
            echo "FAIL  $n  builds clean now, but is still listed - remove it from check-sizes"; failed=1
        else
            printf 'ok    %-22s %s\n' "$n" "$([ "$listed" = 1 ] && echo "known: $problem" || echo builds)"
        fi
    done
    exit $failed

# Fail if the configuration report contains an undefined or non-finite number.
check-report:
    #!/usr/bin/env bash
    # OpenSCAD does not error on an undefined variable or a missing argument - it yields
    # undef, and undef propagates through arithmetic to the report without a word. Every
    # derived number here has been undef at least once because a file `use`d something it
    # needed to `include`. The report is where that surfaces, so the report is checked.
    #
    # Run in BOTH unit systems, because every reported number now passes through a
    # formatter that has a branch per system, and a fault in one branch is invisible from
    # the other. This is the right place for that and check-sizes is not: undef propagates
    # to the report whatever the units, so the size sweep catches a size-specific undef in
    # metric alone, while a units-specific fault does not depend on the size at all.
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
    failed=0
    for u in metric imperial; do
        {{OPENSCAD}} -D "units=\"$u\"" -o "$tmp/r.csg" scad/tube_bender.scad 2>"$tmp/err" >/dev/null
        bad=$(grep '^ECHO' "$tmp/err" | grep -inE 'undef|nan|inf' || true)
        if [ -n "$bad" ]; then
            echo "FAIL  the $u report carries values that are not numbers:"
            echo "$bad" | sed 's/^/        /'
            failed=1
        else
            echo "ok    every reported value is a number, in $u"
        fi
    done
    exit $failed
