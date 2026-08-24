# Design basis

Why this machine is shaped the way it is, and where each number comes from. Every
quantity here is one of four kinds, and which kind it is travels with it:

- **measured** — a source states it for this exact thing
- **catalogued** — it is what you can actually buy, read off a vendor's list
- **derived** — computed from the geometry or from a stated model
- **reasoned, not cited** — nothing found supports it and the model needs a value anyway

Sources are in [`references.md`](references.md); what the Onshape original measured, and
which of its features survive, is in [`reverse-engineering.md`](reverse-engineering.md).

---

## 1. What this is

A manual rotary-draw tube bender of the swing-arm pattern: a grooved forming die on a
centre pivot, a clamp strapping the tube to the die, a followbar (pressure die) reacting
the bending load, and a drive link that rotates the die from a handle.

The vocabulary is the trade's, not invented here — **forming die**, **U-strap**,
**followbar**, **drive link**, **frame link**, **drive holes** — taken from the J D Squared
Model 32 manual [JD2-M32]. Using their names means a builder can read either document.

## 2. Tube, not pipe

Tube is specified by **outside diameter and wall thickness**; pipe is specified by a
nominal size that is neither its OD nor its ID, plus a schedule [JD2-M32 p.4]. This model
is parametric on tube OD. Pipe is supported the way the trade supports it: by looking up
the pipe's real OD and treating it as a tube of that OD.

The die must match the tube. A 1-1/2 in tube in a 1-5/8 in die set damages the followbar
[JD2-M32 p.4]. That is an assert, not an echo.

## 3. Size range: 1/8 in to 2 in OD

**Lower bound 1/8 in (3.175 mm)** — catalogued. It is the smallest tube the Swagelok hand
bender covers [SWAGELOK-MS-13-43], and below it tube becomes capillary and bending stops
being a fabrication operation.

**Upper bound 2 in (50.8 mm)** — catalogued and derived, agreeing. Both reference manual
machines stop there: the Pro-Tools 105 is rated 1/2 to 2 in OD [PROTOOLS-105] and the JD2
Model 32 is rated 1/2 to 2 in x 0.120 in wall [JD2-M32]. The derivation in §6 puts the
handle for 2 in x 0.120 in ERW at **4.4 m**, which is not a hand tool. Above 2 in the
mode of actuation changes rather than the size merely growing.

Neither bound is a limit of the geometry — the model will draw a 3 in die. They are the
band in which a *manual* machine is the right answer, and the model reports when a
configuration leaves it rather than refusing to draw it.

## 4. Centreline radius: minimum 3 x OD

CLR is stated as **D of bend**, `Fd = R / T` — centreline radius over tube OD
[BENDTOOLING]. Its companion is **wall factor**, `Fw = T / W` — OD over wall thickness.
Both are ratios; a larger `Fd` and a smaller `Fw` each make a bend easier
[BENDTOOLING, PROTOOLS-WALLFACTOR].

Note the direction, because secondary sources get it backwards: wall factor is
**OD divided by wall**, so *thin wall = high wall factor = harder*. One trade-press
summary read during this research stated it inverted.

**The rule this model adopts: minimum CLR = 3 x OD.** It is the industry rule of thumb for
bending without an internal mandrel [PROTOOLS-WALLFACTOR, THEFABRICATOR-4MODES], and this
machine has no mandrel. Below 3D a mandrel becomes worth considering; below 2D one is
generally required, and unsupported tube ovalises and wrinkles [ROGUEFAB-MANDREL].

Sanity-checked against what is actually sold. Pro-Tools' own round-die matrix
[PROTOOLS-DIES] runs:

| OD | CLRs offered | D of bend |
|---|---|---|
| 3/4 | 3, 3-1/2 | 4.0 – 4.7 |
| 1 | 3, 3-1/2, 4, 4-1/2 | 3.0 – 4.5 |
| 1-1/4 | 4, 4-1/2, 5, 6 | 3.2 – 4.8 |
| 1-1/2 | 4-1/2, 5, 6, 7 | 3.0 – 4.7 |
| 2 | 6, 7 | 3.0 – 3.5 |
| 2-1/2 | 7 | 2.8 |

Every entry sits between 2.8D and 4.8D, clustered on 3–4.5D.

**The small end does not agree, and the disagreement is real.** The Swagelok hand bender's
fixed radii are 0.56 in on 1/8 in tube (4.5D), 0.56 **and 0.75** in on 1/4 in (2.25D and
3.0D), 0.94 in on 5/16 in (3.0D), 0.94 in on 3/8 in (**2.5D, and it is the only radius
offered**) and 1.5 in on 1/2 in (3.0D) [SWAGELOK-MS-13-43]. So at 1/4 in and 3/8 in the
trade routinely bends tighter than 3D, and at 3/8 in there is nothing else on offer.

That is not a reason to move the floor. The 3D rule is about ovality and wrinkling in the
unsupported span of a large tube, and thin instrumentation tube in a hand bender's fully
enclosing groove is a different problem. But it does mean the floor is **reported, not
enforced**, at the bottom of the range: `bend_departures()` distinguishes "you chose a
radius nobody sells" from "every radius sold for this OD is tighter than 3 x OD", because
those call for opposite responses.

An earlier draft of this section quoted only the 3.0D options from the same table and
concluded the small end agreed. It does not. The sweep in `just check-sizes` is what
surfaced it.

So `clr_min = 3 * od` is a floor the whole industry sits on or just above, and the model
**echoes the D of bend and names it when it falls below 3**, rather than refusing — a
thick-wall DOM tube at 2.8D is a real bend that real people make.

**Default CLR** is the smallest catalogued radius at or above 3D for the selected tube,
because a die you can buy is worth more than a die you have to justify.

## 5. The forming die groove is not a half-round

This is the finding that most changes the part. A production forming die's groove is
machined to a profile such that **the tube does not fully seat in it**:

> "If you lay a section of tubing into the forming die you will notice that it will NOT
> completely seat into the die's groove. This is normal for tube size dies and becomes
> very important as the tube's wall thickness gets thinner." — [JD2-M32 p.4]

The profile exists to resist flattening on the outside of the bend. Pipe dies, being
thicker-walled and more forgiving, do let the pipe seat fully.

The followbar carries the same idea: its rear insert is **angled** relative to the tube
axis, "calculated and machined into the backing block to 1/1000 of a degree from
theoretically perfect for the tube size and bend radius", to support the tube just past
the point of bend [JD2-M32 p.5]. And the followbar's grooves ride *slightly lower* than
the die's groove so the followbar can rise under load rather than bind [JD2-M32 p.5].

