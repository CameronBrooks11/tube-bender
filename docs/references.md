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
**Re-read for the frame assembly (p.1, p.7), and it settled a design question.** The frame
pins are plain, loose, drop-in pins - two of them, the same part serving the die pivot and
the followbar - and the assembly procedure makes them the ALIGNMENT GAUGE: frame bolts hand
tight, pins in, then "tighten the 3/4 nuts as tightly as possible, while insuring the two
pins are perfectly vertical and slide easily through their respective holes". Searched end
to end the manual has **no cotter, clip, snap ring or retainer of any kind on any pin**; the
word does not appear. One instruction covers all of them: "make sure all pins are completely
seated in their holes... failure to do this may cause damage to the bender links or worse yet
the operator may slip and fall". Also: the frame pair is clamped by 3/4 in bolts through 1 in
OD spacer tubes, which continue through the base and the mounting surface to nuts underneath,
so one set of bolts clamps the pair AND anchors the machine; and the die locking pin carries
a 3/16 x 1-1/4 roll pin so it can be parked by lifting and rotating it (p.8).
→ `docs/design-basis.md` §1, §2, §5, §7, §22; `scad/purchased/pin.scad`

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

**Bend Tooling Inc. (n.d.).** *Encyclopedia: clamp die.*
<https://bendtooling.com/encyclopedia/clamp-die/> **[VN]** · **read**
Cited as **[BENDTOOLING-CLAMP]**. Clamp die length `L = t x k - r`, t the tube diameter,
k a rigidity constant, r the centreline radius; and the minimum: "A minimum value for L,
if the clamp die cavity is smooth, is around two times the tube diameter." Serrations and
knurling permit L to be about half a smooth cavity's. This is what the die's tail length
is cut from.
→ `docs/design-basis.md` §12, `scad/utils/bend.scad`

**Benderparts (n.d.).** *Tube Bending Formulas — Rotary-Draw Precision Calculations.*
<https://www.benderparts.com/tube-bending-formulas/> **[VN]** · **read**
Cited as **[BENDERPARTS-FORMULAS]**. Confirms `Fw = T / W` and `Fd = R / T` in the same
direction as [BENDTOOLING], gives the rigidity constant a default of 2 — which is where
`k = 5` comes from — and states smooth clamps start around 2 x OD of engagement and
serrated around 1 x. Carries no clamp-length formula and no groove-depth rule, which is
itself useful: two vendors' formula sheets and neither specifies the groove.
→ `docs/design-basis.md` §12, `scad/utils/bend.scad`

**Tools For Bending (n.d.).** *Tooling Design.*
<https://www.toolsforbending.com/tooling/tooling-design/> **[VN]** · **read**
Bend die and clamp die "hardened tool steel or alloy steel, heat treated and nitrided";
pressure die "alloy steel and nitrided". **Cited here as a correction.** A claim about the
part line and groove depth was attributed to this page from a search summary and used in
`forming_die.scad`; the page was then fetched and does not contain it. The claim is
withdrawn. Nothing in the model rests on this source except the material note.
→ `docs/design-basis.md` §5

**The Fabricator (n.d.).** *Getting a grip.*
<https://www.thefabricator.com/tubepipejournal/article/bending/getting-a-grip> **[TP]** · **unread**
Cited as **[FABRICATOR-GRIP]**, and cited only to record that it could NOT be read: the
site returns 403. A summary of it supplied the "grip length at least 3 x OD" rule and the
"3 x OD at 1 D falling to 1 x OD at 5 D" scaling, and the 3 was used in the model until
the two sources above were read and both said 2. The scaling may well be right; it is not
in the model because nobody here has seen it stated.
→ nothing; recorded so the next person does not re-import it from a summary

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

## Structural allowables and materials

**Goel, S.C. (n.d.).** "Combined Shear and Tension Stresses." *AISC Engineering Journal.*
<https://ej.aisc.org/index.php/engj/article/download/467/466/466> **[PR]** · **read**
Cited as **[AISC-GOEL]**. States the AISC allowable stress design fractions directly:
"tension, Ft = 0.6Fy, and that in shear, Fv = 0.4Fy", against the von Mises shear yield of
about 0.6Fy. Every pin diameter and both link widths are cut from these two numbers.
**Read properly, and worth it:** a search summary of the same topic conflated the ASD
allowable (0.4Fy) with the von Mises shear yield (0.6Fy), which are a factor of 1.5 apart.
→ `scad/utils/pin_sizing.scad`, `docs/design-basis.md` §13

