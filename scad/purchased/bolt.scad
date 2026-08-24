/**
 * @file bolt.scad
 * @brief Accessors for the rows in bolts.scad, and the bolts they describe
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Drawn head-down at the origin, shank running up +z, matching pin().
 *
 * Sets no $fn, so the resolution of the calling file carries through - but the head is
 * drawn with $fn = 6 locally, because a hexagon is six-sided at every resolution.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

function bolt_name(type)     = type[0];  //! Registry name
function bolt_size(type)     = type[1];  //! Imperial size, the identity you order by
function bolt_diameter(type) = type[2];  //! Nominal diameter, mm
function bolt_part_no(type)  = type[3];  //! Order number, or undef if none is known

//! Whether this row describes something a second builder could actually order.
function bolt_is_orderable(type) = !is_undef(bolt_part_no(type));

//! Width across flats, mm. 1.5 x nominal, the ANSI hex head cap screw relation, checked
//! against the one measured row: 28.575 across flats on 19.05 nominal.
function bolt_across_flats(type) = 1.5 * bolt_diameter(type);

//! Head height, mm. 2/3 nominal, from the same measured row: 12.7 on 19.05.
function bolt_head_height(type) = 2 / 3 * bolt_diameter(type);

//! Clearance hole for a bolt that has to pass through rather than thread.
function bolt_clearance_hole(type) = bolt_clearance_hole_d(bolt_diameter(type));

//! The same, from a bare diameter, for callers that only have the number.
function bolt_clearance_hole_d(d) = d + 1;

//! Draw a bolt, head down, shank running up from z = 0.
module bolt(type, length) {
    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("bolt(", bolt_name(type), ", ", round(length), "): Bolt hex head ",
                bolt_size(type), " x ", fmt_length(length), ", with nut and washers",
                bolt_is_orderable(type) ? str(", ", bolt_part_no(type))
                                        : ", NO ORDER NUMBER - this row is a hole in the BOM"));

    color("silver") {
        translate_z(-bolt_head_height(type))
            cylinder(d = bolt_across_flats(type) / cos(30), h = bolt_head_height(type), $fn = 6);

        cylinder(d = bolt_diameter(type), h = length);
    }
}