**A withdrawn claim.** An earlier draft of this section also stated that the part line
sits on the tube centreline with the bend die containing 50 % of the tube and the clamp
and pressure die grooves somewhat less, cited to a tooling vendor's design page. That page
was then retrieved and **does not contain it** — it carries die materials and hardness and
nothing about groove depth. The statement came from a search summary that had blended
sources. It is removed rather than re-attributed, because the only honest position is that
**no source read here specifies the bend die's groove profile**.

**Decision.** v1 cuts a true half-round groove of radius `od/2` and exposes a
`groove_seat` factor plus a followbar drop, both defaulting to a plain fit, with the
non-circular profile and the followbar angle recorded on the roadmap. Reason: the exact
profile is proprietary, no source states it, and inventing one would be a
*reasoned, not cited* number sitting in the load path of the finished part. A plain
half-round is a known, stateable approximation; a guessed ellipse is not.

## 6. Leverage: handle length is derived from a force budget, not copied

The die's drive torque has to reach the tube's fully plastic bending moment:

```
Zp = (D^3 - d^3) / 6           plastic section modulus, round tube
Mp = sigma_y * Zp              fully plastic bending moment
L  = Mp / F_operator           handle length for a given pull
```

`Zp` for a hollow round section is standard plasticity [PLASTIC-MOMENT]. `Mp` is a
**floor**, not the answer: it ignores strain hardening, the friction of the followbar and
U-strap, and the fact that the hinge travels. The real torque is higher. The model
reports `Mp` and says so.

Yield strength is registered as the **band the standard gives**, not a single number.
ASTM A513 round tube [TOTTEN-A513]:

| condition | yield ksi | yield MPa |
|---|---|---|
| as-welded (ERW, A513 T1) | 30 – 45 | 207 – 310 |
| normalized | 23 – 40 | 159 – 276 |
| mandrel-drawn (DOM, A513 T5) | 50 – 70 | 345 – 483 |
| mandrel-drawn, stress-relieved | 45 – 65 | 310 – 448 |

**Operator force ceiling: 490 N.** That is the largest horizontal push or pull the FAA
Human Factors Design Standard allows a designer to require, and only when both hands are
used and the operator is braced against a wall or standing on non-slip ground; with
ordinary traction the ceiling is 200–310 N [HFDS-2009 Exh. 14.5.3.1]. Arm strength alone,
5th-percentile male, is about 180–200 N [HFDS-2009 Exh. 14.5.2.1].

Handle length at 490 N, taking the top of each yield band:

| OD x wall | Zp mm^3 | ERW Mp N·m | handle m | DOM Mp N·m | handle m |
|---|---|---|---|---|---|
| 1/4 x .035 | 27 | 8 | 0.02 | 13 | 0.03 |
| 1/2 x .049 | 164 | 51 | 0.10 | 79 | 0.16 |
| 3/4 x .065 | 501 | 155 | 0.32 | 242 | 0.49 |
| 1 x .065 | 933 | 289 | 0.59 | 451 | 0.92 |
| 1-1/4 x .065 | 1497 | 464 | 0.95 | 723 | 1.48 |
| 1-1/2 x .095 | 3078 | 954 | 1.95 | 1487 | 3.03 |
| 1-3/4 x .095 | 4269 | 1323 | 2.70 | 2062 | 4.21 |
| 2 x .120 | 6960 | 2158 | 4.40 | 3362 | 6.86 |

Read across the ERW column and the size range falls out of the arithmetic:

- **to 1 in** — handle under 0.75 m. A hand-held tool.
- **1-1/4 to 1-1/2 in** — 1 to 2 m. Bench- or floor-mounted, two hands, long handle.
- **1-3/4 in and up** — 2.7 m and beyond. Not a manual machine.

That is the same boundary a practitioner gave independently: handheld to roughly 1/2–1 in,
~1.5 in as the practical manual target, 2 in as the extreme for a floor-mounted
high-advantage machine, powered above.

It also puts a number on the reference machines. JD2 states a 36 in (0.914 m) handle lets
an average user bend 1-3/4 x .095 mild steel [JD2-M32 p.2]; against `Mp` that is
**1449 N of pull**, three times the HFDS design ceiling — and the same manual tells you to
cut a length of 1 in pipe for more leverage when you want it. The reference machines are
worked past the limit an ergonomics standard would let a designer specify. This model
derives the handle instead of copying theirs, and echoes the implied operator force so the
departure is visible.

## 7. Pin fits: the drive holes are meant to be sloppy

Not a defect to correct. JD2's drive holes are **1 in holes on a 7/8 in drive pin —
drilled 1/8 in oversize on purpose**, "to provide easier pin installation" [JD2-M32 p.7].
The pin is repositioned by hand every few degrees of bend; a close fit would make the
machine unusable.

So the model registers two distinct fits and names them:

- **pivot fit** — the frame pin the die and links rotate on. Close running clearance.
- **index fit** — drive holes, U-strap pin, lock pin. Deliberately oversize, default
  +1/8 in on the pin, from JD2's practice.

Dies with a CLR under 3 in have no drive holes at all — there is no room — and the
ratchet is not used for them [JD2-M32 p.4, p.7]. The model derives whether drive holes
fit rather than always drawing them.

## 8. Units: imperial identity, millimetre arithmetic

Tube is bought by imperial OD in North America and the entire die catalogue is imperial,
so **a registry row's identity is its inch size** — `3/4 in OD x 3 in CLR` is the name of a
real thing and 19.05 x 76.2 is not. Metric tube is registered the same way in its own
native sizes.

**All arithmetic is in millimetres**, because OpenSCAD and NopSCADlib are millimetre
libraries and mixing units inside the derivation is how the two halves of a dimension
drift apart. Inch values are converted once, at the registry row.

### Reading is a third thing, and it is a whole system

The derivation stays in millimetres, newtons and megapascals whatever the reader wants.
`units` converts at the last step before a number reaches a human — the report and the BOM
— and nothing upstream of that knows it exists. `scad/utils/units.scad` is the only file in
the model where a unit is ever written down.

**It moves everything together, not just lengths.** Inches with newtons is harder to check
than either system on its own: you cannot carry a sanity calculation across mixed units in
your head. So length, force, moment, stress and mass convert as a set.

There is a second reason, and it turned out to be the more useful one. Most of the sources
this model rests on are imperial-native, so reporting in imperial puts their numbers back
into the form they were published in — and **shows where a registry row is itself a rounded
conversion**, which is invisible from the metric side:

| quantity | registry holds | reported imperial | the source's own number |
|---|---|---|---|
| A513 T1 yield, top of band | 310 MPa | 44.96 ksi | **45 ksi** [TOTTEN-A513] |
| A36 plate, `0.6 Fy` | 0.6 × 250 MPa = 150 MPa | 21.76 ksi | 0.6 × **36 ksi** = 21.6 ksi |
| operator pull ceiling | 490 N | 110.2 lbf | **490 N** [HFDS-2009] |

