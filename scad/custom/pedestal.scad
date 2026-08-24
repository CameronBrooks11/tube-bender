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
use <../utils/units.scad>
use <../purchased/plate.scad>
use <../purchased/structural_tube.scad>
use <../utils/weld.scad>

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

//! The weld that holds the post on, at either end: a ring of fillet round its outside
//! diameter.
//!
//! The bore in the foot lets a second ring be run inside as well, and this does not count
//! it. One ring is what the arithmetic is done on and the inside pass is margin.
function pedestal_weld_group(post) = weld_group_ring(structural_od(post) / 2);

//! Load on the worst millimetre of the FOOT weld, N/mm - the bottom of the post, where the
//! operator's pull has the whole working height to act over.
function pedestal_foot_weld_load(post, force_N, height_mm, moment_Nm) =
    weld_group_load(pedestal_weld_group(post), moment_Nm * 1000, force_N * height_mm,
                    force_N);

//! And of the TOP weld, where the post meets the base plate.
//!
//! Same torque, and effectively no bending: the pull is applied at this end, so its lever
//! arm has not started. That is why the post is a bending problem at the bottom and a pure
//! torsion problem at the top, and why the two welds are not the same size.
function pedestal_top_weld_load(post, force_N, moment_Nm) =
    weld_group_load(pedestal_weld_group(post), moment_Nm * 1000, 0, force_N);

//! The thinner of the two parts at either post weld, mm - which is the post's wall on every
//! size in the registry, and is what sets the code minimum.
function pedestal_weld_thinner(post, plate) =
    min(structural_wall(post), plate_thickness(plate));

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

//! The profile the foot is cut from, centred on the post's axis.
//!
//! The post is not here and neither is the weld. A pedestal is a WELDMENT - a purchased
//! length of tube with a cut plate on the end of it - so the only thing this file makes is
//! the plate, and the assembly is what puts the two together.
//!
//! The bore is the post's own INSIDE diameter, so the post's wall lands on the plate as an
//! annulus rather than the post standing on a solid disc. What that buys is access: the
//! joint can be run as a fillet outside the post and again inside the bore.
module pedestal_foot_2D(post, plate, bolt_d) {
    s = pedestal_foot_size(post);

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
    te       = pedestal_equivalent_torque(force_N, height_mm, moment_Nm);
    tau      = te / (2 * structural_section_modulus(post));
    r        = pedestal_foot_radius(post, bolt_diameter(bolt));
    shear    = moment_Nm * 1000 / (4 * r) + force_N / 4;
    tens     = pedestal_foot_tension_N(force_N, height_mm, r);
    allow    = bend_anchor_bolt_allowable_N(bolt_diameter(bolt), bolt_yield);
    t_thin   = pedestal_weld_thinner(post, plate);
    fw       = pedestal_foot_weld_load(post, force_N, height_mm, moment_Nm);
    foot_leg = weld_leg(fw, t_thin);
    top_leg  = weld_leg(pedestal_top_weld_load(post, force_N, moment_Nm), t_thin);

    echo(str("pedestal: ", structural_size(post), " post ", fmt_length(length), " long, ",
             fmt_mass(structural_mass_per_m(post) * length / 1000), ", on a ",
             plate_size(plate), " foot ", fmt_length(pedestal_foot_size(post)[0]),
             " square"));
    echo(str("          bending ", fmt_moment(force_N * height_mm / 1000), " and torsion ",
             fmt_moment(moment_Nm), " give ", fmt_stress(tau), " shear against ",
             fmt_stress(pin_allowable_shear_fraction * structural_yield(post)),
             " allowable"));
    echo(str("          welded to the foot with a ", fmt_length(foot_leg),
             " fillet all round, set by ", weld_governing_mode(fw, t_thin), " - ",
             fmt_force_per_length(fw), " against ",
             fmt_force_per_length(weld_capacity_N_per_mm(foot_leg)),
             " - almost all of it BENDING, which the post's own section above is the",
             " real check on"));
    echo(str("          and to the base plate above with a ", fmt_length(top_leg),
             " fillet: no bending up there, the pull is applied at that end"));
    echo(str("          4 x ", bolt_size(bolt), " foot bolts on r ", fmt_length(r), ": ",
             fmt_force(shear), " shear, ", fmt_force(tens), " tension, allowable ",
             fmt_force(allow), " at a safety factor of ", bend_anchor_safety_factor));
    // The ceiling is quoted rather than written out, so it converts with everything else.
    echo(str("          working plane at ", fmt_length(height_mm),
             height_mm >= pedestal_braced_band[0] && height_mm <= pedestal_braced_band[1]
                 ? str(" - inside the braced band the ",
                       fmt_force(bend_operator_force_ceiling), " ceiling assumes")
                 : str(" - OUTSIDE the braced band; the ",
                       fmt_force(bend_operator_force_ceiling),
                       " ceiling does not apply here")));
}
