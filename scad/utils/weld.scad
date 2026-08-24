/**
 * @file weld.scad
 * @brief What leg a fillet weld needs, from the load the joint carries
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Draws nothing. Three joints on this machine are welded rather than bolted -
 * the lower frame link to the base plate, and the pedestal post to its foot and to the base
 * plate above it - and between them they carry everything the machine sheds into the world.
 * Every other load path here is sized from a stress and an allowable; these were a sentence
 * in a comment until this file existed.
 *
 * ## Weld as a line
 *
 * A fillet's strength is proportional to its LENGTH, so a weld group is treated as a line
 * of unit width rather than as an area. Its "area" is then a length in mm and its second
 * moments come out in mm^3, which means dividing a moment by one of them gives newtons per
 * millimetre of weld directly - with no leg size anywhere in the arithmetic.
 *
 * That is the whole point. The required leg falls out at the end by dividing by what one
 * millimetre of a unit fillet can carry, instead of being guessed, checked and guessed
 * again.
 *
 * ## Allowables
 *
 * AISC allowable stress design: shear on a fillet weld's EFFECTIVE THROAT is 0.30 times the
 * nominal tensile strength of the electrode [AISC-WELD, MECHSIM-WELD]. For E70XX - 70 ksi,
 * the common mild steel filler and the one every quoted allowable assumes - that is 21 ksi,
 * or 144.8 MPa.
 *
 * The throat is the shortest path across the corner, `leg / sqrt(2)`, which is where a
 * fillet loaded any way at all actually fails.
 *
 * ## The code minimum is not about strength
 *
 * AISC also sets a MINIMUM leg from the thickness of the parts joined [AISC-360 Table J2.4],
 * and it has nothing to do with the load. It is a heat-input rule: too small a bead against
 * heavy plate chills too fast and cracks. On this machine it governs every joint, by a wide
 * margin at the base and narrowly at the post, so both figures are reported side by side -
 * a joint that is minimum-governed is a joint with margin, and that is worth being able to
 * see rather than infer.
 *
 * Sets no $fn.
 */

include <NopSCADlib/core.scad>;   // inch()

//! Nominal tensile strength of the filler metal, MPa. E70XX is 70 ksi.
weld_electrode_MPa = 482.63;

//! AISC ASD fraction of that allowed as shear on the effective throat [AISC-WELD].
weld_allowable_fraction = 0.30;

//! Allowable shear on the throat, MPa.
function weld_allowable_MPa() = weld_allowable_fraction * weld_electrode_MPa;

//! Effective throat of a fillet with leg `a`, mm.
function weld_throat(leg) = leg / sqrt(2);

//! What one millimetre of a fillet with leg `a` can carry, N/mm.
function weld_capacity_N_per_mm(leg) = weld_throat(leg) * weld_allowable_MPa();

//! The leg a fillet needs to carry `f` newtons per millimetre of weld, mm.
function weld_size_for_load(f_per_mm) = f_per_mm * sqrt(2) / weld_allowable_MPa();

//! Round a required leg up to what a welder is actually asked for: 1/16 in steps.
//!
//! Which is also the metric series in disguise - 1/8, 3/16, 1/4 and 5/16 in are 3.2, 4.8,
//! 6.4 and 7.9 mm, and the fillets a metric shop runs are 3, 5, 6 and 8. Nobody sets a
//! machine to 4.31.
function weld_specified_size(mm) = ceil(mm / inch(1/16) - 1e-9) * inch(1/16);

//! Smallest leg the code allows on a joint whose thinner part is `t` mm
//! [AISC-360 Table J2.4], limited to that thickness where the table exceeds it.
//!
//! The table is read against the THINNER part joined, which is current AISC and current
//! AWS. Older editions read it against the thicker part and secondary sources still repeat
//! that, so the two readings are both in circulation and they do not agree here: at the
//! base, 1/4 in link on 3/8 in plate, thinner gives 1/8 in and thicker gives 3/16.
//!
//! Thinner is taken, and not because it is smaller. The rule exists so a bead is not
//! chilled by the mass around it; on a 0.120 in post wall the LARGER figure is the
//! dangerous one, because it burns through the very part the rule is protecting.
function weld_min_size(t_thinner) =
    min(t_thinner,
        t_thinner <= inch(1/4) ? inch(1/8)
      : t_thinner <= inch(1/2) ? inch(3/16)
      : t_thinner <= inch(3/4) ? inch(1/4)
      :                          inch(5/16));