The first row is the good case: Totten states 30–45 ksi, the registry carries the
conversion, and imperial reporting recovers 44.96 — the whole chain agreeing to the
rounding.

The second is the interesting one. `[ASTM-A36]` is recorded as **abstract**, from a vendor
page that pairs "36 ksi" with "250 MPa" — and those two are not equal. 36 ksi is 248.2 MPa,
so the registered figure is 0.7 % over the number the grade is named for, and every plate
allowance carries that. It is inside the "a real plate is stronger" margin the row already
records, and it is left alone; the point is that switching units is what made it visible.

The third is a reminder that the arrow does not always point the same way: HFDS is metric at
source, so 110.2 lbf is *ours*, not theirs. Do not read a converted number back as a
citation.

**ksi for strength, psi for bearing.** Both are stress and the trade writes them
differently because they differ by orders of magnitude: structural allowables are quoted in
ksi, what a machine bears onto a bench is quoted in psi. The base's 0.01 MPa in ksi is
0.0000015 and tells nobody anything.

### A name is not a measurement, and neither is an input

`tube_size()`, `plate_size()` and `pin_size()` return `1-1/2 in OD x 0.095 in wall`,
`1/4 in`, `7/8 in dia` — in **both** systems, because those are identities. A metric builder
still orders 1/4 in plate. Only measurements convert.

The same rule runs the other way, through the configuration. **A number you type in never
changes meaning when you change the unit system**; its unit is in its name and stays what it
says. Inputs that followed the toggle would silently reinterpret every saved configuration
the moment somebody switched, turning a 950 mm pedestal into a 24 m one. Which unit a given
input takes follows §8's rule: chosen off a catalogue means the catalogue's unit — CLR is
`clr_override_in` because every die catalogue lists 4-1/2, 5, 6, 7 — and a free dimension
takes the model's own, `pedestal_height_mm`.

### Precision is matched on resolution, not on digits

A decimal place is worth a different amount in each system: one newton is 0.22 lbf, so
integer newtons and integer pounds-force are a factor of four apart in what they resolve.
Each quantity is given whatever number of decimals puts the two within about a factor of
two, and OpenSCAD drops trailing zeros, so one rule prints `13066 N` and `2.7 N` and shows
thousandths of an inch only when a length genuinely has them.

## 9. Fabrication: one forming die now, sliced dies later

The forming die is the one part that needs real machining — a grooved disc, thickness
equal to the tube OD. v1 draws it as a single CNC-machined part.

On the roadmap, not in v1: a **sliced die**, built from stacked laser- or waterjet-cut
plates that approximate the groove in steps. It makes the machine buildable by anyone with
access to a flat-sheet cutter, which is the larger part of the audience. It is deliberately
deferred because doing it well means a parametric, interface-driven decomposition — the
same discipline as the rest of the model — and doing it badly means a stack of plates that
does not hold a tube round.

## 10. Mounting: the base reacts a torque, not a weight

The frame has to be anchored or the machine is unusable — JD2 says only "anything rigid
enough not to twist or move during the bending operation" and drills two 3/4 in holes
[JD2-M32 p.1]. That is not a specification, so here is the free body.

The tube being bent is free at its far end, so it applies no net external load. The only
external loads are the operator's pull and the base reaction. The base must therefore
supply:

- a **moment `Mp` about the vertical pivot axis** — the full drive torque, in the plane of
  the die;
- a **force `F_operator`** equal and opposite to the pull;
- a **tipping moment `F_operator x h`**, where `h` is the height of the die plane above the
  anchor plane. On a bench-mounted plate `h` is the stack height and this term is small.
  On a pedestal it is the post height and it dominates the post's design.

Bolt shear for a two-bolt bench pattern is `Mp / s + F / 2`, `s` being the bolt spacing.
At the 490 N ceiling:

| case | Mp N·m | handle m | shear per bolt, s = 100 mm | min s for a 3/4 in A307 bolt at 4x |
|---|---|---|---|---|
| 1 x .065 ERW | 289 | 0.59 | 1.7 kN | 33 mm |
| 1-1/4 x .065 ERW | 464 | 0.95 | 2.6 kN | 53 mm |
| 1-1/2 x .095 ERW | 954 | 1.95 | 5.0 kN | 109 mm |
| 2 x .120 ERW | 2158 | 4.40 | 11.0 kN | 247 mm |

**The bolts are never the problem; the spacing and what they land in are.** A pattern that
works for 1 in tube is 3x too small at 1-1/2 in, and the loads land as bearing on whatever
the plate is bolted to — a wooden bench crushes long before a 3/4 in bolt shears.

So the base is derived, not fixed: **bolt-pattern span comes from `Mp`**, not from a
remembered hole spacing. A pedestal registers as an option whose post is sized for
`F x h` bending plus `Mp` torsion, both of which the model reports.

**Reasoned, not cited:** the 4x factor on bolt shear. Nothing found sets a factor for a
hand-operated bender, and the failure is a machine that walks across the bench rather than
a fracture, so the number is chosen for stiffness margin, not strength.

## 11. Toolchain

NopSCADlib's build system is used as intended: `assembly()` for build steps, `stl()` and
`dxf()` for made parts, `vitamin()` for bought ones, and `make_all` to generate the BOM,
the DXFs, the exploded views and the assembly manual. Its multiple-configuration support
(`config_<target>.scad`) is what carries the size range — each supported tube size is a
target with its own BOM and its own DXFs.

Two gaps in the library have to be filled locally, and both are the expected kind:

- **Fasteners stop at M8.** The library's screw registry has no imperial sizes above
  `No8` wood screws and nothing near the 3/4 in pins and bolts this machine runs on. Large
  imperial fasteners, clevis pins and the die pins are registered project-side, following
  NopSCADlib's own vitamin conventions so they land on the BOM.
- **Sheet stock stops at 8 mm aluminium.** `sheets.scad` is thin sheet for enclosures.
  Structural plate — 1/4 in and up in mild steel — is registered project-side against the
  same row shape, so `sheet_2D()`, `render_2D_sheet()` and `dxf()` work unchanged.

Costed BOMs come from `parts.py`, which `bom.py` calls per part for a price and URL. That
is where McMaster part numbers live.


## 12. The forming die

Everything about the die falls out of the tube, the CLR and the pins. Nothing about it is
a remembered dimension.

**Thickness = OD + 1/4 in.** The groove is a half-round of OD/2 on the rim, so the die has
to be at least as thick as the tube is wide; an eighth of an inch of land above and below
keeps the groove from running out tangentially at the faces. That the sum lands on a stock
plate thickness for every tube in the range — tube ODs step in eighths, and plate steps in
eighths to 1 in and quarters above — is a coincidence, but it is why the land is 1/8 in
and not 3 mm.

