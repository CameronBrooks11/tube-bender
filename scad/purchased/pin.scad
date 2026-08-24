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
 * ## Every pin here drops in, head up, and nothing holds it
 *
 * That is not a simplification, it is what the reference machine does. Searched end to end,
 * the Model 32 manual contains no cotter, no clip, no snap ring and no retainer of any kind
 * on any pin [JD2-M32]. They are plain pins, dropped into vertical holes, held by gravity,
 * with one operating instruction covering the lot: "make sure all pins are completely
 * seated in their holes... failure to do this may cause damage to the bender links or worse
 * yet the operator may slip and fall" [JD2-M32 p.7].
 *
 * The reason it works is that every hole on this machine is VERTICAL. Nothing here ever
 * turns a pin upside down: the die rotates about a vertical axis, so a pin that is upright
 * at the start of a bend is upright at the end of it.
 *
 * The reason it MATTERS is that all of them come out. The frame pin is pulled to load a
 * die and to get the drive links in; the drive pin is pulled at every stroke; the lock pin
 * is lifted to release the die. A pin with a cotter on it is a pin you cannot pull, and the
 * manual's own assembly step depends on being able to: bolts hand tight, pins in, then
 * "tighten the nuts as tightly as possible, while insuring the two pins are perfectly
 * vertical and slide easily through their respective holes" [JD2-M32 p.1]. The pins are the
 * alignment gauge.
 *
 * ## The head goes on TOP, and on some pins it is the only thing holding them up
 *
 * `seat` records what is UNDER a pin, because the two cases are not equally forgiving:
 *
 * - **"base"** - the frame, followbar and lock pins sit over the base plate, and it is what
 *   they land on. The head is then a handle and a stop for the plate above, not a structural
 *   necessity.
 * - **"stack"** - the drive, U-strap and spacer pins hang in the stack with nothing beneath
 *   them, so the head IS what holds them up. A row with no head dimensions looked up draws
 *   as a bare shank, and that is honest: nothing is holding that pin, in the drawing or on
 *   the bench, until somebody looks the part up.
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

//! Whether a head-seated pin's row knows what its head is - which is the only thing keeping
//! that pin from dropping through, so it is worth being able to ask.
function pin_head_is_known(type) = !is_undef(pin_head_diameter(type));

//! Draw a pin gripping `grip` mm of stack, shank running up from z = 0, and bill it at the
//! usable length you would order plus whatever holds it in.
//!
//! `seat` is what stops it dropping: "base" for a pin that lands on the base plate and is
//! therefore plain and headless, "head" for one that hangs in the stack on its own head,
//! which is then drawn on TOP. `retainer` is what stops it lifting - "cotter", "clip", or
//! "none" for a pin that is meant to come out. See the file header.
//!
//! A head-seated row with no head geometry looked up yet draws as a bare shank. That is
//! honest rather than convenient: nothing is holding that pin up, in the drawing or on the
//! bench, until somebody looks the part up.
module pin(type, grip, seat = "stack") {
    d      = pin_diameter(type);
    headed = pin_head_is_known(type);
    length = pin_usable_length(grip);

    // The key before the colon is the BOM's own identity for this part and stays in
    // millimetres in both systems, the way a part number would - it is what groups
    // identical items, not something anybody measures. Only the human half converts.
    vitamin(str("pin(", pin_name(type), ", ", round(length), "): Pin clevis ",
                pin_size(type), " x ", fmt_length(length), " usable",
                seat == "base" ? ", seats on the base plate" : "",
                pin_is_orderable(type)
                    ? str(", ", pin_part_no(type))
                    : ", NO ORDER NUMBER - this row is a hole in the BOM"));

    color("silver") {
        // On TOP. Every pin here goes in head up: on a stack-seated pin the head is the
        // only thing holding it, and on a base-seated one it is the handle you pull it out
        // by and the stop that keeps the plate above from lifting.
        if (headed)
            translate_z(length)
                cylinder(d = pin_head_diameter(type), h = pin_head_thickness(type));

        cylinder(d = d, h = length + (headed ? 0 : pin_end_allowance));
    }
}
