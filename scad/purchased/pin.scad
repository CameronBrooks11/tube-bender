/**
 * @file pin.scad
 * @brief Accessors for the rows in pins.scad, and the pins they describe
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Drawn head-down at the origin with the shank running up +z, so a hole
 * pattern can place one without arithmetic.
 *
 * The two clearances a pin gets are NOT the same number and must not be written as one.
 * A pivot pin turns in its hole for the life of the machine; an index pin is pulled and
 * repositioned by hand every few degrees of a bend, and JD2 drills its drive holes 1/8 in
 * oversize precisely so that is quick. See docs/design-basis.md section 7.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

function pin_name(type)            = type[0];  //! Registry name
function pin_size(type)            = type[1];  //! Imperial size, the identity you order by
function pin_diameter(type)        = type[2];  //! Shank diameter, mm
function pin_length(type)          = type[3];  //! Length under the head, mm
function pin_head_diameter(type)   = type[4];  //! Head diameter, mm
function pin_head_thickness(type)  = type[5];  //! Head thickness, mm
function pin_cotter_hole(type)     = type[6];  //! Cotter pin hole diameter, mm
function pin_cotter_from_end(type) = type[7];  //! Cotter hole centre to the pin's end, mm
function pin_part_no(type)         = type[8];  //! Order number, or undef if none is known

//! Whether this row describes something a second builder could actually order.
function pin_is_orderable(type) = !is_undef(pin_part_no(type));

//! Running clearance on the diameter for a pin that turns in its hole for the life of the
//! machine. REASONED, NOT CITED: no source read gives a fit for this joint, and the
//! consequence of getting it slightly loose is lost motion at the die rather than a
//! failure, so it is a machining allowance rather than a calculated fit.
pin_pivot_clearance = 0.4;

//! Clearance on the diameter for a pin that is pulled and repositioned by hand mid-bend,
//! as a FRACTION of the pin diameter.
//!
//! JD2 drills 1 in drive holes for a 7/8 in drive pin - 1/8 in oversize - "to provide
//! easier pin installation" [JD2-M32 p.7]. That is a real number for a real machine, and
//! it is stated as an absolute; it is carried here as the ratio it implies, 1/8 over 7/8,
//! because their bender is ONE size covering 1/2 to 2 in tube while this one scales. An
//! absolute 3.2 mm on the 6 mm drive pin a 3/8 in bender wants is not a clearance, it is
//! a slot.
pin_index_clearance_fraction = (1/8) / (7/8);

//! Hole diameter for a pin that turns in it.
function pin_pivot_hole(diameter) = diameter + pin_pivot_clearance;

//! Hole diameter for a pin that is indexed by hand.
function pin_index_hole(diameter) = diameter * (1 + pin_index_clearance_fraction);

//! Draw a clevis pin, head down, shank running up from z = 0.
module pin(type) {
    vitamin(str("pin(", pin_name(type), "): Pin clevis ", pin_size(type),
                pin_is_orderable(type) ? str(", ", pin_part_no(type))
                                       : ", NO ORDER NUMBER - this row is a hole in the BOM"));

    d = pin_diameter(type);

    color("silver") {
        translate_z(-pin_head_thickness(type))
            cylinder(d = pin_head_diameter(type), h = pin_head_thickness(type));

        render()
            difference() {
                cylinder(d = d, h = pin_length(type));

                translate([0, 0, pin_length(type) - pin_cotter_from_end(type)])
                    rotate([90, 0, 0])
                        cylinder(d = pin_cotter_hole(type), h = d + 2 * eps, center = true);
            }
    }
}