**Outer radius = CLR.** Not a free choice. It cannot be larger: the tube's own outer
surface is at CLR + OD/2 and the followbar has to reach it. It cannot be smaller without
cutting the groove away.

**Arc = bend angle + 5 degrees** of overbend for springback. JD2 measures 3 to 4 degrees on
1-1/2 in x 0.120 in welded mild steel and says chromoly springs back about twice as far
[JD2-M32]. The 5 is that band plus margin, on one material at one size — a die allowance,
not a prediction. Bend Tooling states outright that no effective springback formula exists
[BENDTOOLING].

**Clamp tail = `max(OD x 5 - CLR, 2 x OD)`.** Bend Tooling gives the clamp die length as
`L = t x k - r` and puts the minimum for a smooth cavity "around two times the tube
diameter" [BENDTOOLING-CLAMP]; Benderparts gives the rigidity constant a default of 2, so
`k = Kr x 2.5 = 5`, and says the same about smooth versus serrated engagement
[BENDERPARTS-FORMULAS]. The two terms are not independent: k = 5 against a floor of 2
returns exactly the floor at 3 D, 3 x OD at a 2 D bend, and the floor for anything easier.

*This corrected a real error.* The first version used a flat 3 x OD grip length, taken
from a summary of a trade article that returned 403 when it was finally fetched. Both
sources that could be read say 2. The die's tail is a third shorter for it — 76 mm rather
than 114 mm on the 1-1/2 in die — which is the difference between a rule looked up and a
rule quoted.

**Drive circle** is as large as the material allows, because the whole drive torque goes
through one pin: the hole and its web have to stay inside the groove root. Whether drive
holes fit *at all* is derived, not assumed. JD2 reaches the same conclusion by hand —
"die sets with a radius smaller than 3 in will generally not have drive holes because there
is no room to drill them" [JD2-M32] — but their pins are one size for a whole 1/2 to 2 in
machine, so their cutoff is not this one's.

At the 1-1/2 in check size the derivation returns **five drive holes**, which is what JD2
drills. That is a coincidence worth noticing rather than evidence, since the pitch is
currently the prototype's 36 degrees and the frame has not been built yet — the pitch
should equal the drive link's swing, and when the frame exists it will say so if it does
not.

**Pins are not yet derived.** The die takes the frame, drive and U-strap pin diameters as
inputs and reports the force on the drive pin (12.7 kN at 1-1/2 in) so the choice can be
checked. Sizing them needs the drive link's geometry.


## 13. Pins and links

### Bending sizes every pin on this machine, not shear

Each pin runs through a central member with an outer one either side, so it is in double
shear — and it also bends across that span. The two are checked separately because **they
do not agree**: bending asks for more than twice the diameter shear does. Sizing on shear
alone gives the 1-1/2 in machine a 3/8 in drive pin where it needs 7/8 in.

The bending model takes the pin as a simply supported beam, the central member's load `F`
at midspan and each outer member reacting `F/2` at its own centroid, so the span is
`t_centre + t_outer` and `M = F (t_centre + t_outer) / 4`. That is the standard
conservative treatment — it ignores that the load is spread across each member's thickness.

**The central member is the die *and its plates*, not the die.** The plates are bolted hard
to the die's faces, carry the same pivot bore and the same drive holes, and turn with it, so
a pin through the die is a pin through all three. Taking the die alone understated the span
by two plate thicknesses — 12.7 mm at 1-1/2 in — and bending governs every pin here, so
that is not a rounding error. `layout_central_thickness()` states it once, beside the stack
it is a fact about.

The U-strap pin is the exception and keeps the die's thickness, for a different reason: its
central member is the **clamp**, which sits *between* the plates rather than turning with
them, and the clamp is as thick as the die by construction.

Allowables are AISC allowable stress design, stated in the Engineering Journal as
"tension, Ft = 0.6Fy, and that in shear, Fv = 0.4Fy" [AISC-GOEL]. Bending uses the tension
figure; AISC allows more for a solid round, so this is deliberately conservative. Bearing
on the plates is **reported, not allowed for** — no bearing allowable was found in a source
that could be read.

### The derivation lands on the reference machines' hardware

| | derived here | JD2 Model 32 |
|---|---|---|
| drive pin at 1-1/2 in | 7/8 in | 7/8 in |
| frame pin at 2 in | **1-3/8 in** | 1-1/4 in |
| drive holes | 5 | 5 |
| drive holes below a small die | none | none below 3 in CLR |

JD2 sells one machine for the whole 1/2 to 2 in range, so their single pin size has to
cover the top of it — which is exactly where the two tables meet. That is corroboration
rather than proof, but the agreements are more than coincidence deserves.

**The frame pin no longer agrees, and the disagreement was expected.** It read 1-1/4 in
until the central member was corrected to include the die plates, and it is now one size
over the reference machine. That is not evidence against either: **JD2's die is one piece
and has no plates**, so their pin crosses a shorter span than ours by construction. The
extra size is the price of a design decision this machine made and theirs did not — the
plates that §15 shows the clamp cannot do without.

Two further conservatisms sit on the same number and were left alone. Bending uses AISC's
**tension** allowable, where a solid round is permitted more; and the drive torque is the
tube's fully plastic moment, which §6 records as a floor. Either is worth about one size in
the series. The model is not tuned to reproduce JD2 — where it lands elsewhere, that is
reported rather than corrected.

### Link widths come from the section, not from the prototype

Each link is sized on the net section at its worst hole, at `0.6 Fy` for A36 plate
[ASTM-A36]. The width solves a cubic — `w^3 - ws^2 w - d^3 = 0` — by five passes of a
contraction map, which is converged to under a hundredth of a millimetre.

The **drive link's** peak moment is not at the pivot. Cut it just outside the pivot eye and
the outboard piece carries the handle force at the handle's length and the drive pin's
force at the drive radius, and those two balance — that balance is what the machine is. The
internal moment there is zero, rising outward to a peak **at the drive hole**, which is
also the weakest section.

The **frame link** is taken as a cantilever from the pivot to the followbar. That is
conservative: the base will take some of it, but where the base grabs is not decided, and a
link sized as a cantilever cannot be made worse by adding a support.

### The force ceiling is a maximum, not a target

Taking 490 N as the design pull breaks at the small end. A 1/8 in tube needs 1.4 N·m; at
490 N that is a handle **2.8 mm long** — shorter than the machine it bolts to, so the
moment between the socket and the handle's end went negative and the link width came out
`nan`.

