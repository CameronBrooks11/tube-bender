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
