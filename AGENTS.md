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

## The configuration block is the interface, and the Customizer sets its rules

The block at the top of `scad/tube_bender.scad` is what a user drives the model with, and
OpenSCAD's Customizer decides what may be in it. Three rules, all easy to break by accident
and all silent when broken - the parameter simply does not appear:

- **Literals only.** A string, a number, a boolean, or a list of at most four numeric
  literals. `tube = tube_1p500x0p095;` assigns an identifier, so the Customizer cannot see
  it; that is why the block holds `tube_name = "tube_1p500x0p095";` and turns it into a row
  with `tube_by_name()` below. Every registry carries a `*_by_name()` for this, and it
  asserts rather than returning undef.
- **This file only.** Anything assigned in an `include` or a `use` is ignored.
- **Before the first brace.** Everything after the first opening brace in the file is out
  of scope, so the configuration goes at the top and `/* [Hidden] */` covers the derived
  block. Comments do not count - the lexer removes them - but do not write one that looks
  like it does.

Descriptions are a `//` comment on the line **above** the variable; the widget comes from a
`//` annotation **after** it - `// [15:5:180]` for a slider, `// [a:Label, b:Label]` for a
dropdown, a bare `// 0.1` for a spinbox step. Prose floating above a group of variables is
documentation, not annotation, and produces bare unlabelled boxes.

**The dropdown option lists are generated.** An annotation is a literal comment and cannot
be computed, so the registry names appear in the configuration block as well as in the
registry. `scripts/customizer.py` writes them from the registries - via OpenSCAD, so it is
not a second parser of those files - and `just check-customizer` fails if the two have
drifted. Run `just customizer` after adding a registry row; do not edit those lists by hand.

Which registry a parameter draws on is a naming convention, not a table: `tube_name` takes
the tube registry, anything ending `_plate_name` takes the plate registry.

## Registries are the source of every bought number

Anything purchased is a row in `scad/purchased/`, following NopSCADlib's convention: a
plural file holds the rows and is `include`d, a singular file holds the accessors and
modules and is `use`d. Geometry is cut from the row, never from a number typed beside it.

A row states **what the source says**. Where a source gives a band, register the band
(`tube_materials.scad`). Where it gives nothing, register `undef` or leave the row out
rather than invent a plausible number — see the missing chromoly row.

NopSCADlib's own registries stop short of this machine in two places, so large imperial
fasteners and structural plate are registered project-side against the same row shapes.

**A computed dimension is not an orderable one.** The pin and bolt registries are DIAMETER
series; length is whatever the stack turns out to be, and a stack thickness is never a
length anyone stocks. So a fastener is passed the GRIP it has to hold and rounds up to a
stock step itself — `pin_usable_length()`, `bolt_stock_length()`, both a quarter inch. Do
not bill a raw computed length; it puts `1/2 in x 1.556 in` on the parts list.

**A hole with nothing in it is a missing BOM line** — but check the sources before deciding
what goes in it. Retainers were added to every pin on a reasonable-looking argument and then
removed, because the reference machine has none: every hole here is vertical and every pin
comes out, so a cotter is a thing that stops you using the machine. See design-basis §22.

**Read the reference manuals for the question in front of you, not just the one you had.**
`[JD2-M32]` had been mined for tooling practice and was sitting there with the answer to a
mechanical question the model had got wrong for months.

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
rather than by everyone remembering. `forming_die_drive_pitch()` is the pattern: the pitch
is a variable the die owns, and every consumer reads the function instead.

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

## A flat part is a DXF, a machined part is an STL

NopSCADlib has two categories for a made part and they are not interchangeable here:

- **`dxf()` → "CNC cut"** for anything a laser, waterjet or plasma table makes from a 2D
  outline: both links, the die plates, the base, the pedestal foot. The profile lives in a
  `<part>_2D()` module in the part's own file; `<name>_dxf()` in `tube_bender.scad` is what
  `dxfs.py` finds and exports, and the module name IS the file name.
- **`stl()` → "Printed"** for anything with real depth to cut: the forming die, the clamp,
  the followbar. "Printed" is NopSCADlib's word, not ours; these are machined.

Place a cut part with `routed_plate(stock, name, colour)`, never by extruding the profile
by hand. It names the part for the BOM, declares the DXF, extrudes the profile for the
assembly view **and** sets the colour — and when the manual's views are posed NopSCADlib
imports the exported file instead of the children, so the picture in the manual is drawn
from the cut file itself. That is the check: the two cannot drift apart quietly.