The handle therefore also has a floor: one hand breadth of grip beyond where it attaches,
10.0 cm at the 99th percentile male [HFDS-2009 Exh. 14.3.2.1 item 45]. Where the grip
governs, the operator pulls less than the ceiling, and the model reports **the force
actually needed** — 12 N at 1/8 in, 490 N at 1 in and above. That figure says how hard the
machine is to work, which is the more useful number.

Nothing below 1/2 in would have caught this. `just check-sizes` now drives the whole model
at every registered size rather than only the bend arithmetic, and that is what found it.


## 14. The handle is the link, and the base is four bolts

### There is no separate handle

The drive link runs the full handle length and the pair of them, joined by two spacer bolts
at the grip, is what the operator holds. That is what the prototype does, and there is a
reason worth writing down for why a bolted-on handle is worse rather than merely different:

**The moment at a handle's root is the full bending moment, whatever the handle's length.**
`F x (L - r)` with `F x L = Mp` is `Mp` for any small `r`. So a separate handle needs a root
section as big as the link's, plus a joint that carries it, plus that joint to physically
fit. At 1-1/2 in the smallest registered tube whose bore clears the link pair is a 3 in
member weighing 15 kg — the same as the plate pair it would replace. The joint buys nothing
and costs a joint.

What it does cost is mass: **15.6 kg of handle** at 1-1/2 in, because the link is constant
width for 1.95 m and only the section at the drive hole needs to be that wide. Tapering it
is on the roadmap and would take most of that back.

### The base reacts a torque, and two bolts could not

The first attempt put two anchor bolts on the frame link's own axis, between its eyes, and
ran the drive torque out through them. It failed at both ends of the range and the sweep
said so:

- at **1/8 in** the whole frame link is 22 mm long, and after the pivot eye and the
  followbar eye there is no room left at all — the required span came out **negative**;
- at **2 in** the span the link can offer is 97 mm, which asks for a bolt **bigger than
  the series carries**.

Bigger bolts do not fix either, and they make the first one worse: a bigger bolt needs a
bigger edge distance, which eats the span, which raises the load. **The load path was
wrong, not the fastener.**

What replaced it:

- The **lower frame link is welded to the base plate.** No bolts in that joint at all.
- The frame link pair is already joined at both ends — the frame pin at the pivot, the
  followbar pin at the far end — so the two frame bolts were a third fixing on a two-point
  member.
- The torque leaves through **four anchor bolts at the base plate's corners**. Four bolts
  on a wide rectangle instead of two on a narrow one divides the shear by four and roughly
  doubles the arm at the same time. At 1-1/2 in that is 1890 N per bolt against 3167 N
  allowable, on 1/2 in bolts.

The plate's size comes from the footprint it has to weld to and stand on, not from any
fastener, which is what breaks the circularity.

### Sizing anything against its own edge distance needs two passes

Choosing a bolt makes the radius it sits on **smaller**, because its edge distance comes
out of the plate. So the load goes up after the bolt is chosen, and one pass is optimistic:
a 3/8 in bolt picked against the nominal radius came out 1.6 % over its own allowable at
the radius it then had. The second pass settles it, and an assert now catches the case
where it would not.

The same shape appears in the drive pin — the die's drive radius depends on the hole, which
depends on the pin — and is handled the same way, with both passes printed so the
convergence can be judged rather than assumed.

### What the anchor bolts are not

They are not the thing that fails first. A 1/2 in bolt will not shear at these loads. What
fails first is **whatever the plate is bolted to**: the report prints the bearing pressure
and says plainly that it is fine on steel and wants checking against a bench top. A
pedestal is on the roadmap, and its post is the same section-modulus problem as everything
else here — bending from `F x h` plus torsion from `Mp`.


## 15. The followbar, and the clamp that is not built

### The followbar closes a placeholder rather than adding a parameter

Where the followbar's pin sits was carried as a placeholder from Phase 3 to Phase 4 — one
tube diameter outboard of the tube, on the prototype's precedent, because the part it
belonged to did not exist. It is now derived: half the tube to reach the groove's deepest
point, a machining web behind that, then half the pin. At 1-1/2 in that is **19 mm closer
in than the guess**, which shortens the frame link's reach and takes its bending moment
from 815 to 757 N·m.

That is the whole argument for declaring interfaces instead of inventing numbers. The
guess was not wildly wrong, and it was wrong.

### It is only as tall as the die, and that is a kinematic constraint

The followbar sits in the die's own z band and no taller, because the drive links occupy
the bands either side and **they sweep every radius**. Anything standing proud of the die
is in their path.

The pin that holds the followbar has the same problem and cannot be solved the same way —
it has to reach the frame links, which means crossing the drive links' band. So the
constraint is angular rather than axial: **the bend has to fit in the part of the circle
the followbar is not in.**

```
sweep:   315 deg free of the followbar, and the bend needs 185 deg
```

`bend_available_sweep()` takes the drive link's own angular half-width and the followbar's
at that radius out of the full circle, and `bend_mechanism_departures()` names it if the
bend will not fit. At 180 degrees there is 130 degrees to spare; the check exists because
nothing about it is obvious, and a 300 degree die would not fit.

### The clamp, and the plates that had to come first

The clamp holds the tube to the die while the die drags it round. Its mounting has a
topology problem, and it is worth setting out because the answer was not the clamp.

What has to be true at once:

1. It must sit **outboard of the tube** on the die's tail, where the die has no material —
   the tail's outer face *is* the tube's groove.
2. It must be **removable**. A closed channel in the tail would be simpler and stronger,
   and it was considered and rejected: you could then only load a tube by threading it in
   from an end, which makes multi-bend parts impossible. JD2's own worked example is a
   four-bend rollbar.
3. It cannot stand **above or below the die**, because the drive links are there. Note the
   reason carefully, because §17 gets it wrong in the other direction: the clamp is fixed
   to the die and **turns with it**, so it visits every angle in the arc and will meet a
   drive link at one of them. A part fixed to the *frame* does not move at all and can live
   in an angle the links never reach — which is exactly how the die lock is mounted.
4. The only die material it can reach is **inboard of the groove**, and the path is blocked
   — by the tube below the groove's flanks and by 3.2 mm of land above them.

Nothing about the die can satisfy all four. What can is a **plate on each face of the
die**, in the gap between the die and the drive links, whose tail **overhangs the tube**.
That overhang is the only material anywhere that the clamp can be pinned to. At 1-1/2 in
it reaches r = 169 mm, past the tube's outer surface at 133 mm.

