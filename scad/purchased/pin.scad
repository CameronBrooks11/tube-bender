/**
 * @file pin.scad
 * @brief Accessors for the rows in pins.scad, and the pins they describe
 * @author Cameron K. Brooks
 * @copyright 2026
 * @description Drawn head-down at the origin with the shank running up +z, so a hole
 * pattern can place one without arithmetic. Length is passed in, not registered - it is
 * the stack the pin has to cross.
 *
 * ## Grip in, usable length out
 *
 * The caller passes the GRIP: how much stack the pin has to hold together. What gets
 * ordered is the USABLE LENGTH - head underside to the cotter hole - and that comes in
 * quarter-inch steps, because a clevis pin's holes are spaced a quarter inch apart
 * [MCMASTER-CLEVIS]. So the grip is rounded up, and the slack that leaves is reported
 * rather than hidden: it is up to a quarter inch of washers, and a builder who does not
 * know that assembles a joint that rattles.
 *
 * ## What holds it in depends on how often it comes out
 *
 * A pivot pin is fitted once and forgotten, and a cotter is exactly right for it. An
 * INDEXED pin is pulled and replaced at every stroke of every bend - five times per bend
 * here - and a cotter is exactly wrong: nobody bends and unbends a split pin five times a
 * bend, and one that has been straightened twice is scrap. Those get a pin clip instead,
 * which comes off with a thumb.
 *
 * Either way the retainer is a BOM line. The holes were being drawn with nothing to go in
 * them.
 *
 * The two clearances a pin gets are NOT the same number and must not be written as one.
 * A pivot pin turns in its hole for the life of the machine; an index pin is pulled and
 * repositioned by hand every few degrees of a bend, and JD2 drills its drive holes 1/8 in
 * oversize precisely so that is quick. See docs/design-basis.md section 7.
 *
 * Sets no $fn, so the resolution of the calling file carries through.
 */

include <NopSCADlib/core.scad>;

use <../utils/units.scad>

function pin_name(type)            = type[0];  //! Registry name
function pin_size(type)            = type[1];  //! Imperial size, the identity you order by
function pin_diameter(type)        = type[2];  //! Shank diameter, mm
function pin_head_diameter(type)   = type[3];  //! Head diameter, mm, or undef if unlooked-up
function pin_head_thickness(type)  = type[4];  //! Head thickness, mm, or undef
function pin_cotter_hole(type)     = type[5];  //! Cotter pin hole diameter, mm, or undef
function pin_cotter_from_end(type) = type[6];  //! Cotter hole centre to the pin's end, mm
function pin_part_no(type)         = type[7];  //! Order number, or undef if none is known

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

//! The step a clevis pin's usable length comes in, mm.
//!
//! CATALOGUED: a clevis pin carries several cotter holes "spaced 1/4 inch apart", and which
//! one the cotter goes through is what sets the usable length [MCMASTER-CLEVIS]. So the
//! series is not a list of part numbers, it is an increment.
pin_length_step = inch(1/4);

//! The usable length to order for a pin that has to grip `mm` of stack.
function pin_usable_length(mm) = ceil(mm / pin_length_step - 1e-9) * pin_length_step;

//! How much the ordered pin overshoots the stack, mm - a washer stack, not a rounding
//! error. Never as much as one step.
function pin_slack(mm) = pin_usable_length(mm) - mm;

//! How far past the cotter hole a pin's own end runs, mm, where no row has been measured.
//!
//! REASONED, NOT CITED, and drawing only: nothing is sized from it and nothing is ordered by
//! it, because usable length is what a pin is bought by. Where the row HAS been looked up,
//! its measured cotter-hole-to-end is used instead - 3.99 mm on the 3/4 in pin, which is
//! what this stands in for.
pin_end_allowance = 3;

//! What holds a pin in, and it is not the same answer for every pin. See the file header:
//! "cotter" for one that is fitted and forgotten, "clip" for one that is pulled and
//! replaced every stroke.
//!
//! The SIZE of either is left open on purpose. Cotter geometry is looked up per row and is
//! undef on every row but the measured one, so naming a cotter size for the rest would be
//! exactly the invention the registry refuses. The row says which retainer and which pin it
//! belongs to, and the number is a shopping trip like the pin's own.
module pin_retainer(type, kind) {
    vitamin(str("pin_retainer(", pin_name(type), ", ", kind, "): ",
                kind == "clip" ? "Pin clip" : "Cotter pin",
                " to suit a ", pin_size(type), " clevis pin",
                kind == "clip" ? " that is pulled every stroke" : "",
                ", NO ORDER NUMBER - this row is a hole in the BOM"));
}

//! Draw a clevis pin gripping `grip` mm of stack, head down, shank running up from z = 0,
//! and bill it at the usable length you would order plus whatever holds it in.
//!
//! A row with no head geometry looked up yet draws as a bare shank, which is what it is: an
//! unspecified pin of a known diameter.
module pin(type, grip, retainer = "cotter") {
    d        = pin_diameter(type);
    headed   = !is_undef(pin_head_diameter(type));
    cottered = !is_undef(pin_cotter_hole(type));
    length   = pin_usable_length(grip);

    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("pin(", pin_name(type), ", ", round(length), "): Pin clevis ",
                pin_size(type), " x ", fmt_length(length), " usable",
                pin_is_orderable(type) ? str(", ", pin_part_no(type))
                                       : ", NO ORDER NUMBER - this row is a hole in the BOM"));

    pin_retainer(type, retainer);

    end_run = cottered ? pin_cotter_from_end(type) : pin_end_allowance;

    color("silver") {
        if (headed)
            translate_z(-pin_head_thickness(type))
                cylinder(d = pin_head_diameter(type), h = pin_head_thickness(type));

        render()
            difference() {
                cylinder(d = d, h = length + end_run);

                // The hole IS the usable length: that is where the retainer goes and where
                // the stack stops.
                if (cottered)
                    translate([0, 0, length])
                        rotate([90, 0, 0])
                            cylinder(d = pin_cotter_hole(type), h = d + 2 * eps, center = true);
            }
    }
}