**McMaster-Carr (n.d.).** *Selectable-Length Clevis Pins.*
<https://www.mcmaster.com/products/clevis-pins/performance~selectable-length/> **[VN]** · **abstract**
Cited as **[MCMASTER-CLEVIS]**. The one fact taken: a clevis pin's cotter holes are
**spaced 1/4 in apart**, and which one the cotter goes through is what sets the usable
length. That is the increment `pin_usable_length()` rounds to. **Abstract:** the statement
comes from the product listing as surfaced in search, not from a page that was opened, and
it describes the selectable-length line specifically — a plain clevis pin has one hole and
the same 1/4 in step is then a statement about which lengths are stocked rather than about
holes in one pin.
→ `scad/purchased/pin.scad`

**ASME B18.8.1, Clevis Pins and Cotter Pins (Inch Series).** Cotter pin nominal sizes run
1/32 in to 3/4 in with a tabulated gage hole for each; 1/8 in pin to a 0.141 in hole.
<https://amesweb.info/Fasteners/Pins/Cotter-Pin-Sizes-Chart.aspx> **[STD]** · **abstract**
Cited as **[ASME-B18.8.1]**. Reached through a secondary table, not obtained. Recorded
because it is the standard that WOULD settle the cotter sizes this model deliberately leaves
open, and because it also settles that the clevis pin standard stops at 1 in — two of the
pins here are larger than anything it covers.
→ `scad/purchased/pins.scad`

**MechSimulator (n.d.).** *Fillet Weld Strength Design — Throat, Allowable Stress & FOS.*
<https://mechsimulator.com/blog/articles/weld-strength-fillet-weld-design-guide/> **[TP]** · **read**
Cited as **[AISC-WELD]**. States the allowable directly: the shear allowable on a fillet
weld's effective throat is **0.30 x the electrode's nominal tensile strength**, which for
E70XX is 21 ksi / 144.9 MPa, and the throat is `0.707 x leg`. Corroborated independently by
a second calculator page reached from a different search. **Secondary, and marked as such:**
both restate AISC/AWS rather than being it, and the specification itself was not obtained.
The number is not in doubt — it is the most-quoted figure in weld design — but the
provenance is one step removed from every other allowable in this project.
→ `scad/utils/weld.scad`, `docs/design-basis.md` §19

**IDEA StatiCa (n.d.).** *Detailing of bolts and welds according to AISC.*
<https://www.ideastatica.com/support-center/detailing-of-bolts-and-welds-according-to-aisc> **[VN]** · **read**
Cited as **[AISC-360]** for the two detailing rules the weld sizing uses. Minimum fillet
size, Table J2.4, read against **the thickness of the thinner plate**: 1/8 in to 1/4 in,
3/16 in to 1/2 in, 1/4 in to 3/4 in, 5/16 in above. Maximum size along an edge, J2.2b,
quoted verbatim: "For plate thickness smaller than 1/4 in, the weld size should be no bigger
than plate thickness. For plate thickness equal to or higher than 1/4 in, the weld size
should be no bigger than the plate thickness -1/16 in."

**A disagreement worth recording.** A second secondary source states the minimum is read
against the **thicker** part, and on this machine the two readings differ — 1/4 in link on
3/8 in plate gives 1/8 in one way and 3/16 in the other. Thinner is current AISC and current
AWS, and the commentary rationale quoted for the change ("the prevalence of the use of
filler metal considered to be low hydrogen") is consistent with that direction. Older
editions read it against the thicker part, which is why the wrong figure is still in
circulation.
→ `scad/utils/weld.scad`, `docs/design-basis.md` §19

**Elgin / MW Components (n.d.).** *Carbon Steel Grade 1018 Data Sheet — AISI 1018, cold drawn.*
<https://www.mwcomponents.com/uploads/Resource-Center/Elgin-Material-Sheets/Carbon-Steel-Grade-1018-Data-Sheet_Elgin.pdf> **[VN]** · **read**
Cited as **[MW-1018]**. Cold drawn 1018: tensile ultimate 440 MPa, **yield 370 MPa**. The
pin material anchor. Note what it does NOT settle: the prototype's pin is sold as
"1004-1045 carbon steel", a range rather than a grade, and 1004 sits below this. A pin has
to be ordered to a stated grade or the margin re-checked.
→ `scad/purchased/pins.scad`

**ASTM A36 structural steel.** Specified minimum yield 36 ksi (250 MPa), tensile
400-550 MPa. <https://www.ssab.com/en-us/brands-and-products/commercial-steel/structural-steel/astm-a36> **[STD]** · **abstract**
Cited as **[ASTM-A36]**. The yield is definitional — the grade is named for it — and
several vendor pages agree, but the standard itself was not obtained. It is a MINIMUM: a
real plate is stronger, and nothing here is sized on the difference.
→ `scad/purchased/plates.scad`, both links

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
