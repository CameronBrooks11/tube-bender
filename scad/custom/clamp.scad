/**
 * @file clamp.scad
 * @brief What holds the tube to the die while it is dragged round
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description The trade calls this the U-strap, and on both reference machines it is
 * one - a strap over the tube. Here it is a block, for the same reason the followbar is:
 * the die's groove holds the inboard half of the tube and this caps the outboard half.
 *
 * ## Removable, on purpose
 *
 * Two pins hold it, and pulling them takes it off. A closed channel in the die's tail
 * would be simpler and stronger and was rejected: you could then only load a tube by
 * threading it in from an end, which makes multi-bend parts impossible. JD2's own worked
 * example is a four-bend rollbar.
 *
 * Two pins rather than one, because one pin plus a tube that is being dragged along its
 * own axis is a hinge.
 *
 * ## The bolt
 *
 * The pins hold the block; the bolt stops the tube sliding through it. JD2: "tighten the
 * U-strap bolt to prevent the tube from slipping through the die while bending... If
 * bending thin wall tubing (.065 or thinner) you must always use the U-strap bolt", and
 * put a slice of larger tube between the bolt and the work so the bolt does not dimple it
 * [JD2-M32 p.7]. That pad is a consumable, not a part, and is not modelled.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../purchased/bolt.scad>
use <../utils/units.scad>
use <../purchased/pin.scad>
use <../purchased/plate.scad>
use <forming_die.scad>
use <die_plate.scad>

include <../utils/bend.scad>;
include <../purchased/plates.scad>;

//! Radial depth of the block, mm - the groove, the pins behind it, and a web each side.
function clamp_depth(tube, pin_d) =
    tube_od(tube) / 2 + 2 * die_web(tube) + pin_pivot_hole(pin_d);

//! Height, mm. The die's thickness, for the same reason the followbar has it: the bands
//! either side belong to the die plates and then the drive links.
function clamp_height(tube) = forming_die_thickness(tube);

//! The plate it is machined from.
function clamp_blank(tube) = plate_smallest_at_least(clamp_height(tube));

//! The block, drawn about the TUBE'S axis: x outboard, y along the tube, tube centreline
//! on the z = 0 line at x = 0.
module clamp(tube, clr, pin_d, bolt_d) {
    lc    = forming_die_tail_length(tube, clr);
    d     = clamp_depth(tube, pin_d);
    h     = clamp_height(tube);
    gr    = forming_die_groove_radius(tube);
    blank = clamp_blank(tube);
    px    = tube_od(tube) / 2 + die_web(tube) + pin_pivot_hole(pin_d) / 2;

    assert(!is_undef(blank), "clamp: no registered plate is thick enough for this blank");

    vitamin(str("clamp_blank(", plate_name(blank), "): ", plate_description(blank), " ",
                plate_size(blank), ", blank ", fmt_bare_length(d), " x ", fmt_length(lc),
                ", faced to ", fmt_length(h)));

    color(plate_colour(blank))
        render()
            difference() {
                translate([d / 2, -lc / 2, 0])
                    cube([d, lc, h], center = true);

                rotate([90, 0, 0])
                    cylinder(r = gr, h = lc + 2 * eps, center = true);

                for (y = [-lc / 4, -3 * lc / 4])
                    translate([px, y, 0])
                        cylinder(d = pin_pivot_hole(pin_d), h = h + 2 * eps, center = true);

                // The bolt that stops the tube sliding, threaded in from outboard at the
                // middle of the grip and aimed at the tube's centreline.
                translate([d + eps, -lc / 2, 0])
                    rotate([0, -90, 0])
                        cylinder(d = bolt_d, h = d - gr + 2 * eps);
            }
}

//! Echo what the clamp comes out as.
module clamp_report(tube, clr, pin_d, bolt, force_N) {
    echo(str("clamp:   ", fmt_bare_length(clamp_depth(tube, pin_d)), " x ",
             fmt_bare_length(forming_die_tail_length(tube, clr)), " x ",
             fmt_length(clamp_height(tube)), " from ", plate_size(clamp_blank(tube)),
             " plate, 2 pins and a ", bolt_size(bolt), " bolt"));
    echo(str("         holding ", fmt_force(force_N),
             " of tangential drag - the moment over the bend radius"));
}