So the clamp is a block like the followbar — capping the outboard half of the tube —
held by **two pins through the die plates**. Two rather than one, because one pin plus a
tube being dragged along its own axis is a hinge. Pulling the pins takes it off, which is
constraint 2. A bolt through the block presses the tube so it cannot slide: JD2 requires it
for wall under 0.065 in, and says to put a slice of larger tube between the bolt and the
work so it does not dimple [JD2-M32 p.7] — a consumable, not a part, and not modelled.

**The prototype got here first.** Its die assembly carries a plate above and below the die
halves, and its clamp has a 6.35 mm tongue running in a slot in those plates. This model
reached the plates from the constraints, and then found them already in the teardown.

### What the clamp load actually is

The tube is dragged round by the clamp, so the clamp carries the **tangential force in the
tube — the bending moment over the radius it is bent on**, `Mp / CLR`. At 1-1/2 in that is
8348 N. It is the same moment the drive pin sees, arriving at a different radius.

That force reaches the die through the plates, so the plate bolts carry it as a force plus
the moment it makes about the pivot — which is the full bending moment, because that is
what the clamp is holding. Standard bolt group: `F/n + M/(n r)`.

### The plates make the sliced die natural

A die with plates bolted to it is already a stack. Whatever the roadmap's laser-cut sliced
die turns out to be, it inherits the same bolt circle and the same interfaces, so that item
got cheaper by being blocked on this one.


## 16. Two dies behind one interface, and what the sliced one gives up

The forming die is the only part that needs a mill. `sliced_die.scad` is the same die made
from flat plates a laser or waterjet can cut — and it takes every dimension from the same
functions in `forming_die.scad`, so the arc, hub, tail, drive circle and groove root are
one expression used twice rather than two that agree until one moves. Nothing downstream
chooses between them; `die_style` does.

### No horizontal slicing can follow this groove

The groove is a half-round, and near its edges its surface runs almost parallel to the
die's axis — `dr/dz` goes to infinity at the part line. A stack always falls away from it
somewhere, and the further out it goes the worse it gets.

Each slice is cut to the groove's radius at **its own edge nearest the mid-plane**, so the
stack is everywhere at or inside the true groove and never proud of it. The tube gets line
contact on each rim. Cutting to each slice's mid-height instead would halve the gaps and
put every corner *into* the tube's path — the wrong trade for a surface being formed.

What that costs is **wrap**:

```
sliced die: 14 x 1/8 in slices, 3.18 mm each after facing
            supports 113 deg of the tube's section against 180 machined,
            and falls up to 10.53 mm away from the groove between rims
            wall factor here is 15.8 - a stepped groove suits thick wall and marks thin
```

113 degrees against 180. Thinner slices buy more — 1/16 in stock gets it to about 133 —
and no thickness reaches 180, because the last few degrees need a surface tangent to the
die's axis. That is not a defect in the implementation; it is what slicing a half-round
means, and the number is printed so the choice is made with it rather than around it.

### Who it is for

A stepped groove suits thick wall and marks thin, which is what **wall factor** measures,
so the report gives that alongside. The machined die remains the default. The sliced one
is there because a shop with a waterjet and no mill can build the whole machine, and
knowing exactly what that costs is better than not offering it.

### Not yet done

Each slice should come out as its own DXF. NopSCADlib names made parts through modules,
which does not fit a count that varies with the tube, so the stack currently exports as one
STL. That is a build-system problem rather than a modelling one.


## 17. The die lock, and the claim that was in the way

### What the cycle actually costs

```
cycle:   5 strokes of 1.22 m at the handle's end, re-pinning the drive pin between each
         5 drive holes index 180 deg of the 185 deg groove, so the last is over-pulled to
         41 deg and 1.39 m
handle:  1947 mm, needing 490 N of pull
```

Five pulls, each swinging the end of a two-metre handle through a metre and a quarter, and
between every one of them the drive pin comes out and goes into the next hole in the die.

**The stroke count is bounded by the holes, not by the pitch.** Each hole is used exactly
once, so `n` holes give `n` strokes and `n x pitch` degrees of die rotation — one pitch
more than the obvious guess, because engaging the last hole and pulling a pitch brings each
of the remaining `n - 1` round in turn and the final pull adds one more. Five holes at 36
degrees is 180, and a die with overbend wants 185, so **the last stroke is over-pulled**
rather than a sixth hole being drilled where there is no room. Both reference machines
carry five holes and must work the same way.

An earlier version of this file computed strokes as `ceil(arc / pitch)` with no reference
to how many holes existed, and reported six. At 1/2 in, where the die carries four holes
indexing 144 of the 185 degrees, it reported six against an actual four and said nothing
about the 41 degrees the last one has to make up.

### The real problem is springback between strokes

Stroke length is the lesser half of the case for a ratchet. **Nothing holds the die while
the drive pin is out**, so the tube springs back before it can be re-pinned and every
stroke gives back part of what the last one gained. JD2 solves that with two things: a die
lock pin, spring-loaded in a collar on the frame link, that "slides along the upper surface
of the forming die" until it drops into a drive hole and locks it; and an anti-springback
ratchet on the drive link's spacer tube [JD2-M32 p.7, p.8].

### The claim that said it could not be reached — withdrawn

This section previously said the lock pin could not be fitted without reordering the whole
stack, on this reasoning:

> *"To reach the die's drive holes from a frame link, the pin has to cross the drive links'
> band — and the drive links sweep every radius, so there is nothing at that radius they do
> not pass through."*

**That is withdrawn.** The drive links do sweep every radius, and it does not matter. What
a fixed part has to avoid is the band the links occupy in ANGLE, and that band is narrow,
because the machine indexes.

Work the cycle: the link engages the hole at world angle `psi`, pulls through the pitch,
the pin comes out, and the link swings **back** to `psi` — where the next hole has arrived,
because the die carried it there. Every stroke starts and ends at the same two angles. Over
a 180 degree bend the die turns 180 degrees and **the link never leaves a band one pitch
wide**. The frame stands still at a fixed angle, so a lock pin dropped from it meets the
drive link only if the two are angularly close.

The error was not arithmetic. It was describing a mechanism by the envelope of everything
it touches over a whole cycle, when what a collision needs is where two things are *at the
same time*. The sweep check in `bend.scad` carried the same mistake — it asked whether the
whole bend fitted between the followbar's keep-outs, which is the question for a machine
that does not index. It passed only because it was about five times too strict.

`bend_drive_band()` now states the band, and it is asked at a radius rather than answered
once: the same link is angularly narrow far out and angularly enormous close in. At 1/2 in
the link is 34.5 mm wide on a 23 mm drive circle, so its half-width there is 48 degrees and
the band is nearly four times the swing that generated it.

### Where it goes, and it is not two pitches

Two constraints looked like the whole problem, and one of them turned out to be a
distraction.

