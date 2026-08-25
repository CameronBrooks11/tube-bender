/**
 * @file followbar.scad
 * @brief The pressure die: what the tube is squeezed against while it is drawn round
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A block outboard of the tube, downstream of the point of bend, carrying a
 * half-round groove that caps the half of the tube the forming die does not. It is pinned
 * to the frame links and stays put while the die turns.
 *
 * ## Its position is not free
 *
 * The straight tube between the point of bend and this block carries only this block's
 * force, so for the moment at the point of bend to reach `Mp`, the force here must be
 * `Mp / station` - closer in means a harder squeeze, further out means less control of the
 * tube. The station comes from the die's tail plus a clearance, and the force follows.
 *
 * ## Why it is only as tall as the die
 *
 * It sits in the die's own z band and no taller. The drive links occupy the bands either
 * side of that, and they sweep the whole radius - so anything of this block that stood
 * proud of the die would be in their path. The pin that holds it has the same problem and
 * cannot be solved the same way, which is what the sweep check in bend.scad is about.
 *
 * ## What is simplified
 *
 * A production followbar is a backing block with two inserts, and the rear one is ANGLED
 * relative to the tube axis "to 1/1000 of a degree from theoretically perfect for the tube
 * size and bend radius" to support the tube just past the point of bend [JD2-M32 p.5]. The
 * angle is not stated by any source read here and this block is drawn without it, as
 * design-basis section 5 committed to.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <forming_die.scad>

include <../utils/bend.scad>;
include <../purchased/plates.scad>;   // plate_smallest_at_least searches a list

//! How far outboard of the TUBE'S AXIS the followbar's pin sits, mm.
//!
//! Derived, and it is what closes the placeholder the frame link carried through Phase 3
//! and 4: half the tube to reach the groove's deepest point, a machining web behind it,
//! then half the pin. The frame link reads this rather than guessing at one tube diameter,
//! which is what it did before and was 19 mm too far out.
function followbar_pin_offset(tube, pin_d) =
    tube_od(tube) / 2 + die_web(tube) + pin_pivot_hole(pin_d) / 2;

//! Radial depth of the block, mm - the groove, the pin, and a web either side of it.
function followbar_depth(tube, pin_d) =
    followbar_pin_offset(tube, pin_d) + pin_pivot_hole(pin_d) / 2 + die_web(tube);

//! Height of the block, mm. The die's thickness exactly: taller and it fouls the drive
//! links, shorter and it stops capping the tube.
function followbar_height(tube) = forming_die_thickness(tube);

//! The plate the block is machined from, or `undef` if nothing is thick enough. It is as
//! tall as the die, so it comes off the same kind of stock the die does - NOT off the
//! plate the links are cut from, which is a tenth as thick. Passing the link's plate in
//! put "1/4 in plate, faced to 44.45 mm" on the bill of materials.
function followbar_blank(tube) = plate_smallest_at_least(followbar_height(tube));

//! The angles the block occupies as seen from the pivot, [min, max] SIGNED degrees.
//!
//! The followbar does not turn, but it is a big block sitting between the frame links and it
//! lands right where the space behind the die runs out - at 1-1/2 in it spans -55 to -27
//! degrees, and the die's tail only reaches -43. So anything looking for clear air between
//! the frame links has to take the followbar out as well as the parts that move, and it is
//! the followbar that sets the limit rather than the die.
//!
//! Signed rather than wrapped to 0-360, because every corner is outboard and downstream of
//! the pivot - x is at least the CLR and y is at most half the block short of the station -
//! so all four angles sit in the fourth quadrant and there is no wrap to handle.
function followbar_angles(tube, clr, pin_d) =
    let (d  = followbar_depth(tube, pin_d),
         lf = bend_followbar_length(tube),
         st = bend_followbar_station(tube, clr),
         a  = [for (x = [clr, clr + d], y = [-st - lf / 2, -st + lf / 2]) atan2(y, x)])
        [min(a), max(a)];

//! Bearing pressure on the tube, MPa, taken over the projected area the groove presses on.
//! Reported, not checked - the tube is being deliberately deformed a few millimetres away,
//! so there is no meaningful allowable here, only a number worth seeing.
function followbar_bearing_MPa(force_N, tube) =
    force_N / (tube_od(tube) * bend_followbar_length(tube));

//! The followbar, drawn about the TUBE'S axis: x runs outboard, y along the tube, and the
//! tube's centreline is the z = 0 line at x = 0.
module followbar(tube, pin_d) {
    lf    = bend_followbar_length(tube);
    d     = followbar_depth(tube, pin_d);
    h     = followbar_height(tube);
    gr    = forming_die_groove_radius(tube);
    blank = followbar_blank(tube);

    assert(!is_undef(blank), "followbar: no registered plate is thick enough for this blank");

    vitamin(str("followbar_blank(", plate_name(blank), "): ", plate_description(blank),
                " ", plate_size(blank), ", blank ", fmt_bare_length(d), " x ",
                fmt_length(lf), ", faced to ", fmt_length(h)));

    color(plate_colour(blank))
        render()
            difference() {
                translate([d / 2, 0, 0])
                    cube([d, lf, h], center = true);

                rotate([90, 0, 0])
                    cylinder(r = gr, h = lf + 2 * eps, center = true);

                translate([followbar_pin_offset(tube, pin_d), 0, 0])
                    cylinder(d = pin_pivot_hole(pin_d), h = h + 2 * eps, center = true);
            }
}

//! Echo what the followbar comes out as.
module followbar_report(tube, clr, pin_d, force_N) {
    echo(str("followbar: ", fmt_bare_length(followbar_depth(tube, pin_d)), " x ",
             fmt_bare_length(bend_followbar_length(tube)), " x ",
             fmt_length(followbar_height(tube)), ", pin ",
             fmt_length(followbar_pin_offset(tube, pin_d)),
             " outboard of the tube's axis, from ",
             plate_size(followbar_blank(tube)), " plate"));
    // A contact pressure, so psi rather than ksi - see utils/units.scad.
    echo(str("           ", fmt_force(force_N), " onto the tube at ",
             fmt_pressure(followbar_bearing_MPa(force_N, tube)),
             " over its projected area"));
}
