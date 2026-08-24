/**
 * @file die_plate.scad
 * @brief The plate above and below the die, and the only thing the clamp can hold on to
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description A pair of these bolt to the die's faces and turn with it. They exist for
 * one reason, and it is worth being explicit about because a one-piece die does not
 * otherwise need them: **they reach outboard past the tube on the die's tail, and that is
 * the only material anywhere that the clamp can be pinned to.**
 *
 * The die itself cannot offer it. Its tail ends at the CLR, which is where the tube's
 * groove is; there is 3.2 mm of land above and below that groove and nothing beyond it.
 * The bands either side of the die belong to the drive links, and the clamp cannot share
 * them: it is FIXED TO THE DIE and turns with it, so it visits every angle in the arc,
 * including whichever one a drive link is standing in. (That is what separates it from the
 * die lock pin, which is fixed to the FRAME, never moves, and can therefore live in an
 * angle the links do not reach - see design-basis section 17.)
 *
 * The plates fit in the gap that is left - outside the die, inside the drive links - and
 * their tail overhangs the tube where nothing else can.
 *
 * The prototype arrived at the same answer, with a 6.35 mm tongue on its clamp running in
 * a slot in plates just like these. This model reached it from the constraints instead,
 * and then found the prototype had been there first.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/bolt.scad>
use <../utils/units.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <forming_die.scad>

include <../utils/bend.scad>;

//! How far past the tube's outer surface the tail overhangs, mm - enough for the clamp's
//! pins and a web either side of them.
function die_plate_overhang(tube, clamp_pin_d) =
    2 * die_web(tube) + pin_pivot_hole(clamp_pin_d);

//! Outboard edge of the tail, mm from the pivot.
function die_plate_tail_edge(tube, clr, clamp_pin_d) =
    clr + tube_od(tube) / 2 + die_plate_overhang(tube, clamp_pin_d);

//! Where the clamp's two pins sit, as [x, y] in the die's frame. Both in the overhang,
//! spread along the tail so the clamp cannot rotate about either of them.
function die_plate_clamp_pins(tube, clr, clamp_pin_d) =
    let (x  = clr + tube_od(tube) / 2 + die_web(tube) + pin_pivot_hole(clamp_pin_d) / 2,
         lc = forming_die_tail_length(tube, clr))
        [[x, -lc / 4], [x, -3 * lc / 4]];

//! Radius of the circle that bolts the plates to the die, mm - inside the drive holes,
//! outside the hub, with a web each way.
function die_plate_bolt_radius(tube, clr, frame_pin_d, drive_pin_d, bolt_d) =
    (forming_die_hub_radius(tube, frame_pin_d) + plate_eye_radius(bolt_clearance_hole_d(bolt_d))
     + forming_die_drive_radius(tube, clr, drive_pin_d)
       - pin_index_hole(drive_pin_d) / 2 - plate_eye_radius(bolt_clearance_hole_d(bolt_d))) / 2;

//! Where those bolts sit, spread evenly over the die's arc.
function die_plate_bolt_positions(tube, clr, frame_pin_d, drive_pin_d, bolt_d, bend_angle,
                                  n) =
    let (r   = die_plate_bolt_radius(tube, clr, frame_pin_d, drive_pin_d, bolt_d),
         arc = forming_die_arc(bend_angle))
        [for (i = [0 : n - 1])
             let (a = arc * (i + 0.5) / n) r * [cos(a), sin(a)]];

//! Shear in each of those bolts, N.
//!
//! The clamp drags the tube round, so its force reaches the die through these bolts, and
//! it arrives as a force AND the moment it makes about the pivot - which is the full
//! bending moment, because that is what the clamp is holding. Standard bolt group: the
//! direct share plus the torsional share, `F/n + M/(n r)`.
function die_plate_bolt_shear_N(moment_Nm, clr, radius_mm, n) =
    bend_clamp_force_N(moment_Nm, clr) / n + moment_Nm * 1000 / (n * radius_mm);

//! The profile the plate is cut from, on z = 0, pivot at the origin, in the die's own
//! frame.
module die_plate_2D(tube, clr, plate, bend_angle, frame_pin_d, drive_pin_d, clamp_pin_d,
                    bolt_d, n_bolts) {
    arc   = forming_die_arc(bend_angle);
    lc    = forming_die_tail_length(tube, clr);
    edge  = die_plate_tail_edge(tube, clr, clamp_pin_d);
    depth = edge - (clr - forming_die_tail_depth(tube));
    steps = max(8, ceil(arc / 3));
    drives = forming_die_drive_angles(tube, clr, frame_pin_d, drive_pin_d, bend_angle);
    r_drv  = forming_die_drive_radius(tube, clr, drive_pin_d);

    plate_2D(plate, 2 * clr, clr + lc)
        offset(0)
            difference() {
                union() {
                    polygon([[0, 0],
                             for (i = [0 : steps]) let (a = arc * i / steps)
                                 clr * [cos(a), sin(a)]]);

                    circle(r = forming_die_hub_radius(tube, frame_pin_d));

                    translate([edge - depth, -lc])
                        square([depth, lc]);
                }

                circle(d = pin_pivot_hole(frame_pin_d));

                for (a = drives)
                    rotate(a) translate([r_drv, 0])
                        circle(d = pin_index_hole(drive_pin_d));

                for (p = die_plate_clamp_pins(tube, clr, clamp_pin_d))
                    translate(p) circle(d = pin_pivot_hole(clamp_pin_d));

                for (p = die_plate_bolt_positions(tube, clr, frame_pin_d, drive_pin_d,
                                                  bolt_d, bend_angle, n_bolts))
                    translate(p) circle(d = bolt_clearance_hole_d(bolt_d));
            }
}

//! Echo what the plates come out as.
module die_plate_report(tube, clr, plate, bend_angle, frame_pin_d, drive_pin_d, clamp_pin_d,
                        bolt, bolt_yield, n_bolts, moment_Nm) {
    r     = die_plate_bolt_radius(tube, clr, frame_pin_d, drive_pin_d, bolt_diameter(bolt));
    shear = die_plate_bolt_shear_N(moment_Nm, clr, r, n_bolts);
    allow = pin_allowable_shear_fraction * bolt_yield * PI * pow(bolt_diameter(bolt), 2) / 4;

    echo(str("die plate: ", plate_size(plate), " plate, tail overhangs to r ",
             fmt_length(die_plate_tail_edge(tube, clr, clamp_pin_d)),
             " so the clamp has something to pin to"));
    echo(str("           ", n_bolts, " x ", bolt_size(bolt), " to the die on r ",
             fmt_length(r), ", ", fmt_force(shear), " each against ", fmt_force(allow),
             " at yield"));
}
