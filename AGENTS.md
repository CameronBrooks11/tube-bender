# Project conventions

Rules specific to this repo. Global conventions live in `~/.config/opencode/AGENTS.md`;
these take precedence where they conflict.

## Commands

- `just check` — the CI gate. Runs `check-scad`.
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

## Units: imperial identity, millimetre arithmetic

A row's name and `size` field are its imperial size, because that is what you order and
what is stamped on the die. **All arithmetic is millimetres.** Convert once, at the row.

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
