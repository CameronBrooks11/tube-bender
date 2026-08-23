# References

Every external source this design rests on, what it is used for, and where in the repo
that use lives. Kept so a number in the CAD can be traced back to the thing that
justifies it.

**Verification status is recorded per source.**

- **read** — the full text was retrieved and the cited passage confirmed
- **abstract** — only the abstract or a catalogue summary was available
- **unread** — cited from a secondary source, not obtained

Grades: **[PR]** peer-reviewed · **[STD]** standard or government handbook ·
**[TX]** textbook / reference · **[TP]** trade press · **[VN]** vendor documentation.

Vendor catalogue pages and McMaster part numbers that justify a single registry row are
cited inline on that row, not here. This file carries the sources that shape the design.

---

## Machine architecture and tooling practice

**J D Squared Inc. (2009).** *Model 32 Tube Bender — Assembly & Operating Instructions.*
<https://support.jd2.com/MiscDown/dl/M32BDirections.pdf> **[VN]** · **read**
Cited as **[JD2-M32]**. The closest published description of the machine being rebuilt
here. Supplies: the trade vocabulary (forming die, U-strap, followbar, drive link, frame
link, drive holes); tube-versus-pipe specification and the die-must-match-the-tube rule
(p.4); **the forming die groove is profiled so the tube does not fully seat** (p.4); the
followbar's angled rear insert and its deliberate ride height below the die groove (p.5);
**drive holes drilled 1/8 in oversize on a 7/8 in pin, on purpose** (p.7); dies under 3 in
CLR carry no drive holes (p.4, p.7); pin sizes 1-1/4 in frame, 7/8 in drive and U-strap;
the 36 in handle and the 1-3/4 x .095 mild steel claim (p.2); hydraulic pressures for a
10-ton cylinder on three test materials (p.3); springback of 3–4 degrees on 1-1/2 x .120
mild steel and roughly double for chromoly (p.9, p.11); never lubricate a round-tube
forming die groove (p.7).
→ `docs/design-basis.md` §1, §2, §5, §7

**Pro-Tools (n.d.).** *Tube and Pipe Bender, 105 Series Heavy Duty — specifications.*
<https://pro-tools.com/products/manual-tube-and-pipe-bender-105-series-heavy-duty> **[VN]** · **read**
Cited as **[PROTOOLS-105]**. Capacity 1/2 to 2 in OD round tube to 0.134 in wall; minimum
CLR approximately 3 x OD; maximum CLR 7 in; 5/8 in thick frame arms; bends to 180 degrees
depending on the die. One of the two machines that fix the upper size bound.
→ `docs/design-basis.md` §3, §4

**Pro-Tools (n.d.).** *90 Degree Round Tube Dies for 105 Brute Tube and Pipe Bender.*
<https://pro-tools.com/pages/90-degree-round-tube-dies-for-105-brute-tube-and-pipe-bender> **[VN]** · **read**
Cited as **[PROTOOLS-DIES]**. The full OD x CLR matrix actually sold, 3/4 in through
2-1/2 in OD. Every entry falls between 2.8D and 4.8D. This is the catalogue the CLR
registry is built from and the empirical check on the 3D rule.
→ `docs/design-basis.md` §4

**Swagelok (rev. 5).** *Hand Tube Bender Manual, MS-13-43.*
<https://www.swagelok.com/downloads/webcatalogs/en/ms-13-43.pdf> **[VN]** · **abstract**
Cited as **[SWAGELOK-MS-13-43]**. Bend radii for the small end: 0.56 in on 1/8 in tube,
0.56 and 0.75 in on 1/4 in, 0.94 in on 5/16 and 3/8 in, 1.50 in on 1/2 in — i.e. 2.25D to
4.5D. Fixes the lower size bound at 1/8 in. Values taken from the catalogue's ordering
table as surfaced in search; the PDF itself was not opened, so this is **abstract** and
should be upgraded before any of these radii drive geometry.
→ `docs/design-basis.md` §3, §4

## Bend geometry and bendability

**Bend Tooling Inc. (n.d.).** *Tube Bending Calculations & Formulas.*
<https://bendtooling.com/tube-bending-formulas/> **[VN]** · **read**
Cited as **[BENDTOOLING]**. The authoritative statement of the two ratios, in the correct
direction: wall factor `Fw = T / W` (OD over wall) and D of bend `Fd = R / T` (CLR over
OD). Also clamp length, pressure die length `Lp = (R x pi x (B/180)) + (T x Kr)`, arc
elongation, and a bend difficulty rating. Explicitly states that **no effective formula
for springback exists** — it is machine- and material-specific.
→ `docs/design-basis.md` §4

**Pro-Tools (n.d.).** *Wall Factor and D of Bend: Getting to the Center of the Centerline
Radius Debate.*
<https://pro-tools.com/blogs/protoolsusa/42288387-wall-factor-and-d-of-bend-getting-to-the-center-of-the-centerline-radius-debate> **[TP]** · **read**
Cited as **[PROTOOLS-WALLFACTOR]**. The 3 x OD rule of thumb for the minimum centreline
radius achievable without an internal mandrel, and its own caveat that the rule is "very
rudimentary" and material-specific.
→ `docs/design-basis.md` §4