**Clearance.** The drive link's band must miss the pin by the link's half-width at the
pin's radius plus the pin's own. At 1-1/2 in that is 53 degrees.

**Phase.** A lock is only worth having if a hole is *at* the pin when the stroke ends. A
hole sits at angle `beta` exactly when `beta` is congruent to the stroke's home angle
modulo the pitch, and because the die advances by exactly one pitch per stroke, if that
holds once it holds every stroke.

From those two this section originally concluded that the pin sits on the frame link's own
axis, nudged by up to half a pitch to fix the phase, two pitches clear of the drive band.
**That is wrong, and the model is what said so.** Both constraints are satisfied and the
lock still does not work, because there is a third thing neither of them describes:

> **The die has to be there.**

The frame link points at the followbar, which is off the die's arc at the start of a bend.
The die's sector only rotates over that angle in the last 45 degrees. Phasing the holes to a
pin on the frame link's axis locks **the last two strokes of five and no others** — the
phase is right and the die is somewhere else.

More generally: the holes cover a window of only `(n-1) x pitch` in the die's own frame, and
the bend is longer than that window. So *where* the pin sits decides *which* strokes it
catches, and most angles catch some and miss others.

### One angle catches all of them

Holes sit at `a_i = inset + i x pitch` for `i` in `0 .. n-1`. Stroke `k` ends with the die
turned through `k x pitch`, so hole `n - k` is then at

```
a_(n-k) + k x pitch  =  inset + (n-k) x pitch + k x pitch  =  inset + n x pitch
```

The same angle for every `k` from 1 to `n`. **One pitch past the last drive hole**, and it
is exact rather than optimised — a hole arrives under the pin at the end of every stroke
without exception.

```
die lock: 7/8 in dia pin through the whole stack on r 73 mm at 198 deg - one pitch past the
          last drive hole, so a hole reaches it at the end of all 5 strokes
          on its own arm off the frame link, 57 mm wide for 477 N.m per link, drawn at the
          link's 87
          the drive band must clear it by 53 deg and stands 180 deg = 5 pitches off
```

At the die's start position that angle is just past the trailing edge of its arc, so the pin
begins a bend over air. Correct: a straight tube has nothing to spring back, and the die
rotates into the pin during the first stroke.

The clearance constraint survives as a check rather than a driver. The separation is
`n x pitch` by construction — 180 degrees at 1-1/2 in, against 53 needed — so it is checked
in both directions round the circle and never governs at any registered size.

### The frame link grows a second arm

198 degrees is nowhere near the followbar, so the frame link reaches it with an arm off the
same pivot. That is cheap — one more lobe on a plate already being cut — and the arm never
has to clear anything, because it lives in the frame links' own z bands, the same way the
followbar arm already runs straight over the die. **Only the pin crosses the drive links'
plane**, and only the pin needs the angular clearance.

The two arms carry unrelated loads and neither helps the other: the followbar arm reacts the
tube's push as a cantilever, the lock arm takes the springback moment back into the frame,
`Mp / 2` per link at the pivot. Both are drawn at the link's one width, which the followbar
sizes; the lock arm's own requirement is reported beside it and is under it at every size —
57 mm against 87 at 1-1/2 in, 84 against 106 at 2 in.

### It goes all the way through, and that is worth two pin sizes

Not a plunger hanging off the upper link. The angular exclusion holds at every radius, so
both drive links are clear and the pin can run the whole stack as a symmetric double-shear
joint like the frame pin.

That is not tidiness. Cantilevered off one frame link the span is from that link's
mid-plane to the die's, 39 mm at 1-1/2 in, and it wants **1-1/8 in**. Through the stack the
span is the standard `(t_centre + t_outer) / 2` and it wants **7/8**. A 1-1/8 in spring
plunger is not a plunger.

The drive pin and the lock pin go in the **same holes** at different angles, so they are one
size and the hole is sized once — on the lock's span, which is the longer of the two.

The cost is that the lock is inserted and pulled by hand like the drive pin, where JD2's
drops in by itself. A spring collar over the through pin would get that back; it is a
fitting rather than a load path and is not modelled.

### The exception

A die too small to carry drive holes is not indexed at all. JD2 drives those on the U-strap
pin instead [JD2-M32 p.7], the link really does swing the whole arc, and there is nothing to
lock into. **1/8 in and 1/4 in get no die lock.** That is what those sizes *are*, not a band
they fall outside, so it is reported as a plain fact and not as a departure.

## 18. What actually leaves the repo: cut files

Everything above decides what the machine *is*. This section is about what a shop is handed.

### The flat parts are cut, not printed

Seven of the fifteen made parts are a 2D outline in plate: the two frame links, the two
drive links, the two die plates, the base, and the pedestal foot. A laser, waterjet or
plasma table makes those from a **DXF**, and until now the model emitted them only as STL —
a mesh nobody can quote from.

They are now `dxf()` parts. `just build` writes `dxfs/*.dxf`, and the BOM files them under
**"CNC cut"** instead of under "Printed". What is left under "Printed" — the forming die,
the clamp, the followbar — are the three parts with real depth to cut, and those genuinely
want a solid model.

### The profile is the deliverable, and the picture is drawn from it

Each flat part's file now yields a `<part>_2D()` profile and nothing else; the extrusion
belongs to whoever places it. `routed_plate()` is what places one, and it does four things
at once: names the part on the BOM, declares the DXF, extrudes the profile for the assembly
view, and colours it.

The fourth thing is the one worth writing down. When NopSCADlib poses the assembly for the
manual's renders it **imports the exported DXF** in place of the module's children. So the
picture in `readme.md` is drawn from the cut file itself, not from a parallel description of
it. A cut file that does not match the assembly cannot sit there quietly; it changes the
picture.

### Two things the DXF does not carry

**Curves are polylines.** OpenSCAD writes a DXF at the current `$fn`, so every eye and every
bolt hole arrives as a 90-segment polyline rather than an arc. Cutter CAM reads it fine and
cuts it fine, and it is worth knowing before someone opens the file and wonders. Raise
`facets` before exporting production files if the finish matters.

**The sliced die is still not exported.** Its slice count varies with the tube — 14 at
1-1/2 in — and NopSCADlib names a made part through a module, one module per file. A count
that is a function of the configuration does not fit that, so the sliced die remains a
report and a preview only. It is the last part of the machine with no cut file, and it is
the one that needs the most of them.

## 19. The three welds

Three joints on this machine are welded, and until now they were a sentence. Every other
load path here is sized from a stress and an allowable; these carried **everything the
machine sheds into the world** on the strength of the word "welded".

| joint | what it carries |
|---|---|
| lower frame link → base plate | the drive torque about the pivot, the operator's pull, and the overturning that pull makes at the working plane |
| post → base plate (top) | the drive torque, and the pull as direct shear. No bending: the load is applied at this end, so its lever arm has not started |
| post → foot plate (bottom) | the drive torque, and the pull over the **whole** working height |

