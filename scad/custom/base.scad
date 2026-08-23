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
use <../purchased/plate.scad>
use <frame_link.scad>

include <../utils/bend.scad>;

//! How far the plate stands out past the bolts and the frame link, mm.
//!
//! REASONED, NOT CITED: one bolt diameter beyond the bolt's own edge distance. It is a
//! spreader, so more is better and the limit is only material; this is the least that
//! looks deliberate.
function base_margin(bolt_d) = bolt_clearance_hole_d(bolt_d);

// There was a base_nominal_anchor_radius() here, to size a first bolt against a nominal
// inset before the real one was known. base_anchor_bolt() stopped needing it when the
// two-pass sizing was replaced by a direct filter, and it was left behind - DEAD, and
// broken with it: it called base_anchor_radius() with four arguments where the signature
// takes five, so the inset arrived as undef and the whole thing returned undef. Nothing
// called it, so nothing noticed. This is the missing-argument failure AGENTS.md warns
// about, sitting in the file for however long.

//! The radius a bolt of `bolt_d` actually gets, once its own edge distance is taken out of
//! the plate. Always SMALLER than the nominal, so the load goes UP when a bolt is chosen -
//! which is why one sizing pass is not enough. A 3/8 in bolt picked against the nominal
//! radius came out 1.6 % over its own allowable at the radius it then had.
function base_actual_anchor_radius(tube, clr, link_width, followbar_pin_d, bolt_d) =
    base_anchor_radius(tube, clr, link_width, followbar_pin_d,
                       plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1);

//! Plan size of the plate, [length, width] mm, along the frame link's axis and across it.
//! Set by the footprint it has to weld to and stand on, not by any fastener.
function base_size(tube, clr, link_width, followbar_pin_d) =
    [frame_link_reach(tube, clr, followbar_pin_d) + link_width, 2 * link_width];

//! The four anchor bolts, [x, y] each, in the plate's own frame - one inset at each corner.
function base_anchor_positions(tube, clr, link_width, followbar_pin_d, inset) =
    let (size = base_size(tube, clr, link_width, followbar_pin_d))
        [for (sx = [-1, 1], sy = [-1, 1])
             [sx * (size[0] / 2 - inset), sy * (size[1] / 2 - inset)]];

//! Distance from the pattern's centre to each anchor bolt, mm - the arm the torque works
//! on. FOUR bolts, not two: the shear in each is `M / (4 r)`.
function base_anchor_radius(tube, clr, link_width, followbar_pin_d, inset) =
    norm(base_anchor_positions(tube, clr, link_width, followbar_pin_d, inset)[0]);

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
function base_anchor_bolt(tube, clr, link_width, followbar_pin_d, moment_Nm, force_N,
                          yield_MPa, candidates) =
    let (fits = [for (b = candidates)
                     if (base_anchor_shear_N(moment_Nm,
                             base_actual_anchor_radius(tube, clr, link_width,
                                                       followbar_pin_d, bolt_diameter(b)),
                             force_N)
                         <= bend_anchor_bolt_allowable_N(bolt_diameter(b), yield_MPa))
                         bolt_diameter(b)])
        len(fits) == 0 ? undef
                       : [for (b = candidates) if (bolt_diameter(b) == min(fits)) b][0];

//! Bearing pressure the plate puts on whatever it is bolted to, MPa, if the operator's
//! whole pull were taken as a compression over the plate's area. A crude figure, and
//! reported rather than checked, because what it bears ON is not the model's to know -
//! mild steel shrugs at 1 MPa and softwood does not.
function base_bearing_MPa(force_N, size) = force_N / (size[0] * size[1]);

//! The base plate, lying on z = 0 with its long axis along the frame link.
module base(tube, clr, plate, link_width, followbar_pin_d, bolt_d) {
    size  = base_size(tube, clr, link_width, followbar_pin_d);
    inset = plate_eye_radius(bolt_clearance_hole_d(bolt_d)) + 1;
    mid   = frame_link_reach(tube, clr, followbar_pin_d) / 2;

    assert(inset * 2 < min(size),
           "base: the anchor bolts do not fit inside the plate - the frame link is too small for this load");

    render_2D_plate(plate)
      plate_2D(plate, size[0], size[1])
        offset(0)
            difference() {
                translate([mid, 0])
                    square([size[0], size[1]], center = true);

                for (p = base_anchor_positions(tube, clr, link_width, followbar_pin_d, inset))
                    translate(p + [mid, 0])
                        circle(d = bolt_clearance_hole_d(bolt_d));
            }
}

//! Echo what the anchorage comes out as.
module base_report(tube, clr, plate, link_width, followbar_pin_d, moment_Nm, force_N,
                   bolt, bolt_yield, working_height) {
    size   = base_size(tube, clr, link_width, followbar_pin_d);
    inset  = plate_eye_radius(bolt_clearance_hole_d(bolt_diameter(bolt))) + 1;
    r      = base_anchor_radius(tube, clr, link_width, followbar_pin_d, inset);
    shear  = base_anchor_shear_N(moment_Nm, r, force_N);
    allow  = bend_anchor_bolt_allowable_N(bolt_diameter(bolt), bolt_yield);

    echo(str("base:    ", plate_size(plate), " plate, ", round(size[0]), " x ",
             round(size[1]), " mm, lower frame link welded to it"));
    assert(shear <= allow,
           "base: the anchor bolts are over their allowable at the radius they end up with - size up");

    echo(str("         4 x ", bolt_size(bolt), " anchor bolts on r ", round(r), " mm, ",
             round(shear), " N each against ", round(allow),
             " N allowable at a safety factor of ", bend_anchor_safety_factor));
    echo(str("         the work happens ", round(working_height),
             " mm above the mounting surface, and it bears on it at ",
             round(base_bearing_MPa(force_N, size) * 100) / 100,
             " MPa - fine on steel, check it against a bench top"));
}
