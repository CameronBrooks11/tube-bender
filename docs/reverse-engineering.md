# Reverse-engineering the Onshape original

A 1.5 in prototype was drawn in Onshape and exported as
`Bender assembly.step` (AP242, millimetres). That file is the reference this model was
started from; it is **not** the specification. This document records what it actually
measures and, feature by feature, what carries over.

The STEP and everything derived from it live in `reference/`, which is gitignored: the
file is ~1.2 MB, the exploded parts and meshes are derived from it, and none of it belongs
in this repo's history. Regenerate with `reference/tools/explode.py`, which reads the
B-rep with OCCT and reports exact face and edge parameters — nothing here was scaled off a
screenshot.

---

## What it is

A manual swing-arm rotary-draw bender of the J D Squared / Pro-Tools pattern. Tube OD
**38.1 mm (1.5 in)** — every groove in the model is r = 19.05.

Onshape part names map onto the trade's vocabulary (see
[`design-basis.md`](design-basis.md) §1):

| Onshape name | trade name |
|---|---|
| `top_die` + `bottom_die` + `top_plate` + `bottom_plate` | forming die |
| `Die tubing locker` | U-strap / clamp |
| `Tube guide` | followbar / pressure die |
| `loop` | follower shoe on the outgoing leg |
| `fixed arm` | frame link |
| `mobile arm` | drive link |
| `spacer` | spacer |

## Stack (z, mm) — total 76.2 (3 in)

| z range | part |
|---|---|
| 0 – 6.35 | frame link (lower) |
| 6.35 – 12.70 | drive link (lower) |
| 12.70 – 19.05 | bottom_plate |
| 19.05 – 38.10 | bottom_die |
| 38.10 – 57.15 | top_die |
| 57.15 – 63.50 | top_plate |
| 63.50 – 69.85 | drive link (upper) |
| 69.85 – 76.20 | frame link (upper) |

Tube centreline plane z = 38.10, the die split plane. Plates and links are 6.35 mm
(1/4 in); each die half is 19.05 mm (3/4 in), so **die thickness = tube OD**.

## Forming die

- groove: half-round r = 19.05 cut in the outer rim, split on z = 38.10
- groove root circle r = **113.010** → tube **CLR = 132.06 mm**, i.e. **3.466 x OD**
- die outer r = 131.814; die plates r = **136.525** (5.375 in)
- arc span 221.7 deg
- clamp bolts: **20 x d8 on r = 95.25 (3.75 in)**, evenly spaced 10.9447 deg, symmetric
  about +Y, spanning +/-104 deg
- drive holes: **d20 at centre + 6 x d20 on r = 70.0**, spaced 36 deg
- the plates carry a 6.35-wide slot for the U-strap tongue

## Links (both 6.35 mm plate, 60 mm wide, all holes d20)

- **drive link**: pivot eye r30 at x = 0; holes at x = 0, 70, 315, 375; nose ending x = 400
- **frame link**: pivot eye r30 at x = 0, 45 deg dog-leg to a beam at y = 60 carrying
  **8 holes at 23.175 mm pitch, x = 88.758 .. 250.983**, then holes at x = 354.323 and
  399.323, same nose

## Small parts

- **followbar** 65 x 80 x 63.5 block; half-round r19.05 channel along y at local
  (x = 0, z = 31.75), relieved between y = 20..60; d20 pin hole at (46.35, 30)
- **follower shoe** half-round cradle r19.05 / OD 50.8, 40 mm long, arm out to a d20 pin
  hole 72 mm away
- **U-strap** 57.7 x 86.4 x 50.8 block, d20 pin hole, tapped cross hole d17.5, 6.35 tongue
  running in the die-plate slot, r2 fillets
- **spacer** washer OD 30 / ID 20 / t 4.05

## Hardware carried in the STEP

- **McMaster 91236A849** hex head screw: shank d19.05 (3/4 in), hex 28.575 across flats,
  head 12.7 thick, thread minor d15.75 → 3/4-10 UNC
- **McMaster 98306A868** clevis pin: shank d19.05 (3/4 in), head d23.98, cotter hole
  d3.96 (5/32 in)

---

## The four anomalies, resolved

Four things in the STEP could not be explained by the geometry alone. Research settled
three of them and two turned out to be **correct practice that would have been "fixed"
into a defect**.

### 1. Every pin hole is d20.0 metric on a d19.05 (3/4 in) pin — 0.95 mm of slop

**Keep, and make it explicit.** This is not slop, it is how the machine works. JD2 drills
its drive holes **1 in on a 7/8 in pin — 1/8 in (3.18 mm) oversize on purpose**, "to
provide easier pin installation", because the drive pin is moved by hand every few degrees
of bend [JD2-M32 p.7]. Tightening these holes would make the bender unusable.

What the original does not do is distinguish the fits: the frame pivot, which should be a
close running fit, has the same d20 hole as the index holes, which should be loose. The
model registers **pivot fit** and **index fit** separately.

### 2. The followbar channel is at x = 135.108; the die tangent line is at 132.06

3.048 mm (0.120 in) outboard. **Probably a real effect, drawn the wrong way.** A
production followbar's rear insert is deliberately **angled** relative to the tube axis to
support the tube just past the point of bend, and its grooves ride slightly *lower* than
the die's groove so it can rise under load rather than bind [JD2-M32 p.5]. A plain 3 mm
radial offset is neither of those. Treated as drafting slop for now; the real geometry is
a followbar drop and a rear-insert angle, both on the roadmap (`design-basis.md` §5).

### 3. CLR 132.06 mm = 5.199 in is round in neither system

**Discard.** No rule recovers it and it is not a radius anyone sells: Pro-Tools' 1-1/2 in
dies are 4-1/2, 5, 6 and 7 in [PROTOOLS-DIES]. It sits between two catalogue sizes. The
parametric model defaults to the smallest catalogued CLR at or above 3 x OD, which for
1-1/2 in tube is **4-1/2 in (114.3 mm)**.

For comparison against the original, 5.199 in is 3.466D — comfortably inside the 2.8–4.8D
band the whole catalogue occupies, so the prototype bends fine. It is just not a die you
can order.

### 4. The follower shoe and its pin are not coincident with any hole in either link

**Discard.** The shoe's cradle axis is 131.5 mm from the pivot against a 132.06 mm CLR,
and its pin lands at radius 103.6 where nothing else has a hole. Hand-placed, not mated.

---

## What the original contributes, in the end

The prototype is the reason this repo exists and it fixes the architecture: the stack
order, the split-die-plus-plates construction, the dog-leg frame link, the U-strap tongue
running in a plate slot, and 1.5 in as the size to check the parametric model against.

Its **numbers** are a starting point and mostly do not survive: the CLR is not orderable,
the pin fits are undifferentiated, the followbar is offset the wrong way, and the whole
thing is one fixed size. That is the expected outcome of a late-night prototype and is why
the model is being derived rather than transcribed.
