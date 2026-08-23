/**
 * @file pedestal.scad
 * @brief A post to stand the machine on, for when a bench will not do
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Bolted to a bench, the whole machine works in a plane 45 mm above the
 * bench top and the tube's free end sweeps across it. That is fine for the small sizes
 * and useless for the large ones, where the handle is two metres long and the operator
 * needs to get their weight behind it. The pedestal raises the working plane and lets the
 * tube point anywhere.
 *
 * ## The post carries two things at once
 *
 * Bending, from the operator's pull acting at the working height, and torsion, from the
 * drive torque the machine is reacting. Sized by the maximum shear stress theory: an
 * equivalent torque `sqrt(M^2 + T^2)` against the polar modulus, which for a round section
 * is twice the section modulus.
 *
 * ## The height is not arbitrary
 *
 * The 490 N pull that sizes the whole machine is only available to a braced operator, and
 * the standard qualifies it: braced "against a vertical wall 510-1780 mm from and parallel
 * to the panel, or if anchoring the feet on a perfectly non-slip ground" [HFDS-2009
 * Exh. 14.5.3.1]. A handle outside that band is not a handle that 490 N applies to, so the
 * working height is checked against it and reported.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/bolt.scad>
use <../purchased/plate.scad>
use <../purchased/structural_tube.scad>

include <../utils/bend.scad>;

//! The band the operator can be braced in for the 490 N figure to apply, mm [HFDS-2009].
pedestal_braced_band = [510, 1780];

//! Equivalent torque on the post, N.mm, from bending and torsion together.
function pedestal_equivalent_torque(force_N, height_mm, moment_Nm) =
    let (m = force_N * height_mm, t = moment_Nm * 1000)
        sqrt(m * m + t * t);

//! Tension in the worst foot bolt, N, from the machine trying to tip over: the operator's
//! pull at the working height, resisted as a couple by the bolts on the far side.
function pedestal_foot_tension_N(force_N, height_mm, radius_mm) =
    force_N * height_mm / (2 * radius_mm);

//! Size of the foot plate, [x, y] mm.
//!
//! REASONED, NOT CITED: three times the post's diameter, square. It is a base plate for a
//! free-standing post, so what matters is the couple arm its bolts get, and three
//! diameters puts them clear of the weld without becoming a trip hazard.
function pedestal_foot_size(post) = [3 * structural_od(post), 3 * structural_od(post)];

//! Where the four foot bolts sit, [x, y] each.
function pedestal_foot_bolts(post, bolt_d) =
    let (s = pedestal_foot_size(post),
         e = plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1)
        [for (sx = [-1, 1], sy = [-1, 1]) [sx * (s[0] / 2 - e), sy * (s[1] / 2 - e)]];

//! Distance from the post's axis to each foot bolt, mm.
function pedestal_foot_radius(post, bolt_d) = norm(pedestal_foot_bolts(post, bolt_d)[0]);

//! The worst load on a foot bolt, N - whichever of shear and tension governs.
function pedestal_foot_bolt_load_N(force_N, height_mm, moment_Nm, radius_mm) =
    max(moment_Nm * 1000 / (4 * radius_mm) + force_N / 4,
        pedestal_foot_tension_N(force_N, height_mm, radius_mm));

//! The smallest bolt in `candidates` that carries its load at the radius it itself leaves,
//! or `undef`. Same shape as the base's selection and for the same reason: a bigger bolt
//! needs a bigger edge distance, which shrinks the radius, which raises the load.
//!
//! The safety factor is the base's, applied here too. It was left off at first, which let
//! a 1/4 in bolt look adequate where a 1/2 in is wanted - the same joint into the same
//! floor should not be judged two ways depending on which file sized it.
function pedestal_foot_bolt(post, force_N, height_mm, moment_Nm, yield_MPa, candidates) =
    let (fits = [for (b = candidates)
                     if (pedestal_foot_bolt_load_N(force_N, height_mm, moment_Nm,
                             pedestal_foot_radius(post, bolt_diameter(b)))
                         <= bend_anchor_bolt_allowable_N(bolt_diameter(b), yield_MPa))
                         bolt_diameter(b)])
        len(fits) == 0 ? undef
                       : [for (b = candidates) if (bolt_diameter(b) == min(fits)) b][0];

//! The post and its foot, drawn with the top of the post at z = 0 and running down.
module pedestal(post, plate, length, bolt_d) {
    s = pedestal_foot_size(post);
    t = plate_thickness(plate);

    translate_z(-length)
        structural_tube(post, length);

    translate_z(-length - t)
        render_2D_plate(plate)
          plate_2D(plate, s[0], s[1])
            offset(0)
                difference() {
                    square(s, center = true);

                    circle(d = structural_id(post));

                    for (p = pedestal_foot_bolts(post, bolt_d))
                        translate(p) circle(d = bolt_clearance_hole_d(bolt_d));
                }
}

//! Echo what the pedestal comes out as.
module pedestal_report(post, plate, length, bolt, bolt_yield, force_N, height_mm,
                       moment_Nm) {
    te    = pedestal_equivalent_torque(force_N, height_mm, moment_Nm);
    tau   = te / (2 * structural_section_modulus(post));
    r     = pedestal_foot_radius(post, bolt_diameter(bolt));
    shear = moment_Nm * 1000 / (4 * r) + force_N / 4;
    tens  = pedestal_foot_tension_N(force_N, height_mm, r);
    allow = bend_anchor_bolt_allowable_N(bolt_diameter(bolt), bolt_yield);

    echo(str("pedestal: ", structural_size(post), " post ", round(length), " mm long, ",
             round(structural_mass_per_m(post) * length / 1000 * 10) / 10, " kg, on a ",
             plate_size(plate), " foot ", round(pedestal_foot_size(post)[0]), " mm square"));
    echo(str("          bending ", round(force_N * height_mm / 1000), " N.m and torsion ",
             round(moment_Nm), " N.m give ", round(tau), " MPa shear against ",
             round(pin_allowable_shear_fraction * structural_yield(post)), " MPa allowable"));
    echo(str("          4 x ", bolt_size(bolt), " foot bolts on r ", round(r), " mm: ",
             round(shear), " N shear, ", round(tens), " N tension, allowable ",
             round(allow), " N at a safety factor of ", bend_anchor_safety_factor));
    echo(str("          working plane at ", round(height_mm), " mm",
             height_mm >= pedestal_braced_band[0] && height_mm <= pedestal_braced_band[1]
                 ? " - inside the braced band the 490 N ceiling assumes"
                 : " - OUTSIDE the braced band; the 490 N ceiling does not apply here"));
}
