OPENSCAD    := env("OPENSCAD", "openscad")
LIBRARIES   := env("OPENSCADPATH", env("HOME") + "/.local/share/OpenSCAD/libraries")
NOPSCADLIB  := LIBRARIES + "/NopSCADlib"

# List available recipes.
default:
    @just --list

# Everything CI runs.
check: check-scad check-sizes

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

# Report every registered tube size, not just the selected one.
check-sizes:
    #!/usr/bin/env bash
    # check-scad renders each file once, at its defaults, so a departure that only fires
    # at one end of the size range never gets evaluated. This recipe walks the registry.
    # It FAILS on a departure nothing expects and on an expected departure that stopped
    # firing - a fix that goes unnoticed leaves a stale list behind.
    set -uo pipefail
    export OPENSCADPATH="{{LIBRARIES}}"
    expected=(
        "tube_0p375x0p049"  # Swagelok's only 3/8 in radius is 2.5 D, tighter than the floor
        "tube_0p625x0p049"  # neither catalogue reaches 5/8 in
    )
    tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
    cat > "$tmp/sweep.scad" <<SCAD
    include <$PWD/scad/purchased/tubes.scad>
    use <$PWD/scad/utils/bend.scad>
    for (t = tubes) {
        echo(str("ROW|", tube_name(t), "|", len(bend_departures(t, bend_default_clr(t)))));
        bend_report(t, bend_default_clr(t));
    }
    SCAD
    {{OPENSCAD}} -o "$tmp/sweep.csg" "$tmp/sweep.scad" 2>"$tmp/err" >/dev/null
    if grep -q '^ERROR' "$tmp/err"; then
        echo "FAIL  the sweep did not build"; grep '^ERROR' "$tmp/err" | sed 's/^/        /'; exit 1
    fi
    failed=0
    while IFS='|' read -r name n; do
        listed=0
        for e in "${expected[@]}"; do [ "$e" = "$name" ] && listed=1; done
        if [ "$n" != "0" ] && [ "$listed" = 0 ]; then
            echo "FAIL  $name  departs and is not expected to"
            grep -A6 "ROW|$name|" "$tmp/err" | grep 'DEPARTURE' | sed 's/^ECHO: "/        /; s/"$//'
            failed=1
        elif [ "$n" = "0" ] && [ "$listed" = 1 ]; then
            echo "FAIL  $name  no longer departs, but is still listed - remove it from check-sizes"
            failed=1
        else
            printf 'ok    %-22s %s\n' "$name" "$([ "$listed" = 1 ] && echo "known departure" || echo 'clean')"
        fi
    done < <(grep '^ECHO: "ROW|' "$tmp/err" | sed 's/^ECHO: "ROW|//; s/"$//')
    exit $failed