### Weld as a line

A fillet's strength goes with its **length**, so a weld group is treated as a line of unit
width rather than as an area. Its "area" is a length in mm and its second moments come out
in mm³ — one power down from their solid-section namesakes. Divide a moment by one of those
and you get **newtons per millimetre of weld**, with no leg size anywhere in the arithmetic.

That is the whole reason for doing it this way. The required leg falls out at the end, by
dividing by what one millimetre of fillet can carry, instead of being guessed, checked, and
guessed again.

The base joint is two parallel runs along the frame link's followbar arm; both post joints
are a ring round the post's OD. In-plane torsion and direct shear are added as scalars —
they are collinear at one point of the group and smaller everywhere else, which is the
standard hand check. Bending is combined as a vector, because it pulls the throat open
rather than shearing it.

### The allowable, and how good it is

**0.30 × the electrode's nominal tensile strength, on the effective throat** — 21 ksi /
144.8 MPa for E70XX [AISC-WELD]. The throat is `leg / √2`, the shortest path across the
corner, which is where a fillet loaded any way at all actually fails.

**This is the weakest-sourced number in the project, and it should be said plainly.** Every
other allowable here comes from a peer-reviewed journal or a mill data sheet; this one comes
from two secondary pages that restate AISC and AWS rather than being them. The figure itself
is not in doubt — it is the most-quoted number in weld design and the two sources agree to
three digits — but the provenance is one step further out than anything else in the load
path.

### The code minimum is not about strength, and it governs

AISC also sets a **minimum** leg from the thickness of the parts joined [AISC-360 Table
J2.4], and it has nothing to do with the load. It is a heat-input rule: too small a bead
against heavy plate chills too fast and cracks.

**The base weld is minimum-governed at every size in the range** — a 1/8 in fillet, both
sides of the link, where the load asks for well under a tenth of that. At 1-1/2 in it
carries 52 N/mm against 325 N/mm of capacity. The joint that looked like the biggest open
question turns out to have a factor of six in hand, and that is worth knowing rather than
assuming either way.

The post welds are the opposite: **load-governed at every size but the smallest**, and one
of them runs at 97 % of a 1/8 in fillet before stepping to 3/16. The report prints both
figures side by side and says which decided it, because a minimum-governed joint has margin
and a load-governed one does not.

### Which part the table is read against — a live disagreement

Table J2.4 is read against the **thinner** part joined. That is current AISC and current
AWS. Older editions read it against the **thicker** part, and secondary sources still repeat
that, so both readings are in circulation and **they do not agree here**: 1/4 in link on
3/8 in plate gives 1/8 in one way and 3/16 in the other.

Thinner is taken, and not because it is smaller. The rule exists so that a bead is not
chilled by the mass around it. On the pedestal's 0.120 in post wall the **larger** figure is
the dangerous one — it burns through the very part the rule is there to protect. The code
carries that logic itself: where the table minimum exceeds the thinner part's thickness, the
minimum is limited to that thickness, which is why two of the post welds come out at 3.05 mm
— the wall — rather than at a round 1/16 in step.

### A check I got wrong, and what it taught

A weld cannot be stronger than the metal it is welded to, so the first version asserted the
resultant against `0.4 Fy × t` of the part underneath. **It fired on seven perfectly good
sizes.**

The reason is worth keeping. At the post's foot, 300 of the 315 N/mm is **bending** — a
normal force pulling on the fusion face, not a shear across it — and comparing it to a
*shear* allowable conflates two limit states. The real check on that force is the post's own
section, which `pedestal_report()` already makes and which passes with room (71 MPa
equivalent against 100 allowable). The base weld is the opposite case, all but 4 % of it
in-plane, and there the same check is the right one and is kept.

The lesson is not "the check was too conservative". It was checking the wrong thing, and
only looked conservative.

## 20. What you actually order: lengths, and what holds a pin in

Two things stood between the parts list and someone using it, and both were invisible until
somebody tried to read the list as a list.

### A stack thickness is not a length you can buy

The model computes what a fastener has to cross and, until now, billed that number. So the
list asked for a `1/2 in × 1.556 in` bolt and a `1-1/8 in × 3.565 in` pin. Nobody stocks
those.

**Pins are ordered by USABLE length** — head underside to the cotter hole — and that comes in
**quarter-inch steps**, because a clevis pin's holes are spaced a quarter inch apart and
which one takes the cotter is what sets the length [MCMASTER-CLEVIS]. So the stack is the
**grip**, and `pin_usable_length()` rounds it up. `layout_pin_length()` became
`layout_pin_grip()` and lost the 6 mm allowance it used to add for a cotter: usable length
already ends at the cotter hole, so the allowance was the same thing counted twice.

**Bolts round the same way**, to a quarter inch. That step is *reasoned* rather than
catalogued — it is where the common lengths fall through the range this machine needs, and
no source was obtained for it.

### The rounding leaves slack, and the slack is a part

A stack never lands exactly on a step, so the ordered pin is always a little long — up to a
quarter inch. That gap is **washers**, and a builder who is not told about it assembles a
joint that rattles and blames the clearances. At 1-1/2 in the frame pin grips 84.55 mm and
orders 88.9, so 4.35 mm of washers go under its head. The report says so.

### What holds a pin in is not one answer

The holes were being drilled with nothing to go in them: no cotter, no clip, nothing on the
parts list. Adding "a cotter pin per pin" would have been wrong, and the model already knew
why — it distinguishes a **pivot** hole from an **index** hole (§7) precisely because those
two pins live different lives.

- A **pivot** pin — frame, followbar, U-strap, spacer — is fitted once and forgotten. A
  cotter is exactly right.
- An **indexed** pin — drive, and now the die lock — is pulled and re-seated at the end of
  every stroke, **five times per bend**. A cotter is exactly wrong: nobody opens and closes
  a split pin five times a bend, and one that has been straightened twice is scrap. Those
  get a **pin clip**.

Both are BOM lines now. Neither has a size, and that is deliberate: cotter geometry is
looked up per registry row and is `undef` on every row but the one measured off the
prototype's CAD, so naming a cotter size for the rest would be exactly the invention the
registry exists to refuse. The row says which retainer and which pin it belongs to; the
number is a shopping trip, like the pin's own.

Worth knowing while doing that shopping: **ASME B18.8.1 stops at 1 in** [ASME-B18.8.1], and
two of the pins here — the 1-1/8 in frame pin at the top of the range, and the 1-3/8 and
1-1/2 in rows the series was extended to — are larger than the clevis pin standard covers.
