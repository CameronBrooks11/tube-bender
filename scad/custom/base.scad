/**
 * @file base.scad
 * @brief What holds the machine still
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description The tube's far end is free, so the base is not carrying a weight. It is
 * reacting a TORQUE about the vertical pivot axis - the whole drive torque - plus the
 * operator's pull. See docs/design-basis.md section 10.
 *
 * ## One set of bolts does everything
 *
 * The two anchor bolts run down through the upper frame link, a spacer tube, the lower
 * frame link, this plate, and on through the mounting surface to nuts underneath. They
 * join the frame pair, set its spacing, and hold the machine down, all at once. That is
 * how JD2 does it - "using the Base as a template, drill two 3/4 holes through your
 * mounting surface" [JD2-M32 p.1] - and it is why the plate has no fasteners of its own.
 *
 * ## What the plate is actually for
 *
 * Not strength. The bolts carry the torque whether the plate is there or not. The plate
 * gives the frame links a flat to sit on and spreads their footprint into whatever they
 * are bolted to, which is the thing that actually fails first: a 3/4 in bolt will not
 * shear at these loads, but a wooden bench top crushes under one long before that.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/bolt.scad>
use <../utils/units.scad>
use <../purchased/plate.scad>
use <../utils/weld.scad>
use <frame_link.scad>
use <forming_die.scad>   // die_web(), the margin the plate stands out by

include <../utils/bend.scad>;

//! How far the plate stands out past the frame link it is welded to, mm.
//!
//! Enough for an anchor bolt to sit outside the link with a web to spare: the bolt keeps its
//! own edge distance off the plate's edge, and this puts its centre one web clear of the
//! link's outline. So the margin is derived rather than chosen - the only reasoned part is
//! the web, and that is `die_web()`, the dimension this model uses everywhere for "leave a
//! bit of room beside something".
function base_margin(tube, bolt_d) =
    plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1 + die_web(tube);

// There was a base_nominal_anchor_radius() here, to size a first bolt against a nominal
// inset before the real one was known. base_anchor_bolt() stopped needing it when the
// two-pass sizing was replaced by a direct filter, and it was left behind - DEAD, and
// broken with it: it called base_anchor_radius() with four arguments where the signature
// takes five, so the inset arrived as undef and the whole thing returned undef. Nothing
// called it, so nothing noticed. This is the missing-argument failure AGENTS.md warns
// about, sitting in the file for however long.

//! The plate, as [[x0, y0], [x1, y1]] mm in the frame link's own frame - which IS the
//! world's, so nothing has to be rotated to place it.
//!
//! It is the link's bounding box plus a margin. Set by the footprint it has to weld to and
//! stand on, not by any fastener - though the margin has to know the bolt, because the bolt
//! has to fit outside the link.
function base_rect(extents, tube, bolt_d) =
    let (m = base_margin(tube, bolt_d))
        [extents[0] - [m, m], extents[1] + [m, m]];

//! Plan size of the plate, [x, y] mm.
function base_size(rect) = rect[1] - rect[0];

//! Centre of the plate, [x, y] mm. NOT the pivot: the link is a star with three arms on one
//! side, so its box is nowhere near centred on the pin everything turns about.
function base_centre(rect) = (rect[0] + rect[1]) / 2;

//! The four anchor bolts, [x, y] each - one inset at each corner.
function base_anchor_positions(rect, bolt_d) =
    let (i = plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1,
         c = base_centre(rect),
         s = base_size(rect))
        [for (sx = [-1, 1], sy = [-1, 1])
             c + [sx * (s[0] / 2 - i), sy * (s[1] / 2 - i)]];

//! Distance from the pattern's centre to each anchor bolt, mm - the arm the torque works
//! on. FOUR bolts, not two: the shear in each is `M / (4 r)`.
//!
//! Measured from the bolt group's own centroid, not from the pivot, which is right because
//! a couple is a free vector: the drive torque about the pin is the same torque about the
//! group, and it is the group that has to resist it.
function base_anchor_radius(rect, bolt_d) =
    norm(base_anchor_positions(rect, bolt_d)[0] - base_centre(rect));

//! Shear in each of the four anchor bolts, N.
function base_anchor_shear_N(moment_Nm, radius_mm, force_N) =
    moment_Nm / (4 * radius_mm / 1000) + force_N / 4;

//! The smallest bolt in `candidates` that carries its load AT THE RADIUS IT ITSELF LEAVES,
//! or `undef` if none does.
//!
//! Not an iteration. Sizing this by passes is unstable in a way that is easy to miss: a
//! bigger bolt needs a bigger edge distance, which shrinks the radius, which RAISES the
//! load - so each pass can overshoot and the next undershoot. Two passes were tried and
//! held until the followbar moved 19 mm inboard, at which point the second pass was over
//! its own allowable and the assert caught it.
//!
//! Testing each candidate against its own consequences settles it in one go and cannot be
//! marginal by construction. `candidates` is passed rather than defaulted because a
//! default argument cannot see a list this file does not own.
//! Its own consequences now include the PLATE: a bigger bolt wants a bigger margin, which
//! makes the plate bigger, which makes its radius bigger. That pulls the opposite way to the
//! edge distance and does not change the shape of the answer.
function base_anchor_bolt(extents, tube, moment_Nm, force_N, yield_MPa, candidates) =
    let (fits = [for (b = candidates)
                     if (base_anchor_shear_N(moment_Nm,
                             base_anchor_radius(base_rect(extents, tube, bolt_diameter(b)),
                                                bolt_diameter(b)),
                             force_N)
                         <= bend_anchor_bolt_allowable_N(bolt_diameter(b), yield_MPa))
                         bolt_diameter(b)])
        len(fits) == 0 ? undef
                       : [for (b = candidates) if (bolt_diameter(b) == min(fits)) b][0];

//! The weld group that holds the machine down: two runs of fillet along the two long edges
//! of the lower frame link's followbar arm, where that arm lies on this plate.
//!
//! Only the followbar arm is counted. The link's lock arm is welded down as well and helps,
//! and leaving it out is free conservatism on a joint the code minimum governs anyway.
function base_weld_group(tube, clr, link_width, followbar_pin_d) =
    weld_group_parallel(frame_link_reach(tube, clr, followbar_pin_d), link_width);

//! Load on the worst millimetre of that weld, N/mm.
//!
//! The weld and the anchor bolts are IN SERIES on one path: everything the machine sheds
//! into the world crosses this joint, then the plate, then the bolts. So the weld carries
//! what the bolts carry - the drive torque about the pivot, and the operator's pull - and
//! the overturning that pull makes about the working plane on top of it.
function base_weld_load_N_per_mm(tube, clr, link_width, followbar_pin_d, moment_Nm, force_N,
                                 working_height) =
    weld_group_load(base_weld_group(tube, clr, link_width, followbar_pin_d),
                    moment_Nm * 1000, force_N * working_height, force_N);

//! Bearing pressure the plate puts on whatever it is bolted to, MPa, if the operator's
//! whole pull were taken as a compression over the plate's area. A crude figure, and
//! reported rather than checked, because what it bears ON is not the model's to know -
//! mild steel shrugs at 1 MPa and softwood does not.
function base_bearing_MPa(force_N, size) = force_N / (size[0] * size[1]);

//! The profile the base plate is cut from, on z = 0, in the frame link's own frame - which
//! is the world's, so it is drawn where it goes and nothing rotates it.
module base_2D(rect, plate, bolt_d) {
    size  = base_size(rect);
    inset = plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1;

    assert(inset * 2 < min(size),
           "base: the anchor bolts do not fit inside the plate - the frame link is too small for this load");

    plate_2D(plate, size[0], size[1])
        offset(0)
            difference() {
                translate(base_centre(rect))
                    square(size, center = true);

                for (p = base_anchor_positions(rect, bolt_d))
                    translate(p)
                        circle(d = bolt_clearance_hole_d(bolt_d));
            }
}

//! Echo what the anchorage comes out as.
module base_report(rect, tube, clr, plate, link_plate, link_width, followbar_pin_d,
                   moment_Nm, force_N, bolt, bolt_yield, working_height) {
    size   = base_size(rect);
    r      = base_anchor_radius(rect, bolt_diameter(bolt));
    shear  = base_anchor_shear_N(moment_Nm, r, force_N);
    allow  = bend_anchor_bolt_allowable_N(bolt_diameter(bolt), bolt_yield);
    // The weld runs along the frame link's EDGE, on top of this plate: a lap joint, so the
    // link's own thickness caps the fillet as well as setting the minimum.
    t_thin = min(plate_thickness(plate), plate_thickness(link_plate));
    wf     = base_weld_load_N_per_mm(tube, clr, link_width, followbar_pin_d, moment_Nm,
                                     force_N, working_height);
    leg    = weld_leg(wf, t_thin);
    run    = frame_link_reach(tube, clr, followbar_pin_d);

    echo(str("base:    ", plate_size(plate), " plate, ", fmt_bare_length(size[0]), " x ",
             fmt_length(size[1]), ", lower frame link welded to it"));
    assert(leg <= weld_max_edge_size(plate_thickness(link_plate)),
           "base: the weld the load wants is bigger than the frame link's edge can take - thicker link plate");
    assert(wf <= weld_base_metal_N_per_mm(t_thin, pin_allowable_shear_fraction * plate_yield(link_plate)),
           "base: the weld is over what the plate it lands on can carry - thicker plate, not a bigger weld");

    echo(str("         weld ", fmt_length(leg), " fillet both sides of the link, ",
             fmt_length(run), " each side, set by ", weld_governing_mode(wf, t_thin),
             " - E70XX, ", fmt_stress(weld_allowable_MPa()), " on the throat"));
    echo(str("         carrying ", fmt_force_per_length(wf), " against ",
             fmt_force_per_length(weld_capacity_N_per_mm(leg)), " at that leg"));
    assert(shear <= allow,
           "base: the anchor bolts are over their allowable at the radius they end up with - size up");

    echo(str("         4 x ", bolt_size(bolt), " anchor bolts on r ", fmt_length(r), ", ",
             fmt_force(shear), " each against ", fmt_force(allow),
             " allowable at a safety factor of ", bend_anchor_safety_factor));
    // What it bears ONTO is a bench or a floor, so this is a contact pressure - psi.
    echo(str("         the work happens ", fmt_length(working_height),
             " above the mounting surface, and it bears on it at ",
             fmt_pressure(base_bearing_MPa(force_N, size)),
             " - fine on steel, check it against a bench top"));
}