Whichever category a part is in, the stock it comes from is declared separately as a
`vitamin()`, because a parts list has to say what to *buy*.

**DXF arcs are polylines at the current `$fn`.** A cutter gets whatever `facets` was set to
when the file was written.

## The assembly IS the build manual

`main_assembly()` is not a way of grouping the drawing. Each sub-assembly is a step somebody
performs — a weldment that has to cool, a bolted group that never comes apart, a pair of
links joined before the die will fit between them — and NopSCADlib turns the `//!` comment
above each one into a section of `readme.md`. Write those comments as **instructions to a
builder**, not as notes to whoever edits the file next.

Two mechanical facts about the generator:

- **Sub-assemblies are listed in REVERSE order of first appearance** (`bom.py` inserts each
  at the front as it opens). So the calls in `main_assembly()` run backwards for the manual's
  contents to read forwards. Reordering them changes the document, not the machine.
- **Do not write a derived number into an instruction.** It is a function of the
  configuration and the comment is static, so it would be wrong for every configuration but
  one. Say where the number comes from — `just report` — and let the reader run it.

Placing a part in an assembly is also what BILLS it. Every fastener the model drills a hole
for must actually be placed, or it silently leaves the parts list: eleven bolts and seven
retainers were missing for exactly that reason, and building the sub-assemblies is what
surfaced them.

## Units: imperial identity, millimetre arithmetic, and one place that converts

A row's name and `size` field are its imperial size, because that is what you order and
what is stamped on the die. **All arithmetic is millimetres.** Convert once, at the row.

Reading is separate again. `scad/utils/units.scad` is **the only file that may write a unit
down**, and it converts at the last step before a number reaches a human - the report and
the BOM. Nothing upstream knows the setting exists, so no calculation can be affected by it.

- Use `fmt_length`, `fmt_force`, `fmt_moment`, `fmt_stress`, `fmt_pressure`, `fmt_mass`. The
  unit travels with the number, because a number and its unit travelling separately is how
  they end up mismatched. `fmt_bare_length` plus `fmt_length_unit` covers a list or a
  coordinate pair, where repeating the unit on every entry is noise.
- **`fmt_stress` is ksi and `fmt_pressure` is psi.** Structural allowables are quoted in
  ksi; what a part bears onto a bench is quoted in psi, and putting 0.01 MPa into ksi says
  nothing.
- **Do not convert** angles, counts, ratios, or a threshold used in a comparison.
- **Identities do not convert.** `plate_size()` says `1/4 in` in both systems. So does the
  key before the colon in a `vitamin()` string: that is what groups identical parts, not
  something anybody measures.
- **An input's unit lives in its name and never changes meaning.** `clr_override_in`,
  `pedestal_height_mm`. Making inputs follow the toggle would silently reinterpret every
  saved preset the moment somebody switched.

The setting travels as `$units`, a special variable, so it is dynamically scoped and reaches
every report module and every function they call across `use` boundaries without being
threaded through signatures that have nothing else to do with it. Unset means metric.

`check-report` drives both systems, because each formatter has a branch per system and a
fault in one is invisible from the other. `check-sizes` stays metric on purpose: undef
reaches the report whatever the units, and a units fault does not depend on the size.

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

## Moving parts: check engagement, not clearance

Anything that indexes has two separate questions and the easy one hides the hard one.

**Clearance** asks whether two parts can be in the same place. It is tempting to answer it
with the envelope of everywhere a part goes over a whole cycle - and that is the wrong
envelope, because a collision needs two things in one place *at the same time*. The drive
links sweep every radius and occupy only one narrow band of angle, and reading the first as
the answer cost a working die lock for a round and put a stack reorder on the roadmap that
was never needed.

**Engagement** asks whether the right parts are in the same place when they need to be. It
is the question that gets skipped, and clearance cannot stand in for it. A die lock that
cleared every obstacle and satisfied the hole phase still engaged on two strokes out of
five, because on the other three the die had not rotated far enough to be under it at all.

So: **enumerate the cycle and check every step of it.** Five lines of arithmetic printing
LOCKS or no hole at the pin for each stroke found that in seconds; no clearance check ever
would have. Then look for the closed form - there was one, and it is exact.

## Provenance

Every number that came from outside is cited in `docs/references.md` with a verification
status, and the reasoning that placed it is in `docs/design-basis.md`. If you add a number
from a source, add the source. If you add one from nowhere, mark it
**reasoned, not cited** in the file that uses it.