**The Fabricator (n.d.).** *4 essential modes of tube bending.*
<https://www.thefabricator.com/thefabricator/article/tubepipefabrication/4-essential-modes-of-tube-bending> **[TP]** · **abstract**
Cited as **[THEFABRICATOR-4MODES]**. Tightest achievable CLR is 1 x diameter; 1.5 x
recommended where possible; 3 x OD for benders without a mandrel; outside wall thins up to
33 %. **Caution:** the summary read of this article states wall factor as *wall over OD*,
which is inverted relative to [BENDTOOLING]. The inverted form was not adopted; the
discrepancy is the reason §4 states the direction explicitly.
→ `docs/design-basis.md` §4

**Rogue Fabrication (n.d.).** *Mandrel Bending: What It Is and When You Need It.*
<https://www.roguefab.com/mandrel-bending/> **[TP]** · **abstract**
Cited as **[ROGUEFAB-MANDREL]**. 3.0D as the threshold below which a mandrel is worth
serious consideration; below 2.0D generally required; unsupported tube tighter than 2 x OD
develops excessive ovality. Thin wall, at or below 18 ga, needs more support.
→ `docs/design-basis.md` §4

**Tang, N.C. (2000).** "Plastic-deformation analysis in tube bending." *International
Journal of Pressure Vessels and Piping* 77(12):751-759.
[doi:10.1016/S0308-0161(00)00061-2](https://doi.org/10.1016/S0308-0161(00)00061-2)
**[PR]** · **unread**
The standard analytical treatment: stress in bends, wall thickness change, neutral axis
deviation, bending moment and flattening. **Paywalled and not obtained** — recorded here
because it is the source that would replace the plain plastic-moment floor used in §6 with
a real bending-moment model. Nothing in the current design rests on it.
→ roadmap for `docs/design-basis.md` §6

## Material properties

**Totten Tubes (n.d.).** *ASTM A513 Specification Information — Hardness Limits and Tensile
Properties for A513 Steel Round Tubing.*
<https://www.tottentubes.com/astm-a513-specification-information> **[VN]** · **read**
Cited as **[TOTTEN-A513]**. Yield bands across grades 1008–1026 by processing condition:
as-welded 30–45 ksi, normalized 23–40 ksi, sink-drawn 38–55 ksi, mandrel-drawn 50–70 ksi,
mandrel-drawn stress-relieved 45–65 ksi. Registered as **bands**, because that is what the
source gives; picking a midpoint would invent a precision the specification does not have.
→ `docs/design-basis.md` §6

## Mechanics

**Plastic moment / plastic section modulus.** Standard plasticity result; the hollow round
section's plastic modulus is `Zp = (D^3 - d^3)/6`.
<https://en.wikipedia.org/wiki/Plastic_moment> **[TX]** · **read**
Cited as **[PLASTIC-MOMENT]**. Used as a **lower bound** on the drive torque: it ignores
strain hardening, followbar and U-strap friction, and the travelling hinge, all of which
raise the real figure.
→ `docs/design-basis.md` §6

## Human factors

**Federal Aviation Administration (2003, amended Oct 2009).** *Human Factors Design
Standard (HFDS), Chapter 14: Anthropometry and biomechanics.*
<https://hf.tc.faa.gov/hfds/download-hfds/hfds_pdfs/Ch14_Anthropometry_and_biomechanics_Oct2009.pdf>
**[STD]** · **read**
Cited as **[HFDS-2009]**. Exhibit 14.5.3.1 (from MIL-HDBK-759B, 1992), horizontal push or
pull a designer may require: 110 N low traction, 200 N medium traction, 240 N one hand
braced, 310 N high traction, **490 N both hands braced against a wall or feet anchored on
non-slip ground**, 730 N with the back. Exhibit 14.5.2.1, 5th-percentile male arm strength
for control forces: pull 177.6–199.2 N depending on elbow flexion. 490 N is the ceiling the
handle length is derived against.
→ `docs/design-basis.md` §6

**ISO 11228-2:2007.** *Ergonomics — Manual handling — Part 2: Pushing and pulling.*
<https://www.iso.org/standard/26521.html> **[STD]** · **unread**
Recorded, not used. It is the obvious companion to [HFDS-2009], but it is restricted to
two-handed whole-body exertions while standing or walking and is paywalled. If the handle
force budget is ever contested, this is the standard to buy.

---

## On `references.bib`

There is no BibTeX file yet, on purpose. Exactly one source above is literature
(Tang 2000) and it is unread; the rest are vendor documentation and government
handbooks, which by the same convention are cited inline rather than exported. A `.bib`
holding one entry is ceremony. It gets written when the literature side of this list is
worth importing in one go.

## Software

**Palmer, C. (2018–).** *NopSCADlib.* <https://github.com/nophead/NopSCADlib> **[VN]** · **read**
The library this project is built on, used for its full BOM and assembly machinery, not
just its vitamins: `assembly()` build steps, `stl()`/`dxf()` for made parts, `vitamin()`
for bought ones, `make_all` for BOM, DXFs, exploded views and the assembly manual, and
`config_<target>.scad` for multiple configurations. Requirements read from
[`docs/usage.md`](https://github.com/nophead/NopSCADlib/blob/master/docs/usage.md):
OpenSCAD 2021.01+, Python 3.6+, **ImageMagick 7** (the scripts call the `magick` binary),
and the Python `colorama`, `markdown` and `codespell` modules.
→ everything in `scad/`, `docs/design-basis.md` §11
