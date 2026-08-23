# Project conventions

Rules specific to this repo. Global conventions live in `~/.config/opencode/AGENTS.md`;
these take precedence where they conflict.

## Commands

- `just check` — the CI gate. Runs `check-scad`, `check-sizes` and `check-report`.
- `just report` — echo what the current configuration implies, drawing nothing.
- `just build` — NopSCADlib `make_all`: BOM, DXFs, STLs, assembly views, `readme.md`.
- `just bom` — regenerate just the BOM.

Run `just check` before every commit. `just build` needs ImageMagick 7 (`magick`) and the
Python `markdown` and `codespell` modules.

## `readme.md` is generated

The front page is written by `make_all` from the `//!` description block at the top of
`scad/tube_bender.scad`. Edit the description, not `readme.md`. There is deliberately no
`README.md` — two files differing only in case is a trap.

`readme.md`, `assemblies/`, `bom/`, `dxfs/` and `stls/` are the build manual and are
committed. `deps/`, `tmp/`, `readme.html` and the logs are not.

## `check-scad` checks in both directions

Files listed in the `entry` array of the `check-scad` recipe must emit geometry. **Every
other file must emit none** — a registry that draws its own example draws it into every
consumer. A new entry file therefore fails until it is listed, and that list is the record
of what renders.

A failing assert still exits 0 in OpenSCAD and writes a ~1 byte file, so nothing may be
gated on `$?`. The recipe greps stderr for `ERROR` and uses file size as the backstop.

## Registries are the source of every bought number

Anything purchased is a row in `scad/purchased/`, following NopSCADlib's convention: a
plural file holds the rows and is `include`d, a singular file holds the accessors and
modules and is `use`d. Geometry is cut from the row, never from a number typed beside it.

A row states **what the source says**. Where a source gives a band, register the band
(`tube_materials.scad`). Where it gives nothing, register `undef` or leave the row out
rather than invent a plausible number — see the missing chromoly row.

NopSCADlib's own registries stop short of this machine in two places, so large imperial
fasteners and structural plate are registered project-side against the same row shapes.

## `include` for anything with constants, `use` for behaviour only

`use` brings a file's **modules and functions but not its variables**, and a default
argument is evaluated in the scope of the file that *defines* the function. So a file that
only `use`s a registry gets `undef` for every constant in it — and `undef` propagates
through arithmetic without a word. This cost three separate bugs in one sitting:
`plate_smallest_at_least()` returned `undef` for every thickness ever asked of it,
`forming_die_arc()` returned `undef`, and both looked like design failures rather than
scoping ones.

The rule: **`include` any file you read a constant or a list from; `use` files you only
call.** A lookup over a registry lives beside the registry, not in the singular file.

Better still where it fits: **export the calculation, not the constant.** A function crosses
a `use` boundary safely, so a file that would otherwise have to export a number can export
the thing it wanted the number for instead, and the boundary becomes safe by construction
rather than by everyone remembering. `base_nominal_anchor_radius()` is the pattern.

Related: OpenSCAD does not error on a missing argument, it passes `undef`. Changing a
function's signature silently mis-computes every call site you forget. Grep for the name.

Also related: **top-level names are global and the last assignment wins everywhere.** Two
`let`-like config values sharing a name do not shadow, they collide, and the collision can
make an earlier expression depend on a later one and resolve to `undef`. Reusing
`nominal_r` for two different two-pass sizings did exactly that.

## `offset(0)` on a unioned 2D outline before extruding

Where several 2D regions meet along a shared edge, `union()` leaves degenerate vertices at
the seam. Extruding that and cutting across the seam gives CGAL a mesh it calls *not
closed* and refuses to render — with no clue where. `offset(0)` runs the region through
Clipper's cleanup and the same model builds. `render()` does not fix it.

`forming_die_outline()` carries one. Removing it brings the failure straight back.

Note also that **exporting `.csg` does not build the mesh**, so `just check-scad` cannot
catch this class of fault at all. Export an STL or a PNG when the geometry is in question.

## The BOM says "Printed" for machined parts

NopSCADlib has two categories for a made part, `stl()` and `dxf()`. The forming die is
machined, so it goes under `stl()` and the BOM files it under "Printed". The stock it is
cut from is declared separately as a `vitamin()`, because a parts list has to say what to
*buy*.

## Units: imperial identity, millimetre arithmetic

A row's name and `size` field are its imperial size, because that is what you order and
what is stamped on the die. **All arithmetic is millimetres.** Convert once, at the row.

## The three gates, and what each one cannot see

`check-scad` evaluates every file once, at its defaults, in both directions. It cannot see
a fault that only appears at one end of the size range, and — because a `.csg` export never
builds the mesh — it cannot see a geometry fault at all.

`check-sizes` drives the whole model with `-D tube=...` at every registered size. Two sizes
are listed as known departures; it fails both ways, so a fix that removes one without
removing its entry is caught too. This is the gate that finds parametric breakage: the
`nan` link width at 1/8 in, which nothing at 1/2 in and up would have shown.

`check-report` fails if any echoed value is `undef`, `nan` or `inf`. OpenSCAD does not
error on an undefined variable or a missing argument — it yields `undef` and propagates it
silently through arithmetic into the report. Every derived number in this model has been
`undef` at least once.

None of them build a mesh. When geometry is in question, export an STL or a PNG.

## Numbers before geometry

`scad/utils/bend.scad` draws nothing. It decides whether a configuration is a machine
before any of it exists, and every published band it checks is reported by **name** rather
than as a boolean — a configuration out on one count is a different thing from one out on
three. Add the check there and read `just report` before drawing the part.

Assert only what is physically impossible or unbuildable. Echo everything else.

## Provenance

Every number that came from outside is cited in `docs/references.md` with a verification
status, and the reasoning that placed it is in `docs/design-basis.md`. If you add a number
from a source, add the source. If you add one from nowhere, mark it
**reasoned, not cited** in the file that uses it.