//! Largest leg the code allows along the EDGE of a part `t` mm thick [AISC-360 J2.2b].
//!
//! Only where the weld runs along an edge - a lap joint, like the frame link lying on the
//! base plate. A T-joint has no edge to melt back and its fillet may be larger than the
//! member standing on it, which is why the post welds are not checked against this.
function weld_max_edge_size(t) = t < inch(1/4) ? t : t - inch(1/16);

//
// Weld groups. Each is [length mm, weakest bending modulus mm^2, polar modulus mm^3,
// distance to the farthest millimetre mm] - all of it weld-as-a-line, so the moduli are one
// power of length down from their solid-section namesakes.
//
function weld_group_length(g)  = g[0];  //! Total length of weld, mm
function weld_group_S(g)       = g[1];  //! Bending modulus about the weakest axis IN the group's plane
function weld_group_J(g)       = g[2];  //! Polar modulus about the axis NORMAL to it
function weld_group_r_max(g)   = g[3];  //! Distance from the centroid to the worst millimetre

//! Two parallel runs of fillet, each `L` long and `d` apart.
function weld_group_parallel(L, d) =
    [2 * L,
     min(L * d, L * L / 3),
     L * d * d / 2 + L * L * L / 6,
     norm([L, d]) / 2];

//! A ring of fillet of radius `r`.
function weld_group_ring(r) = [2 * PI * r, PI * r * r, 2 * PI * r * r * r, r];

//! Load on the worst millimetre of a weld group, N/mm, from a torque about the axis NORMAL
//! to the group, a bending moment about an axis IN it, and a direct shear across it.
//!
//! The torsional and direct shear terms are added as scalars. They point the same way at
//! only one point of the group and the true resultant is smaller everywhere else; adding
//! them everywhere is the standard hand check. The bending term is genuinely perpendicular
//! to both - it pulls the throat open rather than shearing it - so that one is combined as
//! a vector rather than piled on top.
function weld_group_load(group, torque_Nmm, bending_Nmm, shear_N) =
    let (inplane = torque_Nmm * weld_group_r_max(group) / weld_group_J(group)
                       + shear_N / weld_group_length(group),
         normal  = bending_Nmm / weld_group_S(group))
        norm([inplane, normal]);

//! What one millimetre of the part a weld lands on can carry, N/mm - an allowable over its
//! thickness. A weld cannot be stronger than the metal it is welded to.
//!
//! MIND WHICH ALLOWABLE. This takes one, because the caller is the only thing that knows
//! which limit state its resultant belongs to. Applied with the shear allowable to a
//! resultant that is mostly BENDING it fires on a perfectly good joint - which is what it
//! did on the pedestal post, where 300 of the 315 N/mm at the foot is a normal force on the
//! fusion face and not a shear across it at all. The post's own section carries that, and
//! pedestal_report() checks it there. The base weld is the opposite case, all but 4 % of it
//! in-plane, and this is the right check to make on it.
function weld_base_metal_N_per_mm(t, allowable_MPa) = allowable_MPa * t;

//! The leg a joint is built with: what the load needs, or the code minimum, whichever is
//! larger, rounded up to a size a welder is asked for.
function weld_leg(f_per_mm, t_thinner) =
    max(weld_specified_size(weld_size_for_load(f_per_mm)), weld_min_size(t_thinner));

//! Which of the two decided it - for the report, because a minimum-governed joint has
//! margin and a load-governed one is at its limit.
function weld_governing_mode(f_per_mm, t_thinner) =
    weld_specified_size(weld_size_for_load(f_per_mm)) > weld_min_size(t_thinner)
        ? "the load" : "the code minimum";
